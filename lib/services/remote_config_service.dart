import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage remote app settings from Supabase
class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._internal();

  factory RemoteConfigService() {
    return instance;
  }

  RemoteConfigService._internal();

  final _supabase = Supabase.instance.client;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  /// Cache for settings
  final Map<String, dynamic> _settingsCache = {};
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  /// Fetch all app settings from Supabase
  Future<void> fetchSettings() async {
    try {
      // Check cache validity
      if (_lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheDuration) {
        return; // Use cached data
      }

      final response = await _supabase
          .from('app_settings')
          .select('setting_key, setting_value')
          .timeout(const Duration(seconds: 3));

      _settingsCache.clear();
      for (final row in response as List<dynamic>) {
        final key = row['setting_key'] as String;
        final value = row['setting_value'];
        _settingsCache[key] = value;
      }
      _lastFetch = DateTime.now();
      _isOffline = false;
    } catch (e) {
      print('Error fetching remote config (Offline?): $e');
      _isOffline = true;
      // Keep using cached data or defaults on error
    }
  }

  /// Get a specific setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      if (_settingsCache.containsKey(key)) {
        final value = _settingsCache[key];
        if (value is Map<String, dynamic> && value.containsKey('enabled')) {
          return value['enabled'] as T?;
        }
        return value as T?;
      }
      return defaultValue;
    } catch (e) {
      print('Error getting setting $key: $e');
      return defaultValue;
    }
  }

  /// Check if ads are enabled globally
  bool areAdsEnabled() {
    return getSetting<bool>('ads_enabled', defaultValue: true) ?? true;
  }

  /// Force refresh settings (clears cache)
  Future<void> forceRefresh() async {
    _lastFetch = null;
    await fetchSettings();
  }

  /// Get a specific ad unit ID for the current platform
  String getAdUnitId() {
    final ids = getSetting<Map<String, dynamic>>('admob_interstitial_ids');
    if (ids != null) {
      if (Platform.isAndroid)
        return ids['android'] ?? 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS)
        return ids['ios'] ?? 'ca-app-pub-3940256099942544/4411468910';
    }

    // Default test IDs if not found in remote config
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    return 'ca-app-pub-3940256099942544/4411468910';
  }

  /// Get a banner ad unit ID for the current platform
  String getBannerAdUnitId() {
    final ids = getSetting<Map<String, dynamic>>('admob_banner_ids');
    if (ids != null) {
      if (Platform.isAndroid)
        return ids['android'] ?? 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS)
        return ids['ios'] ?? 'ca-app-pub-3940256099942544/2934735716';
    }

    // Default test IDs if not found in remote config
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  /// Get the minimum supported version
  String getMinVersion() {
    return getSetting<String>('min_version', defaultValue: '1.0.0') ?? '1.0.0';
  }

  /// Get the App Store / Play Store URL
  String getAppStoreUrl() {
    return getSetting<String>(
          'app_store_url',
          defaultValue: 'market://details?id=com.qseek.howmuch',
        ) ??
        'market://details?id=com.qseek.howmuch';
  }

  /// Clear cache
  void clearCache() {
    _settingsCache.clear();
    _lastFetch = null;
  }
}
