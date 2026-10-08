import 'dart:async';

/// Lets the network/session layer tell the auth controller that the server
/// rejected the current token, without a dependency cycle between them.
final class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void emitExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  void dispose() => _expired.close();
}
