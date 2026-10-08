# Async flow patterns

How a use case, repository and Cubit talk about long-running platform or
network operations. The sample phone verification is one example; the same
shape applies to payments, uploads, permissions, location, push registration
or any SDK with callbacks.

## Rules

1. **A port returns one result.** Wrap callback-based SDKs inside the data
   adapter and expose `Future<Outcome>` or `Stream<Event>`. The Future
   completes only when the operation has reached a state the caller acts on,
   not when the SDK call returns.
2. **Outcomes are a closed set.** Use an enum or sealed class for the success
   cases (for example `codeSent`, `autoVerified`, `superseded`). Failures are
   thrown as one typed domain failure with a code, never as SDK exceptions.
3. **Newer requests supersede older ones in the adapter.** The adapter keeps a
   generation counter. An older request completes with a `superseded` outcome
   and its late SDK callbacks are ignored. Callers do nothing on `superseded`.
4. **Input normalization lives in the domain, once.** Phone numbers, currency
   amounts, dates and similar are normalized by one function in the use case
   or a domain value type, not in each Cubit.
5. **The Cubit awaits once.** After `await`, check `isClosed`, ignore
   `superseded`, then emit state or a typed UI effect. Errors go to one
   handler that emits an error effect with a retry action.
6. **Use a Stream only for many results over time** (progress, live updates).
   Do not use a Stream or callbacks for a single result.

## Shape

```dart
// domain
enum UploadOutcome { uploaded, superseded }

abstract class UploadRepo {
  /// Completes when the file is stored; throws UploadFailure.
  Future<UploadOutcome> upload(FileRef file);
}

// cubit
Future<void> upload(FileRef file) async {
  emit(state.copyWith(loading: LoadingStatus.loading));
  try {
    final outcome = await _useCase.upload(file);
    if (isClosed || outcome == UploadOutcome.superseded) return;
    emit(state.copyWith(loading: LoadingStatus.complete));
  } catch (error) {
    if (isClosed) return;
    emit(state.copyWith(loading: LoadingStatus.error, error: error));
    _emitEffect(UploadShowErrorEffect(error: error));
  }
}
```

## Current implementation to copy

| Concern | File |
|---|---|
| Outcome port | `lib/domain/repositories/phone_verification_repo.dart` |
| SDK adapter with generation counter and Completer | `lib/data/repositories/firebase_phone_verification_repo.dart` |
| Single domain normalizer | `AuthUseCase.normalizePhone` in `lib/domain/use_case/auth_use_case.dart` |
| Adapter tests that play the SDK callbacks | `test/data/repositories/firebase_phone_verification_repo_test.dart` |
| Cubit tests for outcome, failure, superseded, close | `test/presentation/confirm_information_cubit_test.dart` |
