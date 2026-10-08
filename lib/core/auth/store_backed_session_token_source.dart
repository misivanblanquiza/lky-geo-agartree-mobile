import 'session_events.dart';
import 'session_store.dart';
import 'session_token_source.dart';

final class StoreBackedSessionTokenSource implements SessionTokenSource {
  const StoreBackedSessionTokenSource(this._store, this._events);

  final SessionStore _store;
  final SessionEvents _events;

  /// Sends the stored token even if the local expiry hint has passed: device
  /// clocks drift, and the server decides.
  @override
  Future<String?> readAccessToken() async => (await _store.readToken())?.accessToken;

  @override
  Future<void> handleUnauthorized(String rejectedToken) async {
    final current = await _store.readToken();
    if (current == null || current.accessToken != rejectedToken) {
      return; // already cleared, or replaced by a newer sign-in
    }
    await _store.clearToken();
    _events.emitExpired();
  }
}
