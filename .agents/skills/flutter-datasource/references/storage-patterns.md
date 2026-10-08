# Storage patterns

How to store data in this base so that features generated later stay safe and
consistent. The sample auth feature is only one user of these patterns; a fork
may replace it entirely.

## Pick the store

| Data | Store | Why |
|---|---|---|
| Credentials, tokens, secrets | `flutter_secure_storage`, behind one provider such as `TokenProvider` | Keychain/Keystore; never readable from backups or other apps |
| Personal data cached for offline use (profile, account) | `SharedPreferences` only when it is not secret, otherwise secure storage | Survives restart; must be cleared with the session |
| Settings (language, theme, onboarding seen) | `SharedPreferences` | Non-sensitive, survives logout |
| Large or queryable caches (lists, offline data) | A dedicated local database added when a feature needs it | Not part of the base until required |
| Short-lived UI state | Cubit/BLoC state only | Never persist what can be refetched cheaply |

## Rules

1. **One owner per lifecycle.** Data that must be created and destroyed
   together has exactly one module that owns all of it. Example: the session
   owns token and cached account, so sign-out and expiry cannot leave one
   behind. Do not split such data across repositories that the use case must
   remember to call in the right order.
2. **The port speaks domain types.** A repository interface accepts and
   returns domain entities. The implementation converts to storable models
   (`Model.fromEntity`) instead of silently ignoring values that are not
   data-layer models.
3. **Persistence is a parameter, not a separate code path.** "Remember me",
   "save offline" and similar choices decide whether a value is persisted,
   never whether it exists in memory. In-memory state must work the same way
   whether or not it is persisted.
4. **Every value that belongs to a user is cleared on sign-out.** List it in
   the session's `end()` or in a hook it calls. Settings that belong to the
   device, such as language, stay.
5. **Expiry equals sign-out.** Forced expiry from the network layer calls the
   same end-of-session path as a user sign-out, then publishes a typed event.
6. **Writes are serialized and versioned when they can race.** Token refresh
   uses a revision check so a late refresh cannot overwrite a newer sign-in.
   Copy this pattern for any value written by both the UI and a background
   path.
7. **Migrations are one-time and idempotent.** Moving a key between stores
   reads the old store once, writes the new one, deletes the old key, and is
   safe to run again.

## Current implementation to copy

| Concern | File |
|---|---|
| Session port (token + account, start/update/end) | `lib/domain/repositories/session_repo.dart` |
| Session adapter | `lib/data/repositories/session_repo_impl.dart` |
| Secure token store with revision and in-memory mode | `lib/data/datasource/local/token_provider.dart` |
| Expiry through the session | `lib/data/datasource/local/session_expiry_coordinator.dart` |
| Lifecycle tests on in-memory storage | `test/data/repositories/session_repo_impl_test.dart` |

## Testing

Test a storage owner through its port with real data sources backed by
in-memory storage (`SharedPreferences.setMockInitialValues`, a map-backed
secure storage), then simulate a restart by constructing the stores again.
Assert observable outcomes: signed in or not, value present after restart,
everything cleared after end.
