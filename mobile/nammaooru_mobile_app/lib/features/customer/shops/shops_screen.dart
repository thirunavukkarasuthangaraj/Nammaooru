import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/shop_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/shop_api_service.dart';
import '../products/products_screen.dart';

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
      
      if (mounted && response['success'] == true && response['data'] != null) {
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
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category ?? 'Nearby Shops',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // TODO: Navigate to map view
            },
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search shops...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    // TODO: Use current location
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSortingChips() {
    final sortOptions = [
      {'key': 'name', 'label': 'Name'},
      {'key': 'rating', 'label': 'Rating'},
      {'key': 'latest', 'label': 'Latest'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = _sortBy == option['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sortBy = option['key']!;
                  _applySortAndFilter();
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopsList() {
    if (_filteredShops.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Shops Found',
        message: 'Try adjusting your search or filters',
        icon: Icons.store_mall_directory_outlined,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        return _buildShopCard(_filteredShops[index]);
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final shopName = shop['name']?.toString() ?? 'Shop';
    final shopDescription = shop['description']?.toString() ?? 'No description available';
    final businessType = shop['businessType']?.toString() ?? 'Store';
    final rating = double.tryParse(shop['averageRating']?.toString() ?? '4.0') ?? 4.0;
    final isActive = shop['isActive'] ?? true;
    final shopId = shop['id']?.toString() ?? '1';
    final address = shop['addressLine1']?.toString() ?? 'Address not available';
    final city = shop['city']?.toString() ?? '';
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToShop(shop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Image
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: shop.images.isNotEmpty 
                      ? shop.images.first 
                      : 'https://via.placeholder.com/300x150',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, size: 40),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shopDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' (Reviews)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fullAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        businessType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Open' : 'Closed',
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToShop(Map<String, dynamic> shop) {
    final shopId = shop['id']?.toString() ?? '1';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(shopId: shopId),
      ),
    );
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Open Now
                CheckboxListTile(
                  title: const Text('Open Now'),
                  value: _openNowOnly,
                  onChanged: (value) {
                    setModalState(() {
                      _openNowOnly = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Distance Range
                const Text('Maximum Distance'),
                Slider(
                  value: _maxDistance,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${_maxDistance.toStringAsFixed(0)} km',
                  onChanged: (value) {
                    setModalState(() {
                      _maxDistance = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Rating Filter
                const Text('Minimum Rating'),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setModalState(() {
                      _minRating = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterShops();
                    },
                    child: const Text('Apply Filters'),
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