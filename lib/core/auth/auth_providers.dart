import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'device_identity.dart';
import 'local_user_data_cleaner.dart';
import 'session_events.dart';
import 'session_store.dart';
import 'session_token_source.dart';
import 'store_backed_session_token_source.dart';

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final sessionStoreProvider = Provider<SessionStore>(
    (ref) => SecureSessionStore(ref.watch(secureStorageProvider)));

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final sessionTokenSourceProvider = Provider<SessionTokenSource>((ref) =>
    StoreBackedSessionTokenSource(
      ref.watch(sessionStoreProvider),
      ref.watch(sessionEventsProvider),
    ));

final deviceIdentitySourceProvider = Provider<DeviceIdentitySource>((ref) =>
    PlatformDeviceIdentitySource(storage: ref.watch(secureStorageProvider)));

/// Empty until the Drift cache / pending queue exist; they register here.
final localUserDataCleanersProvider =
    Provider<List<LocalUserDataCleaner>>((ref) => const []);
