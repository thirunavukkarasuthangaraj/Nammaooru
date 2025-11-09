import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../../core/services/location_service.dart';
import '../../../core/theme/village_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/delivery_location_service.dart';
import '../widgets/save_address_dialog.dart';

class GoogleMapsLocationPickerScreen extends StatefulWidget {
  final String? currentLocation;
  final double? initialLatitude;
  final double? initialLongitude;

  const GoogleMapsLocationPickerScreen({
    super.key,
    this.currentLocation,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<GoogleMapsLocationPickerScreen> createState() => _GoogleMapsLocationPickerScreenState();
}

class _GoogleMapsLocationPickerScreenState extends State<GoogleMapsLocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  String _selectedAddress = '';
  String _selectedStreet = '';
  String _selectedCity = '';
  String _selectedVillage = '';
  String _selectedState = '';
  String _selectedPincode = '';
  bool _isLoadingLocation = false;
  bool _isLoadingMap = false;
  bool _isSearching = false;

  double? _selectedLatitude;
  double? _selectedLongitude;
  // Default location for search fallback only - not used for map center
  static const double _searchFallbackLat = 13.0827;
  static const double _searchFallbackLng = 80.2707;

  Set<Marker> _markers = {};
  loc.LocationData? _currentPosition;
  loc.LocationData? _userActualLocation; // Store user's real current location for distance calculations

  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  bool _isMapMoving = false; // Track when user is moving the map

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _addressController.text = widget.currentLocation ?? '';
    _initializeLocation();
    // Get current location by default when map opens
    _getCurrentLocationOnMapLoad();

    // Add focus listener to update UI
    _addressFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _getCurrentLocationOnMapLoad() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        setState(() {
          _selectedLatitude = position.latitude!;
          _selectedLongitude = position.longitude!;
          _userActualLocation = position; // Store user's actual location
        });

        await _getAddressFromCoordinates(position.latitude!, position.longitude!);
        _updateMarker(LatLng(position.latitude!, position.longitude!));
        _animateToPosition(position.latitude!, position.longitude!);
      }
    } catch (e) {
      print('Error getting current location on map load: $e');
      // No fallback - let user manually select location
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Only initialize if we have coordinates
    if (_selectedLatitude != null && _selectedLongitude != null) {
      if (_selectedLatitude != null && _selectedLongitude != null) {
        _updateMarker(LatLng(_selectedLatitude!, _selectedLongitude!));
        // Get address in background - don't await
        _getAddressFromCoordinates(_selectedLatitude!, _selectedLongitude!);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        setState(() {
          _currentPosition = position;
          _selectedLatitude = position.latitude!;
          _selectedLongitude = position.longitude!;
          _userActualLocation = position; // Update user's actual location
        });

        await _getAddressFromCoordinates(position.latitude!, position.longitude!);
        _updateMarker(LatLng(position.latitude!, position.longitude!));
        _animateToPosition(position.latitude!, position.longitude!);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to get current location', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final address = await LocationService.instance.getAddressFromCoordinates(latitude, longitude);
      if (address != null && mounted) {
        // Build a complete address string with proper formatting
        String fullAddress = '';
        List<String> addressParts = [];

        // Get street components
        String? streetNumber = address['streetNumber'];
        String? streetName = address['streetName'];
        String? subLocality = address['subLocality'];
        String? locality = address['locality'];

        // Build street address part
        if (streetName?.isNotEmpty == true) {
          if (streetNumber?.isNotEmpty == true) {
            // Has both number and street name: "3, Greams Road"
            addressParts.add('$streetNumber, $streetName');
          } else {
            // Has only street name: "Greams Road"
            addressParts.add(streetName!);
          }
        } else if (streetNumber?.isNotEmpty == true) {
          // Has only street number (common in villages): "129"
          // Store it as it's better than nothing
          addressParts.add(streetNumber!);
        }

        // Add subLocality (area/neighborhood) if different from street name
        if (subLocality?.isNotEmpty == true &&
            subLocality != streetName) {
          addressParts.add(subLocality!);
        }

        // Add locality (city)
        if (locality?.isNotEmpty == true) {
          addressParts.add(locality!);
        }

        fullAddress = addressParts.join(', ');

        print('📍 FORMATTED ADDRESS: $fullAddress');
        print('  - Street Number: $streetNumber');
        print('  - Street Name: $streetName');
        print('  - SubLocality: $subLocality');
        print('  - Locality: $locality');

        setState(() {
          _selectedAddress = fullAddress.isNotEmpty ? fullAddress : 'Selected Location';
          // Store street: use street name if available, otherwise use street number (common in villages)
          _selectedStreet = streetName?.isNotEmpty == true
              ? streetName!
              : (streetNumber ?? '');
          _selectedCity = address['locality'] ?? 'Tirupattur'; // City from locality
          _selectedVillage = address['subLocality'] ?? ''; // Village from subLocality
          _selectedState = address['administrativeArea'] ?? 'Tamil Nadu'; // State from administrativeArea
          _selectedPincode = address['postalCode'] ?? '600001';
          _addressController.text = _selectedAddress;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      // Set fallback values if address lookup fails
      if (mounted) {
        setState(() {
          _selectedAddress = 'Selected Location';
          _selectedCity = 'Chennai';
          _selectedVillage = '';
          _selectedState = 'Tamil Nadu';
          _selectedPincode = '600001';
          _addressController.text = _selectedAddress;
        });
      }
    }
  }

  void _updateMarker(LatLng position) async {
    final customIcon = await _createCustomMarker();
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            _onMapTap(newPosition);
          },
          icon: customIcon,
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Drag to adjust position',
          ),
        ),
      };
    });
  }

  Future<BitmapDescriptor> _createCustomMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(60, 80);

    // Draw the lollipop pin
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw the circular top (lollipop head)
    canvas.drawCircle(
      Offset(size.width / 2, size.width / 4),
      size.width / 4,
      paint,
    );

    // Draw the pin (stick)
    final pinPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(size.width / 2 - 3, size.width / 4);
    pinPath.lineTo(size.width / 2 + 3, size.width / 4);
    pinPath.lineTo(size.width / 2, size.height - 10);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // Draw white border for visibility
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.width / 2, size.width / 4),
      size.width / 4,
      borderPaint,
    );

    // Draw small white dot in center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.width / 4),
      4,
      centerPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _animateToPosition(double latitude, double longitude) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _showSuggestions = false; // Hide suggestions when map is tapped
    });
    _updateMarker(position);
    FocusScope.of(context).unfocus();
    // Get address asynchronously without blocking UI
    _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  void _onCameraMove(CameraPosition position) {
    // Update UI to show map is moving
    if (!_isMapMoving) {
      setState(() {
        _isMapMoving = true;
      });
    }
  }

  void _onCameraIdle() async {
    // Map stopped moving - get the center coordinates
    setState(() {
      _isMapMoving = false;
    });

    if (_mapController != null) {
      final LatLngBounds bounds = await _mapController!.getVisibleRegion();
      final LatLng center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      // Update selected coordinates to map center
      setState(() {
        _selectedLatitude = center.latitude;
        _selectedLongitude = center.longitude;
        _showSuggestions = false;
      });

      print('📍 Map stopped at center: ${center.latitude}, ${center.longitude}');

      // Get address for the center position
      await _getAddressFromCoordinates(center.latitude, center.longitude);
    }
  }

  void _onMapLongPress(LatLng position) {
    // Show quick save dialog on long press (like Swiggy/Zomato)
    _onMapTap(position);
    _showQuickSaveDialog(position);
  }

  Future<void> _showQuickSaveDialog(LatLng position) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Wait for address to load

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: VillageTheme.primaryGreen,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'Save this location?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedAddress.isNotEmpty
                  ? _selectedAddress
                  : 'Selected location on map',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveLocation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VillageTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.length > 2) {
      _searchPlaces(query);
    } else {
      setState(() {
        _searchSuggestions.clear();
        _showSuggestions = false;
      });
    }
  }

  Future<void> _searchAddress(String address) async {
    if (address.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      // Use geocoding to find the location
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _selectedLatitude = location.latitude;
          _selectedLongitude = location.longitude;
        });

        // Move map to searched location
        final searchedLocation = LatLng(location.latitude, location.longitude);
        _updateMarker(searchedLocation);
        _animateToPosition(location.latitude, location.longitude);
        await _getAddressFromCoordinates(location.latitude, location.longitude);

        FocusScope.of(context).unfocus();
      } else {
        Helpers.showSnackBar(context, 'Location not found. Try a different search term.', isError: true);
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error searching location: $e', isError: true);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    print('Searching for: $query'); // Debug log

    setState(() {
      _isSearching = true;
      _showSuggestions = false; // Hide while searching
    });

    try {
      // Use geocoding to search for locations
      List<Location> locations = [];

      // Try different search strategies - prioritize exact matches
      try {
        // Search for locations - try with a broader context first
        print('Calling locationFromAddress with query: $query'); // Debug log

        // Try searching without additional context first
        try {
          locations = await locationFromAddress(query).timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );
        } catch (e) {
          print('First attempt failed: $e');
          // If that fails, try with India context
          locations = await locationFromAddress('$query, India').timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );
        }

        print('Found ${locations.length} locations'); // Debug log

        // Filter out irrelevant results that don't contain the search query
        final filteredLocations = <Location>[];
        for (final location in locations) {
          try {
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );

            if (placemarks.isNotEmpty) {
              // Add all locations - let user see all results from geocoding
              // This makes search less restrictive and shows more places
              filteredLocations.add(location);
            }
          } catch (e) {
            // Skip this location if placemark lookup fails
          }
        }

        locations = filteredLocations;

      } catch (e) {
        // Log the error for debugging
        print('Error in locationFromAddress: $e');
        locations = [];
      }

      if (locations.isNotEmpty && mounted) {
        final suggestions = <Map<String, dynamic>>[];
        final processedLocations = <String>{};  // Track unique locations

        // Use user's actual current location for distance calculation (not selected location)
        double? currentLat;
        double? currentLng;

        // Always try to get fresh current location for accurate distance
        try {
          final currentPos = await LocationService.instance.getCurrentPosition();
          if (currentPos != null && currentPos.latitude != null && currentPos.longitude != null) {
            currentLat = currentPos.latitude!;
            currentLng = currentPos.longitude!;
            _userActualLocation = currentPos; // Update stored location
          }
        } catch (e) {
          // Use previously stored actual location if fresh location fails
          if (_userActualLocation != null) {
            currentLat = _userActualLocation!.latitude;
            currentLng = _userActualLocation!.longitude;
          } else {
            // Use fallback location for distance calculation only
            currentLat = _searchFallbackLat;
            currentLng = _searchFallbackLng;
          }
        }

        for (int i = 0; i < locations.length && suggestions.length < 10; i++) {
          final location = locations[i];
          try {
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );

            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;

              // Build location identifier
              String businessName = query;
              String locationArea = '';
              String cityName = placemark.locality ?? '';

              // Extract business/place name - show any match
              String searchLower = query.toLowerCase();

              if (placemark.name != null && placemark.name!.toLowerCase().contains(searchLower)) {
                businessName = placemark.name!;
              } else if (placemark.street != null && placemark.street!.toLowerCase().contains(searchLower)) {
                businessName = placemark.street!;
              } else if (placemark.subLocality != null && placemark.subLocality!.toLowerCase().contains(searchLower)) {
                businessName = placemark.subLocality!;
              } else if (placemark.locality != null && placemark.locality!.toLowerCase().contains(searchLower)) {
                businessName = placemark.locality!;
              }
              // No need to skip - show all geocoding results

              // Extract street name and area
              String streetName = placemark.street ?? '';

              // Extract area/location name (different from business name and street)
              if (placemark.subLocality != null &&
                  placemark.subLocality!.isNotEmpty &&
                  placemark.subLocality != businessName &&
                  placemark.subLocality != streetName) {
                locationArea = placemark.subLocality!;
              } else if (placemark.street != null &&
                        placemark.street!.isNotEmpty &&
                        placemark.street != businessName) {
                locationArea = placemark.street!;
              }

              // Format display name with street - like "Apollo Hospital - Greams Road, Chennai"
              String displayName;
              if (businessName.toLowerCase().contains(query.toLowerCase())) {
                // Business name matches search - show street if available
                if (streetName.isNotEmpty && streetName != businessName) {
                  displayName = '$businessName - $streetName, $cityName';
                } else if (locationArea.isNotEmpty && locationArea != businessName) {
                  displayName = '$businessName - $locationArea, $cityName';
                } else {
                  displayName = '$businessName - $cityName';
                }
              } else {
                // Show street with area/city
                if (streetName.isNotEmpty) {
                  displayName = '$query - $streetName, $cityName';
                } else if (locationArea.isNotEmpty) {
                  displayName = '$query - $locationArea, $cityName';
                } else {
                  displayName = '$query - $cityName';
                }
              }

              // Build full address
              final address = _formatAddress(placemark);

              // Check for duplicates
              final locationKey = '${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
              if (!processedLocations.contains(locationKey)) {
                processedLocations.add(locationKey);

                // Calculate distance from current location if available
                double distance = 0.0;
                if (currentLat != null && currentLng != null) {
                  distance = _calculateDistance(
                    currentLat,
                    currentLng,
                    location.latitude,
                    location.longitude,
                  );
                } else {
                  // Default distance if no current location available
                  distance = 0.0;
                }

                // Calculate relevance score (exact match gets higher score)
                int relevanceScore = 0;
                String searchLower = query.toLowerCase();

                if (businessName.toLowerCase().contains(searchLower)) {
                  relevanceScore += 100;
                }
                if (businessName.toLowerCase().startsWith(searchLower)) {
                  relevanceScore += 50;
                }
                if (streetName.toLowerCase().contains(searchLower)) {
                  relevanceScore += 40;
                }
                if (locationArea.toLowerCase().contains(searchLower)) {
                  relevanceScore += 30;
                }

                suggestions.add({
                  'name': displayName,
                  'full': address,
                  'lat': location.latitude,
                  'lng': location.longitude,
                  'placemark': placemark,
                  'street': streetName,
                  'area': locationArea,
                  'city': cityName,
                  'distance': distance,
                  'relevance': relevanceScore,
                });
              }
            }
          } catch (e) {
            print('Error getting placemark: $e');
          }
        }

        // Sort suggestions by relevance first, then by distance
        suggestions.sort((a, b) {
          int relevanceA = a['relevance'] ?? 0;
          int relevanceB = b['relevance'] ?? 0;

          // First sort by relevance (higher is better)
          if (relevanceA != relevanceB) {
            return relevanceB.compareTo(relevanceA);
          }

          // If same relevance, sort by distance (closer is better)
          double distA = a['distance'] ?? double.infinity;
          double distB = b['distance'] ?? double.infinity;
          return distA.compareTo(distB);
        });

        // Add distance info to display names (only if we have user's location)
        for (var suggestion in suggestions) {
          double distance = suggestion['distance'] ?? 0;
          String? distanceStr;
          if (currentLat != null && currentLng != null && distance > 0) {
            if (distance < 1) {
              distanceStr = '${(distance * 1000).toStringAsFixed(0)} m';
            } else {
              distanceStr = '${distance.toStringAsFixed(1)} km';
            }
          }
          suggestion['distanceStr'] = distanceStr;
        }

        setState(() {
          _searchSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          print('Set ${suggestions.length} suggestions, showing: $_showSuggestions'); // Debug log
        });
      } else {
        // No results found
        print('No locations found for query: $query'); // Debug log
        setState(() {
          _searchSuggestions = [];
          _showSuggestions = false;
        });
      }
    } catch (e) {
      print('Error in _searchPlaces: $e'); // Better error logging
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Calculate distance between two coordinates in kilometers using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // PI / 180
    double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
        math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) / 2;

    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    // Add street name first
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }

    // Add area/sublocality
    if (placemark.subLocality?.isNotEmpty == true &&
        placemark.subLocality != placemark.street) {
      parts.add(placemark.subLocality!);
    }

    // Add locality (city)
    if (placemark.locality?.isNotEmpty == true &&
        placemark.locality != placemark.subLocality) {
      parts.add(placemark.locality!);
    }

    // Add state
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }

    // Add postal code
    if (placemark.postalCode?.isNotEmpty == true) {
      parts.add(placemark.postalCode!);
    }

    return parts.join(', ');
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    _addressController.text = suggestion['full'];
    setState(() {
      _showSuggestions = false;
      _selectedLatitude = suggestion['lat'];
      _selectedLongitude = suggestion['lng'];
    });

    // Move map to the selected location and add marker
    final selectedLocation = LatLng(suggestion['lat'], suggestion['lng']);
    _updateMarker(selectedLocation);
    _animateToPosition(suggestion['lat'], suggestion['lng']);
    _getAddressFromCoordinates(suggestion['lat'], suggestion['lng']);

    FocusScope.of(context).unfocus();
  }

  Future<void> _saveLocation() async {
    if (_selectedAddress.isEmpty) {
      Helpers.showSnackBar(context, 'Address not found for this location', isError: true);
      return;
    }

    // Show save address dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaveAddressDialog(
        latitude: _selectedLatitude ?? 0.0,
        longitude: _selectedLongitude ?? 0.0,
        detectedAddress: _selectedVillage, // Pass area/locality as the detected address
        detectedStreet: _selectedStreet, // Pass street name separately
        detectedCity: _selectedCity,
        detectedVillage: _selectedVillage,
        detectedState: _selectedState,
        detectedPincode: _selectedPincode,
      ),
    );

    if (result != null && result['success'] == true) {
      // Address was saved successfully
      if (mounted) {
        Navigator.pop(context, result['fullAddress']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Select Location',
      ),
      body: Column(
        children: [
          _buildAddressInput(),
          Expanded(
            child: _buildMapContainer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAddressInput() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _addressFocusNode.hasFocus
                  ? VillageTheme.primaryGreen
                  : Colors.grey.shade300,
              width: _addressFocusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.search,
                  color: _addressFocusNode.hasFocus
                      ? VillageTheme.primaryGreen
                      : Colors.grey.shade500,
                  size: 24,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: VillageTheme.primaryGreen,
                  decoration: InputDecoration(
                    hintText: 'Search for area, street or landmark',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide clear button
                    _onSearchChanged(value);
                  },
                  onSubmitted: (value) {
                    _searchAddress(value);
                  },
                  focusNode: _addressFocusNode,
                  onTap: () {
                    setState(() {}); // Rebuild to update focus state
                    if (_searchSuggestions.isNotEmpty) {
                      setState(() {
                        _showSuggestions = true;
                      });
                    }
                  },
                ),
              ),
              if (_addressController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    _addressController.clear();
                    setState(() {
                      _searchSuggestions.clear();
                      _showSuggestions = false;
                    });
                  },
                ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        VillageTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_showSuggestions && _searchSuggestions.isNotEmpty)
          _buildSearchSuggestions(),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    // Calculate available height considering keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight - 200; // 200 for search bar and margins

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      constraints: BoxConstraints(
        maxHeight: availableHeight > 200 ? availableHeight * 0.4 : 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.white,
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _searchSuggestions.length > 5 ? 5 : _searchSuggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade200,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: VillageTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion['name'] ?? 'Location',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (suggestion['distanceStr'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.near_me,
                                          size: 10,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          suggestion['distanceStr'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (suggestion['street'] != null && suggestion['street'].toString().isNotEmpty) ...[
                                  Icon(
                                    Icons.signpost,
                                    size: 12,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      suggestion['street'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else if (suggestion['area'] != null || suggestion['city'] != null) ...[
                                  Icon(
                                    Icons.location_city,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${suggestion['area'] ?? ''} ${suggestion['city'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              suggestion['full'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return GestureDetector(
      onTap: () {
        // Hide suggestions when map is tapped
        setState(() {
          _showSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: const BoxDecoration(
          border: null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
            child: Stack(
              children: [
                GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  print('Google Maps created successfully');
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: _selectedLatitude != null && _selectedLongitude != null
                    ? LatLng(_selectedLatitude!, _selectedLongitude!)
                    : const LatLng(20.5937, 78.9629), // Center of India as neutral starting point
                  zoom: _selectedLatitude != null && _selectedLongitude != null ? 16.0 : 5.0, // Zoom out to show more area
                ),
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                markers: {}, // Remove all markers - we'll use center overlay
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                buildingsEnabled: true,
                indoorViewEnabled: true,
                trafficEnabled: false,
                mapType: MapType.normal,
              ),
              // Center marker overlay
              Center(
                child: Container(
                  transform: Matrix4.translationValues(0, -20, 0), // Offset to point to ground
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: _isMapMoving ? Colors.grey.shade600 : VillageTheme.primaryGreen,
                  ),
                ),
              ),
              // Current location button
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.small(
                  heroTag: "current_location",
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  backgroundColor: VillageTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick actions row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: VillageTheme.primaryGreen,
                      side: BorderSide(color: VillageTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAddress.isNotEmpty ? _saveLocation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VillageTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark_add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedAddress.isNotEmpty
                        ? 'Save Location'
                        : 'Select a location to save',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}