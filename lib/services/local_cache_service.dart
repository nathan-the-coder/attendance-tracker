import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles local caching of attendance data for offline support
class LocalCacheService extends ChangeNotifier {
  static const String _daysCacheKey = 'cached_days';
  static const String _sectionsCacheKey = 'cached_sections';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _lastSyncKey = 'last_sync_time';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _hasLocalData = false;
  DateTime? _lastSyncTime;

  bool get isInitialized => _isInitialized;
  bool get hasLocalData => _hasLocalData;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _hasLocalData = _prefs!.containsKey(_daysCacheKey);
    final lastSync = _prefs!.getString(_lastSyncKey);
    if (lastSync != null) {
      _lastSyncTime = DateTime.tryParse(lastSync);
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Saves days data to local cache
  Future<void> cacheDays(List<Map<String, dynamic>> days) async {
    if (_prefs == null) return;

    final jsonString = jsonEncode(days);
    await _prefs!.setString(_daysCacheKey, jsonString);
    await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
    _hasLocalData = true;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Gets cached days data
  List<Map<String, dynamic>>? getCachedDays() {
    if (_prefs == null) return null;

    final jsonString = _prefs!.getString(_daysCacheKey);
    if (jsonString == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding cached days: $e');
      return null;
    }
  }

  /// Saves sections/students data to local cache
  Future<void> cacheSections(List<Map<String, dynamic>> sections) async {
    if (_prefs == null) return;

    final jsonString = jsonEncode(sections);
    await _prefs!.setString(_sectionsCacheKey, jsonString);
    notifyListeners();
  }

  /// Gets cached sections data
  List<Map<String, dynamic>>? getCachedSections() {
    if (_prefs == null) return null;

    final jsonString = _prefs!.getString(_sectionsCacheKey);
    if (jsonString == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding cached sections: $e');
      return null;
    }
  }

  /// Adds a pending action to be synced when online
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    if (_prefs == null) return;

    final pendingActions = getPendingActions();
    pendingActions.add({
      ...action,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _prefs!.setString(_pendingActionsKey, jsonEncode(pendingActions));
    notifyListeners();
  }

  /// Gets all pending actions
  List<Map<String, dynamic>> getPendingActions() {
    if (_prefs == null) return [];

    final jsonString = _prefs!.getString(_pendingActionsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding pending actions: $e');
      return [];
    }
  }

  /// Clears all pending actions after successful sync
  Future<void> clearPendingActions() async {
    if (_prefs == null) return;
    await _prefs!.remove(_pendingActionsKey);
    notifyListeners();
  }

  /// Clears all cached data
  Future<void> clearCache() async {
    if (_prefs == null) return;
    await _prefs!.remove(_daysCacheKey);
    await _prefs!.remove(_sectionsCacheKey);
    await _prefs!.remove(_pendingActionsKey);
    await _prefs!.remove(_lastSyncKey);
    _hasLocalData = false;
    _lastSyncTime = null;
    notifyListeners();
  }
}
