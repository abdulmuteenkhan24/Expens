import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// App lock is **optional**. Off by default until enabled in Settings.
class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  bool _loaded = false;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _unlocked = true;

  bool get isLoaded => _loaded;
  bool get pinEnabled => _pinEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  bool get isUnlocked => _unlocked;

  /// Only locks when the user has explicitly enabled a PIN.
  bool get needsLock => _loaded && _pinEnabled && !_unlocked;

  Future<void> load() async {
    // Defaults: unlocked, no PIN — never block app start.
    _pinEnabled = false;
    _biometricEnabled = false;
    _biometricAvailable = false;
    _unlocked = true;

    try {
      final hasPin = await _service.hasPin();
      final biometricOn = await _service.isBiometricEnabled();
      final biometricOk = await _service.canCheckBiometrics();

      _pinEnabled = hasPin;
      _biometricEnabled = hasPin && biometricOn;
      _biometricAvailable = biometricOk;
      // Lock only if PIN was previously enabled.
      _unlocked = !hasPin;
    } catch (e, st) {
      debugPrint('Auth load skipped (optional): $e\n$st');
      _pinEnabled = false;
      _biometricEnabled = false;
      _biometricAvailable = false;
      _unlocked = true;
    }

    _loaded = true;
    notifyListeners();
  }

  void lock() {
    if (!_pinEnabled) return;
    if (_unlocked) {
      _unlocked = false;
      notifyListeners();
    }
  }

  void unlock() {
    if (!_unlocked) {
      _unlocked = true;
      notifyListeners();
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final ok = await _service.verifyPin(pin);
      if (ok) unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_biometricEnabled || !_biometricAvailable) return false;
    try {
      final ok = await _service.authenticateWithBiometrics();
      if (ok) unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enablePin(String pin) async {
    try {
      await _service.setPin(pin);
      _pinEnabled = true;
      _unlocked = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('enablePin failed: $e');
      return false;
    }
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final ok = await _service.verifyPin(currentPin);
      if (!ok) return false;
      await _service.setPin(newPin);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disablePin(String currentPin) async {
    try {
      final ok = await _service.verifyPin(currentPin);
      if (!ok) return false;
      await _service.clearPin();
      _pinEnabled = false;
      _biometricEnabled = false;
      _unlocked = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (!_pinEnabled) return;
    try {
      if (enabled) {
        _biometricAvailable = await _service.canCheckBiometrics();
        if (!_biometricAvailable) return;
        final ok = await _service.authenticateWithBiometrics(
          reason: 'Enable biometric unlock',
        );
        if (!ok) return;
      }
      await _service.setBiometricEnabled(enabled);
      _biometricEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('setBiometricEnabled failed: $e');
    }
  }

  Future<void> refreshBiometricAvailability() async {
    try {
      _biometricAvailable = await _service.canCheckBiometrics();
    } catch (_) {
      _biometricAvailable = false;
    }
    notifyListeners();
  }
}
