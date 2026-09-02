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
import '../../../core/services/contact_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/womens_corner_service.dart';
import '../widgets/post_payment_handler.dart';
import '../widgets/voice_input_button.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';
import '../../../services/post_config_service.dart';

class CreateWomensCornerScreen extends StatefulWidget {
  const CreateWomensCornerScreen({super.key});

  @override
  State<CreateWomensCornerScreen> createState() =>
      _CreateWomensCornerScreenState();
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
  bool _categoryLoadFailed = false;
  final List<File> _selectedImages = [];
  int _maxImages = 3;
  bool _isSubmitting = false;
  bool _wantsBanner = false;
  bool _phoneLocked = false;
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
    // Auto-apply profile phone privacy setting
    SharedPreferences.getInstance().then((prefs) {
      if (mounted && (prefs.getBool('phone_privacy_enabled') ?? false)) {
        setState(() => _phoneLocked = true);
      }
    });
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
      _phoneController.text = FormValidators.normalizeIndianMobile(phone);
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
      if (position != null &&
          position.latitude != null &&
          position.longitude != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
        _categoryLoadFailed = false;
      });
    }
    final categories = await _service.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        _categoryLoadFailed = categories.isEmpty;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first['name'];
        } else {
          _selectedCategory = null;
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
    // No maxWidth/maxHeight/imageQuality here — those force image_picker's
    // own native resize into a cache file ("scaled_*.jpg") that races with
    // reads on some OEM builds (Samsung and others), causing
    // PathNotFoundException. ImageCompressor below handles resizing instead.
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
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
    // See _pickImageFromCamera — no native resize params, ImageCompressor handles it.
    final pickedFiles = await picker.pickMultiImage();
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

  Future<void> _submitPost({int? paidTokenId, bool isBanner = false}) async {
    if (_isLoadingCategories ||
        _categories.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please load and select a category before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_wantsBanner && paidTokenId == null && _paidTokenId == null) {
      _handleBannerPayment();
      return;
    }

    final bannerFlag = isBanner || _wantsBanner;

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
        isBanner: bannerFlag,
        latitude: _latitude,
        longitude: _longitude,
        phoneLocked: _phoneLocked,
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
      onPaymentCancelled: () {
        if (mounted)
          setState(() {
            _isSubmitting = false;
          });
      },
    );
    handler.startPayment();
  }

  void _handleBannerPayment() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'WOMENS_CORNER',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId;
        _submitPost(paidTokenId: tokenId, isBanner: true);
      },
      onPaymentCancelled: () {
        if (mounted)
          setState(() {
            _isSubmitting = false;
          });
      },
    );
    handler.startPayment(includeBanner: true);
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

  void _showHelpGuide(LanguageProvider langProvider) {
    final isTamil = langProvider.showTamil;
    final steps = [
      {
        'icon': Icons.category_outlined,
        'color': Colors.pink.shade600,
        'title': isTamil ? '1. வகை தேர்வு செய்யவும்' : '1. Choose a Category',
        'desc': isTamil
            ? 'உங்கள் சேவை அல்லது பொருளுக்கு பொருத்தமான வகையை தேர்வு செய்யவும். வகைகள் நிர்வாகியால் நிர்ணயிக்கப்படும்.'
            : 'Select the right category for your service or product. Categories are set by admin.'
      },
      {
        'icon': Icons.title,
        'color': Colors.orange.shade600,
        'title': isTamil ? '2. தலைப்பு & விவரம்' : '2. Title & Description',
        'desc': isTamil
            ? 'உங்கள் சேவை என்ன என்று தெளிவான தலைப்பு எழுதவும். விவரத்தில் முழு தகவல் தரவும். குரல் பொத்தான் உதவும்.'
            : 'Write a clear title for your service. Add full details in description. Use mic button.'
      },
      {
        'icon': Icons.currency_rupee,
        'color': Colors.green.shade700,
        'title': isTamil ? '3. விலை (விருப்பம்)' : '3. Price (Optional)',
        'desc': isTamil
            ? 'சேவைக்கான விலை இருந்தால் குறிப்பிடவும். விலை இல்லாமலும் பதிவிடலாம்.'
            : 'Enter price if applicable. You can also post without a price (for free services).'
      },
      {
        'icon': Icons.lock_outline,
        'color': Colors.purple.shade600,
        'title':
            isTamil ? '4. தொலைபேசி & பூட்டு தேர்வு' : '4. Phone & Privacy Lock',
        'desc': isTamil
            ? '"தொலைபேசி எண் பூட்டு" இயக்கினால் உங்கள் எண் மறைக்கப்படும். வாங்குவோர் அனுமதி கோரவேண்டும். பெண்களுக்கு பாதுகாப்பான அம்சம்.'
            : 'Enable "Lock Phone" to hide your number. Buyers must request permission first. Safe for women.'
      },
      {
        'icon': Icons.location_on_outlined,
        'color': Colors.red.shade600,
        'title': isTamil ? '5. இடம்' : '5. Location',
        'desc': isTamil
            ? 'உங்கள் கிராமம் அல்லது நகரம் உள்ளிடவும். இது அருகில் உள்ளவர்களுக்கு உங்கள் பதிவை காட்ட உதவும்.'
            : 'Enter your village or town. This helps show your post to nearby customers.'
      },
      {
        'icon': Icons.camera_alt_outlined,
        'color': Colors.blue.shade600,
        'title': isTamil ? '6. புகைப்படம்' : '6. Add Photos',
        'desc': isTamil
            ? 'உங்கள் பொருள் அல்லது சேவையின் படம் சேர்க்கவும். கேமரா அல்லது கேலரியிலிருந்து தேர்வு செய்யலாம்.'
            : 'Add photos of your product or service. Choose from camera or gallery.'
      },
      {
        'icon': Icons.check_circle_outline,
        'color': _primaryColor,
        'title': isTamil ? '7. சமர்ப்பிக்கவும்' : '7. Submit Post',
        'desc': isTamil
            ? '"பதிவு சமர்ப்பிக்கவும்" அழுத்தவும். உங்கள் பதிவு உடனே பட்டியலில் தோன்றும்.'
            : 'Tap "Submit Post". Your post will appear in the listing immediately.'
      },
    ];
    _showGuideSheet(
        langProvider,
        steps,
        isTamil ? 'பதிவு உருவாக்குவது எப்படி?' : 'How to Create a Post?',
        isTamil
            ? '7 எளிய படிகளில் பதிவு உருவாக்கவும்'
            : 'Create your post in 7 easy steps',
        isTamil
            ? 'குறிப்பு: தொலைபேசி எண் பூட்டு அம்சம் பெண்களுக்கு தனியுரிமை மற்றும் பாதுகாப்பை உறுதி செய்கிறது.'
            : 'Tip: Phone Lock feature ensures privacy and safety for women sellers.');
  }

  void _showGuideSheet(
      LanguageProvider langProvider,
      List<Map<String, dynamic>> steps,
      String title,
      String subtitle,
      String tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.lightbulb_outline,
                          color: _primaryColor, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ])),
            const Divider(height: 1),
            Expanded(
                child: ListView.separated(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = steps[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: (s['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (s['color'] as Color).withOpacity(0.2))),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: (s['color'] as Color).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(s['icon'] as IconData,
                                color: s['color'] as Color, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(s['title'] as String,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: (s['color'] as Color)
                                          .withOpacity(0.9))),
                              const SizedBox(height: 4),
                              Text(s['desc'] as String,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4)),
                            ])),
                      ]),
                );
              },
            )),
            Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200)),
                child: Row(children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(tip,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              height: 1.4))),
                ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          langProvider.getText("Create Post",
              '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B89\u0BB0\u0BC1\u0BB5\u0BBE\u0B95\u0BCD\u0B95\u0BC1'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip:
                langProvider.getText('How to Post', 'எப்படி பதிவிட வேண்டும்'),
            onPressed: () => _showHelpGuide(langProvider),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Dropdown
                Text(
                    langProvider.getText(
                        'Category *', '\u0BAA\u0BBF\u0BB0\u0BBF\u0BB5\u0BC1 *'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : _categoryLoadFailed
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                      'Categories could not be loaded. Please try again.'),
                                ),
                                TextButton(
                                  onPressed: _loadCategories,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _inputDecoration(langProvider.getText(
                                'Select category',
                                '\u0BAA\u0BBF\u0BB0\u0BBF\u0BB5\u0BC1 \u0BA4\u0BC7\u0BB0\u0BCD\u0BA8\u0BCD\u0BA4\u0BC6\u0B9F\u0BC1\u0B95\u0BCD\u0B95')),
                            items: _categories.map((cat) {
                              final tamilName = cat['tamilName'] ?? '';
                              return DropdownMenuItem<String>(
                                value: cat['name'],
                                child: Text(
                                    '${cat['name']}${tamilName.isNotEmpty ? ' ($tamilName)' : ''}'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            validator: (val) =>
                                val == null ? 'Please select a category' : null,
                          ),
                const SizedBox(height: 16),

                // Title
                Text(
                    langProvider.getText('Title *',
                        '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1 *'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: 200,
                  decoration: _inputDecoration(langProvider.getText(
                          'What are you offering?',
                          '\u0BA8\u0BC0\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B8E\u0BA9\u0BCD\u0BA9 \u0BB5\u0BB4\u0B99\u0BCD\u0B95\u0BC1\u0B95\u0BBF\u0BB1\u0BC0\u0BB0\u0BCD\u0B95\u0BB3\u0BCD?'))
                      .copyWith(
                    suffixIcon: VoiceInputButton(controller: _titleController),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                    langProvider.getText(
                        'Description', '\u0BB5\u0BBF\u0BB5\u0BB0\u0BAE\u0BCD'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: null,
                  decoration: _inputDecoration(langProvider.getText(
                          'Describe your service...',
                          '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B9A\u0BC7\u0BB5\u0BC8\u0BAF\u0BC8 \u0BB5\u0BBF\u0BB5\u0BB0\u0BBF\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD...'))
                      .copyWith(
                    suffixIcon:
                        VoiceInputButton(controller: _descriptionController),
                  ),
                ),
                const SizedBox(height: 16),

                // Price
                Text(
                    langProvider.getText(
                        'Price (\u20B9)', '\u0BB5\u0BBF\u0BB2\u0BC8 (\u20B9)'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  decoration: _inputDecoration(langProvider.getText(
                      'Enter price (optional)',
                      '\u0BB5\u0BBF\u0BB2\u0BC8 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BC1\u0B95')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return FormValidators.isValidPositiveDecimal(value)
                        ? null
                        : langProvider.getText(
                            'Enter a valid price above 0 with up to 2 decimals',
                            '0-ஐ விட அதிகமான சரியான விலையை உள்ளிடவும்',
                          );
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                Text(
                    langProvider.getText('Phone Number *',
                        '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC7\u0B9A\u0BBF \u0B8E\u0BA3\u0BCD *'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10)
                  ],
                  decoration: _inputDecoration(FormValidators.mobileExample),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return langProvider.getText(
                          'Phone number is required', 'தொலைபேசி எண் தேவை');
                    }
                    return FormValidators.isValidIndianMobile(value)
                        ? null
                        : langProvider.getText(
                            'Enter a valid 10-digit mobile number starting with 6, 7, 8 or 9',
                            '6, 7, 8 அல்லது 9-ல் தொடங்கும் சரியான 10 இலக்க எண்ணை உள்ளிடவும்',
                          );
                  },
                ),
                const SizedBox(height: 12),

                // Phone Lock toggle
                Row(
                  children: [
                    Switch(
                      value: _phoneLocked,
                      onChanged: (val) => setState(() => _phoneLocked = val),
                      activeColor: const Color(0xFFE91E63),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            langProvider.getText(
                                'Lock Phone Number', 'தொலைபேசி எண் பூட்டு'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            langProvider.getText(
                              'Buyers must request permission before seeing your number',
                              'வாங்குபவர்கள் உங்கள் எண்ணை பார்க்க அனுமதி கோரவேண்டும்',
                            ),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                Text(langProvider.getText('Location', 'இடம்'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                LocationAutocompleteField(
                  controller: _locationController,
                  hintText: langProvider.getText(
                      'Enter your location', 'உங்கள் இடம்'),
                  accentColor: const Color(0xFFE91E63),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return value.trim().length <= 200
                        ? null
                        : langProvider.getText(
                            'Location is too long', 'இடம் மிக நீளமாக உள்ளது');
                  },
                ),
                const SizedBox(height: 20),

                // Photos
                Row(
                  children: [
                    Text(
                      langProvider.getText('Photos',
                          '\u0BAA\u0BC1\u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0B9F\u0B99\u0BCD\u0B95\u0BB3\u0BCD'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedImages.length}/$_maxImages',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedImages.length >= _maxImages
                            ? Colors.orange
                            : Colors.grey[500],
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text('${index + 1}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11)),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
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
                          label: Text(langProvider.getText('Camera',
                              '\u0B95\u0BBE\u0BAE\u0BBF\u0BB0\u0BBE')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(
                                color: _primaryColor.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImagesFromGallery,
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: Text(langProvider.getText(
                              'Gallery', '\u0B95\u0BBE\u0BB2\u0BB0\u0BBF')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(
                                color: _primaryColor.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // Banner toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _wantsBanner ? Colors.amber.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _wantsBanner
                          ? Colors.amber.shade400
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: _wantsBanner
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              langProvider.getText('Feature as Banner',
                                  '\u0BAA\u0BC7\u0BA9\u0BB0\u0BBE\u0B95 \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _wantsBanner
                                    ? Colors.amber.shade900
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              langProvider.getText(
                                'Show at top of listings (paid)',
                                '\u0BAA\u0B9F\u0BCD\u0B9F\u0BBF\u0BAF\u0BB2\u0BCD\u0B95\u0BB3\u0BBF\u0BA9\u0BCD \u0BAE\u0BC7\u0BB2\u0BC7 \u0B95\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1 (\u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD)',
                              ),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
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
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitPost(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            langProvider.getText('Submit Post',
                                '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BAE\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BBF\u0B95\u0BCD\u0B95'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
