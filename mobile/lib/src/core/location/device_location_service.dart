import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// The only place in the app that imports `geolocator`.
///
/// No map, no reverse geocoding (DEC-004) — a coordinate pair is the whole job. Every failure
/// path returns `null` rather than throwing: a donor who declines, has location services off,
/// or is permanently denied must still finish setup with a district-only, matchable profile
/// (ADR 0003).
final class DeviceLocationService implements LocationService {
    const DeviceLocationService();

    @override
    Future<LocationFix?> currentFix() async {
        // One `try` around the permission calls too, not only the fix: iOS throws from
        // `requestPermission()` when the Info.plist purpose string is missing, and a throw
        // here left the setup screen's "use my current location" spinner running forever
        // (SEC-REVIEW-005 M-01).
        try {
            if (!await Geolocator.isLocationServiceEnabled()) return null;

            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
                return null;
            }

            final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: Duration(seconds: 15),
                ),
            );
            return (latitude: position.latitude, longitude: position.longitude);
        } on Object {
            // Timeout, provider disabled mid-call, a platform-channel error, a missing purpose
            // string. Coordinates are optional; the profile must still be completable.
            return null;
        }
    }
}
