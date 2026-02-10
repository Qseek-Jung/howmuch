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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';

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

  // Fetch remote configuration (ads control, etc.) - Max 3s wait
  try {
    await RemoteConfigService.instance.fetchSettings();
  } catch (e) {
    print('RemoteConfig fetch failed: $e');
  }

  // Initialize AdMob - Max 2s wait or just don't await if not critical
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 2));
    // Load first interstitial ad
    AdMobService.instance.loadInterstitialAd();
  } catch (e) {
    print('AdMob initialization failed/timed out: $e');
  }

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
      builder: (context, child) {
        return VersionCheckWrapper(child: child!);
      },
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

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  const VersionCheckWrapper({super.key, required this.child});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    try {
      final remoteConfig = RemoteConfigService.instance;
      final minVersion = remoteConfig.getMinVersion();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionLower(currentVersion, minVersion)) {
        if (!mounted) return;
        _showUpdateDialog(remoteConfig.getAppStoreUrl());
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  bool _isVersionLower(String current, String min) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(String storeUrl) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('업데이트 안내'),
        content: const Text('안정적인 서비스 이용을 위해 필수 업데이트가 필요합니다.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final url = Uri.parse(storeUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('업데이트 하러 가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
