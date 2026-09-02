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
import '../services/marketplace_service.dart';
import '../widgets/post_payment_handler.dart';
import '../widgets/voice_input_button.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';

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
  bool _wantsBanner = false;
  int? _paidTokenId;
  double? _latitude;
  double? _longitude;
  bool _hasShownTour = false;

  final List<String> _categories = [
    'Electronics',
    'Mobile & Tablets',
    'Furniture',
    'Vehicles',
    'Two Wheelers',
    'Four Wheelers',
    'Clothing',
    'Books',
    'Home Appliances',
    'Tools & Equipment',
    'Sports & Hobbies',
    'Rent',
    'Other',
  ];

  static const Map<String, String> _categoryTamil = {
    'Electronics': 'எலக்ட்ரானிக்ஸ்',
    'Mobile & Tablets': 'மொபைல் & டேப்லெட்',
    'Furniture': 'மரச்சாமான்',
    'Vehicles': 'வாகனங்கள்',
    'Two Wheelers': 'இருசக்கர வாகனம்',
    'Four Wheelers': 'நான்கு சக்கர வாகனம்',
    'Clothing': 'ஆடைகள்',
    'Books': 'புத்தகங்கள்',
    'Home Appliances': 'வீட்டு உபகரணங்கள்',
    'Tools & Equipment': 'கருவிகள் & உபகரணங்கள்',
    'Sports & Hobbies': 'விளையாட்டு & பொழுதுபோக்கு',
    'Rent': 'வாடகை',
    'Other': 'மற்றவை',
  };

  @override
  void initState() {
    super.initState();
    _prefillData();
    _maybeShowFirstTimeTour();
  }

  void _maybeShowFirstTimeTour() {
    final alreadySeen = LocalStorage.getBool('create_post_tour_shown') ?? false;
    if (!alreadySeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasShownTour) return;
        _hasShownTour = true;
        LocalStorage.setBool('create_post_tour_shown', true);
        final langProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        _showHelpGuide(langProvider, isAutoShown: true);
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
    // Pre-fill phone from locally stored user data
    final phone = LocalStorage.getString('phoneNumber');
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = FormValidators.normalizeIndianMobile(phone);
    } else {
      _fetchPhoneFromProfile();
    }

    // Pre-fill location
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      // No maxWidth/maxHeight/imageQuality here — those force image_picker's
      // own native resize into a cache file ("scaled_*.jpg") that races with
      // reads on some OEM builds (Samsung and others), causing
      // PathNotFoundException. ImageCompressor below handles resizing instead.
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final compressed = await ImageCompressor.compressXFile(pickedFile);
        setState(() {
          _selectedImage = File(compressed.path);
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
              title:
                  Text(langProvider.getText('Take Photo', 'புகைப்படம் எடுக்க')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langProvider.getText(
                  'Choose from Gallery', 'கேலரியிலிருந்து தேர்வு செய்க')),
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

    // If user wants banner and no token yet, start payment flow first
    if (_wantsBanner && paidTokenId == null && _paidTokenId == null) {
      _handleBannerPayment();
      return;
    }

    // Use stored token if available (retry after failed post creation)
    final tokenToUse = paidTokenId ?? _paidTokenId;
    final bannerFlag = isBanner || _wantsBanner;

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
        paidTokenId: tokenToUse,
        latitude: _latitude,
        longitude: _longitude,
        isBanner: bannerFlag,
      );

      if (mounted) {
        if (result['success'] == true) {
          _paidTokenId = null; // Clear token after successful post
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

  void _handleBannerPayment() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'MARKETPLACE',
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

  void _handleLimitReached() {
    final handler = PostPaymentHandler(
      context: context,
      postType: 'MARKETPLACE',
      onPaymentSuccess: () {},
      onTokenReceived: (tokenId) {
        _paidTokenId = tokenId; // Store token for retry if post creation fails
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
            const Icon(Icons.check_circle,
                color: VillageTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            Text(
              langProvider.getText(
                  'Post Submitted!', 'பதிவு சமர்ப்பிக்கப்பட்டது!'),
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

  void _showHelpGuide(LanguageProvider langProvider,
      {bool isAutoShown = false}) {
    final isTamil = langProvider.showTamil;

    final steps = [
      {
        'icon': Icons.camera_alt_outlined,
        'color': Colors.blue.shade600,
        'title': isTamil ? '1. புகைப்படம் சேர்க்கவும்' : '1. Add a Photo',
        'desc': isTamil
            ? 'உங்கள் பொருளின் தெளிவான புகைப்படம் எடுக்கவும் அல்லது கேலரியிலிருந்து தேர்வு செய்யவும். நல்ல படம் வேகமாக விற்க உதவும்.'
            : 'Take a clear photo of your item or pick one from gallery. A good photo helps sell faster.',
      },
      {
        'icon': Icons.title,
        'color': Colors.orange.shade600,
        'title': isTamil ? '2. தலைப்பு எழுதவும்' : '2. Write a Title',
        'desc': isTamil
            ? 'உங்கள் பொருளை சுருக்கமாக விவரிக்கும் தலைப்பு எழுதவும் (அதிகபட்சம் 10 வார்த்தைகள்). எ.கா: "டிராக்டர் விற்பனைக்கு"'
            : 'Write a short title describing your item (max 10 words). e.g., "Tractor for Sale"',
      },
      {
        'icon': Icons.description_outlined,
        'color': Colors.purple.shade600,
        'title': isTamil ? '3. விவரம் எழுதவும்' : '3. Add Description',
        'desc': isTamil
            ? 'பொருளின் நிலை, வயது, தரம் போன்ற விவரங்களை தெளிவாக எழுதவும். அதிகபட்சம் 1000 எழுத்துகள் உள்ளிடலாம்.'
            : 'Describe the condition, age, and quality of your item clearly. Up to 1000 characters.',
      },
      {
        'icon': Icons.currency_rupee,
        'color': Colors.green.shade700,
        'title': isTamil ? '4. விலை குறிப்பிடவும்' : '4. Set Your Price',
        'desc': isTamil
            ? 'உங்கள் பொருளுக்கான விலையை ரூபாயில் உள்ளிடவும். சரியான விலை குறிப்பிட்டால் வாங்குபவர்கள் விரைவாக தொடர்பு கொள்வார்கள்.'
            : 'Enter your price in rupees (₹). A fair price attracts buyers faster.',
      },
      {
        'icon': Icons.category_outlined,
        'color': Colors.teal.shade600,
        'title': isTamil ? '5. வகை தேர்வு செய்யவும்' : '5. Choose a Category',
        'desc': isTamil
            ? 'உங்கள் பொருளுக்கு பொருத்தமான வகையை தேர்வு செய்யவும். சரியான வகை தேர்ந்தெடுத்தால் சரியான நபரிடம் பதிவு சென்று சேரும்.'
            : 'Select the right category for your item. This helps the right buyers find your post.',
      },
      {
        'icon': Icons.phone_outlined,
        'color': Colors.indigo.shade600,
        'title':
            isTamil ? '6. தொலைபேசி எண் சேர்க்கவும்' : '6. Add Phone Number',
        'desc': isTamil
            ? 'வாங்குபவர்கள் தொடர்பு கொள்ள உங்கள் 10-இலக்க மொபைல் எண்ணை உள்ளிடவும். இது தானியங்கியாக நிரப்பப்படும்.'
            : 'Enter your 10-digit mobile number so buyers can contact you. It is auto-filled from your profile.',
      },
      {
        'icon': Icons.location_on_outlined,
        'color': Colors.red.shade600,
        'title': isTamil ? '7. இடம் சேர்க்கவும்' : '7. Add Location',
        'desc': isTamil
            ? 'உங்கள் கிராமம் அல்லது நகரம் குறிப்பிடவும். GPS பொத்தானை அழுத்தினால் தானாக இடம் கண்டுபிடிக்கும்.'
            : 'Enter your village or town. Tap the GPS icon to auto-detect your current location.',
      },
      {
        'icon': Icons.star_outlined,
        'color': Colors.amber.shade700,
        'title':
            isTamil ? '8. பேனர் (விருப்பமானது)' : '8. Banner Boost (Optional)',
        'desc': isTamil
            ? '"பேனராக காட்டு" ஐ இயக்கினால் உங்கள் பதிவு பட்டியலின் மேலே காட்டப்படும். இது கட்டணம் செலுத்தும் சேவை.'
            : 'Enable "Feature as Banner" to show your post at the top of listings. This is a paid feature.',
      },
      {
        'icon': Icons.check_circle_outline,
        'color': VillageTheme.primaryGreen,
        'title': isTamil ? '9. சமர்ப்பிக்கவும்' : '9. Submit for Approval',
        'desc': isTamil
            ? '"ஒப்புதலுக்கு சமர்ப்பிக்கவும்" பொத்தானை அழுத்தவும். நிர்வாகி சரிபார்த்த பின் உங்கள் பதிவு தெரியும்.'
            : 'Tap "Submit for Approval". Your post will be visible to others after admin review.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAutoShown
                            ? Icons.waving_hand
                            : Icons.lightbulb_outline,
                        color: VillageTheme.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAutoShown
                                ? (isTamil
                                    ? 'வணக்கம்! முதல்முறை பதிவிடுகிறீர்களா?'
                                    : 'Welcome! First time posting?')
                                : (isTamil
                                    ? 'எப்படி பதிவிட வேண்டும்?'
                                    : 'How to Post an Ad?'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isTamil
                                ? '9 எளிய படிகளில் உங்கள் பதிவை உருவாக்கவும்'
                                : 'Create your listing in 9 easy steps',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // First-time welcome banner
              if (isAutoShown)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        VillageTheme.primaryGreen.withOpacity(0.1),
                        Colors.blue.shade50
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: VillageTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('📸', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isTamil
                              ? 'முதலில் உங்கள் பொருளின் புகைப்படம் சேர்க்கவும் — இது வேகமாக விற்க உதவும்!'
                              : 'Start by adding a clear photo of your item — it helps sell 3x faster!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // Steps list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final step = steps[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (step['color'] as Color).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: (step['color'] as Color).withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (step['color'] as Color).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(step['icon'] as IconData,
                                color: step['color'] as Color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: (step['color'] as Color)
                                        .withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step['desc'] as String,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Bottom tip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isTamil
                            ? 'குறிப்பு: ஒரு நாளில் 3 இலவச பதிவுகள் மட்டுமே சமர்ப்பிக்கலாம். அதிக பதிவுகளுக்கு கட்டணம் உண்டு.'
                            : 'Tip: You can post up to 3 listings per day for free. Additional posts require a small fee.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Got it button (always shown, more prominent when auto-shown)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      isTamil
                          ? 'புரிந்தது! பதிவிடத் தொடங்குவோம்'
                          : 'Got it! Let\'s Start Posting',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Post Ad', 'விளம்பரம் பதிவிட'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip:
                langProvider.getText('How to Post', 'எப்படி பதிவிட வேண்டும்'),
            onPressed: () => _showHelpGuide(langProvider, isAutoShown: false),
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
                _buildLabel(langProvider.getText('Title *', 'தலைப்பு *')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  maxLength: 200,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    langProvider.getText('e.g., Tractor for Sale',
                        'எ.கா., டிராக்டர் விற்பனைக்கு'),
                  ).copyWith(
                      suffixIcon:
                          VoiceInputButton(controller: _titleController)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return langProvider.getText(
                          'Title is required', 'தலைப்பு தேவை');
                    }
                    if (value.trim().length < 3) {
                      return langProvider.getText(
                          'Must be at least 3 characters',
                          'குறைந்தது 3 எழுத்துகள் தேவை');
                    }
                    if (value.trim().split(RegExp(r'\s+')).length > 10) {
                      return langProvider.getText('Title max 10 words',
                          'தலைப்பு அதிகபட்சம் 10 வார்த்தைகள்');
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
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: _inputDecoration(
                    langProvider.getText('Describe your item...',
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

                // Price
                _buildLabel(langProvider.getText('Price *', 'விலை *')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('e.g., 50000').copyWith(
                    prefixText: '\u20B9 ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return langProvider.getText(
                          'Price is required', 'விலை தேவை');
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null) {
                      return langProvider.getText(
                          'Enter a valid price', 'சரியான விலையை உள்ளிடவும்');
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
                      _selectedCategory = value ?? 'Other';
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
                        size: 20, color: VillageTheme.primaryGreen),
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
                        accentColor: VillageTheme.primaryGreen,
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
                          color: VillageTheme.primaryGreen),
                      onPressed: _getLocation,
                      tooltip: 'Use current location',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                              langProvider.getText(
                                  'Feature as Banner', 'பேனராக காட்டு'),
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
                                'பட்டியல்களின் மேலே காட்டு (கட்டணம்)',
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
                            langProvider.getText('Submit for Approval',
                                'ஒப்புதலுக்கு சமர்ப்பிக்கவும்'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
        borderSide:
            const BorderSide(color: VillageTheme.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildImagePicker(LanguageProvider langProvider) {
    final hasImage = _selectedImage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step label
        if (!hasImage)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.looks_one, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  langProvider.getText('Start here — Add Photo',
                      'இங்கிருந்து தொடங்கவும் — படம் சேர்க்கவும்'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasImage ? Colors.black : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? Colors.transparent : Colors.blue.shade400,
                width: hasImage ? 0 : 2,
              ),
            ),
            child: hasImage
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
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                langProvider.getText('Change', 'மாற்றவும்'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_a_photo,
                            size: 36, color: Colors.blue.shade700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        langProvider.getText('Tap to add product photo',
                            'பொருள் புகைப்படம் சேர்க்க தட்டவும்'),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        langProvider.getText('📷 Camera  |  🖼️ Gallery',
                            '📷 கேமரா  |  🖼️ கேலரி'),
                        style: TextStyle(
                            color: Colors.blue.shade400, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        langProvider.getText(
                          'Photos help sell 3x faster!',
                          'புகைப்படம் வேகமாக விற்க உதவும்!',
                        ),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
