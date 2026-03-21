import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  final loc.Location _location = loc.Location();

  // Cached position from last successful GPS fetch
  static double? _cachedLatitude;
  static double? _cachedLongitude;

  /// Get cached latitude (set after first successful GPS fetch)
  static double? get cachedLatitude => _cachedLatitude;

  /// Get cached longitude (set after first successful GPS fetch)
  static double? get cachedLongitude => _cachedLongitude;

  /// Check if a cached position is available
  static bool get hasCachedPosition => _cachedLatitude != null && _cachedLongitude != null;

  // Use your Google Maps API key from env config
  static const String _googleApiKey = 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';

  Future<Map<String, String>?> getAddressFromGoogleAPI(double latitude, double longitude) async {
    try {
      print('🌍 GOOGLE API REQUEST: lat=$latitude, lng=$longitude');

      // Add result_type to prioritize locality (village/town) results
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
                  'latlng=$latitude,$longitude&'
                  'result_type=street_address|route|neighborhood|locality|sublocality&'
                  'key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 GOOGLE API RESPONSE: ${data['status']}');
        print('📍 Total results: ${data['results'].length}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Try to find the best result - prefer locality over neighborhood
          var result = data['results'][0];

          // Look for a result with locality type (actual village/town)
          for (var res in data['results']) {
            final types = res['types'] as List;
            if (types.contains('locality') || types.contains('sublocality_level_1')) {
              result = res;
              print('✅ Found locality type result, using that instead');
              break;
            }
          }
          final addressComponents = result['address_components'] as List;

          String streetNumber = '';
          String route = '';
          String premise = '';
          String neighborhood = '';
          String subLocality = '';
          String subLocalityLevel2 = '';
          String subLocalityLevel3 = '';
          String locality = '';
          String administrativeArea = '';
          String postalCode = '';
          String country = '';

          // Parse address components with better street name extraction
          for (var component in addressComponents) {
            final types = component['types'] as List;
            final longName = component['long_name'] as String;

            if (types.contains('street_number')) {
              streetNumber = longName;
            } else if (types.contains('route')) {
              route = longName;
            } else if (types.contains('premise')) {
              premise = longName;
            } else if (types.contains('neighborhood')) {
              neighborhood = longName;
            } else if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
              subLocality = longName;
            } else if (types.contains('sublocality_level_2')) {
              subLocalityLevel2 = longName;
            } else if (types.contains('sublocality_level_3')) {
              subLocalityLevel3 = longName;
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

          // Build street/road name - try multiple sources
          String streetName = route; // This is the actual street/road name
          String houseNumber = streetNumber;

          // If no route, try to get from other sources
          if (streetName.isEmpty) {
            if (premise.isNotEmpty) {
              streetName = premise;
            } else if (neighborhood.isNotEmpty) {
              streetName = neighborhood;
            } else if (subLocalityLevel3.isNotEmpty) {
              // Sometimes the street name is in sublocality level 3
              streetName = subLocalityLevel3;
            } else if (subLocalityLevel2.isNotEmpty && subLocalityLevel2 != subLocality) {
              // Use sublocality level 2 if it's different from level 1
              streetName = subLocalityLevel2;
            }
          }

          // Determine best 'name' for the location (village/area name)
          // Priority: neighborhood > subLocalityLevel3 > subLocalityLevel2 > subLocality > locality
          String locationName = '';
          if (neighborhood.isNotEmpty) {
            locationName = neighborhood;
          } else if (subLocalityLevel3.isNotEmpty) {
            locationName = subLocalityLevel3;
          } else if (subLocalityLevel2.isNotEmpty) {
            locationName = subLocalityLevel2;
          } else if (subLocality.isNotEmpty) {
            locationName = subLocality;
          } else if (locality.isNotEmpty) {
            locationName = locality;
          }

          print('🏠 GOOGLE API PARSED DATA:');
          print('  - streetNumber: $streetNumber');
          print('  - route (street name): $route');
          print('  - premise: $premise');
          print('  - neighborhood: $neighborhood');
          print('  - subLocality: $subLocality');
          print('  - subLocalityLevel2: $subLocalityLevel2');
          print('  - subLocalityLevel3: $subLocalityLevel3');
          print('  - locality: $locality');
          print('  - administrativeArea: $administrativeArea');
          print('  - postalCode: $postalCode');
          print('  - country: $country');
          print('  - FINAL streetName: $streetName');
          print('  - FINAL locationName: $locationName');
          print('  - formatted_address: ${result['formatted_address']}');

          return {
            'name': locationName, // Best name for village/area
            'streetName': streetName,
            'streetNumber': houseNumber,
            'street': streetName, // Keep for backward compatibility
            'subLocality': subLocality,
            'neighborhood': neighborhood,
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
        print('❌ Location permission denied');
        return null;
      }

      print('📍 Getting current location with 15s timeout...');
      // Add timeout to prevent infinite loading
      loc.LocationData position = await _location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Location request timed out after 15 seconds');
          throw Exception('Location request timed out. Please check your device location settings.');
        },
      );
      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      // Cache for instant reuse in other screens
      _cachedLatitude = position.latitude;
      _cachedLongitude = position.longitude;
      return position;
    } catch (e) {
      print('❌ Error getting current position: $e');
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
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Geocoding request timed out');
          return [];
        },
      );

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

        // Extract street name and number separately
        String streetName = '';
        String streetNumber = '';

        // thoroughfare = street name, subThoroughfare = street number
        if (place.thoroughfare?.isNotEmpty == true) {
          streetName = place.thoroughfare!;
        } else if (place.street?.isNotEmpty == true) {
          streetName = place.street!;
        }

        if (place.subThoroughfare?.isNotEmpty == true) {
          streetNumber = place.subThoroughfare!;
        }

        // If still no street name, try to use name if it's different from locality
        if (streetName.isEmpty &&
            place.name?.isNotEmpty == true &&
            place.name != place.subLocality &&
            place.name != place.locality) {
          streetName = place.name!;
        }

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
          'streetName': streetName,
          'streetNumber': streetNumber,
          'street': streetName, // Keep for backward compatibility
          'subLocality': place.subLocality ?? '',
          'locality': cityName,
          'administrativeArea': place.administrativeArea ?? 'Tamil Nadu',
          'postalCode': place.postalCode ?? '',
          'country': place.country ?? 'India',
        };

        print('✅ FLUTTER GEOCODING RESULT:');
        print('  - streetNumber: ${result['streetNumber']}');
        print('  - streetName: ${result['streetName']}');
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