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
import '../services/womens_corner_service.dart';
import '../widgets/post_payment_handler.dart';
import '../widgets/voice_input_button.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../services/post_config_service.dart';

class CreateWomensCornerScreen extends StatefulWidget {
  const CreateWomensCornerScreen({super.key});

  @override
  State<CreateWomensCornerScreen> createState() => _CreateWomensCornerScreenState();
}

class _CreateWomensCornerScreenState extends State<CreateWomensCornerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final WomensCornerService _service = WomensCornerService();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  final List<File> _selectedImages = [];
  int _maxImages = 3;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  int? _paidTokenId;
  double? _latitude;
  double? _longitude;

  static const Color _primaryColor = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _prefillData();
    _loadCategories();
    _loadImageLimit();
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
    final location = LocalStorage.getString('lastLocation');
    if (location != null && location.isNotEmpty) {
      _locationController.text = location;
    }
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first['name'];
        }
      });
    }
  }

  Future<void> _loadImageLimit() async {
    await PostConfigService.instance.fetch();
    if (mounted) {
      setState(() {
        _maxImages = PostConfigService.instance.imageLimit;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }
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
  }

  Future<void> _pickImagesFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }
    final picker = ImagePicker();
    final remaining = _maxImages - _selectedImages.length;
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (pickedFiles.isNotEmpty && mounted) {
      final toAdd = pickedFiles.take(remaining).toList();
      final compressed = await ImageCompressor.compressMultiple(toAdd);
      setState(() {
        _selectedImages.addAll(compressed.map((f) => File(f.path)).toList());
      });
      if (pickedFiles.length > remaining) {
        _showMaxImagesMessage();
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

  Future<void> _submitPost({int? paidTokenId}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _service.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()),
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        paidTokenId: paidTokenId ?? _paidTokenId,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Post created successfully!'),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final statusCode = result['statusCode']?.toString() ?? '';
        final httpStatus = result['httpStatus'];
        if (statusCode == 'LIMIT_REACHED' || httpStatus == 402) {
          _handleLimitReached();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleLimitReached() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'WOMENS_CORNER',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId;
        _submitPost(paidTokenId: tokenId);
      },
      onPaymentCancelled: () {},
    );
    handler.startPayment();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          langProvider.getText("Create Post", '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B89\u0BB0\u0BC1\u0BB5\u0BBE\u0B95\u0BCD\u0B95\u0BC1'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              Text(langProvider.getText('Category', '\u0BAA\u0BBF\u0BB0\u0BBF\u0BB5\u0BC1'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(langProvider.getText('Select category', '\u0BAA\u0BBF\u0BB0\u0BBF\u0BB5\u0BC1 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95')),
                      items: _categories.map((cat) {
                        final tamilName = cat['tamilName'] ?? '';
                        return DropdownMenuItem<String>(
                          value: cat['name'],
                          child: Text('${cat['name']}${tamilName.isNotEmpty ? ' ($tamilName)' : ''}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (val) => val == null ? 'Please select a category' : null,
                    ),
              const SizedBox(height: 16),

              // Title
              Text(langProvider.getText('Title', '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(langProvider.getText('What are you offering?', '\u0BA8\u0BC0\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B8E\u0BA9\u0BCD\u0BA9 \u0BB5\u0BB4\u0B99\u0BCD\u0B95\u0BC1\u0B95\u0BBF\u0BB1\u0BC0\u0BB0\u0BCD\u0B95\u0BB3\u0BCD?')).copyWith(
                  suffixIcon: VoiceInputButton(controller: _titleController),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              Text(langProvider.getText('Description', '\u0BB5\u0BBF\u0BB5\u0BB0\u0BAE\u0BCD'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(langProvider.getText('Describe your service...', '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B9A\u0BC7\u0BB5\u0BC8\u0BAF\u0BC8 \u0BB5\u0BBF\u0BB5\u0BB0\u0BBF\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD...')).copyWith(
                  suffixIcon: VoiceInputButton(controller: _descriptionController),
                ),
              ),
              const SizedBox(height: 16),

              // Price
              Text(langProvider.getText('Price (\u20B9)', '\u0BB5\u0BBF\u0BB2\u0BC8 (\u20B9)'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: _inputDecoration(langProvider.getText('Enter price (optional)', '\u0BB5\u0BBF\u0BB2\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BC1\u0B95')),
              ),
              const SizedBox(height: 16),

              // Phone
              Text(langProvider.getText('Phone Number', '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: _inputDecoration('9876543210'),
                validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 16),

              // Location
              Text(langProvider.getText('Location', '\u0B87\u0B9F\u0BAE\u0BCD'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(langProvider.getText('Enter your location', '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0B9F\u0BAE\u0BCD')).copyWith(
                  suffixIcon: VoiceInputButton(controller: _locationController),
                ),
              ),
              const SizedBox(height: 20),

              // Photos
              Row(
                children: [
                  Text(
                    langProvider.getText('Photos', '\u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0B99\u0BCD\u0B95\u0BB3\u0BCD'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedImages.length}/$_maxImages',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedImages.length >= _maxImages ? Colors.orange : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image list
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: _selectedImages.length > 1
                                ? Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            top: 2,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),

              // Add photo buttons
              if (_selectedImages.length < _maxImages)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(langProvider.getText('Camera', '\u0B95\u0BBE\u0BAE\u0BBF\u0BB0\u0BBE')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImagesFromGallery,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(langProvider.getText('Gallery', '\u0B95\u0BBE\u0BB2\u0BB0\u0BBF')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitPost(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          langProvider.getText('Submit Post', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BAE\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BBF\u0B95\u0BCD\u0B95'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
