import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/models/address_model.dart';
import '../../../core/services/address_service.dart';
import '../../../core/services/location_service.dart';
import '../../../services/address_api_service.dart';
import '../../../services/shop_api_service.dart';
import '../../../core/utils/helpers.dart';
import '../screens/address_management_screen.dart';
import '../screens/google_maps_location_picker_screen.dart';

class AddressSelectionDialog extends StatefulWidget {
  final String? currentLocation;
  final Function(String) onLocationSelected;

  const AddressSelectionDialog({
    super.key,
    this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<AddressSelectionDialog> createState() => _AddressSelectionDialogState();
}

class _AddressSelectionDialogState extends State<AddressSelectionDialog> {
  List<SavedAddress> _savedAddresses = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isResolvingSelection = false;
  // One token per search "session" (first keystroke to final pick) so Google
  // bills the autocomplete keystrokes + the details lookup as a single
  // session instead of per-request - a fresh token starts after each pick.
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final addresses = await AddressService.instance.getSavedAddresses();
      setState(() {
        _savedAddresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    _sessionToken ??= const Uuid().v4();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _performSearch(query.trim()),
    );
  }

  // Places Autocomplete is what actually powers Zomato/Swiggy-style
  // suggest-as-you-type (ranked partial matches: streets, localities, POIs) -
  // plain Geocoding only resolves one specific address, which is why the old
  // search returned a single result for a partial name. Merged with the shop
  // network's own known villages (e.g. "Mittur", which Google frequently has
  // no listing for at all), run in parallel so one slow/failing source never
  // blanks the other's results.
  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final sessionToken = _sessionToken;
    final lookups = await Future.wait<List<Map<String, dynamic>>>([
      ShopApiService()
          .searchShopLocations(query)
          .timeout(const Duration(seconds: 3), onTimeout: () => <Map<String, dynamic>>[])
          .catchError((_) => <Map<String, dynamic>>[]),
      LocationService.instance
          .autocompletePlaces(query, sessionToken: sessionToken)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);
    final shopLocations = lookups[0]
        .map((l) => {...l, 'isKnownVillage': true})
        .toList();
    final predictions = lookups[1];

    final seen = shopLocations
        .map((l) => (l['name'] as String).toLowerCase())
        .toSet();
    final results = [
      ...shopLocations,
      ...predictions.where((p) => !seen
          .contains((p['name'] as String).toLowerCase().split(',').first.trim())),
    ];
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    var latitude = result['latitude'] as double?;
    var longitude = result['longitude'] as double?;
    var name = result['name'] as String;

    final placeId = result['placeId'] as String?;
    if (placeId != null) {
      setState(() => _isResolvingSelection = true);
      final details = await LocationService.instance
          .getPlaceDetails(placeId, sessionToken: _sessionToken);
      _sessionToken = null; // session ends once details are resolved
      if (!mounted) return;
      if (details == null) {
        setState(() => _isResolvingSelection = false);
        Helpers.showSnackBar(context, 'Could not load that place. Try another result.',
            isError: true);
        return;
      }
      latitude = details['latitude'] as double;
      longitude = details['longitude'] as double;
      name = details['name'] as String? ?? name;
    }

    if (latitude != null && longitude != null) {
      LocationService.setManualPosition(latitude, longitude);
      LocationService.manualLocationLabel = name;
    }
    widget.onLocationSelected(name);
    Navigator.of(context).pop();
  }

  Future<void> _useCurrentLocation() async {
    LocationService.clearManualPosition();
    final position = await LocationService.instance.getCurrentPosition();
    if (position?.latitude == null || position?.longitude == null) return;
    final address = await LocationService.instance.getAddressFromCoordinates(
      position!.latitude!,
      position.longitude!,
    );
    final label = address != null
        ? '${address['locality'] ?? ''}${address['administrativeArea'] != null ? ', ${address['administrativeArea']}' : ''}'
        : 'Current location';
    widget.onLocationSelected(label.isNotEmpty ? label : 'Current location');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showAddAddressOptionsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_location_alt,
                          color: VillageTheme.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.black54),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose how you want to add your delivery address:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Option 1: Enter Manually (Only option for now)
                InkWell(
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    Navigator.of(dialogContext).pop(); // close the options dialog
                    Navigator.of(context).pop(); // close "Select Delivery Address" too
                    await navigator.push(
                      MaterialPageRoute(
                        builder: (context) => const AddressManagementScreen(
                            autoOpenManualForm: true),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: VillageTheme.primaryGreen, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note,
                              color: VillageTheme.primaryGreen, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Manually',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type your address details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: VillageTheme.primaryGreen, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    final onLocationSelected = widget.onLocationSelected;
                    Navigator.of(dialogContext).pop(); // close the options dialog
                    Navigator.of(context).pop(); // close "Select Delivery Address" too

                    final selectedLocation = await navigator.push<String>(
                      MaterialPageRoute(
                        builder: (_) => GoogleMapsLocationPickerScreen(
                          currentLocation: widget.currentLocation,
                        ),
                      ),
                    );

                    if (selectedLocation != null) {
                      onLocationSelected(selectedLocation);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: VillageTheme.primaryGreen, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: VillageTheme.primaryGreen.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VillageTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.map,
                              color: VillageTheme.primaryGreen, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select from Map',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pinpoint and save your exact location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: VillageTheme.primaryGreen, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: VillageTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Delivery Address',
                    style: VillageTheme.headingMedium.copyWith(
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchField(),
            const SizedBox(height: 12),

            if (_searchController.text.trim().length >= 3)
              _buildSearchResultsSection()
            else if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_savedAddresses.isEmpty)
              _buildNoAddressesView()
            else
              _buildAddressList(),

            const SizedBox(height: 16),

            // Add New Address Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _showAddAddressOptionsDialog(context);
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VillageTheme.primaryGreen,
                  side: BorderSide(color: VillageTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {}); // refresh so switching to/from the results view
          _onSearchChanged(value);
        },
        style: const TextStyle(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: 'Search for a new address or village...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _sessionToken = null;
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    return Expanded(
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isResolvingSelection,
            child: Opacity(
              opacity: _isResolvingSelection ? 0.5 : 1,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location,
                          color: VillageTheme.primaryGreen, size: 20),
                    ),
                    title: const Text(
                      'Use my current location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    onTap: _useCurrentLocation,
                  ),
                  if (_searchResults.isNotEmpty)
                    ..._searchResults.map((place) {
                      final isKnownVillage = place['isKnownVillage'] == true;
                      return ListTile(
                        leading: Icon(
                          isKnownVillage
                              ? Icons.holiday_village
                              : Icons.location_on_outlined,
                          color:
                              isKnownVillage ? Colors.orange.shade700 : Colors.orange,
                        ),
                        title: Text(
                          place['name'] as String,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: isKnownVillage
                            ? const Text(
                                'Known village',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        onTap: () => _selectSearchResult(place),
                      );
                    })
                  else if (_hasSearched && !_isSearching)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Place not found. Try a different name, or use "Add New Address" below for an exact pin.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isResolvingSelection)
            const Center(
              child: CircularProgressIndicator(
                color: VillageTheme.primaryGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoAddressesView() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Addresses',
            style: VillageTheme.headingSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address to get started',
            style: VillageTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _savedAddresses.length,
        itemBuilder: (context, index) {
          final address = _savedAddresses[index];
          return _buildAddressCard(address);
        },
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Use the address's coordinates for shop searches when available;
            // otherwise forward-geocode the city/state so the shop search
            // doesn't silently keep using the previous (stale) position.
            if (address.latitude != null && address.longitude != null) {
              LocationService.setManualPosition(
                  address.latitude!, address.longitude!);
            } else {
              final results = await LocationService.instance
                  .searchPlaces('${address.city}, ${address.state}');
              if (results.isNotEmpty) {
                LocationService.setManualPosition(
                  results.first['latitude'] as double,
                  results.first['longitude'] as double,
                );
              }
            }
            final locationString = '${address.addressLine1}, ${address.city}';
            widget.onLocationSelected(locationString);
            if (context.mounted) Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDefault
                  ? VillageTheme.primaryGreen.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDefault ? VillageTheme.primaryGreen : Colors.grey[300]!,
                width: isDefault ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                      _getAddressTypeIcon(address.addressType),
                      size: 18,
                      color: isDefault
                          ? VillageTheme.primaryGreen
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address.addressType,
                      style: VillageTheme.labelText.copyWith(
                        color: isDefault
                            ? VillageTheme.primaryGreen
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VillageTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: () => _confirmDeleteAddress(address),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.addressLine1.isNotEmpty
                      ? address.addressLine1
                      : 'Address Line 1',
                  style: VillageTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDefault ? VillageTheme.primaryGreen : Colors.black,
                  ),
                ),
                if (address.addressLine2.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address.addressLine2,
                    style: VillageTheme.bodyMedium.copyWith(
                      color: isDefault
                          ? VillageTheme.primaryGreen.withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${address.city}, ${address.state}',
                  style: VillageTheme.bodyMedium.copyWith(
                    color: isDefault
                        ? VillageTheme.primaryGreen.withOpacity(0.8)
                        : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.landmark.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Near ${address.landmark}',
                    style: VillageTheme.bodySmall.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (address.pincode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop,
                        size: 14,
                        color: isDefault
                            ? VillageTheme.primaryGreen
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pincode: ${address.pincode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDefault
                              ? VillageTheme.primaryGreen
                              : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAddress(SavedAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final addressId = int.tryParse(address.id);
    if (addressId == null) return;

    final result = await AddressApiService.deleteAddress(addressId);
    if (!mounted) return;
    if (result['success'] == true) {
      Helpers.showSnackBar(context, result['message'] ?? 'Address deleted');
      await _loadSavedAddresses();
    } else {
      Helpers.showSnackBar(
        context,
        result['message'] ?? 'Failed to delete address',
        isError: true,
      );
    }
  }

  IconData _getAddressTypeIcon(String addressType) {
    switch (addressType.toUpperCase()) {
      case 'HOME':
        return Icons.home;
      case 'WORK':
        return Icons.work;
      case 'OTHER':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }
}
