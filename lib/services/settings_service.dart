import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _pushNotificationsKey = 'owner_push_notifications';
  static const String _inventoryAlertsKey = 'owner_inventory_alerts';
  static const String ownerBiometricEnabledKey = 'owner_biometric_enabled';
  static const String ownerPinKey = 'owner_pin';
  static SharedPreferences? _cachedPrefs;

  static Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  static Future<bool> getPushNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_pushNotificationsKey) ?? true;
  }

  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_pushNotificationsKey, enabled);
  }

  static Future<bool> getInventoryAlertsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_inventoryAlertsKey) ?? true;
  }

  static Future<void> setInventoryAlertsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_inventoryAlertsKey, enabled);
  }

  static Future<bool> getOwnerBiometricEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(ownerBiometricEnabledKey) ?? false;
  }

  static Future<void> setOwnerBiometricEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(ownerBiometricEnabledKey, enabled);
  }

  static Future<String?> getOwnerPin() async {
    final prefs = await _prefs;
    return prefs.getString(ownerPinKey);
  }

  static Future<void> setOwnerPin(String? pin) async {
    final prefs = await _prefs;
    if (pin == null) {
      await prefs.remove(ownerPinKey);
    } else {
      await prefs.setString(ownerPinKey, pin);
    }
  }
}
