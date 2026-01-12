import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User's current location with fallback to Rome
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isReal; // true if from GPS, false if fallback

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isReal = false,
  });

  // Default fallback location (Rome, Italy)
  static const UserLocation fallback = UserLocation(
    latitude: 41.9028,
    longitude: 12.4964,
    isReal: false,
  );
}

/// Service to handle location permissions and fetching
class LocationService {
  /// Check if location services are enabled and permission granted
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location with fallback
  Future<UserLocation> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        return UserLocation.fallback;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        isReal: true,
      );
    } catch (e) {
      // On any error, return fallback
      return UserLocation.fallback;
    }
  }
}

/// Singleton instance
final locationService = LocationService();

/// Provider for current user location (simple FutureProvider, no code generation needed)
final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  return await locationService.getCurrentLocation();
});
