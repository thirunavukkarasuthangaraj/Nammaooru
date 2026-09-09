import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/address_api_service.dart';

class SaveAddressDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String detectedAddress;
  final String detectedStreet;
  final String detectedCity;
  final String detectedVillage;
  final String detectedState;
  final String detectedPincode;

  const SaveAddressDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.detectedAddress,
    this.detectedStreet = '',
    required this.detectedCity,
    required this.detectedVillage,
    required this.detectedState,
    required this.detectedPincode,
  });

  @override
  State<SaveAddressDialog> createState() => _SaveAddressDialogState();
}

class _SaveAddressDialogState extends State<SaveAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _flatHouseController = TextEditingController();
  final _floorController = TextEditingController();
  final _streetController = TextEditingController(); // Street input field
  final _villageController =
      TextEditingController(); // Area / Locality / Village (single field)
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _orderingFor = 'Myself';
  String _selectedAddressType = 'Home';
  bool _isSaving = false;

  final List<String> _orderingOptions = ['Myself', 'Someone else'];
  final List<Map<String, dynamic>> _addressTypes = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'Work', 'icon': Icons.work},
    {'label': 'Hotel', 'icon': Icons.hotel},
    {'label': 'Other', 'icon': Icons.location_on},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Pre-fill fields with detected data. detectedAddress and detectedVillage
    // are the same cleaned locality name from the map picker, so only one
    // field is kept instead of showing the identical value twice.
    _streetController.text = widget.detectedStreet;
    _villageController.text = widget.detectedVillage.isNotEmpty
        ? widget.detectedVillage
        : widget.detectedAddress;
    _cityController.text = widget.detectedCity;
    _stateController.text = widget.detectedState;
    // Deliberately NOT falling back to a previously-used pincode here: a
    // customer's last address could be in a different town/district, and
    // silently reusing that pincode for an unrelated location (e.g. showing
    // a Tirupattur pincode for a Chennai pin) is worse than leaving it blank
    // and letting the required-field validation prompt for the real one.
    _pincodeController.text = widget.detectedPincode;
  }

  @override
  void dispose() {
    _flatHouseController.dispose();
    _floorController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onAddressTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedAddressType = value;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Build full address from components
      List<String> addressParts = [];

      if (_flatHouseController.text.trim().isNotEmpty) {
        addressParts.add(_flatHouseController.text.trim());
      }

      if (_floorController.text.trim().isNotEmpty) {
        addressParts.add('Floor ${_floorController.text.trim()}');
      }

      if (_streetController.text.trim().isNotEmpty) {
        addressParts.add(_streetController.text.trim());
      }

      if (_villageController.text.trim().isNotEmpty) {
        addressParts.add(_villageController.text.trim());
      }

      String fullAddress = addressParts.join(', ');

      final result = await AddressApiService.addAddress(
        label: _selectedAddressType,
        fullAddress: fullAddress,
        details: _landmarkController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
        isDefault: false, // Let user set default from manage addresses
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        flatHouse: _flatHouseController.text.trim(),
        floor: _floorController.text.trim(),
        street: _streetController.text.trim(),
        village: _villageController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          Helpers.showSnackBar(
              context, result['message'] ?? 'Address saved successfully!');
          Navigator.pop(context, {
            'success': true,
            'address': fullAddress,
            'fullAddress':
                '$fullAddress, ${widget.detectedCity.isEmpty ? 'Chennai' : widget.detectedCity}, ${widget.detectedState.isEmpty ? 'Tamil Nadu' : widget.detectedState} - ${widget.detectedPincode.isEmpty ? '600001' : widget.detectedPincode}',
            'nickname': _selectedAddressType,
          });
        } else {
          Helpers.showSnackBar(
              context, result['message'] ?? 'Failed to save address',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error saving address: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 350,
          maxHeight: 600,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildDetectedLocationPreview(),
                  const SizedBox(height: 20),
                  _buildOrderingForSection(),
                  const SizedBox(height: 20),
                  _buildFlatHouseField(),
                  const SizedBox(height: 16),
                  _buildFloorField(),
                  const SizedBox(height: 16),
                  _buildLandmarkField(),
                  const SizedBox(height: 16),
                  _buildAddressDetailsExpander(),
                  const SizedBox(height: 20),
                  _buildAddressTypeSection(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Enter complete address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300, width: 1),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 22),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            tooltip: 'Close',
          ),
        ),
      ],
    );
  }

  Widget _buildOrderingForSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who you are ordering for?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _orderingOptions.map((option) {
            return Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: option,
                    groupValue: _orderingFor,
                    onChanged: (value) {
                      setState(() {
                        _orderingFor = value!;
                      });
                    },
                    activeColor: VillageTheme.primaryGreen,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Flexible(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddressTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Save address as ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _addressTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _selectedAddressType == type['label'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAddressType = type['label'];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                      right: index < _addressTypes.length - 1 ? 4 : 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? VillageTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? VillageTheme.primaryGreen
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'],
                        size: 14,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          type['label'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFlatHouseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Flat / House no. / Building name ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _flatHouseController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter flat/house number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFloorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Floor (optional)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _floorController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // Read-only echo of the pin-dropped location — lets the user confirm at a
  // glance (Zomato/Swiggy pattern) instead of re-reading scattered form
  // fields. To fix a wrong address they go back and move the pin, not edit
  // text here.
  Widget _buildDetectedLocationPreview() {
    final parts = <String>[
      if (widget.detectedStreet.isNotEmpty) widget.detectedStreet,
      if (widget.detectedVillage.isNotEmpty) widget.detectedVillage,
      if (widget.detectedCity.isNotEmpty &&
          widget.detectedCity != widget.detectedVillage)
        widget.detectedCity,
    ];
    final headline = widget.detectedVillage.isNotEmpty
        ? widget.detectedVillage
        : (widget.detectedAddress.isNotEmpty
            ? widget.detectedAddress
            : 'Selected location');
    final subline = parts.join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VillageTheme.primaryGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: VillageTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subline,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Street / area / city / state / PIN, collapsed by default so the primary
  // flow (house no. + landmark + save-as) reads clean like Zomato/Swiggy —
  // still reachable for the rural addresses where geocoding gets it wrong.
  Widget _buildAddressDetailsExpander() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Auto-open when geocoding didn't resolve a locality or pincode —
        // those fields are required, so they can't stay hidden in that case.
        initiallyExpanded: _villageController.text.trim().isEmpty ||
            _pincodeController.text.trim().isEmpty,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 12),
        title: Row(
          children: [
            Icon(Icons.edit_location_alt_outlined,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Edit street, area, city & PIN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        children: [
          _buildStreetField(),
          const SizedBox(height: 16),
          _buildVillageField(),
          const SizedBox(height: 16),
          _buildCityStateRow(),
          const SizedBox(height: 16),
          _buildPincodeField(),
        ],
      ),
    );
  }

  Widget _buildLandmarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby landmark (optional)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _landmarkController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: VillageTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildCityStateRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildCityField(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStateField(),
        ),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City *',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cityController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter city',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State *',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _stateController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'State',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'State is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPincodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pincode *',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pincodeController,
          style: const TextStyle(color: Colors.black),
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit pincode',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pincode is required';
            }
            if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Enter valid 6-digit pincode';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStreetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Street Name',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _streetController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter street name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildVillageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Area / Locality / Village ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _villageController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter area / locality / village name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: VillageTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Area / locality is required';
            }
            return null;
          },
        ),
      ],
    );
  }

}
