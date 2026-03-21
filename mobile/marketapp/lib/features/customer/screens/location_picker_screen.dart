import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import '../../../core/services/location_service.dart';
import '../../../core/theme/village_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers.dart';
import 'map_location_picker_screen.dart';
import 'google_maps_location_picker_screen.dart';
import '../../../core/services/address_service.dart';
import '../widgets/address_selection_dialog.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationPickerScreen({
    super.key,
    this.currentLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = '';
  bool _isLoadingLocation = false;
  loc.LocationData? _currentPosition;
  Map<String, String>? _currentAddress;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation ?? 'Chennai, Tamil Nadu';
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        });

        final address = await LocationService.instance.getAddressFromCoordinates(
          position.latitude!,
          position.longitude!,
        );

        if (address != null && mounted) {
          setState(() {
            _currentAddress = address;
            _selectedLocation = '${address['locality']}, ${address['administrativeArea']}';
          });
        }
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

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, _selectedLocation);
  }

  Future<void> _openMapSelector() async {
    try {
      // First check if user has saved addresses
      final savedAddresses = await AddressService.instance.getSavedAddresses();

      if (savedAddresses.isNotEmpty) {
        // Show address selection dialog if addresses exist
        await showDialog(
          context: context,
          builder: (context) => AddressSelectionDialog(
            currentLocation: _selectedLocation,
            onLocationSelected: (selectedLocation) {
              setState(() {
                _selectedLocation = selectedLocation;
              });
            },
          ),
        );
      } else {
        // If no saved addresses, open map picker to add first address
        final selectedLocation = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleMapsLocationPickerScreen(
              currentLocation: _selectedLocation,
            ),
          ),
        );

        if (selectedLocation != null) {
          setState(() {
            _selectedLocation = selectedLocation;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error opening location selector: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Select Delivery Location',
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCurrentLocationCard(),
          _buildMapPlaceholder(),
          _buildLocationsList(),
        ],
      ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  Widget _buildSearchBar() {
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
        controller: _searchController,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          hintText: 'Search for area, street name...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          // TODO: Implement search functionality
        },
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VillageTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.my_location,
            color: VillageTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          _isLoadingLocation ? 'Getting current location...' : 'Use Current Location',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: _currentAddress != null
          ? Text(
              '${_currentAddress!['street']}, ${_currentAddress!['locality']}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            )
          : const Text(
              'Tap to detect current location',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
        trailing: _isLoadingLocation
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.arrow_forward_ios,
              color: VillageTheme.primaryGreen,
              size: 16,
            ),
        onTap: _isLoadingLocation ? null : () {
          if (_currentAddress != null) {
            _selectLocation('${_currentAddress!['locality']}, ${_currentAddress!['administrativeArea']}');
          } else {
            _getCurrentLocation();
          }
        },
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
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
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openMapSelector,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: const Center(),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Interactive Map View',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Drag to select delivery location',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Icon(
              Icons.location_on,
              color: VillageTheme.primaryGreen,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    final locations = [
      'Chennai, Tamil Nadu',
      'Tirupattur, Tamil Nadu',
      'Bangalore, Karnataka',
      'Coimbatore, Tamil Nadu',
      'Salem, Tamil Nadu',
      'Madurai, Tamil Nadu',
    ];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Popular Locations',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: locations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = _selectedLocation == location;

                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected ? VillageTheme.primaryGreen : Colors.grey,
                    ),
                    title: Text(
                      location,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: VillageTheme.primaryGreen,
                        )
                      : null,
                    onTap: () => _selectLocation(location),
                  );
                },
              ),
            ),
          ],
        ),
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
            onPressed: _selectedLocation.isNotEmpty ? _confirmLocation : null,
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
                const Icon(Icons.check, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Confirm Location: $_selectedLocation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}