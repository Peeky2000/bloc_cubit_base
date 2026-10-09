# Image upload with progress

Decision: [D-0004](../../../../docs/decisions/D-0004-upload-anh-co-tien-trinh.md)
(proposed). Reference code: `test/patterns/image_upload_pattern_test.dart`.

## When to use

The user picks or takes a photo and the server stores it: avatar, receipt,
product photo, scan. Several images: one upload per slot (`product-photo-0`).

## Decision

Picking is a domain port `MediaPickerRepo` returning one
`Future<PickImageOutcome>`; its adapter uses the system picker
(`image_picker`) and re-encodes once with `flutter_image_compress` (1600 px
short side, JPEG 85, upright, no EXIF/GPS). Uploading is a domain port
`ImageUploadRepo` returning `Stream<UploadEvent>` (progress, then one
terminal event) on Dio multipart through `ApiClient`.

## Packages (add with the first feature, after D-0004 is accepted)

| Package | Constraint | Why |
|---|---|---|
| `image_picker` (flutter.dev) | `^1.2.4` | needs Dart 3.11 / Flutter 3.41; 3.44.5 ok. PHPicker on iOS 14+ |
| `image_picker_android` | `^0.8.13+22` | Dart 3.12. `useAndroidPhotoPicker`; +22 Photo Picker on API 36, +25 subsampled decode |
| `image_picker_platform_interface` | `^2.11.0` | `ImagePickerPlatform` for the flag |
| `flutter_image_compress` (fluttercandies) | `^2.5.1` | 2.5.0 fixed EXIF passthrough, SPM; 2.5.1 Gradle 9 |
| `dio` | `^5.10.0` (locked 5.11.0) | 5.10 fixed `FormData.clone()`, used by the 401 replay |

Resolved against the app's graph on 3.44.5. Not `image_picker`'s
`maxWidth/imageQuality`: it keeps EXIF, GPS included, on both platforms.

## Native setup

- iOS `Info.plist`: `NSCameraUsageDescription` (camera) and
  `NSPhotoLibraryUsageDescription` (required by App Store review even though
  PHPicker with `requestFullMetadata: false` never asks). Deployment target
  13.0 already matches.
- Android: no permission. The plugin manifest already merges the
  `com.google.android.gms.metadata.ModuleDependencies` service
  (`photopicker_activity:0:required`) for the backported Photo Picker. Do not
  declare `CAMERA` unless another feature needs it (then it must be granted).
- Play policy forbids `READ_MEDIA_IMAGES`/`_VIDEO` for one-time uploads, but
  `alice` → `open_filex` 4.7.0 merges them (and `READ_MEDIA_AUDIO`), and
  `sli_common` → `photo_manager` merges `READ_EXTERNAL_STORAGE`. Remove them
  in `AndroidManifest.xml` with
  `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" tools:node="remove"/>`
  (same for `_VIDEO`, `_AUDIO`; needs `xmlns:tools`).

## Files to create (feature `profile_photo`)

| Layer | Path | Content |
|---|---|---|
| Entities | `lib/domain/entities/media/local_image.dart`, `uploaded_image.dart` | `LocalImage{path, fileName, mimeType, sizeBytes}`, `UploadedImage{id, url}` |
| Picker port | `lib/domain/repositories/media_picker_repo.dart` | `pickImage(MediaSource)`, `retrieveLostImage()`; `ImagePicked`/`PickCancelled`; `MediaPickFailure{code}` |
| Upload port | `lib/domain/repositories/image_upload_repo.dart` | `Stream<UploadEvent> upload(LocalImage, {required String slot})`; `UploadProgress`/`UploadCompleted`/`UploadSuperseded`; `UploadFailure{code}` |
| UseCase | `lib/domain/use_case/image_use_case.dart` | size (10 MB) and type allowlist before sending |
| Picker adapter | `lib/data/repositories/image_picker_media_repo.dart` | in the test file (commented, `flutter analyze` clean); `ImagePicker` from `RegisterModule` |
| ApiHandler | `lib/data/datasource/remote/api_client.dart` | `upload<T>` (base change below) |
| Remote DS | `lib/data/datasource/remote/image_remote_data_source.dart` | new `FormData` + `MultipartFile.fromFile` per attempt |
| Model, repo | `uploaded_image_response_model.dart`, `image_upload_repo_impl.dart` | `toEntity()`; slots, supersede, throttle, errors |
| Cubit | `lib/presentation/profile_photo/cubit/profile_photo_cubit.dart` | `pickFrom`, `recoverLostPick`, `retryUpload`, `cancelUpload` |

