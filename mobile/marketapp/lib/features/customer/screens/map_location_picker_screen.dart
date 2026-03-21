import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import '../../../core/services/location_service.dart';
import '../../../core/theme/village_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/delivery_location_service.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final String? currentLocation;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPickerScreen({
    super.key,
    this.currentLocation,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final TextEditingController _addressController = TextEditingController();
  String _selectedAddress = '';
  String _selectedCity = '';
  String _selectedState = '';
  String _selectedPincode = '';
  bool _isLoadingLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  loc.LocationData? _currentPosition;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude ?? 13.0827; // Default Chennai
    _selectedLongitude = widget.initialLongitude ?? 80.2707;
    _addressController.text = widget.currentLocation ?? '';
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _selectedLatitude = position.latitude!;
          _selectedLongitude = position.longitude!;
        });

        await _getAddressFromCoordinates(position.latitude!, position.longitude!);
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
        setState(() {
          _selectedAddress = '${address['street']}, ${address['subLocality']}';
          _selectedCity = address['locality'] ?? 'Chennai';
          _selectedState = address['administrativeArea'] ?? 'Tamil Nadu';
          _selectedPincode = address['postalCode'] ?? '600001';
          _addressController.text = _selectedAddress;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      Helpers.showSnackBar(context, 'Please select a location on the map', isError: true);
      return;
    }

    if (_selectedAddress.isEmpty) {
      Helpers.showSnackBar(context, 'Address not found for this location', isError: true);
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save location using API service
      final result = await DeliveryLocationService().saveDeliveryLocation(
        address: _selectedAddress,
        city: _selectedCity,
        state: _selectedState,
        pincode: _selectedPincode,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        landmark: null,
        nickname: 'Selected Location',
        isDefault: false,
      );

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success']) {
        // Also save to local storage for immediate use
        final locationData = {
          'address': _selectedAddress,
          'city': _selectedCity,
          'state': _selectedState,
          'pincode': _selectedPincode,
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'fullAddress': '$_selectedAddress, $_selectedCity, $_selectedState - $_selectedPincode',
          'timestamp': DateTime.now().toIso8601String(),
        };

        await LocalStorage.setMap('selected_delivery_location', locationData);

        if (mounted) {
          Helpers.showSnackBar(context, result['message'] ?? 'Location saved successfully!');
          Navigator.pop(context, locationData['fullAddress']);
        }
      } else {
        if (mounted) {
          Helpers.showSnackBar(context, result['message'] ?? 'Failed to save location', isError: true);
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to save location: ${e.toString()}', isError: true);
      }
    }
  }

  void _onMapTap(double latitude, double longitude) {
    setState(() {
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
    });
    _getAddressFromCoordinates(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Select Location on Map',
      ),
      body: Column(
        children: [
          _buildAddressInput(),
          _buildMapContainer(),
          _buildLocationDetails(),
          _buildQuickActions(),
        ],
      ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _addressController,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          hintText: 'Enter address or search location...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        onSubmitted: (value) {
          // TODO: Implement address search
          Helpers.showSnackBar(context, 'Address search coming soon!');
        },
      ),
    );
  }

  Widget _buildMapContainer() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Map placeholder with interactive area
              GestureDetector(
                onTapDown: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final position = renderBox.globalToLocal(details.globalPosition);

                  // Simulate map coordinates based on tap position
                  final mapHeight = renderBox.size.height;
                  final mapWidth = renderBox.size.width;

                  // Convert tap position to mock coordinates
                  final lat = (_selectedLatitude ?? 13.0827) +
                      (position.dy / mapHeight - 0.5) * 0.01;
                  final lng = (_selectedLongitude ?? 80.2707) +
                      (position.dx / mapWidth - 0.5) * 0.01;

                  _onMapTap(lat, lng);
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade50,
                        Colors.blue.shade50,
                        Colors.green.shade100,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Mock map grid
                      ...List.generate(10, (i) =>
                        Positioned(
                          top: (i * 40.0),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ),
                      ...List.generate(8, (i) =>
                        Positioned(
                          left: (i * 50.0),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ),
                      // Location marker
                      if (_selectedLatitude != null && _selectedLongitude != null)
                        const Center(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      // Instructions overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Tap anywhere on the map to select location',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Current location button
              Positioned(
                bottom: 16,
                right: 16,
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

  Widget _buildLocationDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: VillageTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Selected Location',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedAddress.isNotEmpty) ...[
            _buildDetailRow('Address', _selectedAddress),
            _buildDetailRow('City', _selectedCity),
            _buildDetailRow('State', _selectedState),
            _buildDetailRow('Pincode', _selectedPincode),
            if (_selectedLatitude != null && _selectedLongitude != null)
              _buildDetailRow(
                'Coordinates',
                '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}'
              ),
          ] else ...[
            const Text(
              'Tap on the map to select a location',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use Current'),
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
                // TODO: Show saved locations
                Helpers.showSnackBar(context, 'Saved locations coming soon!');
              },
              icon: const Icon(Icons.bookmark, size: 18),
              label: const Text('Saved'),
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
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
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
        child: SizedBox(
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 20),
                SizedBox(width: 8),
                Text(
                  'Confirm & Save Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}