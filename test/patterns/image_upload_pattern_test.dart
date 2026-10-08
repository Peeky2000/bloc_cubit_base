// Reference implementation: pick an image and upload it with progress.
//
// Pattern: .agents/skills/flutter-patterns/references/image_upload.md
// Decision: docs/decisions/D-0004-upload-anh-co-tien-trinh.md
//
// Picking needs a plugin that is not in pubspec yet (`image_picker`, proposed
// in D-0004), so the picker is a domain port with a documented adapter sketch
// and a fake here. Uploading uses real Dio (FormData, onSendProgress,
// CancelToken) against a fake HttpClientAdapter, so no network is used.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:bloc_cubit_base/data/datasource/remote/api_client.dart';
import 'package:bloc_cubit_base/data/model/response/base_response_model.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/media/local_image.dart
// ---------------------------------------------------------------------------

/// A picked image on the device. Domain keeps a path, never a dart:io File.
final class LocalImage extends Equatable {
  const LocalImage({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  @override
  List<Object?> get props => [path, fileName, mimeType, sizeBytes];
}

/// An image stored on the server.
final class UploadedImage extends Equatable {
  const UploadedImage({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/media_picker_repo.dart
// ---------------------------------------------------------------------------

enum MediaSource { camera, gallery }

/// How a pick ended. A failure is thrown as [MediaPickFailure].
sealed class PickImageOutcome {
  const PickImageOutcome();
}

final class ImagePicked extends PickImageOutcome {
  const ImagePicked(this.image);

  final LocalImage image;
}

/// The user closed the picker. Not an error; the caller does nothing.
final class PickCancelled extends PickImageOutcome {
  const PickCancelled();
}

enum MediaPickFailureCode { permissionDenied, unavailable, unknown }

final class MediaPickFailure implements Exception {
  const MediaPickFailure(this.code);

  final MediaPickFailureCode code;

  @override
  String toString() => 'MediaPickFailure($code)';
}

abstract class MediaPickerRepo {
  /// Opens the system picker and completes once with the outcome. Images are
  /// downscaled by the adapter before they are returned.
  Future<PickImageOutcome> pickImage(MediaSource source);
}

// ---------------------------------------------------------------------------
// lib/data/repositories/image_picker_media_repo.dart  (adapter sketch)
//
// Needs `image_picker` (D-0004). Not compiled here because the package is not
// in pubspec; the fake below plays it in tests.
//
//   @LazySingleton(as: MediaPickerRepo)
//   class ImagePickerMediaRepo implements MediaPickerRepo {
//     ImagePickerMediaRepo(this._picker);   // ImagePicker from RegisterModule
//     final ImagePicker _picker;
//
//     @override
//     Future<PickImageOutcome> pickImage(MediaSource source) async {
//       try {
//         final file = await _picker.pickImage(
//           source: source == MediaSource.camera
//               ? ImageSource.camera
//               : ImageSource.gallery,
//           maxWidth: 2048,
//           maxHeight: 2048,
//           imageQuality: 85,
//         );
//         if (file == null) return const PickCancelled();
//         return ImagePicked(LocalImage(
//           path: file.path,
//           fileName: file.name,
//           mimeType: file.mimeType ?? lookupMimeType(file.path) ?? '',
//           sizeBytes: await file.length(),
//         ));
//       } on PlatformException catch (error) {
//         throw MediaPickFailure(switch (error.code) {
//           'camera_access_denied' || 'photo_access_denied' =>
//             MediaPickFailureCode.permissionDenied,
//           'no_available_camera' => MediaPickFailureCode.unavailable,
//           _ => MediaPickFailureCode.unknown,
//         });
//       }
//     }
//   }
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// lib/domain/repositories/image_upload_repo.dart
// ---------------------------------------------------------------------------

/// Events of one upload. Progress repeats; exactly one terminal event follows
/// unless the stream errors with [UploadFailure].
sealed class UploadEvent {
  const UploadEvent();
}

final class UploadProgress extends UploadEvent {
  const UploadProgress({required this.sentBytes, required this.totalBytes});

  final int sentBytes;

  /// -1 when the size is unknown.
  final int totalBytes;

  /// 0..1, or null for an indeterminate indicator.
  double? get fraction =>
      totalBytes > 0 ? (sentBytes / totalBytes).clamp(0, 1).toDouble() : null;
}

final class UploadCompleted extends UploadEvent {
  const UploadCompleted(this.image);

  final UploadedImage image;
}

/// A newer upload for the same slot replaced this one; do nothing.
final class UploadSuperseded extends UploadEvent {
  const UploadSuperseded();
}

enum UploadFailureCode { tooLarge, unsupportedType, network, server }

final class UploadFailure implements Exception {
  const UploadFailure(this.code);

  final UploadFailureCode code;

  @override
  String toString() => 'UploadFailure($code)';
}

abstract class ImageUploadRepo {
  /// Uploads [image] into [slot] (for example `profile-photo`). Starts when
  /// listened to. Cancelling the subscription cancels the HTTP request. A
  /// newer upload for the same slot ends this one with [UploadSuperseded].
  Stream<UploadEvent> upload(LocalImage image, {required String slot});
}

// ---------------------------------------------------------------------------
// lib/domain/use_case/image_use_case.dart
// ---------------------------------------------------------------------------

class ImageUseCase {
  ImageUseCase(this._picker, this._uploads);

  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> allowedTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  };
  static const String profilePhotoSlot = 'profile-photo';

  final MediaPickerRepo _picker;
  final ImageUploadRepo _uploads;

  Future<PickImageOutcome> pickImage(MediaSource source) =>
      _picker.pickImage(source);

  /// Product rules run before any byte is sent.
  Stream<UploadEvent> uploadProfilePhoto(LocalImage image) {
    if (!allowedTypes.contains(image.mimeType.toLowerCase())) {
      return Stream.error(
        const UploadFailure(UploadFailureCode.unsupportedType),
      );
    }
    if (image.sizeBytes > maxBytes) {
      return Stream.error(const UploadFailure(UploadFailureCode.tooLarge));
    }
    return _uploads.upload(image, slot: profilePhotoSlot);
  }
}

// ---------------------------------------------------------------------------
// Base change to propose: `ApiHandler.upload` in
// lib/data/datasource/remote/api_client.dart. ApiClient implements it with
// its configured `_dio` inside `_remapError`, so auth, session refresh and
// the network inspector apply to uploads too. Shown here as a separate type
// because this change may not edit lib/.
// ---------------------------------------------------------------------------

abstract class UploadApiHandler {
  Future<BaseResponseModel<T>> upload<T>(
    String path, {
    required FormData data,
    required ApiResponseToModelParser<T> parser,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });
}

class DioUploadApiHandler implements UploadApiHandler {
  DioUploadApiHandler(this._dio);

  /// ApiClient's 30 s sendTimeout covers the whole body; an upload on a slow
  /// network needs longer.
  static const Duration sendTimeout = Duration(minutes: 2);

  final Dio _dio;

  @override
  Future<BaseResponseModel<T>> upload<T>(
    String path, {
    required FormData data,
    required ApiResponseToModelParser<T> parser,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(sendTimeout: sendTimeout),
      );
      return BaseResponseModel<T>.fromJson(
        response.data! as Map<String, dynamic>,
        (json) => parser(json as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      // Same mapping as ApiClient._apiErrorToInternalError.
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          (error.type == DioExceptionType.unknown &&
              error.error is SocketException)) {
        throw NetworkIssueException();
      }
      throw ServerException(error);
    }
  }
}

// ---------------------------------------------------------------------------
// lib/data/model/response/media/uploaded_image_response_model.dart
// ---------------------------------------------------------------------------

class UploadedImageResponseModel {
  UploadedImageResponseModel({required this.id, required this.url});

  factory UploadedImageResponseModel.fromJson(Map<String, dynamic> json) =>
      UploadedImageResponseModel(
        id: json['id'] as String,
        url: json['url'] as String,
      );

  final String id;
  final String url;

  UploadedImage toEntity() => UploadedImage(id: id, url: url);
}

// ---------------------------------------------------------------------------
// lib/data/datasource/remote/image_remote_data_source.dart
// ---------------------------------------------------------------------------

abstract class ImageRemoteDataSource {
  Future<UploadedImageResponseModel> upload(
    LocalImage image, {
    required String slot,
    required void Function(int sent, int total) onProgress,
    required CancelToken cancelToken,
  });
}

// @LazySingleton(as: ImageRemoteDataSource)
class ImageRemoteDataSourceImpl implements ImageRemoteDataSource {
  ImageRemoteDataSourceImpl(this._api);

  final UploadApiHandler _api;

  @override
  Future<UploadedImageResponseModel> upload(
    LocalImage image, {
    required String slot,
    required void Function(int sent, int total) onProgress,
    required CancelToken cancelToken,
  }) async {
    // Streams the file from disk; the image is never held in memory whole.
    final form = FormData.fromMap({
      'slot': slot,
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.fileName,
        contentType: DioMediaType.parse(image.mimeType),
      ),
    });
    final response = await _api.upload<UploadedImageResponseModel>(
      '/media/images',
      data: form,
      parser: UploadedImageResponseModel.fromJson,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) throw ServerException(null);
    return data;
  }
}

// ---------------------------------------------------------------------------
// lib/data/repositories/image_upload_repo_impl.dart
// ---------------------------------------------------------------------------

// @LazySingleton(as: ImageUploadRepo)
class ImageUploadRepoImpl implements ImageUploadRepo {
  ImageUploadRepoImpl(this._remote);

  final ImageRemoteDataSource _remote;
  final Map<String, _ActiveUpload> _active = {};

  @override
  Stream<UploadEvent> upload(LocalImage image, {required String slot}) {
    _active.remove(slot)?.supersede();
    final token = CancelToken();
    final controller = StreamController<UploadEvent>();
    final active = _ActiveUpload(controller, token);
    _active[slot] = active;

    void finish() {
      if (_active[slot] == active) _active.remove(slot);
    }

    controller.onListen = () => _run(image, slot, active, finish);
    controller.onCancel = () {
      finish();
      if (!token.isCancelled) token.cancel('subscription cancelled');
    };
    return controller.stream;
  }

  Future<void> _run(
    LocalImage image,
    String slot,
    _ActiveUpload active,
    void Function() finish,
  ) async {
    var lastPercent = -1;
    try {
      final result = await _remote.upload(
        image,
        slot: slot,
        cancelToken: active.token,
        onProgress: (sent, total) {
          // Dio reports every chunk; send at most one event per percent.
          final percent = total > 0 ? sent * 100 ~/ total : -1;
          if (percent == lastPercent) return;
          lastPercent = percent;
          active.add(UploadProgress(sentBytes: sent, totalBytes: total));
        },
      );
      active.add(UploadCompleted(result.toEntity()));
    } on NetworkIssueException {
      active.addError(const UploadFailure(UploadFailureCode.network));
    } on ServerException catch (error) {
      final status = error.error is DioException
          ? (error.error as DioException).response?.statusCode
          : null;
      active.addError(
        UploadFailure(switch (status) {
          413 => UploadFailureCode.tooLarge,
          415 => UploadFailureCode.unsupportedType,
          _ => UploadFailureCode.server,
        }),
      );
    } catch (_) {
      active.addError(const UploadFailure(UploadFailureCode.server));
    } finally {
      finish();
      await active.close();
    }
  }
}

class _ActiveUpload {
  _ActiveUpload(this._controller, this.token);

  final StreamController<UploadEvent> _controller;
  final CancelToken token;

  void add(UploadEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void addError(UploadFailure failure) {
    if (!_controller.isClosed) _controller.addError(failure);
  }

  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }

  void supersede() {
    add(const UploadSuperseded());
    if (!token.isCancelled) token.cancel('superseded');
    // Late Dio callbacks are dropped because the controller is closed.
    unawaited(close());
  }
}

// ---------------------------------------------------------------------------
// lib/presentation/profile_photo/cubit/profile_photo_effect.dart  (part)
// ---------------------------------------------------------------------------

enum ProfilePhotoRetryAction { pick, upload }

sealed class ProfilePhotoEffect {
  const ProfilePhotoEffect();
}

final class ProfilePhotoUploadedEffect extends ProfilePhotoEffect {
  const ProfilePhotoUploadedEffect();
}

/// `MediaPickFailure(permissionDenied)` is shown with an "open settings"
/// action, see references/permission.md.
final class ProfilePhotoShowErrorEffect extends ProfilePhotoEffect {
  const ProfilePhotoShowErrorEffect({
    required this.error,
    required this.retryAction,
  });

  final Object error;
  final ProfilePhotoRetryAction retryAction;
}

// ---------------------------------------------------------------------------
// lib/presentation/profile_photo/cubit/profile_photo_state.dart  (part)
// ---------------------------------------------------------------------------

class ProfilePhotoState extends BaseAppState<Object> {
  const ProfilePhotoState({
    required super.loading,
    super.error,
    this.photo,
    this.pending,
    this.progress,
    this.effect,
  });

  factory ProfilePhotoState.initial({UploadedImage? photo}) =>
      ProfilePhotoState(loading: LoadingStatus.initial, photo: photo);

  /// The photo stored on the server.
  final UploadedImage? photo;

  /// The picked image being uploaded or waiting for retry. The Screen shows
  /// it from disk as a preview over [photo].
  final LocalImage? pending;

  /// 0..1 while uploading, null for indeterminate or idle.
  final double? progress;

  final UiEffect<ProfilePhotoEffect>? effect;

  bool get isUploading => loading == LoadingStatus.loading;

  bool get canRetry => pending != null && loading == LoadingStatus.error;

  ProfilePhotoState copyWith({
    LoadingStatus? loading,
    Object? error,
    UploadedImage? photo,
    LocalImage? pending,
    double? progress,
    bool clearPending = false,
    UiEffect<ProfilePhotoEffect>? effect,
  }) {
    return ProfilePhotoState(
      loading: loading ?? this.loading,
      error: error,
      photo: photo ?? this.photo,
      pending: clearPending ? null : pending ?? this.pending,
      progress: clearPending ? null : progress ?? this.progress,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, photo, pending, progress, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/profile_photo/cubit/profile_photo_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class ProfilePhotoCubit extends BaseCubit<ProfilePhotoState> {
  ProfilePhotoCubit(this._useCase) : super(ProfilePhotoState.initial());

  final ImageUseCase _useCase;
  StreamSubscription<UploadEvent>? _upload;
  Completer<void>? _uploadDone;

  Future<void> pickFrom(MediaSource source) async {
    final PickImageOutcome outcome;
    try {
      outcome = await _useCase.pickImage(source);
    } catch (error) {
      if (isClosed) return;
      _emitEffect(
        ProfilePhotoShowErrorEffect(
          error: error,
          retryAction: ProfilePhotoRetryAction.pick,
        ),
      );
      return;
    }
    if (isClosed) return;
    switch (outcome) {
      case PickCancelled():
        return;
      case ImagePicked(:final image):
        await _start(image);
    }
  }

  Future<void> retryUpload() async {
    final image = state.pending;
    if (image != null && !state.isUploading) await _start(image);
  }

  /// User tapped cancel: stop the request and drop the preview.
  void cancelUpload() {
    _stop();
    emit(state.copyWith(loading: LoadingStatus.initial, clearPending: true));
  }

  Future<void> _start(LocalImage image) {
    _stop();
    emit(
      state.copyWith(
        loading: LoadingStatus.loading,
        pending: image,
        progress: 0,
      ),
    );
    final done = _uploadDone = Completer<void>();
    _upload = _useCase
        .uploadProfilePhoto(image)
        .listen(
          _onEvent,
          onError: (Object error) {
            _onError(error);
            _complete(done);
          },
          onDone: () => _complete(done),
          cancelOnError: true,
        );
    return done.future;
  }

  void _onEvent(UploadEvent event) {
    if (isClosed) return;
    switch (event) {
      case UploadProgress():
        emit(state.copyWith(progress: event.fraction));
      case UploadCompleted(:final image):
        emit(
          state.copyWith(
            loading: LoadingStatus.complete,
            photo: image,
            clearPending: true,
          ),
        );
        _emitEffect(const ProfilePhotoUploadedEffect());
      case UploadSuperseded():
        return;
    }
  }

  void _onError(Object error) {
    if (isClosed) return;
    // Keep the preview so the user can retry without picking again.
    emit(state.copyWith(loading: LoadingStatus.error, error: error));
    _emitEffect(
      ProfilePhotoShowErrorEffect(
        error: error,
        retryAction: ProfilePhotoRetryAction.upload,
      ),
    );
  }

  void _stop() {
    unawaited(_upload?.cancel());
    _upload = null;
    final done = _uploadDone;
    if (done != null) _complete(done);
  }

  static void _complete(Completer<void> done) {
    if (!done.isCompleted) done.complete();
  }

  void _emitEffect(ProfilePhotoEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  late Directory tempDir;
  late LocalImage image;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('upload_pattern');
    final file = File('${tempDir.path}/photo.jpg')
      ..writeAsBytesSync(Uint8List(300 * 1024));
    image = LocalImage(
      path: file.path,
      fileName: 'photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: file.lengthSync(),
    );
  });

  tearDownAll(() => tempDir.deleteSync(recursive: true));

  group('remote data source over real Dio', () {
    late _FakeHttpAdapter adapter;
    late ImageRemoteDataSourceImpl remote;

    setUp(() {
      adapter = _FakeHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      remote = ImageRemoteDataSourceImpl(DioUploadApiHandler(dio));
    });

    test('sends multipart with progress and parses the result', () async {
      final progress = <int>[];

      final result = await remote.upload(
        image,
        slot: 'profile-photo',
        cancelToken: CancelToken(),
        onProgress: (sent, total) => progress.add(sent),
      );

      final request = adapter.request!;
      expect(request.path, '/media/images');
      expect(request.method, 'POST');
      expect(request.sendTimeout, DioUploadApiHandler.sendTimeout);
      expect(request.headers['content-type'], contains('multipart/form-data'));
      final body = latin1.decode(adapter.body);
      expect(body, contains('filename="photo.jpg"'));
      expect(body, contains('content-type: image/jpeg'));
      expect(body, contains('name="slot"'));
      expect(progress.length, greaterThan(2));
      expect(progress.last, adapter.body.length);
      expect(result.url, 'https://cdn.test/img-1.jpg');
    });

    test('a cancelled token aborts the request', () async {
      adapter.hold = Completer<void>();
      final token = CancelToken();

      final uploading = remote.upload(
        image,
        slot: 'profile-photo',
        cancelToken: token,
        onProgress: (_, _) {},
      );
      await pumpEventQueue();
      token.cancel();

      await expectLater(uploading, throwsA(isA<ServerException>()));
    });

    test('HTTP 413 surfaces as a ServerException with the status', () async {
      adapter.status = 413;

      await expectLater(
        remote.upload(
          image,
          slot: 'profile-photo',
          cancelToken: CancelToken(),
          onProgress: (_, _) {},
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => (e.error as DioException).response?.statusCode,
            'status',
            413,
          ),
        ),
      );
    });
  });

  group('ImageUploadRepoImpl', () {
    late _FakeImageRemote remote;
    late ImageUploadRepoImpl repo;

    setUp(() {
      remote = _FakeImageRemote();
      repo = ImageUploadRepoImpl(remote);
    });

    test('progress at most once per percent, then completed', () async {
      remote.chunks = 1000;

      final events = await repo.upload(image, slot: 's').toList();

      final progress = events.whereType<UploadProgress>().toList();
      expect(progress.length, 101);
      expect(progress.last.fraction, 1);
      expect(events.last, isA<UploadCompleted>());
    });

    test('transport failures become typed UploadFailure', () async {
      remote.failWith = NetworkIssueException();
      await expectLater(
        repo.upload(image, slot: 's'),
        emitsThrough(
          emitsError(
            isA<UploadFailure>().having(
              (f) => f.code,
              'code',
              UploadFailureCode.network,
            ),
          ),
        ),
      );

      remote.failWith = ServerException(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 413),
        ),
      );
      await expectLater(
        repo.upload(image, slot: 's'),
        emitsThrough(
          emitsError(
            isA<UploadFailure>().having(
              (f) => f.code,
              'code',
              UploadFailureCode.tooLarge,
            ),
          ),
        ),
      );
    });

    test('cancelling the subscription cancels the request', () async {
      remote.hold = Completer<void>();
      final sub = repo.upload(image, slot: 's').listen((_) {});
      await pumpEventQueue();

      await sub.cancel();

      expect(remote.lastToken!.isCancelled, isTrue);
    });

    test('a newer upload for the same slot supersedes the older', () async {
      remote.hold = Completer<void>();
      final older = <UploadEvent>[];
      final olderDone = Completer<void>();
      repo
          .upload(image, slot: 's')
          .listen(older.add, onDone: olderDone.complete);
      await pumpEventQueue();
      final olderToken = remote.lastToken!;

      remote.hold = null;
      final newer = await repo.upload(image, slot: 's').toList();
      await olderDone.future;

      expect(older.last, isA<UploadSuperseded>());
      expect(olderToken.isCancelled, isTrue);
      expect(newer.last, isA<UploadCompleted>());
    });

    test('different slots upload side by side', () async {
      final results = await Future.wait([
        repo.upload(image, slot: 'a').last,
        repo.upload(image, slot: 'b').last,
      ]);

      expect(results, everyElement(isA<UploadCompleted>()));
    });
  });

  group('ImageUseCase', () {
    late _FakeImageRemote remote;
    late ImageUseCase useCase;

    setUp(() {
      remote = _FakeImageRemote();
      useCase = ImageUseCase(_FakePicker(), ImageUploadRepoImpl(remote));
    });

    test('rejects a too large or unsupported file before sending', () async {
      await expectLater(
        useCase.uploadProfilePhoto(
          LocalImage(
            path: image.path,
            fileName: 'big.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: ImageUseCase.maxBytes + 1,
          ),
        ),
        emitsError(const TypeMatcher<UploadFailure>()),
      );
      await expectLater(
        useCase.uploadProfilePhoto(
          LocalImage(
            path: image.path,
            fileName: 'a.gif',
            mimeType: 'image/gif',
            sizeBytes: 10,
          ),
        ),
        emitsError(
          isA<UploadFailure>().having(
            (f) => f.code,
            'code',
            UploadFailureCode.unsupportedType,
          ),
        ),
      );
      expect(remote.calls, 0);
    });
  });

  group('ProfilePhotoCubit', () {
    late _FakePicker picker;
    late _FakeImageRemote remote;
    late ProfilePhotoCubit cubit;

    setUp(() {
      picker = _FakePicker()..next = ImagePicked(image);
      remote = _FakeImageRemote();
      cubit = ProfilePhotoCubit(
        ImageUseCase(picker, ImageUploadRepoImpl(remote)),
      );
    });

    tearDown(() => cubit.close());

    test('pick, show progress, then the stored photo', () async {
      final progress = <double?>[];
      final sub = cubit.stream.listen((s) => progress.add(s.progress));

      await cubit.pickFrom(MediaSource.gallery);
      await pumpEventQueue();
      await sub.cancel();

      expect(progress.whereType<double>(), contains(0.5));
      expect(cubit.state.loading, LoadingStatus.complete);
      expect(cubit.state.photo!.url, 'https://cdn.test/img-1.jpg');
      expect(cubit.state.pending, isNull);
      expect(cubit.state.progress, isNull);
      expect(cubit.state.effect!.value, isA<ProfilePhotoUploadedEffect>());
    });

    test('a cancelled pick changes nothing', () async {
      picker.next = const PickCancelled();

      await cubit.pickFrom(MediaSource.camera);

      expect(cubit.state, ProfilePhotoState.initial());
      expect(remote.calls, 0);
    });

    test('a picker failure offers to pick again', () async {
      picker.failWith = const MediaPickFailure(
        MediaPickFailureCode.permissionDenied,
      );

      await cubit.pickFrom(MediaSource.camera);

      final effect = cubit.state.effect!.value as ProfilePhotoShowErrorEffect;
      expect(effect.retryAction, ProfilePhotoRetryAction.pick);
      expect(effect.error, isA<MediaPickFailure>());
      expect(cubit.state.loading, LoadingStatus.initial);
    });

    test('a failed upload keeps the preview and retries it', () async {
      remote.failWith = NetworkIssueException();

      await cubit.pickFrom(MediaSource.gallery);

      expect(cubit.state.loading, LoadingStatus.error);
      expect(cubit.state.pending, image);
      expect(cubit.state.canRetry, isTrue);
      final effect = cubit.state.effect!.value as ProfilePhotoShowErrorEffect;
      expect(effect.retryAction, ProfilePhotoRetryAction.upload);

      await cubit.retryUpload();

      expect(cubit.state.loading, LoadingStatus.complete);
      expect(remote.calls, 2);
      expect(picker.calls, 1);
    });

    test('cancel stops the request and drops the preview', () async {
      remote.hold = Completer<void>();
      final uploading = cubit.pickFrom(MediaSource.gallery);
      await pumpEventQueue();

      cubit.cancelUpload();
      await uploading;

      expect(remote.lastToken!.isCancelled, isTrue);
      expect(cubit.state.loading, LoadingStatus.initial);
      expect(cubit.state.pending, isNull);
    });

    test('closing during an upload cancels it and emits nothing', () async {
      remote.hold = Completer<void>();
      final uploading = cubit.pickFrom(MediaSource.gallery);
      await pumpEventQueue();

      await cubit.close();
      remote.hold!.complete();

      await expectLater(uploading, completes);
      expect(remote.lastToken!.isCancelled, isTrue);
    });
  });
}

class _FakePicker implements MediaPickerRepo {
  PickImageOutcome next = const PickCancelled();
  Object? failWith;
  int calls = 0;

  @override
  Future<PickImageOutcome> pickImage(MediaSource source) async {
    calls++;
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}

/// Plays Dio's onSendProgress in [chunks] steps.
class _FakeImageRemote implements ImageRemoteDataSource {
  int chunks = 4;
  int calls = 0;
  Object? failWith;
  Completer<void>? hold;
  CancelToken? lastToken;

  @override
  Future<UploadedImageResponseModel> upload(
    LocalImage image, {
    required String slot,
    required void Function(int sent, int total) onProgress,
    required CancelToken cancelToken,
  }) async {
    calls++;
    lastToken = cancelToken;
    final total = chunks * 10;
    for (var i = 1; i <= chunks; i++) {
      onProgress(i * 10, total);
    }
    await hold?.future;
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      throw failure;
    }
    return UploadedImageResponseModel(
      id: 'img-$calls',
      url: 'https://cdn.test/img-1.jpg',
    );
  }
}

/// Consumes the request body like a socket would, so Dio reports progress.
class _FakeHttpAdapter implements HttpClientAdapter {
  RequestOptions? request;
  final List<int> body = [];
  int status = 200;
  Completer<void>? hold;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    final gate = hold;
    if (gate != null) {
      await Future.any([gate.future, ?cancelFuture]);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'message': '',
        'data': {'id': 'img-1', 'url': 'https://cdn.test/img-1.jpg'},
      }),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
