import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 한글 로케일 지원
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'services/admob_service.dart';
import 'services/remote_config_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Date Formatting
  await initializeDateFormatting();

  // Initialize Supabase
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  // Fetch remote configuration (ads control, etc.)
  await RemoteConfigService.instance.fetchSettings();

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Load first interstitial ad
  AdMobService.instance.loadInterstitialAd();

  // TODO: Initialize Kakao SDK here
  // KakaoSdk.init(nativeAppKey: Constants.kakaoNativeAppKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: '얼마야 (How Much)',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // 🇰🇷 한글 로케일 지원
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
      ],
      locale: const Locale('ko', 'KR'), // 기본 언어: 한국어
    );
  }
}
