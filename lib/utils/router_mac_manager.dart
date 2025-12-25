import 'package:shared_preferences/shared_preferences.dart';

class RouterMacManager {
  static const String _prefName = "mac_prefs";
  static const String _keyCurrentMac = "current_mac";
  static const String _keyMacList = "mac_list";

  static Future<void> saveMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    // Replicate Kotlin behavior: prefix with "mac:"
    await prefs.setString(_keyCurrentMac, "mac:$mac");
    
    // Also save to list
    await _addMacToList(prefs, mac);
  }

  static Future<String> getMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentMac) ?? "";
  }

  static Future<List<String>> getMacList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyMacList) ?? [];
  }

  static Future<void> _addMacToList(SharedPreferences prefs, String mac) async {
    final list = prefs.getStringList(_keyMacList) ?? [];
    if (!list.contains(mac)) {
      list.add(mac);
      await prefs.setStringList(_keyMacList, list);
    }
  }
}
