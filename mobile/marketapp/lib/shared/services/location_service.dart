import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Position? _currentPosition;
  static String? _currentAddress;
  
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }
    
    return true;
  }
  
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  static Future<String?> getCurrentAddress() async {
    try {
      final position = _currentPosition ?? await getCurrentLocation();
      if (position == null) return null;
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}';
        return _currentAddress;
      }
      
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }
  
  static Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return [];
    }
  }
  
  static Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return [];
    }
  }
  
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }
  
  static Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
  
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
  
  static Position? get currentPosition => _currentPosition;
  static String? get currentAddress => _currentAddress;
}