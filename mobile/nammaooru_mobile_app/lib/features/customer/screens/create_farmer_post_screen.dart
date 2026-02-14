import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/localization/language_provider.dart';
import '../services/farmer_products_service.dart';

class CreateFarmerPostScreen extends StatefulWidget {
  const CreateFarmerPostScreen({super.key});

  @override
  State<CreateFarmerPostScreen> createState() => _CreateFarmerPostScreenState();
}

class _CreateFarmerPostScreenState extends State<CreateFarmerPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final FarmerProductsService _farmerService = FarmerProductsService();

  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  final List<File> _selectedImages = [];
  static const int _maxImages = 5;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains & Pulses',
    'Dairy',
    'Spices',
    'Flowers',
    'Organic',
    'Seeds & Plants',
    'Honey & Jaggery',
    'Other',
  ];

  static const Map<String, String> _categoryTamil = {
    'Vegetables': 'காய்கறிகள்',
    'Fruits': 'பழங்கள்',
    'Grains & Pulses': 'தானியங்கள் & பருப்பு',
    'Dairy': 'பால் பொருட்கள்',
    'Spices': 'மசாலா பொருட்கள்',
    'Flowers': 'பூக்கள்',
    'Organic': 'இயற்கை',
    'Seeds & Plants': 'விதைகள் & செடிகள்',
    'Honey & Jaggery': 'தேன் & வெல்லம்',
    'Other': 'மற்றவை',
  };

  final List<String> _units = ['kg', 'g', 'litre', 'piece', 'bunch', 'dozen', 'quintal'];

  static const Map<String, String> _unitTamil = {
    'kg': 'கிலோ',
    'g': 'கிராம்',
    'litre': 'லிட்டர்',
    'piece': 'எண்ணிக்கை',
    'bunch': 'கட்டு',
    'dozen': 'டஜன்',
    'quintal': 'குவிண்டால்',
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
    }
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

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _farmerService.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        unit: _selectedUnit,
        imagePaths: _selectedImages.isNotEmpty
            ? _selectedImages.map((f) => f.path).toList()
            : null,
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
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Post Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your farmer product is submitted for approval. It will be visible once admin approves it.',
                'உங்கள் விவசாய பொருள் ஒப்புதலுக்கு சமர்ப்பிக்கப்பட்டது. நிர்வாகி ஒப்புதல் அளித்தவுடன் தெரியும்.',
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
            Navigator.of(context).pop(true); // Go back to farmer products screen
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
          langProvider.getText('Sell Farm Product', 'விவசாய பொருள் விற்க'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
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
              _buildLabel(langProvider.getText('Product Name *', 'பொருள் பெயர் *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Fresh Tomatoes', 'எ.கா., புதிய தக்காளி'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Product name is required', 'பொருள் பெயர் தேவை');
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
                  langProvider.getText('Describe your product...', 'உங்கள் பொருளை விவரிக்கவும்...'),
                ),
              ),
              const SizedBox(height: 12),

              // Price & Unit row
              _buildLabel(langProvider.getText('Price per unit (optional)', 'ஒரு யூனிட் விலை (விரும்பினால்)')),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g., 50').copyWith(
                        prefixText: '\u20B9 ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: _inputDecoration('Unit'),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(langProvider.getText(unit, _unitTamil[unit] ?? unit)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value ?? 'kg';
                        });
                      },
                    ),
                  ),
                ],
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
                    _selectedCategory = value ?? 'Vegetables';
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

              // Location
              _buildLabel('Location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g., Mittur, Tirupattur').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
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
                    backgroundColor: const Color(0xFF2E7D32),
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
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
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
            _buildLabel(langProvider.getText('Product Photos', 'பொருள் புகைப்படங்கள்')),
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
              // Existing images
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
                      // Remove button
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
                      // Index badge
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
              // Add button
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
