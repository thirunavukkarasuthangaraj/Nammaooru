import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/localization/language_provider.dart';
import '../services/travel_service.dart';

class CreateTravelScreen extends StatefulWidget {
  const CreateTravelScreen({super.key});

  @override
  State<CreateTravelScreen> createState() => _CreateTravelScreenState();
}

class _CreateTravelScreenState extends State<CreateTravelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TravelService _travelService = TravelService();

  String _selectedVehicleType = 'CAR';
  final List<File> _selectedImages = [];
  static const int _maxImages = 3;
  bool _isSubmitting = false;

  static const Color _travelTeal = Color(0xFF00897B);

  static const Map<String, String> _vehicleTypes = {
    'CAR': 'Car',
    'SMALL_BUS': 'Small Bus',
    'BUS': 'Bus',
  };

  static const Map<String, String> _vehicleTypeTamil = {
    'CAR': '\u0B95\u0BBE\u0BB0\u0BCD',
    'SMALL_BUS': '\u0B9A\u0BBF\u0BB1\u0BBF\u0BAF \u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1',
    'BUS': '\u0BAA\u0BC7\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
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
              _fromLocationController.text = '$village, $city';
            } else if (city.isNotEmpty) {
              _fromLocationController.text = city;
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
          '\u0B85\u0BA4\u0BBF\u0B95\u0BAA\u0B9F\u0BCD\u0B9A\u0BAE\u0BCD $_maxImages \u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B85\u0BA9\u0BC1\u0BAE\u0BA4\u0BBF\u0B95\u0BCD\u0B95\u0BAA\u0BCD\u0BAA\u0B9F\u0BC1\u0BAE\u0BCD',
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
              title: Text(langProvider.getText('Take Photo', '\u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0BAE\u0BCD \u0B8E\u0B9F\u0BC1\u0B95\u0BCD\u0B95')),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText('Choose from Gallery', '\u0B95\u0BC7\u0BB2\u0BB0\u0BBF\u0BAF\u0BBF\u0BB2\u0BBF\u0BB0\u0BC1\u0BA8\u0BCD\u0BA4\u0BC1 \u0BA4\u0BC7\u0BB0\u0BCD\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0B95')),
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
      final seatsText = _seatsController.text.trim();
      int? seats;
      if (seatsText.isNotEmpty) {
        seats = int.tryParse(seatsText);
      }

      final result = await _travelService.createPost(
        title: _titleController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _selectedVehicleType,
        fromLocation: _fromLocationController.text.trim(),
        toLocation: _toLocationController.text.trim(),
        price: _priceController.text.trim(),
        seatsAvailable: seats,
        description: _descriptionController.text.trim(),
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
            const Icon(Icons.check_circle, color: Color(0xFF00897B), size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Travel Listing Submitted!', '\u0BAA\u0BAF\u0BA3 \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BAE\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BBF\u0B95\u0BCD\u0B95\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your travel listing has been submitted and is now visible to others.',
                '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAA\u0BAF\u0BA3\u0BAA\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BAE\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BBF\u0B95\u0BCD\u0B95\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1, \u0B87\u0BAA\u0BCD\u0BAA\u0BCB\u0BA4\u0BC1 \u0BAE\u0BB1\u0BCD\u0BB1\u0BB5\u0BB0\u0BCD\u0B95\u0BB3\u0BC1\u0B95\u0BCD\u0B95\u0BC1\u0BA4\u0BCD \u0BA4\u0BC6\u0BB0\u0BBF\u0BAF\u0BC1\u0BAE\u0BCD.',
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
            Navigator.of(context).pop(true); // Go back to travel screen
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
          langProvider.getText('Add Travel', '\u0BAA\u0BAF\u0BA3\u0BAE\u0BCD \u0B9A\u0BC7\u0BB0\u0BCD\u0B95\u0BCD\u0B95'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _travelTeal,
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
              _buildLabel(langProvider.getText('Title *', '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1 *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Chennai to Tirupathi Daily', '\u0B8E.\u0B95\u0BBE., \u0B9A\u0BC6\u0BA9\u0BCD\u0BA9\u0BC8 \u0BA4\u0BBF\u0BB0\u0BC1\u0BAA\u0BCD\u0BAA\u0BA4\u0BBF \u0BA4\u0BBF\u0BA9\u0B9A\u0BB0\u0BBF'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Title is required', '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1 \u0BA4\u0BC7\u0BB5\u0BC8');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Vehicle Type
              _buildLabel(langProvider.getText('Vehicle Type *', '\u0BB5\u0BBE\u0B95\u0BA9 \u0BB5\u0B95\u0BC8 *')),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: _inputDecoration(
                  langProvider.getText('Select vehicle type', '\u0BB5\u0BBE\u0B95\u0BA9 \u0BB5\u0B95\u0BC8\u0BAF\u0BC8\u0BA4\u0BCD \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD'),
                ),
                items: _vehicleTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(langProvider.getText(entry.value, _vehicleTypeTamil[entry.key] ?? entry.value)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleType = value ?? 'CAR';
                  });
                },
              ),
              const SizedBox(height: 12),

              // From Location
              _buildLabel(langProvider.getText('From Location', '\u0BAA\u0BC1\u0BB1\u0BAA\u0BCD\u0BAA\u0B9F\u0BC1\u0BAE\u0BCD \u0B87\u0B9F\u0BAE\u0BCD')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fromLocationController,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Chennai', '\u0B8E.\u0B95\u0BBE., \u0B9A\u0BC6\u0BA9\u0BCD\u0BA9\u0BC8'),
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: _travelTeal),
                    onPressed: _getLocation,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // To Location
              _buildLabel(langProvider.getText('To Location', '\u0B9A\u0BC7\u0BB0\u0BC1\u0BAE\u0BCD \u0B87\u0B9F\u0BAE\u0BCD')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _toLocationController,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Tirupathi', '\u0B8E.\u0B95\u0BBE., \u0BA4\u0BBF\u0BB0\u0BC1\u0BAA\u0BCD\u0BAA\u0BA4\u0BBF'),
                ),
              ),
              const SizedBox(height: 12),

              // Price
              _buildLabel(langProvider.getText('Price', '\u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.text,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., 500, Negotiable', '\u0B8E.\u0B95\u0BBE., 500, \u0BAA\u0BC7\u0B9A\u0BBF \u0BAE\u0BC1\u0B9F\u0BBF\u0BAF\u0BC1\u0BAE\u0BCD'),
                ),
              ),
              const SizedBox(height: 12),

              // Seats Available
              _buildLabel(langProvider.getText('Seats Available', '\u0B87\u0BB0\u0BC1\u0B95\u0BCD\u0B95\u0BC8\u0B95\u0BB3\u0BCD')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(
                  langProvider.getText('e.g., 4', '\u0B8E.\u0B95\u0BBE., 4'),
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              _buildLabel(langProvider.getText('Phone Number *', '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  langProvider.getText('Contact phone number', '\u0BA4\u0BCA\u0B9F\u0BB0\u0BCD\u0BAA\u0BC1 \u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Phone number is required', '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD \u0BA4\u0BC7\u0BB5\u0BC8');
                  }
                  if (value.trim().length < 10) {
                    return langProvider.getText('Enter a valid phone number', '\u0B9A\u0BB0\u0BBF\u0BAF\u0BBE\u0BA9 \u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD\u0BA3\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description
              _buildLabel(langProvider.getText('Description', '\u0BB5\u0BBF\u0BB5\u0BB0\u0BAE\u0BCD')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration(
                  langProvider.getText('Additional details about the travel...', '\u0BAA\u0BAF\u0BA3\u0BA4\u0BCD\u0BA4\u0BC8\u0BAA\u0BCD \u0BAA\u0BB1\u0BCD\u0BB1\u0BBF\u0BAF \u0B95\u0BC2\u0B9F\u0BC1\u0BA4\u0BB2\u0BCD \u0BB5\u0BBF\u0BB5\u0BB0\u0B99\u0BCD\u0B95\u0BB3\u0BCD...'),
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
                    backgroundColor: _travelTeal,
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
                          langProvider.getText('Submit Listing', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BAE\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BBF\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD'),
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
        borderSide: const BorderSide(color: _travelTeal, width: 1.5),
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
            _buildLabel(langProvider.getText('Photos (optional)', '\u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0B99\u0BCD\u0B95\u0BB3\u0BCD (\u0BB5\u0BBF\u0BB0\u0BC1\u0BAE\u0BCD\u0BAA\u0BBF\u0BA9\u0BBE\u0BB2\u0BCD)')),
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
                          langProvider.getText('Add Photo', '\u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0BAE\u0BCD'),
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
