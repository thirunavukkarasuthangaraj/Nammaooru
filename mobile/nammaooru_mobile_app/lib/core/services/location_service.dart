import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  final loc.Location _location = loc.Location();

  // Use your Google Maps API key
  static const String _googleApiKey = 'AIzaSyDcOGJI9jz-tRj3fPYi4UH04H4Z6DQ4TgE';

  Future<Map<String, String>?> getAddressFromGoogleAPI(double latitude, double longitude) async {
    try {
      print('🌍 GOOGLE API REQUEST: lat=$latitude, lng=$longitude');

      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
                  'latlng=$latitude,$longitude&'
                  'key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 GOOGLE API RESPONSE: ${data['status']}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final addressComponents = result['address_components'] as List;

          String street = '';
          String subLocality = '';
          String locality = '';
          String administrativeArea = '';
          String postalCode = '';
          String country = '';

          // Parse address components
          for (var component in addressComponents) {
            final types = component['types'] as List;
            final longName = component['long_name'] as String;

            if (types.contains('street_number') || types.contains('route')) {
              street = '$street ${longName}'.trim();
            } else if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
              subLocality = longName;
            } else if (types.contains('locality')) {
              locality = longName;
            } else if (types.contains('administrative_area_level_2')) {
              // This is often the district/city level
              if (locality.isEmpty) locality = longName;
            } else if (types.contains('administrative_area_level_1')) {
              administrativeArea = longName;
            } else if (types.contains('postal_code')) {
              postalCode = longName;
            } else if (types.contains('country')) {
              country = longName;
            }
          }

          print('🏠 GOOGLE API PARSED DATA:');
          print('  - street: $street');
          print('  - subLocality: $subLocality');
          print('  - locality: $locality');
          print('  - administrativeArea: $administrativeArea');
          print('  - postalCode: $postalCode');
          print('  - country: $country');
          print('  - formatted_address: ${result['formatted_address']}');

          return {
            'street': street,
            'subLocality': subLocality,
            'locality': locality.isNotEmpty ? locality : 'Tirupattur',
            'administrativeArea': administrativeArea.isNotEmpty ? administrativeArea : 'Tamil Nadu',
            'postalCode': postalCode,
            'country': country.isNotEmpty ? country : 'India',
          };
        }
      }

      print('❌ GOOGLE API FAILED: Status ${response.statusCode}');
      return null;
    } catch (e) {
      print('💥 GOOGLE API ERROR: $e');
      return null;
    }
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    loc.PermissionStatus permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != loc.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<loc.LocationData?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      loc.LocationData position = await _location.getLocation();
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getAddressFromCoordinates(double latitude, double longitude) async {
    // Try Google API first for better accuracy
    Map<String, String>? googleResult = await getAddressFromGoogleAPI(latitude, longitude);
    if (googleResult != null) {
      print('✅ USING GOOGLE API RESULT');
      return googleResult;
    }

    // Fallback to Flutter geocoding package
    print('🔄 FALLING BACK TO FLUTTER GEOCODING');
    try {
      print('🌍 GEOCODING REQUEST: lat=$latitude, lng=$longitude');
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      print('📍 GEOCODING RESPONSE: Found ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Log all available data from the placemark
        print('🏠 PLACEMARK DATA:');
        print('  - name: ${place.name}');
        print('  - street: ${place.street}');
        print('  - subLocality: ${place.subLocality}');
        print('  - locality: ${place.locality}');
        print('  - administrativeArea: ${place.administrativeArea}');
        print('  - postalCode: ${place.postalCode}');
        print('  - country: ${place.country}');
        print('  - subAdministrativeArea: ${place.subAdministrativeArea}');
        print('  - thoroughfare: ${place.thoroughfare}');
        print('  - subThoroughfare: ${place.subThoroughfare}');

        // Use subAdministrativeArea (district/city) if available, otherwise locality (area/village)
        String cityName = place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea!
            : (place.locality?.isNotEmpty == true ? place.locality! : 'Tirupattur');

        // Manual mapping for known localities to their proper cities
        Map<String, String> localityToCityMap = {
          'Marimanikuppam': 'Tirupattur',
          'Mittur': 'Tirupattur',
          'Natrampalli': 'Tirupattur',
          'Vaniyambadi': 'Tirupattur',
        };

        // Check if we need to map locality to proper city
        if (localityToCityMap.containsKey(cityName)) {
          cityName = localityToCityMap[cityName]!;
          print('🔄 MAPPED LOCALITY TO CITY: ${place.locality} → $cityName');
        }

        final result = {
          'street': place.street ?? '',
          'subLocality': place.subLocality ?? '',
          'locality': cityName,
          'administrativeArea': place.administrativeArea ?? 'Tamil Nadu',
          'postalCode': place.postalCode ?? '',
          'country': place.country ?? 'India',
        };

        print('✅ FLUTTER GEOCODING RESULT:');
        print('  - street: ${result['street']}');
        print('  - subLocality: ${result['subLocality']}');
        print('  - locality: ${result['locality']}');
        print('  - administrativeArea: ${result['administrativeArea']}');
        print('  - postalCode: ${result['postalCode']}');
        print('  - country: ${result['country']}');

        return result;
      }

      print('❌ NO PLACEMARKS FOUND for lat=$latitude, lng=$longitude');
      return null;
    } catch (e) {
      print('💥 ERROR getting address from coordinates: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getCurrentLocationAddress() async {
    try {
      loc.LocationData? position = await getCurrentPosition();
      if (position == null || position.latitude == null || position.longitude == null) {
        return null;
      }

      return await getAddressFromCoordinates(position.latitude!, position.longitude!);
    } catch (e) {
      print('Error getting current location address: $e');
      return null;
    }
  }
}