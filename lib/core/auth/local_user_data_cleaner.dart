/// Implemented by anything that holds user-scoped local data (Drift cache,
/// pending queue, photos). Run on explicit sign-out and when a different user
/// signs in. NOT run when a session merely expires (401): pending work is
/// preserved for the same user to reassess after signing in again.
abstract interface class LocalUserDataCleaner {
  Future<void> clearUserData();
}
