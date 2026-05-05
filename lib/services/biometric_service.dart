import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_windows/local_auth_windows.dart'; // For Windows Hello support

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device has biometric hardware (Fingerprint/Face/Windows Hello)
  static Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false; // Default to false on web if plugin not fully linked to avoid MissingPluginException
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint("Biometrics not supported or not initialized on this platform.");
      return false;
    }
  }

  /// Trigger the Biometric Auth popup (Windows Hello / Fingerprint / Face ID)
  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to log in to the Staff Portal',
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint("Error during biometric auth: $e");
      return false;
    }
  }
}
