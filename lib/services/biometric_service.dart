import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device hardware supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      // Only check if the hardware supports it — don't gate on enrollment
      // Android will prompt the user to enroll if not already done
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint("Biometrics check failed: $e");
      return false;
    }
  }

  /// Trigger the native biometric prompt (Fingerprint / Face ID)
  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to log in',
      );
    } catch (e) {
      debugPrint("Biometric auth failed: $e");
      return false;
    }
  }
}
