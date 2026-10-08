import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class StoredToken {
  const StoredToken({required this.accessToken, this.expiresAt});

  final String accessToken;

  /// Local hint computed from `expires_in` at sign-in. The server stays
  /// authoritative; this only avoids a pointless request at app start.
  final DateTime? expiresAt;

  bool isExpired(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);
}

/// Persistent session material. The device installation ID is NOT stored here:
/// it must survive sign-out (device binding).
abstract interface class SessionStore {
  Future<StoredToken?> readToken();
  Future<void> writeToken(StoredToken token);

  /// Ends the session but keeps the snapshot (last-known user) so a later
  /// sign-in can tell whether the same person returned.
  Future<void> clearToken();

  /// Last server-confirmed user/permissions/scope as JSON, without the token.
  Future<String?> readSnapshot();
  Future<void> writeSnapshot(String json);

  /// Explicit sign-out: token, expiry and snapshot.
  Future<void> clearAll();
}

final class SecureSessionStore implements SessionStore {
  const SecureSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth.access_token';
  static const _expiresKey = 'auth.expires_at';
  static const _snapshotKey = 'auth.snapshot';

  @override
  Future<StoredToken?> readToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return null;
      final expires = DateTime.tryParse(await _storage.read(key: _expiresKey) ?? '');
      return StoredToken(accessToken: token, expiresAt: expires);
    } on PlatformException {
      // Keystore/keychain data that can no longer be decrypted (e.g. after a
      // restore): treat as signed out rather than crashing at startup.
      return null;
    }
  }

  @override
  Future<void> writeToken(StoredToken token) async {
    await _storage.write(key: _tokenKey, value: token.accessToken);
    final expires = token.expiresAt;
    if (expires == null) {
      await _storage.delete(key: _expiresKey);
    } else {
      await _storage.write(key: _expiresKey, value: expires.toUtc().toIso8601String());
    }
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresKey);
  }

  @override
  Future<String?> readSnapshot() async {
    try {
      return await _storage.read(key: _snapshotKey);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> writeSnapshot(String json) =>
      _storage.write(key: _snapshotKey, value: json);

  @override
  Future<void> clearAll() async {
    await clearToken();
    await _storage.delete(key: _snapshotKey);
  }
}
