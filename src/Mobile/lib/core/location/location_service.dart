import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static double? latitude;
  static double? longitude;

  static bool _skippedEmulatorDefaultPending = false;

  static bool consumeSkippedEmulatorDefaultNotification() {
    final v = _skippedEmulatorDefaultPending;
    _skippedEmulatorDefaultPending = false;
    return v;
  }

  static const double _androidEmuLat = 37.4219983;
  static const double _androidEmuLng = -122.084;

  static const double _iosSimLat = 37.3349;
  static const double _iosSimLng = -122.0090;

  static const double _iosSfPresetLat = 37.785834;
  static const double _iosSfPresetLng = -122.406417;

  static bool _withinKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double km,
  ) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c <= km;
  }

  /// Geliştirici emülatör/simülatör fabrika konumu — gerçek GPS değil.
  static bool isLikelySimulatorDefault(double lat, double lng) {
    return _withinKm(lat, lng, _androidEmuLat, _androidEmuLng, 2.5) ||
        _withinKm(lat, lng, _iosSimLat, _iosSimLng, 3.0) ||
        _withinKm(lat, lng, _iosSfPresetLat, _iosSfPresetLng, 2.0);
  }

  static void _clearStored() {
    latitude = null;
    longitude = null;
  }

  static void clearCache() {
    _clearStored();
    _skippedEmulatorDefaultPending = false;
    _locationServiceOffPending = false;
  }

  static bool _locationServiceOffPending = false;

  static bool consumeLocationServiceDisabledNotification() {
    final v = _locationServiceOffPending;
    _locationServiceOffPending = false;
    return v;
  }

  static Future<({double lat, double lng})?> tryCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 30),
        ),
      );
      final lat = pos.latitude;
      final lng = pos.longitude;

      if (isLikelySimulatorDefault(lat, lng)) {
        _clearStored();
        _skippedEmulatorDefaultPending = true;
        return null;
      }

      latitude = lat;
      longitude = lng;
      return (lat: lat, lng: lng);
    } catch (_) {
      return cached;
    }
  }

  static Future<({double lat, double lng})?> acquireForMap() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _locationServiceOffPending = true;
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 45),
        ),
      );
      final lat = pos.latitude;
      final lng = pos.longitude;

      if (isLikelySimulatorDefault(lat, lng)) {
        _clearStored();
        _skippedEmulatorDefaultPending = true;
        return null;
      }

      latitude = lat;
      longitude = lng;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  static ({double lat, double lng})? get cached {
    if (latitude == null || longitude == null) return null;
    if (isLikelySimulatorDefault(latitude!, longitude!)) {
      _clearStored();
      _skippedEmulatorDefaultPending = true;
      return null;
    }
    return (lat: latitude!, lng: longitude!);
  }
}
