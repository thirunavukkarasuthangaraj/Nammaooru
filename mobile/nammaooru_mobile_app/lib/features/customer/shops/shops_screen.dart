import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/shop_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/shop_api_service.dart';
import '../screens/shop_details_screen.dart';

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
  bool _openNowOnly = false;
  double _maxDistance = 10.0;
  double _minRating = 0.0;
  int _currentPage = 0;
  bool _hasMoreData = true;

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

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(VillageTheme.spacingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.2,
        mainAxisSpacing: VillageTheme.spacingM,
      ),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        return _buildVillageShopCard(_filteredShops[index]);
      },
    );
  }

  Widget _buildVillageShopCard(Map<String, dynamic> shop) {
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
    
    return Container(
      decoration: VillageTheme.elevatedCardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        onTap: () => _navigateToShop(shop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Shop Image with Status Overlay
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(VillageTheme.cardRadius),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(VillageTheme.cardRadius),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: shop['images'] != null && (shop['images'] as List).isNotEmpty 
                            ? shop['images'][0] 
                            : 'https://via.placeholder.com/400x200',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: VillageTheme.surfaceColor,
                          child: Center(
                            child: Text(getBusinessEmoji(businessType), style: TextStyle(fontSize: 60)),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: VillageTheme.surfaceColor,
                          child: Center(
                            child: Text(getBusinessEmoji(businessType), style: TextStyle(fontSize: 60)),
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: VillageTheme.spacingS,
                      right: VillageTheme.spacingS,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: VillageTheme.spacingS,
                          vertical: VillageTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? VillageTheme.successGreen : VillageTheme.errorRed,
                          borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
                          boxShadow: VillageTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isActive ? '✅' : '❌',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 2),
                            Text(
                              isActive ? 'திறந்து' : 'மூடியது',
                              style: VillageTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Rating Badge
                    Positioned(
                      top: VillageTheme.spacingS,
                      left: VillageTheme.spacingS,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: VillageTheme.spacingS,
                          vertical: VillageTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: VillageTheme.warningOrange,
                          borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
                          boxShadow: VillageTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: VillageTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Shop Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(VillageTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name with Emoji
                    Row(
                      children: [
                        Text(
                          '${getBusinessEmoji(businessType)} ',
                          style: TextStyle(fontSize: 20),
                        ),
                        Expanded(
                          child: Text(
                            shopName,
                            style: VillageTheme.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: VillageTheme.spacingXS),
                    
                    // Business Type
                    Text(
                      businessType,
                      style: VillageTheme.bodyMedium.copyWith(
                        color: VillageTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: VillageTheme.spacingXS),
                    
                    // Description
                    Text(
                      shopDescription,
                      style: VillageTheme.bodySmall.copyWith(
                        color: VillageTheme.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    Spacer(),
                    
                    // Location Row
                    Row(
                      children: [
                        Text('📍 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            fullAddress,
                            style: VillageTheme.bodySmall.copyWith(
                              color: VillageTheme.primaryText,
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
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToShop(Map<String, dynamic> shop) {
    final shopId = shop['id'] ?? 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailsScreen(shopId: shopId),
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