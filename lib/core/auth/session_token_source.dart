/// What the network layer needs from the auth layer.
abstract interface class SessionTokenSource {
  Future<String?> readAccessToken();

  /// Called when a request that carried [rejectedToken] returned 401.
  ///
  /// Implementations must end the session only if [rejectedToken] is still the
  /// current token: a request sent before a new sign-in must not sign the user
  /// out of the new session. Clear the token but keep encrypted pending work.
  Future<void> handleUnauthorized(String rejectedToken);
}
