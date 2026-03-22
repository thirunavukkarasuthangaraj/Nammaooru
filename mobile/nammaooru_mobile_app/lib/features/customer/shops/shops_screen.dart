import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/shop_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/shop_api_service.dart';
import '../screens/shop_details_screen.dart';
import '../screens/shop_details_modern_screen.dart';

class ShopsScreen extends StatefulWidget {
  final String? category;
  final double? latitude;
  final double? longitude;

  const ShopsScreen({
    super.key,
    this.category,
    this.latitude,
    this.longitude,
  });

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _shopApi = ShopApiService();
  
  List<dynamic> _shops = [];
  List<dynamic> _filteredShops = [];
  bool _isLoading = true;
  String _sortBy = 'name';
  String? _selectedSubCategory;
  bool _openNowOnly = false;
  double _maxDistance = 10.0;
  double _minRating = 0.0;
  int _currentPage = 0;
  bool _hasMoreData = true;

  static const List<Map<String, String>> _subCategories = [
    {'key': '', 'label': '🏪 அனைத்தும்', 'value': 'All'},
    {'key': 'grocery', 'label': '🥬 மளிகை', 'value': 'Grocery'},
    {'key': 'medical', 'label': '💊 மருந்து', 'value': 'Medical'},
    {'key': 'electronics', 'label': '📱 இலத்திரனியல்', 'value': 'Electronics'},
    {'key': 'clothing', 'label': '👕 ஆடை', 'value': 'Clothing'},
    {'key': 'food', 'label': '🍴 உணவு', 'value': 'Food'},
    {'key': 'bakery', 'label': '🍞 பேக்கரி', 'value': 'Bakery'},
    {'key': 'dairy', 'label': '🥛 பால்', 'value': 'Dairy'},
    {'key': 'hardware', 'label': '🔧 ஹார்ட்வேர்', 'value': 'Hardware'},
    {'key': 'beauty', 'label': '💄 அழகு', 'value': 'Beauty'},
    {'key': 'furniture', 'label': '🛋️ தளவாடம்', 'value': 'Furniture'},
    {'key': 'stationary', 'label': '📚 பேனா/புத்தகம்', 'value': 'Stationery'},
    {'key': 'jewellery', 'label': '💍 நகை', 'value': 'Jewellery'},
    {'key': 'vehicle', 'label': '🏍️ வாகனம்', 'value': 'Vehicle'},
    {'key': 'agriculture', 'label': '🌾 விவசாயம்', 'value': 'Agriculture'},
    {'key': 'services', 'label': '🔨 சேவை', 'value': 'Services'},
  ];

