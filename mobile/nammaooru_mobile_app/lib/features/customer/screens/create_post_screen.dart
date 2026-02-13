import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/localization/language_provider.dart';
import '../services/marketplace_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();

  String _selectedCategory = 'Other';
  File? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Vehicles',
    'Agriculture',
    'Clothing',
    'Food',
    'Finance',
    'Other',
  ];

  static const Map<String, String> _categoryTamil = {
    'Electronics': 'எலக்ட்ரானிக்ஸ்',
    'Furniture': 'மரச்சாமான்',
    'Vehicles': 'வாகனங்கள்',
    'Agriculture': 'விவசாயம்',
    'Clothing': 'ஆடைகள்',
    'Food': 'உணவு',
    'Finance': 'நிதி',
    'Other': 'மற்றவை',
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
    // Pre-fill phone from locally stored user data
    final phone = LocalStorage.getString('phoneNumber');
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    }

    // Pre-fill location
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
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

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _marketplaceService.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        imagePath: _selectedImage?.path,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog();
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
            const Icon(Icons.check_circle, color: VillageTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Post Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your post is submitted for approval. It will be visible to others once admin approves it.',
                'உங்கள் பதிவு ஒப்புதலுக்கு சமர்ப்பிக்கப்பட்டது. நிர்வாகி ஒப்புதல் அளித்தவுடன் மற்றவர்களுக்கு தெரியும்.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    // Auto-close after 3 seconds and go back
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to marketplace (triggers refresh)
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
          langProvider.getText('Sell Something', 'பொருள் விற்க'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: VillageTheme.primaryGreen,
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
                  langProvider.getText('e.g., Tractor for Sale', 'எ.கா., டிராக்டர் விற்பனைக்கு'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Title is required', 'தலைப்பு தேவை');
                  }
                  return null;
                },
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
                  langProvider.getText('Describe your item...', 'உங்கள் பொருளை விவரிக்கவும்...'),
                ),
              ),
              const SizedBox(height: 12),

              // Price
              _buildLabel(langProvider.getText('Price (optional)', 'விலை (விரும்பினால்)')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('e.g., 50000').copyWith(
                  prefixText: '\u20B9 ',
                ),
              ),
              const SizedBox(height: 12),

              // Category
              _buildLabel(langProvider.getText('Category', 'வகை')),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                  langProvider.getText('Select category', 'வகையைத் தேர்ந்தெடுக்கவும்'),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(langProvider.getText(cat, _categoryTamil[cat] ?? cat)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'Other';
                  });
                },
              ),
              const SizedBox(height: 12),

              // Phone
              _buildLabel(langProvider.getText('Phone Number *', 'தொலைபேசி எண் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  langProvider.getText('Your phone number', 'உங்கள் தொலைபேசி எண்'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Phone number is required', 'தொலைபேசி எண் தேவை');
                  }
                  if (value.trim().length < 10) {
                    return langProvider.getText('Enter a valid phone number', 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Location (English only)
              _buildLabel('Location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g., Mittur, Tirupattur').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: VillageTheme.primaryGreen),
                    onPressed: _getLocation,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillageTheme.primaryGreen,
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
        borderSide: const BorderSide(color: VillageTheme.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildImagePicker(LanguageProvider langProvider) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    langProvider.getText('Tap to add product photo', 'பொருள் புகைப்படம் சேர்க்க தட்டவும்'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    langProvider.getText('Camera or Gallery', 'கேமரா அல்லது கேலரி'),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
