import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/currency_data.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  /// Request permission and get current country ISO code (e.g., 'KR', 'JP')
  Future<String?> getCurrentCountryIso() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check Service Status
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled.
      return null;
    }

    // 2. Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 3. Get Position
    try {
      // Use low accuracy for speed and battery, we only need country
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );

      // 4. Reverse Geocoding
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode?.toUpperCase();
      }
    } catch (e) {
      print("Location Error: $e");
    }

    return null;
  }

  /// Find Currency Code and Country Name from ISO Country Code (Flag)
  Map<String, String>? getCountryInfoFromIso(String isoCode) {
    try {
      final country = CurrencyData.allCountries.firstWhere(
        (c) => c['flag'] == isoCode,
      );
      return {
        'currency': country['currency'] ?? '',
        'name': country['countryKR'] ?? '',
        'flag': country['flag'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}
