import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/remote_config_service.dart';

/// 광고 설정 상태
class AdSettings {
  final bool isAdFree;

  AdSettings({this.isAdFree = false});

  AdSettings copyWith({bool? isAdFree}) {
    return AdSettings(isAdFree: isAdFree ?? this.isAdFree);
  }
}

/// 광고 설정 프로바이더
class AdSettingsNotifier extends StateNotifier<AdSettings> {
  static const String _adFreeKey = 'ad_free_mode';
  static const String _secretCode = '770918770918';

  AdSettingsNotifier() : super(AdSettings()) {
    _loadSettings();
  }

  /// SharedPreferences에서 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdFree = prefs.getBool(_adFreeKey) ?? false;
    state = AdSettings(isAdFree: isAdFree);
  }

  /// 광고 없는 모드 토글
  Future<void> toggleAdFreeMode() async {
    final newAdFreeState = !state.isAdFree;
    state = state.copyWith(isAdFree: newAdFreeState);

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adFreeKey, newAdFreeState);
  }

  /// 비밀코드 검증
  bool verifySecretCode(String input) {
    return input == _secretCode;
  }

  /// 광고 표시 여부 확인 (원격 설정 우선, 로컬 설정 차선, 기본값 true)
  bool shouldShowAd() {
    // 1. Check remote config first (for global testing control)
    final remoteAdsEnabled = RemoteConfigService.instance.areAdsEnabled();
    if (!remoteAdsEnabled) {
      return false; // Remote config disabled ads globally
    }

    // 2. Check local ad-free mode (secret code)
    if (state.isAdFree) {
      return false; // Local admin mode enabled
    }

    // 3. Default: show ads
    return true;
  }
}

/// 광고 설정 프로바이더
final adSettingsProvider =
    StateNotifierProvider<AdSettingsNotifier, AdSettings>((ref) {
      return AdSettingsNotifier();
    });
