import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
import 'shop_details_screen.dart';

class ShopListingScreen extends StatefulWidget {
  final String? category;
  final String? categoryTitle;

  const ShopListingScreen({
    super.key,
    this.category,
    this.categoryTitle,
  });

  @override
  State<ShopListingScreen> createState() => _ShopListingScreenState();
}

class _ShopListingScreenState extends State<ShopListingScreen> {
  final ShopApiService _shopApi = ShopApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _shops = [];
  List<dynamic> _filteredShops = [];
  bool _isLoading = true;
  String _sortBy = 'name';
  bool _openNowOnly = false;
  double _maxDistance = 10.0;
  double _minRating = 0.0;

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
        category: widget.category, // Keep category filter
        // City filter removed
        // city: 'Chennai',
      );

      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        setState(() {
          _shops = response['data']['content'] ?? [];
          _filteredShops = List.from(_shops);
          _applySortAndFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load shops: $e', isError: true);
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
        final shopRating = (shop['rating'] ?? 0).toDouble();
        // Use isOpenNow from business hours API, fallback to isActive if not available
        final shopIsOpenNow = shop['isOpenNow'] ?? shop['isActive'] ?? false;

        final matchesSearch = shopName.contains(query) ||
            shopDescription.contains(query) ||
            shopCategory.contains(query);

        final matchesRating = shopRating >= _minRating;
        final matchesOpenNow = !_openNowOnly || shopIsOpenNow;

        return matchesSearch && matchesRating && matchesOpenNow;
      }).toList();

      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _filteredShops.sort((a, b) {
            final aRating = (a['rating'] ?? 0).toDouble();
            final bRating = (b['rating'] ?? 0).toDouble();
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
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle ?? 'Grocery',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildVillageSearchBar(),
          _buildVillageSortingChips(),
          Expanded(
            child: _isLoading ? const LoadingWidget() : _buildVillageShopsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageSearchBar() {
    return Container(
      color: const Color(0xFF4CAF50),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'கடை தேடுங்கள் / Search shops...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search,
              size: 22,
              color: Colors.grey,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterShops();
                    },
                  )
                : const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Color(0xFFFF9800),
                ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVillageSortingChips() {
    final sortOptions = [
      {'key': 'name', 'label': 'பெயர் / Name', 'icon': Icons.sort_by_alpha},
      {'key': 'rating', 'label': 'ரேடிங் / Rating', 'icon': Icons.star},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: sortOptions.map((option) {
          final isSelected = _sortBy == option['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                option['label']! as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sortBy = option['key']! as String;
                  _applySortAndFilter();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVillageShopsList() {
    if (_filteredShops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Icon(
                    Icons.store_outlined,
                    size: 50,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Shops Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShops,
      color: const Color(0xFF4CAF50),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          return _buildVillageShopCard(_filteredShops[index]);
        },
      ),
    );
  }

  Widget _buildVillageShopCard(Map<String, dynamic> shop) {
    final shopName = shop['name']?.toString() ?? 'Shop';
    final shopDescription = shop['description']?.toString() ?? '';
    final businessType = shop['businessType']?.toString() ?? 'Store';
    final rating = double.tryParse(shop['averageRating']?.toString() ?? '0.0') ?? 0.0;
    // Use isOpenNow from business hours API for real-time status
    final isOpenNow = shop['isOpenNow'] ?? shop['isActive'] ?? false;
    final address = shop['addressLine1']?.toString() ?? '';
    final city = shop['city']?.toString() ?? '';
    final fullAddress = address.isNotEmpty && city.isNotEmpty
        ? '$address, $city'
        : (city.isNotEmpty ? city : 'Address not available');

    // Get business type emoji with more variety
    String getBusinessEmoji(String type) {
      switch (type.toLowerCase()) {
        case 'grocery':
        case 'groceries':
          return '🛒';
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
          return '🍽️';
        case 'services':
          return '🔧';
        case 'beauty':
        case 'salon':
          return '💄';
        case 'hardware':
          return '🔨';
        case 'books':
        case 'stationery':
          return '📚';
        default:
          return '🏪';
      }
    }

    // Get dynamic gradient colors based on business type
    List<Color> getBusinessGradient(String type) {
      switch (type.toLowerCase()) {
        case 'grocery':
        case 'groceries':
          return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
        case 'medical':
        case 'pharmacy':
          return [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
        case 'electronics':
          return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
        case 'clothing':
        case 'fashion':
          return [const Color(0xFFE91E63), const Color(0xFFF06292)];
        case 'food':
        case 'restaurant':
          return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
        case 'beauty':
        case 'salon':
          return [const Color(0xFFE91E63), const Color(0xFFF8BBD9)];
        default:
          return [const Color(0xFF607D8B), const Color(0xFF90A4AE)];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _navigateToShop(shop),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Shop Logo or Business Icon
                _buildShopLogo(shop, businessType, getBusinessGradient, getBusinessEmoji),

                const SizedBox(width: 16),

                // Shop Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Name Row with Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Indicator - Real-time Business Hours
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOpenNow
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5252),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpenNow ? 'திறந்து' : 'மூடியது',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Business Type with Rating
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getBusinessGradient(businessType)[0].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              businessType,
                              style: TextStyle(
                                color: getBusinessGradient(businessType)[0],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (rating > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⭐', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF8F00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Address with Location Icon
                      if (fullAddress.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fullAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToShop(Map<String, dynamic> shop) {
    final shopId = shop['id'] ?? 1;
    final shopName = shop['name'] ?? 'Shop';

    // Show modern shop details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailsScreen(
          shopId: shopId,
          shop: shop,
        ),
      ),
    );
  }

  /// Extract logo URL from shop images
  String? _getShopLogoUrl(Map<String, dynamic> shop) {
    final images = shop['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return null;

    // Find LOGO type first, then primary, then first image
    var logo = images.firstWhere(
      (img) => img['imageType'] == 'LOGO',
      orElse: () => images.firstWhere(
        (img) => img['isPrimary'] == true,
        orElse: () => images.isNotEmpty ? images.first : null,
      ),
    );

    return logo?['imageUrl'];
  }

  /// Build shop logo widget with fallback to emoji icon
  Widget _buildShopLogo(
    Map<String, dynamic> shop,
    String businessType,
    List<Color> Function(String) getBusinessGradient,
    String Function(String) getBusinessEmoji,
  ) {
    final logoUrl = _getShopLogoUrl(shop);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: getBusinessGradient(businessType),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: getBusinessGradient(businessType)[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: ImageUrlHelper.getFullImageUrl(logoUrl),
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: Text(
                    getBusinessEmoji(businessType),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    getBusinessEmoji(businessType),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              )
            : Center(
                child: Text(
                  getBusinessEmoji(businessType),
                  style: const TextStyle(fontSize: 36),
                ),
              ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF2E7D32),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ஆப்ஷன்கள் / Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Open Now Filter - Improved Design
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setModalState(() {
                        _openNowOnly = !_openNowOnly;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _openNowOnly
                            ? const Color(0xFF2E7D32).withOpacity(0.08)
                            : Colors.grey[50],
                        border: Border.all(
                          color: _openNowOnly
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _openNowOnly
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _openNowOnly ? Icons.store : Icons.store_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'இப்போது திறந்து உள்ளது',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Open Now',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _openNowOnly
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: _openNowOnly
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                            ),
                            child: _openNowOnly
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Apply Button - Enhanced
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterShops();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ஆப்ஷன்களை பயன்படுத்து / Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}