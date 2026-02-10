import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  factory AnalyticsService() => instance;
  AnalyticsService._internal();

  final _supabase = Supabase.instance.client;
  String? _visitorId;

  /// Initialize analytics by getting or creating a visitor ID
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _visitorId = prefs.getString('analytics_visitor_id');

    if (_visitorId == null) {
      _visitorId = 'app-v-${const Uuid().v4().substring(0, 8)}';
      await prefs.setString('analytics_visitor_id', _visitorId!);
    }
  }

  /// Log a screen view to the page_views table
  Future<void> logScreenView(String screenName) async {
    try {
      if (_visitorId == null) await init();

      final String platform = Platform.isAndroid
          ? 'app_android'
          : (Platform.isIOS ? 'app_ios' : 'app_other');

      await _supabase.from('page_views').insert({
        'page_path': screenName,
        'visitor_id': _visitorId,
        'referrer': platform,
      });

      debugPrint('Analytics: Logged screen view: $screenName ($platform)');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
