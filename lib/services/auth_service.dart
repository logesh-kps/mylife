import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _pinKey = 'mylife_pin_hash';
  static const _pinSetKey = 'mylife_pin_set';
  static const _failCountKey = 'mylife_fail_count';
  static const _lockTimeKey = 'mylife_lock_time';
  static const _bioEnabledKey = 'mylife_biometric_enabled';
  static const _lockDuration = 30;

  static final _localAuth = LocalAuthentication();

  static String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}mylife_salt_2026');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetKey) ?? false;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hashPin(pin));
    await prefs.setBool(_pinSetKey, true);
    await prefs.setInt(_failCountKey, 0);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey) ?? '';
    final match = stored == _hashPin(pin);
    if (match) {
      await prefs.setInt(_failCountKey, 0);
    } else {
      final fails = (prefs.getInt(_failCountKey) ?? 0) + 1;
      await prefs.setInt(_failCountKey, fails);
      if (fails >= 3) {
        await prefs.setInt(_lockTimeKey, DateTime.now().millisecondsSinceEpoch);
      }
    }
    return match;
  }

  static Future<int> getFailCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failCountKey) ?? 0;
  }

  static Future<int> getLockSecondsRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lockTime = prefs.getInt(_lockTimeKey) ?? 0;
    if (lockTime == 0) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lockTime;
    final remaining = _lockDuration - (elapsed / 1000).floor();
    if (remaining <= 0) {
      await prefs.setInt(_lockTimeKey, 0);
      await prefs.setInt(_failCountKey, 0);
      return 0;
    }
    return remaining;
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bioEnabledKey) ?? true;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioEnabledKey, enabled);
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to open MyLife',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<void> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_pinSetKey);
    await prefs.setInt(_failCountKey, 0);
    await prefs.setInt(_lockTimeKey, 0);
  }
}
