import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _pushNotificationsKey = 'owner_push_notifications';
  static const String _inventoryAlertsKey = 'owner_inventory_alerts';
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
}
