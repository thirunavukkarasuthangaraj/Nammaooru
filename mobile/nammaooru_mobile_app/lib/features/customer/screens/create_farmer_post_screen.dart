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
import '../services/farmer_products_service.dart';
import '../widgets/post_payment_handler.dart';
import '../widgets/voice_input_button.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';
import '../../../services/post_config_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _maxImages = 5;
  bool _isSubmitting = false;
  bool _wantsBanner = false;
  int? _paidTokenId;
  double? _latitude;
  double? _longitude;

  // One-time tour: photos → product name → price → submit. Template for the
  // other create-post screens (labour, job, parcel, rental, etc).
  final GlobalKey _tourPhotosKey = GlobalKey();
  final GlobalKey _tourNameKey = GlobalKey();
  final GlobalKey _tourPriceKey = GlobalKey();
  final GlobalKey _tourSubmitKey = GlobalKey();
  bool _postTourChecked = false;
  BuildContext? _postShowcaseCtx;

  Future<void> _startPostTourIfNeeded(BuildContext showcaseCtx) async {
    _postShowcaseCtx = showcaseCtx;
    if (_postTourChecked) return;
    _postTourChecked = true;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('farmer_post_tour_shown') ?? false;
    if (shown || !mounted) return;
    await prefs.setBool('farmer_post_tour_shown', true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _postShowcaseCtx == null) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      ShowCaseWidget.of(_postShowcaseCtx!).startShowCase(
          [_tourPhotosKey, _tourNameKey, _tourPriceKey, _tourSubmitKey]);
    });
  }

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
    'Agri Machines',
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
    'Agri Machines': 'விவசாய இயந்திரங்கள்',
    'Other': 'மற்றவை',
  };

  final List<String> _units = [
    'kg',
    'g',
    'litre',
    'piece',
    'bunch',
    'dozen',
    'quintal'
  ];

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
          final phone =
              userData['mobileNumber'] ?? userData['phoneNumber'] ?? '';
          if (phone.toString().isNotEmpty && mounted) {
            final normalizedPhone = FormValidators.normalizeIndianMobile(phone);
            setState(() {
              _phoneController.text = normalizedPhone;
            });
            await LocalStorage.setString('phoneNumber', normalizedPhone);
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
      if (position != null &&
          position.latitude != null &&
          position.longitude != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        final address =
            await LocationService.instance.getAddressFromCoordinates(
          position.latitude!,
          position.longitude!,
        );
        if (address != null && mounted) {
          final name = address['name'] ?? address['subLocality'] ?? '';
          final city = address['locality'] ?? '';
          setState(() {
            if (name.isNotEmpty && city.isNotEmpty && name != city) {
              _locationController.text = '$name, $city';
            } else if (name.isNotEmpty) {
              _locationController.text = name;
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
              title:
                  Text(langProvider.getText('Take Photo', 'புகைப்படம் எடுக்க')),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText(
                  'Choose from Gallery', 'கேலரியிலிருந்து தேர்வு செய்க')),
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
        paidTokenId: tokenToUse,
        isBanner: bannerFlag,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        if (result['success'] == true) {
          _paidTokenId = null;
          _showSuccessDialog();
        } else if (PostPaymentHandler.isLimitReached(result)) {
          setState(() {
            _isSubmitting = false;
          });
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
      postType: 'FARM_PRODUCTS',
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
      postType: 'FARM_PRODUCTS',
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
              langProvider.getText(
                  'Post Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
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
            Navigator.of(context)
                .pop(true); // Go back to farmer products screen
          }
        });
      }
    });
  }

  void _showHelpGuide(LanguageProvider langProvider) {
    final isTamil = langProvider.showTamil;
    final steps = [
      {
        'icon': Icons.camera_alt_outlined,
        'color': Colors.blue.shade600,
        'title': isTamil
            ? '1. புகைப்படம் சேர்க்கவும் (5 வரை)'
            : '1. Add Photos (up to 5)',
        'desc': isTamil
            ? 'புதிய காய்கறி, பழம் அல்லது பொருளின் தெளிவான படம் எடுக்கவும். பல படங்கள் சேர்க்கலாம்.'
            : 'Take clear photos of your fresh produce or product. You can add multiple photos.'
      },
      {
        'icon': Icons.eco_outlined,
        'color': Colors.green.shade700,
        'title': isTamil ? '2. பொருள் பெயர்' : '2. Product Name',
        'desc': isTamil
            ? 'பொருளின் சரியான பெயர் எழுதவும் (அதிகபட்சம் 3 வார்த்தைகள்). எ.கா: புதிய தக்காளி, நாட்டு கோழி முட்டை.'
            : 'Write the product name (max 3 words). e.g., Fresh Tomatoes, Country Eggs.'
      },
      {
        'icon': Icons.currency_rupee,
        'color': Colors.orange.shade600,
        'title': isTamil ? '3. விலை & அளவு' : '3. Price & Unit',
        'desc': isTamil
            ? 'ஒரு யூனிட்டிற்கான விலை குறிப்பிடவும். கிலோ / லிட்டர் / எண்ணிக்கை / கட்டு என அளவை தேர்வு செய்யவும்.'
            : 'Enter price per unit. Select unit type: kg, litre, piece, bunch, etc.'
      },
      {
        'icon': Icons.category_outlined,
        'color': Colors.teal.shade600,
        'title': isTamil ? '4. வகை தேர்வு' : '4. Select Category',
        'desc': isTamil
            ? 'காய்கறி, பழம், தானியம், பால் பொருட்கள் என சரியான வகையை தேர்வு செய்யவும்.'
            : 'Choose the right category: Vegetables, Fruits, Grains, Dairy, Spices, etc.'
      },
      {
        'icon': Icons.description_outlined,
        'color': Colors.purple.shade600,
        'title': isTamil ? '5. விவரம் எழுதவும்' : '5. Add Description',
        'desc': isTamil
            ? 'பொருளின் தரம், அளவு, அறுவடை நேரம் போன்ற விவரங்கள் எழுதவும். குரல் பொத்தானை பயன்படுத்தலாம்.'
            : 'Describe quality, quantity, harvest date. Use the mic button to speak in Tamil.'
      },
      {
        'icon': Icons.location_on_outlined,
        'color': Colors.red.shade600,
        'title': isTamil ? '6. தொலைபேசி & இடம்' : '6. Phone & Location',
        'desc': isTamil
            ? 'தொடர்பு எண் மற்றும் கிராமம்/நகர பெயர் உள்ளிடவும். GPS பொத்தான் அழுத்தி இடம் கண்டுபிடிக்கலாம்.'
            : 'Enter contact number and village/town. Tap GPS icon to auto-detect location.'
      },
      {
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF2E7D32),
        'title': isTamil ? '7. சமர்ப்பிக்கவும்' : '7. Submit for Approval',
        'desc': isTamil
            ? '"ஒப்புதலுக்கு சமர்ப்பிக்கவும்" அழுத்தவும். நிர்வாகி ஒப்புதல் அளித்தவுடன் வாங்குவோர் தொடர்பு கொள்வார்கள்.'
            : 'Tap "Submit". Buyers will contact you directly after admin approves your post.'
      },
    ];
    _showGuideSheet(
        langProvider,
        steps,
        isTamil
            ? 'விவசாய பொருள் விற்பது எப்படி?'
            : 'How to Sell Farm Products?',
        isTamil
            ? '7 எளிய படிகளில் பொருளை பட்டியலிடவும்'
            : 'List your farm product in 7 easy steps',
        isTamil
            ? 'குறிப்பு: ஒரு நாளில் 3 இலவச பதிவுகள் சமர்ப்பிக்கலாம். இயற்கை பொருட்களுக்கு "Organic" வகை தேர்வு செய்யவும்.'
            : 'Tip: 3 free posts per day. Select "Organic" category for natural farm products.');
  }

  void _showGuideSheet(
      LanguageProvider langProvider,
      List<Map<String, dynamic>> steps,
      String title,
      String subtitle,
      String tip) {
    const accentColor = Color(0xFF2E7D32);
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
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lightbulb_outline,
                          color: accentColor, size: 22)),
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
    return ShowCaseWidget(
      builder: (showcaseCtx) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _startPostTourIfNeeded(showcaseCtx));
        return _buildFarmerPostScaffold();
      },
    );
  }

  Widget _buildFarmerPostScaffold() {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Leaving mid-tour lets the showcase overlay try to find a
            // target that's no longer in the tree ("inactive element"
            // crash) — dismiss it first.
            try {
              ShowCaseWidget.of(context).dismiss();
            } catch (_) {}
            Navigator.of(context).pop();
          },
        ),
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
        child: SingleChildScrollView(
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
                _buildLabel(
                    langProvider.getText('Product Name *', 'பொருள் பெயர் *')),
                const SizedBox(height: 6),
                Showcase(
                  key: _tourNameKey,
                  title: langProvider.getText('Product Name', 'பொருள் பெயர்'),
                  description: langProvider.getText(
                      'Write a short, clear name — e.g. Fresh Tomatoes.',
                      'ஒரு சிறிய, தெளிவான பெயர் எழுதவும் — எ.கா. புதிய தக்காளி.'),
                  tooltipBackgroundColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  titleTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
                  child: TextFormField(
                    controller: _titleController,
                    maxLength: 200,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      langProvider.getText(
                          'e.g., Fresh Tomatoes', 'எ.கா., புதிய தக்காளி'),
                    ).copyWith(
                        suffixIcon:
                            VoiceInputButton(controller: _titleController)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return langProvider.getText(
                            'Product name is required', 'பொருள் பெயர் தேவை');
                      }
                      if (value.trim().length < 3) {
                        return langProvider.getText(
                            'Must be at least 3 characters',
                            'குறைந்தது 3 எழுத்துகள் தேவை');
                      }
                      if (value.trim().split(RegExp(r'\s+')).length > 3) {
                        return langProvider.getText('Title max 3 words',
                            '\u0BA4\u0BB2\u0BC8\u0BAA\u0BCD\u0BAA\u0BC1 \u0B85\u0BA4\u0BBF\u0B95\u0BAA\u0B9F\u0BCD\u0B9A\u0BAE\u0BCD 3 \u0BB5\u0BBE\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BC8\u0B95\u0BB3\u0BCD');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                _buildLabel(langProvider.getText('Description *', 'விவரம் *')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: _inputDecoration(
                    langProvider.getText('Describe your product...',
                        'உங்கள் பொருளை விவரிக்கவும்...'),
                  ).copyWith(
                    suffixIcon:
                        VoiceInputButton(controller: _descriptionController),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return langProvider.getText(
                          'Description is required', 'விவரம் தேவை');
                    }
                    if (value.trim().length < 10) {
                      return langProvider.getText(
                          'Description must be at least 10 characters',
                          'விவரம் குறைந்தது 10 எழுத்துகள் இருக்க வேண்டும்');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Price & Unit row
                _buildLabel(langProvider.getText(
                    'Price per unit *', 'ஒரு யூனிட் விலை *')),
                const SizedBox(height: 6),
                Showcase(
                  key: _tourPriceKey,
                  title: langProvider.getText('Price', 'விலை'),
                  description: langProvider.getText(
                      'Enter the price per unit and pick the unit — kg, litre, piece, etc.',
                      'ஒரு யூனிட் விலையை உள்ளிட்டு, யூனிட் வகையைத் தேர்வு செய்யவும் — கிலோ, லிட்டர், எண்ணிக்கை.'),
                  tooltipBackgroundColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  titleTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g., 50').copyWith(
                            prefixText: '\u20B9 ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return langProvider.getText(
                                  'Price is required', 'விலை தேவை');
                            }
                            final price = double.tryParse(value.trim());
                            if (price == null) {
                              return langProvider.getText('Enter a valid price',
                                  'சரியான விலையை உள்ளிடவும்');
                            }
                            if (price <= 0) {
                              return langProvider.getText(
                                  'Price must be greater than 0',
                                  'விலை 0-ஐ விட அதிகமாக இருக்க வேண்டும்');
                            }
                            if (price > 10000000) {
                              return langProvider.getText(
                                  'Price cannot exceed \u20B91,00,00,000',
                                  'விலை \u20B91,00,00,000 மிகாமல் இருக்க வேண்டும்');
                            }
                            return null;
                          },
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
                              child: Text(langProvider.getText(
                                  unit, _unitTamil[unit] ?? unit)),
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
                ),
                const SizedBox(height: 12),

                // Category
                _buildLabel(langProvider.getText('Category *', 'வகை *')),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration(
                    langProvider.getText(
                        'Select category', 'வகையைத் தேர்ந்தெடுக்கவும்'),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(langProvider.getText(
                          cat, _categoryTamil[cat] ?? cat)),
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
                _buildLabel(
                    langProvider.getText('Phone Number *', 'தொலைபேசி எண் *')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDecoration(
                    langProvider.getText(
                        FormValidators.mobileExample, 'எ.கா., 9876543210'),
                  ).copyWith(
                    prefixIcon: const Icon(Icons.phone,
                        size: 20, color: Color(0xFF2E7D32)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return langProvider.getText(
                          'Phone number is required', 'தொலைபேசி எண் தேவை');
                    }
                    if (value.trim().length != 10) {
                      return langProvider.getText(
                          'Enter valid 10-digit mobile number',
                          'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்');
                    }
                    if (!FormValidators.isValidIndianMobile(value)) {
                      return langProvider.getText(
                          'Must start with 6, 7, 8 or 9',
                          '6, 7, 8 அல்லது 9 இல் தொடங்க வேண்டும்');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Location
                _buildLabel('Location *'),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LocationAutocompleteField(
                        controller: _locationController,
                        hintText: 'e.g., Your Village, District',
                        accentColor: const Color(0xFF2E7D32),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return langProvider.getText(
                                'Location is required', 'இடம் தேவை');
                          }
                          if (value.trim().length < 3) {
                            return langProvider.getText(
                                'Enter a valid location',
                                'சரியான இடத்தை உள்ளிடவும்');
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location,
                          color: Color(0xFF2E7D32)),
                      onPressed: _getLocation,
                      tooltip: 'Use current location',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                Showcase(
                  key: _tourSubmitKey,
                  title: langProvider.getText(
                      'Submit for Approval', 'ஒப்புதலுக்கு சமர்ப்பிக்கவும்'),
                  description: langProvider.getText(
                      'Once every field above is filled, tap here. An admin will approve it before buyers can see it.',
                      'மேலே உள்ள அனைத்தையும் நிரப்பிய பின் இங்கே தட்டவும். நிர்வாகி ஒப்புதல் அளித்தவுடன் வாங்குவோர் காணலாம்.'),
                  tooltipBackgroundColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  titleTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
                  // No onTargetClick here on purpose: the form is still empty
                  // during the tour, so a real submit would just show
                  // validation errors. Tapping simply finishes the tour.
                  child: SizedBox(
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
                              langProvider.getText('Submit for Approval',
                                  'ஒப்புதலுக்கு சமர்ப்பிக்கவும்'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
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
            _buildLabel(
                langProvider.getText('Product Photos', 'பொருள் புகைப்படங்கள்')),
            const SizedBox(width: 8),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: TextStyle(
                fontSize: 13,
                color: _selectedImages.length >= _maxImages
                    ? Colors.orange
                    : Colors.grey[500],
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
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      // Index badge
                      if (_selectedImages.length > 1)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              // Add button
              if (_selectedImages.length < _maxImages)
                Showcase(
                  key: _tourPhotosKey,
                  title:
                      langProvider.getText('Add Photos', 'புகைப்படம் சேர்க்க'),
                  description: langProvider.getText(
                      'Take or pick up to 5 clear photos of your product.',
                      'உங்கள் பொருளின் 5 வரை தெளிவான புகைப்படங்களை எடுக்கவும்.'),
                  tooltipBackgroundColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  titleTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  descTextStyle: const TextStyle(fontSize: 12, height: 1.5),
                  // Otherwise the tour overlay swallows the tap and just
                  // advances instead of opening the photo picker
                  onTargetClick: _showImageSourceDialog,
                  disposeOnTap: true,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 6),
                          Text(
                            langProvider.getText('Add Photo', 'புகைப்படம்'),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
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