### Base change to propose: `ApiHandler.upload`

```dart
Future<BaseResponseModel<T>> upload<T>(String path, {
  required FormData data, required ApiResponseToModelParser<T> parser,
  ProgressCallback? onSendProgress, CancelToken? cancelToken});
```

`ApiClient` implements it with `_dio` inside `_remapError`, so the network
check, `AuthInterceptor`, `SessionInterceptor` (replays `FormData.clone()`)
and the inspector apply. Dio's IO adapter applies `sendTimeout` to the whole
body (`addStream(...).timeout`), so pass
`Options(sendTimeout: 30 s + body / 32 KB/s)` (`sendTimeoutFor`). Also map
`connectionError`, `sendTimeout` and `error is NetworkIssueException` to
`NetworkIssueException`: `_apiErrorToInternalError` misses them today, so the
offline rejection becomes a `ServerException`.

## Repository behavior

- Starts on listen; cancelling the subscription cancels the `CancelToken`.
- A new upload for the same slot emits `UploadSuperseded` on the older
  stream, cancels its token and closes it; late Dio callbacks are dropped.
- Progress at most once per percent (Dio reports every chunk).
- `NetworkIssueException` → `network`; HTTP 413 → `tooLarge`; 415 →
  `unsupportedType`; else `server`. Retry is the user's (`retryUpload`), with
  a fresh `FormData`; a `FormData` or `MultipartFile` cannot be sent twice.

## State and effects

```dart
final UploadedImage? photo;     // stored on the server
final LocalImage? pending;      // preview from disk while uploading or failed
final double? progress;         // 0..1, null = indeterminate or idle
bool get canRetry => pending != null && loading == LoadingStatus.error;
```

Effects: `ProfilePhotoUploadedEffect`, `ProfilePhotoShowErrorEffect{error,
retryAction: pick | upload}`; `permissionDenied` gets "Open settings"
([permission.md](permission.md)).

## Cubit flow

1. `pickFrom(source)`: `PickCancelled` → nothing. Failure → error effect with
   `retryAction.pick`. `ImagePicked` → start upload. The Screen calls
   `recoverLostPick()` once in `initState` (Android lost-activity result).
2. Upload: `loading`, `pending`, `progress = 0`; progress events update
   `progress`; `UploadCompleted` → `complete`, `photo`, clear pending.
3. Failure: `error`, keep `pending` so `retryUpload()` resends without picking.
4. `cancelUpload()` and `close()` cancel the subscription and the request.

## Size, offline, large files

A 1600 px JPEG is about 0.3–1 MB: one multipart request. Offline is
`UploadFailure(network)` with retry; nothing runs in the background.
Presigned/resumable direct-to-storage or background transfer
(`background_downloader`) needs its own decision; presigned URLs are bearer
secrets, never logged.

## Security

- Type and size checked in the use case and again on the server, which
  re-encodes, names the object and never trusts `Content-Type`.
- The adapter deletes the picker's original (it has GPS EXIF); delete the
  re-encoded file after success.

## Test checklist

- [ ] Real Dio + `NetworkInterceptor` + fake adapter: multipart despite a
      JSON content-type interceptor, filename, type, progress to total,
      size-based `sendTimeout`; offline → `NetworkIssueException`, no request.
- [ ] Cancelled token aborts; HTTP 413 keeps its status; retry sends again.
- [ ] Repo: ≤101 progress events, completed last; typed failures; cancel
      cancels the token; same slot supersedes; slots run side by side.
- [ ] UseCase rejects size/type before any request.
- [ ] Cubit: pick → progress → photo; lost pick recovered; cancelled pick;
      picker failure; failed upload keeps preview and retries; cancel; close.

## Nguồn

- https://pub.dev/packages/image_picker (changelog, `pickImage`),
  https://pub.dev/packages/image_picker_android (changelog +22, +25); plugin
  sources: Android `ExifDataCopier` copies GPS, iOS passes metadata through
- https://developer.android.com/training/data-storage/shared/photo-picker,
  https://developer.android.com/training/data-storage/shared/media#media-location-permission,
  https://support.google.com/googleplay/android-developer/answer/14115180
- https://pub.dev/packages/flutter_image_compress (`keepExif`, `minWidth`)
- https://pub.dev/packages/dio (FormData single use, `clone`); dio 5.11
  `io_adapter.dart` (`sendTimeout` wraps `addStream`)
- https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html,
  https://docs.cloud.google.com/storage/docs/resumable-uploads,
  https://pub.dev/packages/background_downloader
