import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _recentFilesKey = 'recent_files';

  // ─── SAVE RECENT FILES TO DISK ────────────────────────────────────────────
  static Future<void> saveRecentFiles(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentFilesKey, paths);
  }

  // ─── LOAD RECENT FILES FROM DISK ─────────────────────────────────────────
  static Future<List<String>> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentFilesKey) ?? [];
  }

  // ─── CLEAR RECENT FILES ───────────────────────────────────────────────────
  static Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentFilesKey);
  }
}