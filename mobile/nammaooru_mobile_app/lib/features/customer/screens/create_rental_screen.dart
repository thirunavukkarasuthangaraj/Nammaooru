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
import '../services/rental_service.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/post_payment_handler.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../services/post_config_service.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final RentalService _rentalService = RentalService();

  String _selectedCategory = 'HOUSE';
  String _selectedPriceUnit = 'per_month';
  final List<File> _selectedImages = [];
  int _maxImages = 3;
  bool _isSubmitting = false;
  bool _wantsBanner = false;
  int? _paidTokenId;
  double? _latitude;
  double? _longitude;

  static const Color _rentalOrange = Color(0xFFFF6F00);

  static const List<String> _categories = [
    'SHOP', 'AUTO', 'BIKE', 'HOUSE', 'LAND', 'EQUIPMENT', 'FURNITURE',
  ];

  static const Map<String, String> _categoryLabels = {
    'SHOP': 'Shop',
    'AUTO': 'Auto',
    'BIKE': 'Bike',
    'HOUSE': 'House',
    'LAND': 'Land',
    'EQUIPMENT': 'Equipment',
    'FURNITURE': 'Furniture',
  };

  static const Map<String, String> _categoryTamil = {
    'SHOP': 'கடை',
    'AUTO': 'ஆட்டோ',
    'BIKE': 'பைக்',
    'HOUSE': 'வீடு',
    'LAND': 'நிலம்',
    'EQUIPMENT': 'உபகரணம்',
    'FURNITURE': 'மரச்சாமான்',
  };

  static const Map<String, String> _priceUnitLabels = {
    'per_hour': 'Per Hour',
    'per_day': 'Per Day',
    'per_month': 'Per Month',
  };

  static const Map<String, String> _priceUnitTamil = {
    'per_hour': 'மணிக்கு',
    'per_day': 'நாளுக்கு',
    'per_month': 'மாதத்திற்கு',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
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
    _loadImageLimit();
  }

  Future<void> _loadImageLimit() async {
    try {
      await PostConfigService.instance.fetch();
      if (mounted) {
        setState(() {
          _maxImages = PostConfigService.instance.imageLimit;
        });
      }
    } catch (e) {
      debugPrint('Error loading image limit: $e');
    }
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
          final village = address['subLocality'] ?? '';
          final city = address['locality'] ?? '';
          setState(() {
            if (village.isNotEmpty && city.isNotEmpty) {
              _locationController.text = '$village, $city';
            } else if (city.isNotEmpty) {
              _locationController.text = city;
            }
          });
        }
      }
    } catch (e) {
      // Location is optional
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (_selectedImages.length >= _maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maximum $_maxImages images allowed')),
          );
        }
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final compressed = await ImageCompressor.compressXFile(pickedFile);
        setState(() {
          _selectedImages.add(File(compressed.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(langProvider.getText('Take Photo', 'புகைப்படம் எடுக்க')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText('Choose from Gallery', 'கேலரியிலிருந்து தேர்வு செய்க')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost({int? paidTokenId, bool isBanner = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_wantsBanner && paidTokenId == null && _paidTokenId == null) {
      _handleBannerPayment();
      return;
    }

    final tokenToUse = paidTokenId ?? _paidTokenId;
    final bannerFlag = isBanner || _wantsBanner;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _rentalService.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        priceUnit: _selectedPriceUnit,
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        latitude: _latitude,
        longitude: _longitude,
        paidTokenId: tokenToUse,
        isBanner: bannerFlag,
      );

      if (mounted) {
        if (result['success'] == true) {
          _paidTokenId = null;
          _showSuccessDialog();
        } else if (PostPaymentHandler.isLimitReached(result)) {
          setState(() { _isSubmitting = false; });
          _handleLimitReached();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleLimitReached() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'RENTAL',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId;
        _submitPost(paidTokenId: tokenId);
      },
      onPaymentCancelled: () {},
    );
    handler.startPayment();
  }

  void _handleBannerPayment() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'RENTAL',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId;
        _submitPost(paidTokenId: tokenId, isBanner: true);
      },
      onPaymentCancelled: () {},
    );
    handler.startPayment(includeBanner: true);
  }

  void _showSuccessDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Post Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your rental post is submitted for approval. It will be visible to others once admin approves it.',
                'உங்கள் வாடகை பதிவு ஒப்புதலுக்கு சமர்ப்பிக்கப்பட்டது. நிர்வாகி ஒப்புதல் அளித்தவுடன் மற்றவர்களுக்கு தெரியும்.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Post for Rent', 'வாடகைக்கு பதிவிடு'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _rentalOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              _buildImagePicker(langProvider),
              const SizedBox(height: 20),

              // Title
              _buildLabel(langProvider.getText('Title *', 'தலைப்பு *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., 2BHK House for Rent', 'எ.கா., 2BHK வீடு வாடகைக்கு'),
                ).copyWith(suffixIcon: VoiceInputButton(controller: _titleController)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Title is required', 'தலைப்பு தேவை');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Must be at least 3 characters', 'குறைந்தது 3 எழுத்துகள் தேவை');
                  }
                  if (value.trim().split(RegExp(r'\s+')).length > 3) {
                    return langProvider.getText('Title max 3 words', '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1 \u0B85\u0BA4\u0BBF\u0B95\u0BAA\u0B9F\u0BCD\u0B9A\u0BAE\u0BCD 3 \u0BB5\u0BBE\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BC8\u0B95\u0BB3\u0BCD');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category
              _buildLabel(langProvider.getText('Category *', 'வகை *')),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                  langProvider.getText('Select category', 'வகையைத் தேர்ந்தெடுக்கவும்'),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(langProvider.getText(
                      _categoryLabels[cat] ?? cat,
                      _categoryTamil[cat] ?? cat,
                    )),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'HOUSE';
                  });
                },
              ),
              const SizedBox(height: 12),

              // Price + Price Unit row
              _buildLabel(langProvider.getText('Price *', 'விலை *')),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g., 5000').copyWith(
                        prefixText: '\u20B9 ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return langProvider.getText('Price is required', 'விலை தேவை');
                        }
                        final price = double.tryParse(value.trim());
                        if (price == null || price <= 0) {
                          return langProvider.getText('Enter a valid price', 'சரியான விலையை உள்ளிடவும்');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriceUnit,
                      decoration: _inputDecoration('Unit'),
                      items: _priceUnitLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(langProvider.getText(
                            entry.value,
                            _priceUnitTamil[entry.key] ?? entry.value,
                          ), style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriceUnit = value ?? 'per_month';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              _buildLabel(langProvider.getText('Description', 'விவரம்')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration(
                  langProvider.getText('Describe the rental...', 'வாடகை பற்றி விவரிக்கவும்...'),
                ).copyWith(
                  suffixIcon: VoiceInputButton(controller: _descriptionController),
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              _buildLabel(langProvider.getText('Phone Number *', 'தொலைபேசி எண் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _inputDecoration(
                  langProvider.getText('Your phone number', 'உங்கள் தொலைபேசி எண்'),
                ).copyWith(
                  prefixIcon: const Icon(Icons.phone, size: 20, color: Color(0xFFFF6F00)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Phone number is required', 'தொலைபேசி எண் தேவை');
                  }
                  if (value.trim().length != 10) {
                    return langProvider.getText('Enter valid 10-digit mobile number', 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்');
                  }
                  if (!RegExp(r'^[6-9]').hasMatch(value.trim())) {
                    return langProvider.getText('Must start with 6, 7, 8 or 9', '6, 7, 8 அல்லது 9 இல் தொடங்க வேண்டும்');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Location
              _buildLabel('Location *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g., Mittur, Tirupattur').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFFFF6F00)),
                    onPressed: _getLocation,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Location is required', 'இடம் தேவை');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Enter a valid location', 'சரியான இடத்தை உள்ளிடவும்');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Banner toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _wantsBanner ? Colors.amber.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _wantsBanner ? Colors.amber.shade400 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _wantsBanner ? Colors.amber.shade700 : Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            langProvider.getText('Feature as Banner', '\u0BAA\u0BC7\u0BA9\u0BB0\u0BBE\u0B95 \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _wantsBanner ? Colors.amber.shade900 : Colors.black87,
                            ),
                          ),
                          Text(
                            langProvider.getText(
                              'Show at top of listings (paid)',
                              '\u0BAA\u0B9F\u0BCD\u0B9F\u0BBF\u0BAF\u0BB2\u0BCD\u0B95\u0BB3\u0BBF\u0BA9\u0BCD \u0BAE\u0BC7\u0BB2\u0BC7 \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1 (\u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD)',
                            ),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _wantsBanner,
                      activeColor: Colors.amber.shade700,
                      onChanged: (val) => setState(() => _wantsBanner = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rentalOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          langProvider.getText('Submit for Approval', 'ஒப்புதலுக்கு சமர்ப்பிக்கவும்'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: VillageTheme.primaryText,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildImagePicker(LanguageProvider langProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              langProvider.getText('Photos', 'புகைப்படங்கள்'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VillageTheme.primaryText),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: TextStyle(
                fontSize: 13,
                color: _selectedImages.length >= _maxImages ? Colors.orange : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              if (_selectedImages.length < _maxImages)
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 4),
                        Text(
                          langProvider.getText('Add Photo', 'புகைப்படம்'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              // Selected images
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