  @override
  void initState() {
    super.initState();
    _loadShops();
    _searchController.addListener(_filterShops);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _shopApi.getActiveShops(
        page: 0,
        size: 20,
        sortBy: _sortBy,
        category: widget.category,
        city: 'Chennai', // TODO: Get from user location
      );
      
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        setState(() {
          _shops = response['data']['content'] ?? [];
          _filteredShops = List.from(_shops);
          _hasMoreData = !response['data']['last'];
          _applySortAndFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load shops', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _filterShops() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredShops = _shops.where((shop) {
        final shopName = shop['name']?.toString().toLowerCase() ?? '';
        final shopDescription = shop['description']?.toString().toLowerCase() ?? '';
        final shopCategory = shop['businessType']?.toString().toLowerCase() ?? '';
        final shopRating = double.tryParse(shop['averageRating']?.toString() ?? '0') ?? 0.0;
        final shopIsActive = shop['isActive'] ?? true;

        final matchesSearch = shopName.contains(query) ||
            shopDescription.contains(query) ||
            shopCategory.contains(query);

        final matchesRating = shopRating >= _minRating;
        final matchesOpenNow = !_openNowOnly || shopIsActive;
        final matchesSubCategory = _selectedSubCategory == null ||
            _selectedSubCategory!.isEmpty ||
            shopCategory.contains(_selectedSubCategory!.toLowerCase());

        return matchesSearch && matchesRating && matchesOpenNow && matchesSubCategory;
      }).toList();

      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _filteredShops.sort((a, b) {
            final aRating = double.tryParse(a['averageRating']?.toString() ?? '0') ?? 0.0;
            final bRating = double.tryParse(b['averageRating']?.toString() ?? '0') ?? 0.0;
            return bRating.compareTo(aRating);
          });
          break;
        case 'name':
          _filteredShops.sort((a, b) {
            final aName = a['name']?.toString() ?? '';
            final bName = b['name']?.toString() ?? '';
            return aName.compareTo(bName);
          });
          break;
        default:
          // Keep original order for other sorts
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Text('🏪 ', style: TextStyle(fontSize: 28)),
            Text(
              widget.category ?? loc?.nearbyShops ?? 'அருகிலுள்ள கடைகள் / Nearby Shops',
              style: VillageTheme.headingMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white, size: VillageTheme.iconLarge),
        actions: [
          Container(
            margin: EdgeInsets.only(right: VillageTheme.spacingS),
            child: IconButton(
              icon: Icon(Icons.tune, size: VillageTheme.iconLarge),
              onPressed: _showFilterBottomSheet,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSubCategoryChips(),
          _buildSortingChips(),
          Expanded(
            child: _isLoading ? const LoadingWidget() : _buildShopsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(VillageTheme.spacingM),
      child: Container(
        decoration: VillageTheme.cardDecoration.copyWith(
          boxShadow: VillageTheme.cardShadow,
        ),
        child: TextField(
          controller: _searchController,
          style: VillageTheme.bodyLarge,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: '🔍 ${loc?.search ?? "தேடல் / Search"} கடைகளை...',
            hintStyle: VillageTheme.bodyMedium.copyWith(color: VillageTheme.hintText),
            prefixIcon: Icon(
              Icons.search,
              size: VillageTheme.iconLarge,
              color: VillageTheme.primaryGreen,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: VillageTheme.iconMedium,
                      color: VillageTheme.secondaryText,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : IconButton(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📍 ', style: TextStyle(fontSize: 18)),
                        Icon(
                          Icons.my_location,
                          size: VillageTheme.iconMedium,
                          color: VillageTheme.accentOrange,
                        ),
                      ],
                    ),
                    onPressed: () {
                      // TODO: Use current location
                    },
                  ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: VillageTheme.spacingM,
              vertical: VillageTheme.spacingM,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subCategories.length,
        itemBuilder: (context, index) {
          final cat = _subCategories[index];
          final key = cat['key']!;
          final isSelected = (_selectedSubCategory ?? '') == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubCategory = key;
                });
                _filterShops();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? VillageTheme.accentOrange : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? VillageTheme.accentOrange
                        : Colors.grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: VillageTheme.accentOrange.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : VillageTheme.primaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortingChips() {
    final loc = AppLocalizations.of(context);
    final sortOptions = [
      {'key': 'name', 'label': '🔤 பெயர் / Name', 'icon': Icons.sort_by_alpha},
      {'key': 'rating', 'label': '⭐ ரேடிங் / Rating', 'icon': Icons.star},
      {'key': 'latest', 'label': '🕰️ புதிய / Latest', 'icon': Icons.access_time},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = _sortBy == option['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: VillageTheme.spacingS),
            child: Container(
              height: 48,
              child: FilterChip(
                label: Text(
                  option['label']! as String,
                  style: VillageTheme.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : VillageTheme.primaryText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _sortBy = option['key']! as String;
                    _applySortAndFilter();
                  });
                },
                backgroundColor: VillageTheme.cardBackground,
                selectedColor: VillageTheme.primaryGreen,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
                  side: BorderSide(
                    color: isSelected ? VillageTheme.primaryGreen : VillageTheme.primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: VillageTheme.spacingM,
                  vertical: VillageTheme.spacingS,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopsList() {
    if (_filteredShops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VillageTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(VillageTheme.cardRadius * 2),
                ),
                child: Center(
                  child: Text('🏪', style: TextStyle(fontSize: 60)),
                ),
              ),
              SizedBox(height: VillageTheme.spacingL),
              Text(
                'கடைகள் இல்லை\nNo Shops Found',
                style: VillageTheme.headingMedium.copyWith(
                  color: VillageTheme.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: VillageTheme.spacingM),
              Text(
                'தேடல் அல்லது ஆப்ஷன்களை மாற்றி மீண்டும் முயலவும்\nTry adjusting your search or filters',
                style: VillageTheme.bodyMedium.copyWith(
                  color: VillageTheme.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on screen width
        int crossAxisCount = 2; // Default for mobile
        double childAspectRatio = 0.65; // Taller cards to fit more info

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4; // Desktop
          childAspectRatio = 0.7;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3; // Tablet
          childAspectRatio = 0.68;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2; // Large phone
          childAspectRatio = 0.65;
        }

        return RefreshIndicator(
          onRefresh: () async => _loadShops(),
          color: VillageTheme.primaryGreen,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(VillageTheme.spacingM),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: VillageTheme.spacingM,
              crossAxisSpacing: VillageTheme.spacingM,
            ),
            itemCount: _filteredShops.length,
            itemBuilder: (context, index) {
              return _buildModernShopCard(_filteredShops[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildModernShopCard(Map<String, dynamic> shop) {
    final shopName = shop['name']?.toString() ?? 'Shop';
    final shopDescription = shop['description']?.toString() ?? 'No description available';
    final businessType = shop['businessType']?.toString() ?? 'Store';
    final rating = double.tryParse(shop['averageRating']?.toString() ?? '4.0') ?? 4.0;
    final isActive = shop['isActive'] ?? true;
    final shopId = shop['id']?.toString() ?? '1';
    final address = shop['addressLine1']?.toString() ?? 'Address not available';
    final city = shop['city']?.toString() ?? '';
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;
    
    // Get business type emoji
    String getBusinessEmoji(String type) {
      switch (type.toLowerCase()) {
        case 'grocery':
        case 'groceries':
          return '🥬';
        case 'medical':
        case 'pharmacy':
          return '💊';
        case 'electronics':
          return '📱';
        case 'clothing':
        case 'fashion':
          return '👕';
        case 'food':
        case 'restaurant':
          return '🍴';
        case 'services':
          return '🔧';
        default:
          return '🏪';
      }
    }
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToShop(shop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Shop Image with Status Overlay
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 140, // Fixed height for consistency
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: shop['images'] != null && (shop['images'] as List).isNotEmpty
                          ? shop['images'][0]
                          : 'https://via.placeholder.com/400x200',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        child: Center(
                          child: Text(getBusinessEmoji(businessType), style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        child: Center(
                          child: Text(getBusinessEmoji(businessType), style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
                    // Compact Status & Rating Row
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('⭐', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Color(0xFF4CAF50) : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'திறந்து' : 'மூடி',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Compact Shop Details Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shop Name with Emoji (Single Line)
                  Row(
                    children: [
                      Text(
                        getBusinessEmoji(businessType),
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shopName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Business Type (Single Line)
                  Text(
                    businessType,
                    style: TextStyle(
                      fontSize: 11,
                      color: VillageTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // Description (2 Lines Max)
                  Text(
                    shopDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: VillageTheme.secondaryText,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Location Row (Single Line)
                  Row(
                    children: [
                      Text('📍', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fullAddress,
                          style: TextStyle(
                            fontSize: 11,
                            color: VillageTheme.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Divider
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  SizedBox(height: 6),

                  // Reviews + Delivery row
                  Row(
                    children: [
                      if (shop['reviewCount'] != null || shop['totalReviews'] != null) ...[
                        Icon(Icons.reviews_outlined, size: 11, color: VillageTheme.secondaryText),
                        SizedBox(width: 3),
                        Text(
                          '${shop['reviewCount'] ?? shop['totalReviews'] ?? 0} reviews',
                          style: TextStyle(fontSize: 10, color: VillageTheme.secondaryText),
                        ),
                        SizedBox(width: 8),
                      ],
                      if (shop['deliveryAvailable'] == true || shop['hasDelivery'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delivery_dining, size: 10, color: Colors.blue),
                              SizedBox(width: 3),
                              Text('Delivery', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 10, color: VillageTheme.accentOrange),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Call + WhatsApp buttons
                  Builder(builder: (context) {
                    final phone = (shop['phoneNumber'] ?? shop['phone'] ?? '').toString();
                    if (phone.isEmpty) return SizedBox.shrink();
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _callShop(phone),
                            icon: Icon(Icons.call, size: 14, color: VillageTheme.primaryGreen),
                            label: Text('Call', style: TextStyle(fontSize: 12, color: VillageTheme.primaryGreen, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              side: BorderSide(color: VillageTheme.primaryGreen.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _whatsappShop(shop, phone),
                            icon: Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                            label: Text('WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFF25D366), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              side: BorderSide(color: Color(0xFF25D366).withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callShop(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    await launchUrl(Uri.parse('tel:$clean'), mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsappShop(Map<String, dynamic> shop, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    final name = shop['name'] ?? 'Shop';
    final msg = Uri.encodeComponent('Hi, I found your shop "$name" on NammaOoru app. I would like to know more.');
    await launchUrl(Uri.parse('https://wa.me/91$clean?text=$msg'), mode: LaunchMode.externalApplication);
  }

  void _navigateToShop(Map<String, dynamic> shop) {
    final shopId = shop['id'] ?? 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailsModernScreen(shopId: shopId),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VillageTheme.cardRadius * 2),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(VillageTheme.spacingL),
            decoration: BoxDecoration(
              color: VillageTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(VillageTheme.cardRadius * 2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text('🔍 ', style: TextStyle(fontSize: 24)),
                    Text(
                      'ஆப்ஷன்கள் / Filters',
                      style: VillageTheme.headingMedium,
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: VillageTheme.secondaryText),
                    ),
                  ],
                ),
                SizedBox(height: VillageTheme.spacingL),
                
                // Open Now Filter
                Container(
                  decoration: VillageTheme.cardDecoration,
                  child: CheckboxListTile(
                    title: Row(
                      children: [
                        Text('✅ ', style: TextStyle(fontSize: 18)),
                        Text(
                          'இப்போது திறந்து உள்ளது / Open Now',
                          style: VillageTheme.bodyLarge,
                        ),
                      ],
                    ),
                    value: _openNowOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _openNowOnly = value ?? false;
                      });
                    },
                    activeColor: VillageTheme.primaryGreen,
                  ),
                ),
                SizedBox(height: VillageTheme.spacingM),
                
                // Distance Filter
                Container(
                  padding: EdgeInsets.all(VillageTheme.spacingM),
                  decoration: VillageTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('📍 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'அதிகபட்ச தூரம் / Maximum Distance',
                            style: VillageTheme.bodyLarge,
                          ),
                        ],
                      ),
                      SizedBox(height: VillageTheme.spacingS),
                      Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${_maxDistance.toStringAsFixed(0)} கி.மீ / km',
                        onChanged: (value) {
                          setModalState(() {
                            _maxDistance = value;
                          });
                        },
                        activeColor: VillageTheme.primaryGreen,
                        inactiveColor: VillageTheme.surfaceColor,
                      ),
                      Text(
                        '${_maxDistance.toStringAsFixed(0)} கி.மீ வரை',
                        style: VillageTheme.bodyMedium.copyWith(
                          color: VillageTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: VillageTheme.spacingM),
                
                // Rating Filter
                Container(
                  padding: EdgeInsets.all(VillageTheme.spacingM),
                  decoration: VillageTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('⭐ ', style: TextStyle(fontSize: 18)),
                          Text(
                            'குறைந்த ரேடிங் / Minimum Rating',
                            style: VillageTheme.bodyLarge,
                          ),
                        ],
                      ),
                      SizedBox(height: VillageTheme.spacingS),
                      Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: '${_minRating.toStringAsFixed(1)} ⭐',
                        onChanged: (value) {
                          setModalState(() {
                            _minRating = value;
                          });
                        },
                        activeColor: VillageTheme.warningOrange,
                        inactiveColor: VillageTheme.surfaceColor,
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 20,
                            color: index < _minRating ? VillageTheme.warningOrange : VillageTheme.hintText,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: VillageTheme.spacingXL),
                
                // Apply Button
                VillageWidgets.bigButton(
                  text: 'ஆப்ஷன்களை பயன்படுத்து / Apply Filters',
                  icon: Icons.check,
                  onPressed: () {
                    Navigator.pop(context);
                    _filterShops();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}