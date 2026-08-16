import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional app lock. Storage failures never crash the app —
/// falls back to SharedPreferences if secure storage is unavailable
/// (e.g. missing plugin after hot restart).
class AuthService {
  AuthService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _secure = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _secure;
  final LocalAuthentication _localAuth;

  /// When secure storage plugin is missing, use prefs for the rest of the session.
  bool _usePrefsOnly = false;

  static const _pinHashKey = 'auth_pin_hash_v1';
  static const _pinSaltKey = 'auth_pin_salt_v1';
  static const _biometricKey = 'auth_biometric_v1';

  Future<bool> hasPin() async {
    final hash = await _read(_pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _read(_biometricKey);
    return v == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _write(_biometricKey, enabled ? 'true' : 'false');
  }

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    await _write(_pinSaltKey, salt);
    await _write(_pinHashKey, hash);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _read(_pinSaltKey);
    final hash = await _read(_pinHashKey);
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  Future<void> clearPin() async {
    await _delete(_pinHashKey);
    await _delete(_pinSaltKey);
    await _write(_biometricKey, 'false');
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final supported = await _localAuth
          .isDeviceSupported()
          .timeout(const Duration(milliseconds: 800), onTimeout: () => false);
      if (!supported) return false;
      final can = await _localAuth.canCheckBiometrics
          .timeout(const Duration(milliseconds: 800), onTimeout: () => false);
      if (!can) return false;
      final types = await _localAuth
          .getAvailableBiometrics()
          .timeout(const Duration(milliseconds: 800), onTimeout: () => []);
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Unlock Expens',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _read(String key) async {
    if (!_usePrefsOnly) {
      try {
        return await _secure.read(key: key);
      } catch (e) {
        debugPrint('Auth storage read fallback: $e');
        _usePrefsOnly = true;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    if (!_usePrefsOnly) {
      try {
        await _secure.write(key: key, value: value);
        return;
      } catch (e) {
        debugPrint('Auth storage write fallback: $e');
        _usePrefsOnly = true;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _delete(String key) async {
    if (!_usePrefsOnly) {
      try {
        await _secure.delete(key: key);
        return;
      } catch (e) {
        debugPrint('Auth storage delete fallback: $e');
        _usePrefsOnly = true;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }
}
