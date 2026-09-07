import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/shop_api_service.dart';

/// Lets a customer register their own shop (grocery or food/restaurant),
/// mirroring the website's "Add New Shop" form. Reachable from the Grocery
/// and Food listing screens via a "Register Your Shop" button.
class ShopRegistrationScreen extends StatefulWidget {
  final String? category;
  final String? categoryTitle;

  const ShopRegistrationScreen({
    super.key,
    this.category,
    this.categoryTitle,
  });

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  static const Color _green = Color(0xFF4CAF50);
  static const Color _darkGreen = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();
  final ShopApiService _shopApi = ShopApiService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _deliveryRadiusController = TextEditingController(text: '5');
  final _freeDeliveryAboveController = TextEditingController(text: '500');
  final _minOrderAmountController = TextEditingController(text: '0');

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _selfDeliveryEnabled = false;
  bool _isSubmitting = false;

  bool get _isFood => (widget.category ?? '').toLowerCase() == 'food';
  String get _businessType => _isFood ? 'RESTAURANT' : 'GROCERY';
  String get _businessTypeLabel => _isFood ? 'Food / Restaurant' : 'Grocery';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _deliveryRadiusController.dispose();
    _freeDeliveryAboveController.dispose();
    _minOrderAmountController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position == null || position.latitude == null || position.longitude == null) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Could not get your location. Please enable location and try again.', isError: true);
        }
        return;
      }

      _latitude = position.latitude;
      _longitude = position.longitude;

      final address = await LocationService.instance.getAddressFromCoordinates(
        position.latitude!,
        position.longitude!,
      );

      final missing = <String>[];

      if (address != null) {
        if (_addressController.text.isEmpty) {
          final street = address['street'] ?? '';
          final locality = address['locality'] ?? '';
          final combined = [street, locality].where((s) => s.isNotEmpty).join(', ');
          if (combined.isNotEmpty) {
            _addressController.text = combined;
          } else {
            missing.add('Address Line 1');
          }
        }
        if (_cityController.text.isEmpty) {
          final locality = address['locality'] ?? '';
          if (locality.isNotEmpty) {
            _cityController.text = locality;
          } else {
            missing.add('City');
          }
        }
        if (_stateController.text.isEmpty) {
          final state = address['administrativeArea'] ?? '';
          if (state.isNotEmpty) {
            _stateController.text = state;
          } else {
            missing.add('State');
          }
        }
        if (_postalCodeController.text.isEmpty) {
          final postal = address['postalCode'] ?? '';
          if (postal.isNotEmpty) {
            _postalCodeController.text = postal;
          } else {
            missing.add('Postal Code');
          }
        }
        if (address['country']?.isNotEmpty == true) _countryController.text = address['country']!;
      } else {
        missing.addAll(['Address Line 1', 'City', 'State', 'Postal Code']);
      }

      if (mounted) {
        setState(() {});
        if (missing.isNotEmpty) {
          Helpers.showSnackBar(
            context,
            'Got your GPS location, but could not detect ${missing.join(', ')} automatically — please fill ${missing.length > 1 ? 'them' : 'it'} in manually.',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      Helpers.showSnackBar(context, 'Please tap "Use my current location" so customers can find your shop.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _shopApi.createShop(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        businessType: _businessType,
        ownerName: _ownerNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        addressLine1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty ? 'India' : _countryController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        minOrderAmount: double.tryParse(_minOrderAmountController.text.trim()),
        deliveryRadius: double.tryParse(_deliveryRadiusController.text.trim()),
        freeDeliveryAbove: double.tryParse(_freeDeliveryAboveController.text.trim()),
        selfDeliveryEnabled: _selfDeliveryEnabled,
      );

      if (!mounted) return;

      if (response['success'] == true || response['statusCode'] == '0000') {
        await _showSuccessDialog();
      } else {
        Helpers.showSnackBar(
          context,
          response['message']?.toString() ?? 'Could not register your shop. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Could not register your shop: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: _green, size: 28),
            SizedBox(width: 10),
            Text('Shop Registered'),
          ],
        ),
        content: Text(
          'Thanks! Your shop has been submitted for review. '
          'A confirmation email has been sent to ${_ownerEmailController.text.trim()}. '
          "We'll notify you once it's approved and live.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // close the dialog
              Navigator.of(context).pop(); // back to the shop listing screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Register Your Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: _green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: 'Shop Details',
              icon: Icons.storefront,
              children: [
                _textField(_nameController, 'Shop Name', required: true),
                const SizedBox(height: 12),
                _readOnlyChipField('Business Type', _businessTypeLabel, _isFood ? Icons.restaurant : Icons.local_grocery_store),
                const SizedBox(height: 12),
                _textField(_descriptionController, 'Description (optional)', maxLines: 3, required: false),
              ],
            ),
            _sectionCard(
              title: 'Owner Details',
              icon: Icons.person_outline,
              children: [
                _textField(_ownerNameController, 'Owner Name', required: true),
                const SizedBox(height: 12),
                _textField(_ownerEmailController, 'Owner Email', required: true, keyboardType: TextInputType.emailAddress, isEmail: true),
                const SizedBox(height: 12),
                _textField(_ownerPhoneController, 'Owner Phone', required: true, keyboardType: TextInputType.phone),
              ],
            ),
            _sectionCard(
              title: 'Shop Address',
              icon: Icons.location_on_outlined,
              children: [
                _textField(_addressController, 'Address Line 1', required: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _textField(_cityController, 'City', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _textField(_stateController, 'State', required: true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _textField(_postalCodeController, 'Postal Code', required: true, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _textField(_countryController, 'Country', required: true)),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_latitude != null ? Icons.check_circle : Icons.my_location, color: _latitude != null ? _green : _darkGreen),
                  label: Text(_latitude != null ? 'Location captured' : 'Use my current location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: BorderSide(color: _latitude != null ? _green : Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Required so customers can find your shop and get accurate delivery estimates.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            _sectionCard(
              title: 'Delivery Settings',
              icon: Icons.local_shipping_outlined,
              children: [
                Row(
                  children: [
                    Expanded(child: _textField(_deliveryRadiusController, 'Delivery Radius (km)', required: false, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _textField(_minOrderAmountController, 'Min Order (₹)', required: false, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _textField(_freeDeliveryAboveController, 'Free Delivery Above (₹)', required: false, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Material(
                  color: _selfDeliveryEnabled ? _green.withOpacity(0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _selfDeliveryEnabled ? _green : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: _green,
                      activeTrackColor: _green.withOpacity(0.4),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                      title: const Text('Self Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _selfDeliveryEnabled
                            ? "On — I'll deliver orders myself instead of using platform delivery partners"
                            : "Off — platform delivery partners will deliver my orders",
                      ),
                      value: _selfDeliveryEnabled,
                      onChanged: (v) => setState(() => _selfDeliveryEnabled = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Register Shop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _darkGreen, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _readOnlyChipField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _darkGreen),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on the menu you opened from',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    required bool required,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return '$label is required';
        if (isEmail && v.isNotEmpty && !Helpers.isValidEmail(v)) return 'Enter a valid email';
        return null;
      },
    );
  }
}
