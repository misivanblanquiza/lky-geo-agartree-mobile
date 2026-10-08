/// What the network layer needs from the auth layer (implemented in step 4).
abstract interface class SessionTokenSource {
  Future<String?> readAccessToken();

  /// Called when a request that carried a token returned 401.
  ///
  /// Implementations clear the session but keep encrypted pending work for
  /// reassessment after sign-in. Must be idempotent: several in-flight
  /// requests can fail with 401 at once.
  Future<void> handleUnauthorized();
}
