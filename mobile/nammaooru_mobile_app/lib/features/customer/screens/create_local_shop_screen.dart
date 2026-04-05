import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/localization/language_provider.dart';
import '../services/local_shops_service.dart';
import '../widgets/post_payment_handler.dart';
import '../widgets/voice_input_button.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';
import '../../../services/post_config_service.dart';

class CreateLocalShopScreen extends StatefulWidget {
  const CreateLocalShopScreen({super.key});

  @override
  State<CreateLocalShopScreen> createState() => _CreateLocalShopScreenState();
}

class _CreateLocalShopScreenState extends State<CreateLocalShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _timingsController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final LocalShopsService _localShopsService = LocalShopsService();

  String _selectedCategory = 'GROCERY';
  final List<File> _selectedImages = [];
  int _maxImages = 3;
  bool _isSubmitting = false;
  bool _wantsBanner = false;
  int? _paidTokenId;
  double? _latitude;
  double? _longitude;

  static const Color _shopColor = Color(0xFFFF6F00);

  static const Map<String, String> _categories = {
    'GROCERY': 'Grocery',
    'MEDICAL': 'Medical / Pharmacy',
    'HARDWARE': 'Hardware',
    'ELECTRONICS': 'Electronics',
    'CLOTHING': 'Clothing / Textiles',
    'STATIONERY': 'Stationery',
    'RESTAURANT': 'Hotel / Restaurant',
    'BAKERY': 'Bakery',
    'VEGETABLES': 'Vegetables / Fruits',
    'MEAT_FISH': 'Meat / Fish',
    'SALON': 'Salon / Parlour',
    'GYM': 'Gym / Yoga',
    'LAUNDRY': 'Laundry',
    'TAILORING': 'Tailoring',
    'PRINTING': 'Printing / Xerox',
    'MOBILE_SHOP': 'Mobile Shop',
    'COMPUTER_SHOP': 'Computer Shop',
    'AUTO_PARTS': 'Auto Spare Parts',
    'PETROL_BUNK': 'Petrol Bunk',
    'JEWELLERY': 'Jewellery',
    'COURIER': 'Courier Service',
    'OTHER': 'Other',
  };

  static const Map<String, String> _categoryTamil = {
    'GROCERY': 'மளிகை கடை',
    'MEDICAL': 'மருந்தகம்',
    'HARDWARE': 'ஹார்டுவேர்',
    'ELECTRONICS': 'எலக்ட்ரானிக்ஸ்',
    'CLOTHING': 'துணிக்கடை',
    'STATIONERY': 'ஸ்டேஷனரி',
    'RESTAURANT': 'ஹோட்டல்',
    'BAKERY': 'பேக்கரி',
    'VEGETABLES': 'காய்கறி / பழம்',
    'MEAT_FISH': 'இறைச்சி / மீன்',
    'SALON': 'சலூன்',
    'GYM': 'ஜிம்',
    'LAUNDRY': 'லாண்டரி',
    'TAILORING': 'தையல்',
    'PRINTING': 'பிரிண்டிங்',
    'MOBILE_SHOP': 'மொபைல் கடை',
    'COMPUTER_SHOP': 'கம்ப்யூட்டர் கடை',
    'AUTO_PARTS': 'ஆட்டோ பாகங்கள்',
    'PETROL_BUNK': 'பெட்ரோல் பங்க்',
    'JEWELLERY': 'நகைக்கடை',
    'COURIER': 'கூரியர்',
    'OTHER': 'மற்றவை',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
    _loadImageLimit();
  }

  Future<void> _loadImageLimit() async {
    await PostConfigService.instance.fetch();
    if (mounted) {
      setState(() {
        _maxImages = PostConfigService.instance.imageLimit;
      });
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _timingsController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefillData() {
    final phone = LocalStorage.getString('phoneNumber');
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    } else {
      _fetchPhoneFromProfile();
    }
    _getLocation();
  }

  Future<void> _fetchPhoneFromProfile() async {
    try {
      final response = await ApiClient.get('/users/me');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['statusCode'] == '0000') {
          final userData = data['data'];
          final phone = userData['mobileNumber'] ?? userData['phoneNumber'] ?? '';
          if (phone.toString().isNotEmpty && mounted) {
            setState(() {
              _phoneController.text = phone.toString();
            });
            await LocalStorage.setString('phoneNumber', phone.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching phone from profile: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        final address = await LocationService.instance.getAddressFromCoordinates(
          position.latitude!,
          position.longitude!,
        );
        if (address != null && mounted) {
          final name = address['name'] ?? address['subLocality'] ?? '';
          final city = address['locality'] ?? '';
          setState(() {
            if (name.isNotEmpty && city.isNotEmpty && name != city) {
              _addressController.text = '$name, $city';
            } else if (name.isNotEmpty) {
              _addressController.text = name;
            } else if (city.isNotEmpty) {
              _addressController.text = city;
            }
          });
        }
      }
    } catch (e) {
      // Location is optional
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFile != null && mounted) {
        final compressed = await ImageCompressor.compressXFile(pickedFile);
        setState(() {
          _selectedImages.add(File(compressed.path));
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty && mounted) {
        final remaining = _maxImages - _selectedImages.length;
        final toAdd = pickedFiles.take(remaining).toList();
        for (final xFile in toAdd) {
          final compressed = await ImageCompressor.compressXFile(xFile);
          if (mounted) {
            setState(() {
              _selectedImages.add(File(compressed.path));
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  void _showMaxImagesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maximum $_maxImages images allowed'), backgroundColor: Colors.orange),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit({int? paidTokenId, bool isBanner = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _localShopsService.createPost(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        timings: _timingsController.text.trim().isNotEmpty ? _timingsController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        latitude: _latitude,
        longitude: _longitude,
        paidTokenId: paidTokenId,
        isBanner: isBanner,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop listing submitted for review!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final statusCode = result['statusCode']?.toString() ?? '';
        if (statusCode == 'LIMIT_REACHED' || result['httpStatus'] == 402) {
          _showPaymentHandler();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit listing'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentHandler() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PostPaymentHandler(
        featureName: 'LOCAL_SHOPS',
        onPaymentSuccess: (tokenId, isBanner) {
          Navigator.pop(context);
          _submit(paidTokenId: tokenId, isBanner: isBanner);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText('Post Your Shop', 'கடை விளம்பரம்')),
        backgroundColor: _shopColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Shop Name
            TextFormField(
              controller: _shopNameController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: lang.getText('Shop Name *', 'கடை பெயர் *'),
                prefixIcon: const Icon(Icons.store, color: _shopColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _shopColor),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Shop name is required';
                if (v.trim().length < 2) return 'Enter a valid shop name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: lang.getText('Phone Number *', 'தொலைபேசி எண் *'),
                prefixIcon: const Icon(Icons.phone, color: _shopColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _shopColor),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.trim().length != 10) return 'Enter a valid 10-digit phone number';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Enter a valid mobile number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: lang.getText('Category *', 'வகை *'),
                prefixIcon: const Icon(Icons.category, color: _shopColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _shopColor),
                ),
              ),
              items: _categories.entries.map((e) {
                final tamil = _categoryTamil[e.key] ?? e.value;
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(lang.getText(e.value, tamil)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),

            // Address / Location
            LocationAutocompleteField(
              controller: _addressController,
              label: lang.getText('Address / Location *', 'முகவரி *'),
              onLocationSelected: (lat, lng, address) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  _addressController.text = address;
                });
              },
              onGpsPressed: _getLocation,
              themeColor: _shopColor,
            ),
            const SizedBox(height: 16),

            // Timings
            TextFormField(
              controller: _timingsController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: lang.getText('Timings (optional)', 'நேரம் (விருப்பத்தேர்வு)'),
                hintText: lang.getText('e.g. 9 AM - 9 PM, Mon-Sat', 'எ.கா. காலை 9 - இரவு 9'),
                prefixIcon: const Icon(Icons.access_time, color: _shopColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _shopColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLength: 1000,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: lang.getText('Description (optional)', 'விவரம் (விருப்பத்தேர்வு)'),
                      hintText: lang.getText('What does your shop sell? Any specialties?', 'கடையின் சிறப்பு என்ன?'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _shopColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                VoiceInputButton(
                  onTextReceived: (text) {
                    setState(() {
                      _descriptionController.text += (_descriptionController.text.isEmpty ? '' : ' ') + text;
                    });
                  },
                  color: _shopColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Images
            Text(
              lang.getText('Photos (optional, max $_maxImages)', 'புகைப்படங்கள் (விருப்பம், அதிகபட்சம் $_maxImages)'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedImages.asMap().entries.map((entry) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
                if (_selectedImages.length < _maxImages)
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: _shopColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: _shopColor.withOpacity(0.05),
                      ),
                      child: const Icon(Icons.add_photo_alternate, color: _shopColor, size: 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Banner toggle
            SwitchListTile(
              title: Text(lang.getText('Feature as Banner (paid)', 'பேனராக காட்டு (கட்டணம்)')),
              subtitle: Text(lang.getText('Show your shop at the top', 'கடையை முன்னிலைப்படுத்தவும்'),
                  style: const TextStyle(fontSize: 12)),
              value: _wantsBanner,
              activeColor: _shopColor,
              onChanged: (v) => setState(() => _wantsBanner = v),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(isBanner: _wantsBanner),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _shopColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        lang.getText('Submit Listing', 'விளம்பரம் சமர்ப்பிக்கவும்'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
