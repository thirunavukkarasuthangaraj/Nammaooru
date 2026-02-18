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
import '../services/labour_service.dart';
import '../widgets/post_payment_handler.dart';

class CreateLabourScreen extends StatefulWidget {
  const CreateLabourScreen({super.key});

  @override
  State<CreateLabourScreen> createState() => _CreateLabourScreenState();
}

class _CreateLabourScreenState extends State<CreateLabourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final LabourService _labourService = LabourService();

  String _selectedCategory = 'GENERAL_LABOUR';
  final List<File> _selectedImages = [];
  static const int _maxImages = 3;
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;

  static const Color _labourBlue = Color(0xFF1565C0);

  static const Map<String, String> _categories = {
    'PAINTER': 'Painter',
    'CARPENTER': 'Carpenter',
    'ELECTRICIAN': 'Electrician',
    'PLUMBER': 'Plumber',
    'CONTRACTOR': 'Contractor',
    'MASON': 'Mason',
    'DRIVER': 'Driver',
    'WELDER': 'Welder',
    'MECHANIC': 'Mechanic',
    'TAILOR': 'Tailor',
    'AC_TECHNICIAN': 'AC Technician',
    'HELPER': 'Helper',
    'BIKE_REPAIR': 'Bike Repair',
    'CAR_REPAIR': 'Car Repair',
    'TYRE_PUNCTURE': 'Tyre Puncture',
    'GENERAL_LABOUR': 'General Labour',
    'OTHER': 'Other',
  };

  static const Map<String, String> _categoryTamil = {
    'PAINTER': 'பெயிண்டர்',
    'CARPENTER': 'தச்சர்',
    'ELECTRICIAN': 'எலக்ட்ரீஷியன்',
    'PLUMBER': 'பிளம்பர்',
    'CONTRACTOR': 'கான்ட்ராக்டர்',
    'MASON': 'மேஸ்திரி',
    'DRIVER': 'டிரைவர்',
    'WELDER': 'வெல்டர்',
    'MECHANIC': 'மெக்கானிக்',
    'TAILOR': 'தையல்காரர்',
    'AC_TECHNICIAN': 'ஏசி டெக்னீஷியன்',
    'HELPER': 'ஹெல்பர்',
    'BIKE_REPAIR': 'பைக் ரிப்பேர்',
    'CAR_REPAIR': 'கார் ரிப்பேர்',
    'TYRE_PUNCTURE': 'டயர் பஞ்சர்',
    'GENERAL_LABOUR': 'கூலி',
    'OTHER': 'மற்றவை',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
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
      // Location is optional, silently fail
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
        setState(() {
          _selectedImages.add(File(pickedFile.path));
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

  Future<void> _pickImagesFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }
    try {
      final picker = ImagePicker();
      final remaining = _maxImages - _selectedImages.length;
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          final toAdd = pickedFiles.take(remaining).map((f) => File(f.path)).toList();
          _selectedImages.addAll(toAdd);
        });
        if (pickedFiles.length > remaining) {
          _showMaxImagesMessage();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _showMaxImagesMessage() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(langProvider.getText(
          'Maximum $_maxImages images allowed',
          'அதிகபட்சம் $_maxImages புகைப்படங்கள் அனுமதிக்கப்படும்',
        )),
        backgroundColor: Colors.orange,
      ),
    );
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
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText('Choose from Gallery', 'கேலரியிலிருந்து தேர்வு செய்க')),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost({int? paidTokenId}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _labourService.createPost(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        experience: _experienceController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePaths: _selectedImages.isNotEmpty
            ? _selectedImages.map((f) => f.path).toList()
            : null,
        latitude: _latitude,
        longitude: _longitude,
        paidTokenId: paidTokenId,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog();
        } else if (PostPaymentHandler.isLimitReached(result)) {
          setState(() { _isSubmitting = false; });
          _handleLimitReached();
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
      postType: 'LABOURS',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _submitPost(paidTokenId: tokenId);
      },
      onPaymentCancelled: () {},
    );
    handler.startPayment();
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
            const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Listing Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your labour listing has been submitted and is now visible to others.',
                'உங்கள் தொழிலாளர் பதிவு சமர்ப்பிக்கப்பட்டது, இப்போது மற்றவர்களுக்குத் தெரியும்.',
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
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Go back to labour screen
          }
        });
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
          langProvider.getText('Add Labour', 'தொழிலாளர் சேர்க்க'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _labourBlue,
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

              // Name
              _buildLabel(langProvider.getText('Worker Name *', 'தொழிலாளர் பெயர் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Raju Kumar', 'எ.கா., ராஜு குமார்'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Worker name is required', 'தொழிலாளர் பெயர் தேவை');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Must be at least 3 characters', 'குறைந்தது 3 எழுத்துகள் தேவை');
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
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(langProvider.getText(entry.value, _categoryTamil[entry.key] ?? entry.value)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'GENERAL_LABOUR';
                  });
                },
              ),
              const SizedBox(height: 12),

              // Phone (auto-filled, read-only)
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
                  langProvider.getText('Worker\'s phone number', 'தொழிலாளர் தொலைபேசி எண்'),
                ).copyWith(
                  prefixIcon: const Icon(Icons.phone, size: 20, color: _labourBlue),
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

              // Experience
              _buildLabel(langProvider.getText('Experience', 'அனுபவம்')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _experienceController,
                maxLength: 100,
                keyboardType: TextInputType.text,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., 5 years, 10+ years', 'எ.கா., 5 வருடங்கள், 10+ வருடங்கள்'),
                ),
              ),
              const SizedBox(height: 12),

              // Location
              _buildLabel(langProvider.getText('Location *', 'இடம் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g., Mittur, Tirupattur').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: _labourBlue),
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
              const SizedBox(height: 12),

              // Description
              _buildLabel(langProvider.getText('Description *', 'விவரம் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration(
                  langProvider.getText('Additional details about the worker...', 'தொழிலாளரைப் பற்றிய கூடுதல் விவரங்கள்...'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Description is required', 'விவரம் தேவை');
                  }
                  if (value.trim().length < 10) {
                    return langProvider.getText('Description must be at least 10 characters', 'விவரம் குறைந்தது 10 எழுத்துகள் இருக்க வேண்டும்');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _labourBlue,
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
                          langProvider.getText('Submit Listing', 'பதிவு சமர்ப்பிக்கவும்'),
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
        borderSide: const BorderSide(color: _labourBlue, width: 1.5),
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
            _buildLabel(langProvider.getText('Photos (optional)', 'புகைப்படங்கள் (விரும்பினால்)')),
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
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          image,
                          width: 120,
                          height: 120,
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
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      if (_selectedImages.length > 1)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              if (_selectedImages.length < _maxImages)
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text(
                          langProvider.getText('Add Photo', 'புகைப்படம்'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
