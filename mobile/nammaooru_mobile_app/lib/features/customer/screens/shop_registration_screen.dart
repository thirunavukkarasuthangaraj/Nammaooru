import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/services/image_service.dart';

/// Lets a customer register their own shop (grocery or food/restaurant),
/// mirroring the website's "Add New Shop" form. Reachable from the Grocery
/// and Food listing screens via a "Register Your Shop" button.
///
/// Everything happens in one continuous form: shop/owner/address details,
/// then the required documents, then a single "Submit Application" button
/// at the bottom that creates the shop and uploads the documents together.
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
  // Populated after a location fetch — any address piece GPS couldn't
  // detect, so the field stays editable as a fallback instead of hiding it.
  final Set<String> _missingAddressFields = {};
  bool _editAddressManually = false;

  // Only self-delivery shops for now — no toggle, always true.
  final bool _selfDeliveryEnabled = true;
  bool _isSubmitting = false;
  String? _submitProgress;

  final Map<String, File> _docFiles = {};

  static const List<Map<String, dynamic>> _requiredDocuments = [
    {'type': 'OWNER_PHOTO', 'name': 'Shop Owner Photo', 'hint': 'Clear photo of you, the owner', 'allowPdf': false},
    {'type': 'SHOP_PHOTO', 'name': 'Shop Photo', 'hint': 'Clear photo of your shop front', 'allowPdf': false},
    {'type': 'FSSAI_CERTIFICATE', 'name': 'FSSAI Certificate', 'hint': 'Food safety certificate — photo or PDF', 'allowPdf': true},
  ];

  bool get _isFood => (widget.category ?? '').toLowerCase() == 'food';
  String get _businessType => _isFood ? 'RESTAURANT' : 'GROCERY';
  String get _businessTypeLabel => _isFood ? 'Food / Restaurant' : 'Grocery';
  bool get _needsManualAddressEntry =>
      _latitude == null || _missingAddressFields.isNotEmpty || _editAddressManually;

  @override
  void initState() {
    super.initState();
    _prefillOwnerDetails();
  }

  // The caller must already be a verified customer to reach this screen
  // (see ShopListingScreen._openShopRegistration), so pre-fill their details
  // and lock the phone number to the one they verified via OTP.
  Future<void> _prefillOwnerDetails() async {
    try {
      final response = await ApiClient.get('/users/me');
      final data = response.data?['data'];
      if (data == null || !mounted) return;

      final firstName = data['firstName']?.toString() ?? '';
      final lastName = data['lastName']?.toString() ?? '';
      setState(() {
        _ownerNameController.text = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
        _ownerEmailController.text = data['email']?.toString() ?? '';
        _ownerPhoneController.text = data['mobileNumber']?.toString() ?? '';
      });
    } catch (e) {
      // Prefill is a convenience — if it fails, the owner can still type
      // their details in manually.
    }
  }

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

      final missing = <String>{};

      if (address != null) {
        final street = address['street'] ?? '';
        final locality = address['locality'] ?? '';
        final combined = [street, locality].where((s) => s.isNotEmpty).join(', ');
        if (combined.isNotEmpty) {
          _addressController.text = combined;
        } else {
          missing.add('Address Line 1');
        }

        if (locality.isNotEmpty) {
          _cityController.text = locality;
        } else {
          missing.add('City');
        }

        final state = address['administrativeArea'] ?? '';
        if (state.isNotEmpty) {
          _stateController.text = state;
        } else {
          missing.add('State');
        }

        final postal = address['postalCode'] ?? '';
        if (postal.isNotEmpty) {
          _postalCodeController.text = postal;
        } else {
          missing.add('Postal Code');
        }

        if (address['country']?.isNotEmpty == true) _countryController.text = address['country']!;
      } else {
        missing.addAll(['Address Line 1', 'City', 'State', 'Postal Code']);
      }

      if (mounted) {
        setState(() {
          _missingAddressFields
            ..clear()
            ..addAll(missing);
          _editAddressManually = false;
        });
        if (missing.isNotEmpty) {
          Helpers.showSnackBar(
            context,
            'Got your GPS location, but could not detect ${missing.join(', ')} automatically — please fill ${missing.length > 1 ? 'them' : 'it'} in below.',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickDocument(String type, String name, bool allowPdf) async {
    if (!allowPdf) {
      await ImageService.showImagePickerDialog(
        context,
        allowCropping: false,
        onImageSelected: (file) => setState(() => _docFiles[type] = file),
      );
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _darkGreen),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _darkGreen),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: _darkGreen),
              title: const Text('Choose PDF File'),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'camera') {
      final file = await ImageService.pickImageFromCamera();
      if (file != null && mounted) setState(() => _docFiles[type] = file);
    } else if (choice == 'gallery') {
      final file = await ImageService.pickImageFromGallery();
      if (file != null && mounted) setState(() => _docFiles[type] = file);
    } else if (choice == 'pdf') {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      final path = result?.files.single.path;
      if (path != null && mounted) setState(() => _docFiles[type] = File(path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      Helpers.showSnackBar(context, 'Please tap "Use my current location" so customers can find your shop.', isError: true);
      return;
    }

    final missingDocs = _requiredDocuments.where((d) => !_docFiles.containsKey(d['type'])).toList();
    if (missingDocs.isNotEmpty) {
      Helpers.showSnackBar(
        context,
        'Please attach: ${missingDocs.map((d) => d['name']).join(', ')}',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitProgress = 'Registering your shop...';
    });
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

      if (response['success'] != true && response['statusCode'] != '0000') {
        Helpers.showSnackBar(
          context,
          response['message']?.toString() ?? 'Could not register your shop. Please try again.',
          isError: true,
        );
        return;
      }

      final data = response['data'] as Map<String, dynamic>?;
      final rawId = data?['id'];
      final shopId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      if (shopId == null) {
        Helpers.showSnackBar(context, 'Shop registered, but documents could not be uploaded automatically. Please contact support.', isError: true);
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final failedDocs = <String>[];
      for (final doc in _requiredDocuments) {
        final type = doc['type'] as String;
        final name = doc['name'] as String;
        final file = _docFiles[type];
        if (file == null) continue;

        if (mounted) setState(() => _submitProgress = 'Uploading $name...');
        final uploadResponse = await _shopApi.uploadShopDocument(
          shopId: shopId,
          documentType: type,
          documentName: name,
          file: file,
        );
        if (uploadResponse['success'] != true) failedDocs.add(name);
      }

      if (!mounted) return;

      if (failedDocs.isEmpty) {
        await _showSuccessDialog();
      } else {
        Helpers.showSnackBar(
          context,
          'Shop registered, but failed to upload: ${failedDocs.join(', ')}. You can try uploading again from your shop dashboard once approved.',
          isError: true,
        );
        Navigator.of(context).pop();
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
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: _green, size: 28),
            SizedBox(width: 10),
            Text('Application Submitted'),
          ],
        ),
        content: const Text(
          "Thanks! Your shop and documents have been submitted for review. "
          "We'll email you once it's approved.",
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
                _textField(_ownerPhoneController, 'Owner Phone', required: true, keyboardType: TextInputType.phone, readOnly: true),
              ],
            ),
            _sectionCard(
              title: 'Shop Address',
              icon: Icons.location_on_outlined,
              children: [
                OutlinedButton.icon(
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_latitude != null ? Icons.check_circle : Icons.my_location, color: _latitude != null ? _green : _darkGreen),
                  label: Text(_latitude != null ? 'Location captured — tap to refresh' : 'Use my current location'),
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
                const SizedBox(height: 14),
                if (_needsManualAddressEntry) ...[
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
                  if (_latitude != null && _missingAddressFields.isEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _editAddressManually = false),
                        child: const Text('Done editing'),
                      ),
                    ),
                  ],
                ] else
                  _buildAddressSummary(),
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
                // Only self-delivery shops for now — platform delivery partners
                // aren't offered to self-registered shops yet.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    border: Border.all(color: _green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: _darkGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Self Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text(
                              "You'll deliver your own orders",
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _sectionCard(
              title: 'Upload Documents',
              icon: Icons.upload_file,
              children: [
                Text(
                  'Attach these before submitting — your application is reviewed together with your shop details.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                for (final doc in _requiredDocuments) ...[
                  _buildDocumentCard(doc['type'] as String, doc['name'] as String, doc['hint'] as String, doc['allowPdf'] as bool),
                  const SizedBox(height: 12),
                ],
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 12),
                          Text(_submitProgress ?? 'Submitting...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Detected address', style: TextStyle(fontWeight: FontWeight.bold, color: _darkGreen)),
              ),
              TextButton(
                onPressed: () => setState(() => _editAddressManually = true),
                child: const Text('Edit'),
              ),
            ],
          ),
          Text(_addressController.text, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            '${_cityController.text}, ${_stateController.text} - ${_postalCodeController.text}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(_countryController.text, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String type, String name, String hint, bool allowPdf) {
    final file = _docFiles[type];
    final isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return Material(
      color: file != null ? _green.withOpacity(0.06) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickDocument(type, name, allowPdf),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: file != null ? _green : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: file != null
                    ? (isPdf
                        ? Container(
                            width: 48,
                            height: 48,
                            color: Colors.red.shade50,
                            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          )
                        : Image.file(file, width: 48, height: 48, fit: BoxFit.cover))
                    : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.description_outlined, color: Colors.grey.shade500),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      file != null ? 'Attached — tap to change' : hint,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                color: file != null ? _green : Colors.grey.shade500,
              ),
            ],
          ),
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
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        helperText: readOnly ? 'Verified via OTP — cannot be changed here' : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : const Color(0xFFF8F9FA),
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
