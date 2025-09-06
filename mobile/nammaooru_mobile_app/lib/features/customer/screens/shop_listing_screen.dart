import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';

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
        category: widget.category,
        city: 'Chennai',
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
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light village background
      appBar: AppBar(
        title: Row(
          children: [
            Text('🏪 ', style: TextStyle(fontSize: 24)),
            Flexible(
              child: Text(
                widget.categoryTitle ?? 'கடைகள் / Shops',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32), // Village green
        elevation: 2,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 28),
              onPressed: _showFilterBottomSheet,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: '🔍 கடை தேடுங்கள் / Search shops...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                size: 24,
                color: Color(0xFF2E7D32),
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterShops();
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.my_location,
                      size: 20,
                      color: Colors.orange,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVillageSortingChips() {
    final sortOptions = [
      {'key': 'name', 'label': '🔤 பெயர் / Name', 'icon': Icons.sort_by_alpha},
      {'key': 'rating', 'label': '⭐ ரேடிங் / Rating', 'icon': Icons.star},
      {'key': 'latest', 'label': '🕰️ புதிய / Latest', 'icon': Icons.access_time},
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = _sortBy == option['key'];
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                option['label']! as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
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
              selectedColor: const Color(0xFF2E7D32),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF2E7D32).withOpacity(0.3),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: isSelected ? 4 : 0,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
            ),
          );
        },
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
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(75),
                ),
                child: const Center(
                  child: Text('🏪', style: TextStyle(fontSize: 80)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'கடைகள் இல்லை\nNo Shops Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'தேடல் அல்லது ஆப்ஷன்களை மாற்றி மீண்டும் முயலவும்\nTry adjusting your search or filters',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
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
      color: const Color(0xFF2E7D32),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.3,
          mainAxisSpacing: 16,
        ),
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
    final isActive = shop['isActive'] ?? true;
    final address = shop['addressLine1']?.toString() ?? '';
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToShop(shop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with shop image/icon
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E7D32).withOpacity(0.8),
                      const Color(0xFF388E3C).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        getBusinessEmoji(businessType),
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                    // Status badges
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isActive ? '✅' : '❌',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'திறந்து' : 'மூடியது',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Rating badge
                    if (rating > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
            
            // Shop details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop name with emoji
                    Row(
                      children: [
                        Text(
                          '${getBusinessEmoji(businessType)} ',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Expanded(
                          child: Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Business type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        businessType,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Address
                    if (fullAddress.isNotEmpty)
                      Row(
                        children: [
                          const Text('📍 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              fullAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
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
    context.push('/customer/shop/$shopId');
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text('🔍 ', style: TextStyle(fontSize: 24)),
                    const Text(
                      'ஆப்ஷன்கள் / Filters',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Open Now Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: const Row(
                      children: [
                        Text('✅ ', style: TextStyle(fontSize: 18)),
                        Text(
                          'இப்போது திறந்து உள்ளது / Open Now',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    value: _openNowOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _openNowOnly = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2E7D32),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Apply Button
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'ஆப்ஷன்களை பயன்படுத்து / Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}