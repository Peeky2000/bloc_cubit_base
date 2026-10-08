# Image upload with progress

Decision: [D-0004](../../../../docs/decisions/D-0004-upload-anh-co-tien-trinh.md)
(proposed). Reference code: `test/patterns/image_upload_pattern_test.dart`.

## When to use

The user picks or takes a photo and the app stores it on the server: avatar,
receipt, product photo, document scan. For several images, run one upload
per slot (`product-photo-0`, `product-photo-1`) with the same port.

## Decision

Picking is a domain port `MediaPickerRepo` returning one
`Future<PickImageOutcome>` (adapter on `image_picker`, proposed); uploading
is a domain port `ImageUploadRepo` returning `Stream<UploadEvent>` (progress,
then one terminal event) built on Dio multipart with `onSendProgress` and
`CancelToken`.

## Files to create (feature `profile_photo`)

| Layer | Path | Content |
|---|---|---|
| Entities | `lib/domain/entities/media/local_image.dart`, `uploaded_image.dart` | `LocalImage{path, fileName, mimeType, sizeBytes}`, `UploadedImage{id, url}` |
| Picker port | `lib/domain/repositories/media_picker_repo.dart` | `Future<PickImageOutcome> pickImage(MediaSource)`; `ImagePicked`/`PickCancelled`; `MediaPickFailure{code}` |
| Upload port | `lib/domain/repositories/image_upload_repo.dart` | `Stream<UploadEvent> upload(LocalImage, {required String slot})`; `UploadProgress`/`UploadCompleted`/`UploadSuperseded`; `UploadFailure{code}` |
| UseCase | `lib/domain/use_case/image_use_case.dart` | size (10 MB) and type allowlist before sending |
| Picker adapter | `lib/data/repositories/image_picker_media_repo.dart` | sketch in the test file; downscale with `maxWidth/maxHeight: 2048, imageQuality: 85` |
| ApiHandler | `lib/data/datasource/remote/api_client.dart` | add `upload<T>(path, {FormData data, parser, onSendProgress, cancelToken})` (base change, see below) |
| Remote DS | `lib/data/datasource/remote/image_remote_data_source.dart` | `FormData` + `MultipartFile.fromFile` |
| Response model | `lib/data/model/response/media/uploaded_image_response_model.dart` | `@JsonSerializable`, `toEntity()` |
| Repo impl | `lib/data/repositories/image_upload_repo_impl.dart` | slot map, supersede, percent throttle, error mapping |
| Cubit | `lib/presentation/profile_photo/cubit/profile_photo_cubit.dart` | `pickFrom`, `retryUpload`, `cancelUpload` |
| State/effect | `.../cubit/profile_photo_state.dart`, `profile_photo_effect.dart` | see below |

### Base change to propose: `ApiHandler.upload`

`ApiHandler` has no multipart method. Add one to `ApiHandler` and implement it
in `ApiClient` with the configured `_dio` inside `_remapError`, so
`AuthInterceptor`, `SessionInterceptor`, the network check and the inspector
apply to uploads. Pass `Options(sendTimeout: Duration(minutes: 2))`: Dio
applies `sendTimeout` to the whole body, and the 30 s default fails large
uploads on slow networks. Until then the reference code has the same contract
as `UploadApiHandler`/`DioUploadApiHandler`.

## Repository behavior

- Starts on listen; cancelling the subscription cancels the `CancelToken`.
- A new upload for the same slot emits `UploadSuperseded` on the older
  stream, cancels its token and closes it; late Dio callbacks are dropped.
- Progress at most once per percent (Dio reports every chunk).
- `NetworkIssueException` → `UploadFailure(network)`; HTTP 413 → `tooLarge`;
  415 → `unsupportedType`; everything else → `server`.
- `MultipartFile.fromFile` streams from disk; never read the whole file into
  memory.

## State and effects

```dart
final UploadedImage? photo;     // stored on the server
final LocalImage? pending;      // preview from disk while uploading or failed
final double? progress;         // 0..1, null = indeterminate or idle
final UiEffect<ProfilePhotoEffect>? effect;
bool get isUploading => loading == LoadingStatus.loading;
bool get canRetry => pending != null && loading == LoadingStatus.error;
```

Effects: `ProfilePhotoUploadedEffect`,
`ProfilePhotoShowErrorEffect{error, retryAction: pick | upload}`.
`MediaPickFailure(permissionDenied)` is shown with "Open settings", as in
[permission.md](permission.md).

## Cubit flow

1. `pickFrom(source)`: `PickCancelled` → nothing. Failure → error effect with
   `retryAction.pick`. `ImagePicked` → start upload.
2. Upload: `loading`, `pending = image`, `progress = 0`; progress events
   update `progress`; `UploadCompleted` → `complete`, `photo`, clear pending,
   uploaded effect; `UploadSuperseded` → nothing.
3. Failure: `error`, keep `pending` so `retryUpload()` sends the same file
   without picking again.
4. `cancelUpload()` cancels the subscription (and the request) and clears
   the preview. `close()` cancels too.

## Error, empty, offline

Offline is `UploadFailure(network)` with retry; nothing is queued in the
background. If the product needs background or resumable uploads, propose a
new decision (WorkManager/BGTask, tus or chunked protocol).

## Security and performance

- Validate type and size in the use case and on the server. Strip EXIF GPS
  on the server (or with a compressor in the adapter) when photos are public.
- Upload with the user's token through `ApiClient`; do not send pre-signed
  URLs to logs.
- Downscale before upload; show the preview from the file, not from bytes.
- Delete temporary files the picker created after the upload when the
  platform does not.

## Test checklist

- [ ] Real Dio + fake `HttpClientAdapter`: multipart body, filename, content
      type, progress reaches the total, `sendTimeout` override.
- [ ] Cancelled token aborts; HTTP 413 surfaces with its status.
- [ ] Repo: progress throttled to 101 events max, completed last.
- [ ] Repo: transport errors become `UploadFailure` codes.
- [ ] Repo: cancel subscription cancels the token; same slot supersedes;
      different slots run side by side.
- [ ] UseCase rejects size/type before any request.
- [ ] Cubit: pick → progress → stored photo; cancelled pick; picker failure;
      failed upload keeps preview and retries; cancel; close during upload.

Reference code: `test/patterns/image_upload_pattern_test.dart`
