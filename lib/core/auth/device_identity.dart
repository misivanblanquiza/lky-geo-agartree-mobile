import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

final class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String appVersion;

  /// Exactly the optional login fields the backend validates.
  Map<String, String> toLoginFields() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'app_version': appVersion,
      };
}

abstract interface class DeviceIdentitySource {
  Future<DeviceIdentity> read();
}

final class PlatformDeviceIdentitySource implements DeviceIdentitySource {
  PlatformDeviceIdentitySource({
    required FlutterSecureStorage storage,
    DeviceInfoPlugin? deviceInfo,
    Uuid uuid = const Uuid(),
  })  : _storage = storage,
        _info = deviceInfo ?? DeviceInfoPlugin(),
        _uuid = uuid;

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _info;
  final Uuid _uuid;

  static const _idKey = 'device.installation_id';

  DeviceIdentity? _value;
  Future<DeviceIdentity>? _inFlight;

  @override
  Future<DeviceIdentity> read() async {
    final cached = _value;
    if (cached != null) return cached;
    final load = _inFlight ??= _load();
    try {
      return _value = await load;
    } finally {
      _inFlight = null;
    }
  }

  Future<DeviceIdentity> _load() async {
    final package = await PackageInfo.fromPlatform();
    return DeviceIdentity(
      deviceId: await _installationId(),
      deviceName: await _deviceName(),
      platform: switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => 'unknown',
      },
      appVersion: package.version,
    );
  }

  /// Generated once, never deleted on sign-out.
  Future<String> _installationId() async {
    String? existing;
    try {
      existing = await _storage.read(key: _idKey);
    } on PlatformException {
      existing = null;
    }
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _uuid.v4();
    try {
      await _storage.write(key: _idKey, value: created);
    } on PlatformException {
      // Keep the in-memory id for this run; a new one is generated next time.
    }
    return created;
  }

  /// Hardware model only. Never the user-chosen device name (personal data).
  Future<String> _deviceName() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final a = await _info.androidInfo;
        final maker = a.manufacturer;
        final cap = maker.isEmpty ? '' : '${maker[0].toUpperCase()}${maker.substring(1)} ';
        return '$cap${a.model}';
      case TargetPlatform.iOS:
        return (await _info.iosInfo).utsname.machine;
      default:
        return 'unknown';
    }
  }
}
