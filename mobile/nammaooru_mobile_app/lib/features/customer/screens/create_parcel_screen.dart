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
import '../services/parcel_service.dart';

class CreateParcelScreen extends StatefulWidget {
  const CreateParcelScreen({super.key});

  @override
  State<CreateParcelScreen> createState() => _CreateParcelScreenState();
}

class _CreateParcelScreenState extends State<CreateParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _priceInfoController = TextEditingController();
  final _addressController = TextEditingController();
  final _timingsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ParcelService _parcelService = ParcelService();

  String _selectedServiceType = 'DOOR_TO_DOOR';
  final List<File> _selectedImages = [];
  static const int _maxImages = 3;
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;

  static const Color _parcelOrange = Color(0xFFE65100);

  static const Map<String, String> _serviceTypes = {
    'DOOR_TO_DOOR': 'Door to Door',
    'PICKUP_POINT': 'Pickup Point',
    'BOTH': 'Both',
  };

  static const Map<String, String> _serviceTypeTamil = {
    'DOOR_TO_DOOR': '\u0bb5\u0bc0\u0b9f\u0bc1 \u0bb5\u0bc0\u0b9f\u0bbe\u0b95',
    'PICKUP_POINT': '\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0baa\u0bcd \u0baa\u0bbe\u0baf\u0bbf\u0ba3\u0bcd\u0b9f\u0bcd',
    'BOTH': '\u0b87\u0bb0\u0ba3\u0bcd\u0b9f\u0bc1\u0bae\u0bcd',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _phoneController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _priceInfoController.dispose();
    _addressController.dispose();
    _timingsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefillData() {
    final phone = LocalStorage.getString('phoneNumber');
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    } else {
      // Phone not in LocalStorage, fetch from profile API
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
              _addressController.text = '$village, $city';
            } else if (city.isNotEmpty) {
              _addressController.text = city;
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
          '\u0b85\u0ba4\u0bbf\u0b95\u0baa\u0b9f\u0bcd\u0b9a\u0bae\u0bcd $_maxImages \u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0b85\u0ba9\u0bc1\u0bae\u0ba4\u0bbf\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd',
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
              title: Text(langProvider.getText('Take Photo', '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bae\u0bcd \u0b8e\u0b9f\u0bc1\u0b95\u0bcd\u0b95')),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText('Choose from Gallery', '\u0b95\u0bc7\u0bb2\u0bb0\u0bbf\u0baf\u0bbf\u0bb2\u0bbf\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0b95')),
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
      final result = await _parcelService.createPost(
        serviceName: _serviceNameController.text.trim(),
        phone: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        fromLocation: _fromLocationController.text.trim(),
        toLocation: _toLocationController.text.trim(),
        priceInfo: _priceInfoController.text.trim(),
        address: _addressController.text.trim(),
        timings: _timingsController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePaths: _selectedImages.isNotEmpty
            ? _selectedImages.map((f) => f.path).toList()
            : null,
        latitude: _latitude,
        longitude: _longitude,
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
            const Icon(Icons.check_circle, color: Color(0xFFE65100), size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Listing Submitted!', '\u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bae\u0bb0\u0bcd\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0ba4\u0bc1!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.getText(
                'Your parcel service listing has been submitted and is now visible to others.',
                '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8 \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bae\u0bb0\u0bcd\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0ba4\u0bc1, \u0b87\u0baa\u0bcd\u0baa\u0bcb\u0ba4\u0bc1 \u0bae\u0bb1\u0bcd\u0bb1\u0bb5\u0bb0\u0bcd\u0b95\u0bb3\u0bc1\u0b95\u0bcd\u0b95\u0bc1\u0ba4\u0bcd \u0ba4\u0bc6\u0bb0\u0bbf\u0baf\u0bc1\u0bae\u0bcd.',
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
            Navigator.of(context).pop(true); // Go back to parcel screen
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
          langProvider.getText('Add Parcel Service', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8 \u0b9a\u0bc7\u0bb0\u0bcd\u0b95\u0bcd\u0b95'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _parcelOrange,
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

              // Service Name
              _buildLabel(langProvider.getText('Service Name *', '\u0b9a\u0bc7\u0bb5\u0bc8 \u0baa\u0bc6\u0baf\u0bb0\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _serviceNameController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Fast Parcel Delivery', '\u0b8e.\u0b95\u0bbe., \u0bb5\u0bc7\u0b95 \u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9f\u0bc6\u0bb2\u0bbf\u0bb5\u0bb0\u0bbf'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Service name is required', '\u0b9a\u0bc7\u0bb5\u0bc8 \u0baa\u0bc6\u0baf\u0bb0\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Must be at least 3 characters', '\u0b95\u0bc1\u0bb1\u0bc8\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1 3 \u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b95\u0bcd\u0b95\u0bb3\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Service Type
              _buildLabel(langProvider.getText('Service Type *', '\u0b9a\u0bc7\u0bb5\u0bc8 \u0bb5\u0b95\u0bc8 *')),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: _inputDecoration(
                  langProvider.getText('Select service type', '\u0b9a\u0bc7\u0bb5\u0bc8 \u0bb5\u0b95\u0bc8\u0baf\u0bc8\u0ba4\u0bcd \u0ba4\u0bc7\u0bb0\u0bcd\u0ba8\u0bcd\u0ba4\u0bc6\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd'),
                ),
                items: _serviceTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(langProvider.getText(entry.value, _serviceTypeTamil[entry.key] ?? entry.value)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value ?? 'DOOR_TO_DOOR';
                  });
                },
              ),
              const SizedBox(height: 12),

              // From Location
              _buildLabel(langProvider.getText('From Location *', '\u0b8e\u0b99\u0bcd\u0b95\u0bbf\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fromLocationController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Chennai', '\u0b8e.\u0b95\u0bbe., \u0b9a\u0bc6\u0ba9\u0bcd\u0ba9\u0bc8'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('From location is required', '\u0b8e\u0b99\u0bcd\u0b95\u0bbf\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Enter a valid from location', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0b87\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // To Location
              _buildLabel(langProvider.getText('To Location *', '\u0b8e\u0b99\u0bcd\u0b95\u0bc1 *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _toLocationController,
                maxLength: 200,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Tirupattur', '\u0b8e.\u0b95\u0bbe., \u0ba4\u0bbf\u0bb0\u0bc1\u0baa\u0bcd\u0baa\u0ba4\u0bcd\u0ba4\u0bc2\u0bb0\u0bcd'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('To location is required', '\u0b8e\u0b99\u0bcd\u0b95\u0bc1 \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Enter a valid to location', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0b87\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Price Info
              _buildLabel(langProvider.getText('Price Info *', '\u0bb5\u0bbf\u0bb2\u0bc8 \u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceInfoController,
                maxLength: 100,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., Rs. 50 per kg, Rs. 200 per parcel', '\u0b8e.\u0b95\u0bbe., \u0bb0\u0bc2. 50 \u0b95\u0bbf\u0bb2\u0bcb\u0bb5\u0bc1\u0b95\u0bcd\u0b95\u0bc1, \u0bb0\u0bc2. 200 \u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bc1\u0b95\u0bcd\u0b95\u0bc1'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Price info is required', '\u0bb5\u0bbf\u0bb2\u0bc8 \u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 2) {
                    return langProvider.getText('Enter valid price info', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0bb5\u0bbf\u0bb2\u0bc8 \u0bb5\u0bbf\u0bb5\u0bb0\u0ba4\u0bcd\u0ba4\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Address / Location
              _buildLabel(langProvider.getText('Address / Location *', '\u0bae\u0bc1\u0b95\u0bb5\u0bb0\u0bbf / \u0b87\u0b9f\u0bae\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('e.g., Mittur, Tirupattur').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: _parcelOrange),
                    onPressed: _getLocation,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Address is required', '\u0bae\u0bc1\u0b95\u0bb5\u0bb0\u0bbf \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Enter a valid address', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0bae\u0bc1\u0b95\u0bb5\u0bb0\u0bbf\u0baf\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Timings
              _buildLabel(langProvider.getText('Timings *', '\u0ba8\u0bc7\u0bb0\u0bae\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _timingsController,
                maxLength: 100,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  langProvider.getText('e.g., 9 AM - 6 PM, Daily', '\u0b8e.\u0b95\u0bbe., \u0b95\u0bbe\u0bb2\u0bc8 9 - \u0bae\u0bbe\u0bb2\u0bc8 6, \u0ba4\u0bbf\u0ba9\u0bae\u0bcd\u0ba4\u0bcb\u0bb1\u0bc1\u0bae\u0bcd'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Timings are required', '\u0ba8\u0bc7\u0bb0\u0bae\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 3) {
                    return langProvider.getText('Enter valid timings', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0ba8\u0bc7\u0bb0\u0ba4\u0bcd\u0ba4\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone
              _buildLabel(langProvider.getText('Phone Number *', '\u0ba4\u0bca\u0bb2\u0bc8\u0baa\u0bc7\u0b9a\u0bbf \u0b8e\u0ba3\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _inputDecoration(
                  langProvider.getText('Contact phone number', '\u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bc1 \u0ba4\u0bca\u0bb2\u0bc8\u0baa\u0bc7\u0b9a\u0bbf \u0b8e\u0ba3\u0bcd'),
                ).copyWith(
                  prefixIcon: const Icon(Icons.phone, size: 20, color: Color(0xFFE65100)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Phone number is required', '\u0ba4\u0bca\u0bb2\u0bc8\u0baa\u0bc7\u0b9a\u0bbf \u0b8e\u0ba3\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length != 10) {
                    return langProvider.getText('Enter valid 10-digit mobile number', '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 10 \u0b87\u0bb2\u0b95\u0bcd\u0b95 \u0bae\u0bca\u0baa\u0bc8\u0bb2\u0bcd \u0b8e\u0ba3\u0bcd\u0ba3\u0bc8 \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bb5\u0bc1\u0bae\u0bcd');
                  }
                  if (!RegExp(r'^[6-9]').hasMatch(value.trim())) {
                    return langProvider.getText('Must start with 6, 7, 8 or 9', '6, 7, 8 \u0b85\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1 9 \u0b87\u0bb2\u0bcd \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95 \u0bb5\u0bc7\u0ba3\u0bcd\u0b9f\u0bc1\u0bae\u0bcd');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description
              _buildLabel(langProvider.getText('Description *', '\u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd *')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration(
                  langProvider.getText('Additional details about the parcel service...', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8 \u0baa\u0bb1\u0bcd\u0bb1\u0bbf\u0baf \u0b95\u0bc2\u0b9f\u0bc1\u0ba4\u0bb2\u0bcd \u0bb5\u0bbf\u0bb5\u0bb0\u0b99\u0bcd\u0b95\u0bb3\u0bcd...'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return langProvider.getText('Description is required', '\u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8');
                  }
                  if (value.trim().length < 10) {
                    return langProvider.getText('Description must be at least 10 characters', '\u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd \u0b95\u0bc1\u0bb1\u0bc8\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1 10 \u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b95\u0bcd\u0b95\u0bb3\u0bcd \u0b87\u0bb0\u0bc1\u0b95\u0bcd\u0b95 \u0bb5\u0bc7\u0ba3\u0bcd\u0b9f\u0bc1\u0bae\u0bcd');
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
                    backgroundColor: _parcelOrange,
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
                          langProvider.getText('Submit Listing', '\u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bae\u0bb0\u0bcd\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd'),
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
        borderSide: const BorderSide(color: _parcelOrange, width: 1.5),
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
            _buildLabel(langProvider.getText('Photos (optional)', '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bcd (\u0bb5\u0bbf\u0bb0\u0bc1\u0bae\u0bcd\u0baa\u0bbf\u0ba9\u0bbe\u0bb2\u0bcd)')),
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
                          langProvider.getText('Add Photo', '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bae\u0bcd'),
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
