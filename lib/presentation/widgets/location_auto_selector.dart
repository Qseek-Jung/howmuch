import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/location_service.dart';
import '../home/currency_provider.dart';

class LocationAutoSelector extends ConsumerStatefulWidget {
  final Widget child;
  const LocationAutoSelector({super.key, required this.child});

  @override
  ConsumerState<LocationAutoSelector> createState() =>
      _LocationAutoSelectorState();
}

class _LocationAutoSelectorState extends ConsumerState<LocationAutoSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    final isoCode = await LocationService.instance.getCurrentCountryIso();

    // [DEBUG]
    print("[LocationAutoSelector] Detected ISO: $isoCode");

    if (isoCode == null || isoCode == 'KR') return;

    // 1. Get Country Info
    final info = LocationService.instance.getCountryInfoFromIso(isoCode);
    if (info == null) return;

    final countryName = info['name']!;
    final currencyCode = info['currency']!;

    if (countryName.isEmpty || currencyCode.isEmpty) return;

    // 2. Format Unique ID (Name:Code)
    final uniqueId = "$countryName:$currencyCode";

    // 3. Update Detected Country Provider (For Ledger Sorting)
    ref.read(detectedCountryProvider.notifier).state = uniqueId;

    // 4. Check Favorites
    final favorites = ref.read(favoriteCurrenciesProvider);
    bool added = false;

    // Check if favorite exists (matches Name:Code OR Code:Name OR just Code)
    final existingIndex = favorites.indexWhere((f) {
      if (f == uniqueId) return true;
      if (f == currencyCode) return true; // Legacy
      // Check swapped
      final parts = f.split(':');
      if (parts.length == 2) {
        if (parts[0] == currencyCode && parts[1] == countryName) return true;
      }
      return false;
    });

    if (existingIndex == -1) {
      // Not in favorites, add it
      ref.read(favoriteCurrenciesProvider.notifier).addFavorite(uniqueId);
      added = true;
      print("[LocationAutoSelector] Added $uniqueId to favorites");
    }

    // 5. Select Currency (if not already selected)
    final selectedId = ref.read(selectedCurrencyIdProvider);
    // Find the actual ID in the favorites (might be legacy format)
    final actualId = existingIndex != -1 ? favorites[existingIndex] : uniqueId;

    if (selectedId != actualId) {
      ref.read(selectedCurrencyIdProvider.notifier).setSelectedId(actualId);

      // Notify User
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? "$countryName($currencyCode)에 도착했습니다. 즐겨찾기에 추가하고 선택했습니다."
                  : "$countryName($currencyCode)에 도착했습니다. 통화를 자동으로 선택했습니다.",
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
