import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';

/// AdMob 전면광고 관리 서비스
/// Singleton 패턴으로 앱 전체에서 단일 인스턴스 사용
class AdMobService {
  static final AdMobService instance = AdMobService._internal();

  factory AdMobService() {
    return instance;
  }

  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;

  /// 전면광고 단위 ID 가져오기
  String get _interstitialAdUnitId {
    return RemoteConfigService.instance.getAdUnitId();
  }

  /// 전면광고 로드
  Future<void> loadInterstitialAd() async {
    // Check Global Switch
    if (!RemoteConfigService.instance.areAdsEnabled()) {
      return;
    }

    if (_isAdLoading || _isAdLoaded) {
      return;
    }

    _isAdLoading = true;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;

          // 광고 이벤트 리스너 설정
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (InterstitialAd ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  _isAdLoaded = false;
                  // 다음 광고 미리 로드
                  loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent:
                    (InterstitialAd ad, AdError error) {
                      ad.dispose();
                      _interstitialAd = null;
                      _isAdLoaded = false;
                      // 다음 광고 미리 로드
                      loadInterstitialAd();
                    },
              );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoading = false;
          _isAdLoaded = false;
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// 전면광고 표시
  /// [onAdDismissed] 광고가 닫힌 후 실행할 콜백
  Future<void> showInterstitialAd({required Function() onAdDismissed}) async {
    if (_interstitialAd != null && _isAdLoaded) {
      // 광고가 로드되어 있으면 표시
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          // 콜백 실행
          onAdDismissed();
          // 다음 광고 미리 로드
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          // 광고 표시 실패 시에도 콜백 실행
          onAdDismissed();
          // 다음 광고 미리 로드
          loadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
    } else {
      // 광고가 로드되지 않았으면 바로 콜백 실행
      onAdDismissed();
      // 광고 로드 시도
      if (!_isAdLoading) {
        loadInterstitialAd();
      }
    }
  }

  /// 배너 광고 생성 및 로드 (Standard)
  BannerAd createBannerAd({
    required Function() onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: RemoteConfigService.instance.getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => onAdLoaded(),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    )..load();
  }

  /// 가변형(Adaptive) 배너 광고 생성 및 로드
  Future<BannerAd> createAdaptiveBannerAd({
    required int width,
    required Function() onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) async {
    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    // Fallback to standard banner if adaptive size fails
    final AdSize size = adaptiveSize ?? AdSize.banner;

    return BannerAd(
      adUnitId: RemoteConfigService.instance.getBannerAdUnitId(),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => onAdLoaded(),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    )..load();
  }

  /// 리소스 정리
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
  }
}
