import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/ad_settings_provider.dart';
import '../../services/admob_service.dart';

/// 앱 하단 고정형 가변 배너 위젯
/// 30초 자동 갱신 및 글로벌 광고 설정 연동
class GlobalBannerAd extends ConsumerStatefulWidget {
  const GlobalBannerAd({super.key});

  @override
  ConsumerState<GlobalBannerAd> createState() => _GlobalBannerAdState();
}

class _GlobalBannerAdState extends ConsumerState<GlobalBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Timer? _refreshTimer;

  // 30초 갱신 주기
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 크기가 결정된 후 초기 로드
    if (!_isLoaded && _bannerAd == null) {
      _loadAd();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  /// 광고 로드 (가변형)
  Future<void> _loadAd() async {
    // 1. 글로벌 설정 체크
    final adSettings = ref.read(adSettingsProvider.notifier);
    if (!adSettings.shouldShowAd()) {
      _cancelTimer();
      if (_bannerAd != null) {
        // 이미 로드된 광고가 있다면 제거 (설정이 변경된 경우)
        _bannerAd!.dispose();
        setState(() {
          _bannerAd = null;
          _isLoaded = false;
        });
      }
      return;
    }

    // 2. 가로폭 계산
    final width = MediaQuery.of(context).size.width.truncate();

    // 3. 기존 광고 정리
    _bannerAd?.dispose();

    // 4. 새 광고 생성
    AdMobService.instance
        .createAdaptiveBannerAd(
          width: width,
          onAdLoaded: () {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
              // 로드 성공 시 타이머 시작 (30초 후 갱신)
              _startTimer();
            }
          },
          onAdFailedToLoad: (ad, error) {
            print('Adaptive Banner failed to load: $error');
            if (mounted) {
              setState(() {
                _isLoaded = false;
              });
              // 실패해도 일정 시간 후 재시도
              _startTimer();
            }
          },
        )
        .then((ad) {
          if (mounted) {
            setState(() {
              _bannerAd = ad;
            });
          }
        });
  }

  /// 타이머 시작
  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshInterval, () {
      if (mounted) {
        _loadAd();
      }
    });
  }

  /// 타이머 취소
  void _cancelTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    // 광고가 로드되지 않았거나 설정상 보이지 말아야 할 경우 빈 공간 반환
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // 배너 높이 계산 (Adaptive)
    final height = _bannerAd!.size.height.toDouble();

    return Container(
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF3F4F6),
      child: SafeArea(
        top: false,
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
