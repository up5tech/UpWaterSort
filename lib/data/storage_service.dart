import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/save_data.dart';

/// Reads and writes the whole player save under the single key `save_v1`
/// (PLAN.md §15).
class StorageService {
  StorageService._(this._prefs);

  static const String saveKey = 'save_v1';

  final SharedPreferences _prefs;

  static Future<StorageService> create() async =>
      StorageService._(await SharedPreferences.getInstance());

  /// Never throws: a corrupt save falls back to a fresh [SaveData].
  SaveData load() {
    final raw = _prefs.getString(saveKey);
    if (raw == null) return SaveData();
    try {
      return SaveData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SaveData();
    }
  }

  Future<void> save(SaveData data) =>
      _prefs.setString(saveKey, jsonEncode(data.toJson()));

  Future<void> clear() => _prefs.remove(saveKey);
}
