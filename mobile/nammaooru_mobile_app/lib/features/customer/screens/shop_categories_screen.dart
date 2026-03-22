import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import 'shop_details_modern_screen.dart';
import 'cart_screen.dart';

class ShopCategoriesScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopCategoriesScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopCategoriesScreen> createState() => _ShopCategoriesScreenState();
}

class _ShopCategoriesScreenState extends State<ShopCategoriesScreen> {
  final ShopApiService _shopApi = ShopApiService();
  Map<String, dynamic>? _shopDetails;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    try {
      print('🔧 Starting _loadShopData');
      setState(() => _isLoading = true);

      // Load shop details
      print('🔧 Loading shop details...');
      final shopResponse = await _shopApi.getShopById(int.parse(widget.shopId));

      if (shopResponse['statusCode'] == '0000' && shopResponse['data'] != null) {
        print('🔧 Shop details loaded successfully');
        _shopDetails = shopResponse['data'];
      }

      // Load categories
      print('🔧 Loading categories...');
      final categoriesResponse = await _shopApi.getShopCategories(int.parse(widget.shopId));

      if (categoriesResponse['statusCode'] == '0000' && categoriesResponse['data'] != null) {
        print('🔧 Raw categories data type: ${categoriesResponse['data'].runtimeType}');
        print('🔧 Raw categories data: ${categoriesResponse['data']}');

        final List<dynamic> categoriesData = categoriesResponse['data'] is List
            ? categoriesResponse['data']
            : [];

        print('🔧 Processing ${categoriesData.length} categories');

        // Handle new CategoryResponse format from API
        try {
          _categories = categoriesData.map((categoryData) {
            print('🔧 Processing category: $categoryData (type: ${categoryData.runtimeType})');

            // Handle both old string format and new object format
            if (categoryData is String) {
              // Old format - convert to new format
              return <String, dynamic>{
                'id': categoryData.hashCode.toString(),
                'name': categoryData,
                'displayName': categoryData,
                'searchName': categoryData,
                'description': 'Products in $categoryData category',
                'productCount': 0,
                'icon': _getDefaultIconForCategory(categoryData),
                'color': _getDefaultColorForCategory(categoryData),
              };
            } else {
              // New format - use API response directly
              return <String, dynamic>{
                'id': categoryData['id']?.toString() ?? '1',
                'name': categoryData['name'] ?? 'Category',
                'displayName': categoryData['displayName'] ?? categoryData['name'],
                'searchName': categoryData['name'] ?? 'Category', // Use name for API calls
                'description': categoryData['description'] ?? '',
                'productCount': categoryData['productCount'] ?? 0,
                'icon': _getIconFromString(categoryData['icon']),
                'color': _parseColor(categoryData['color']),
              };
            }
          }).toList();

          print('🔧 Successfully converted ${_categories.length} categories: $_categories');
        } catch (conversionError) {
          print('💥 Error converting categories: $conversionError');
          _categories = _getDefaultCategories();
        }

        print('🔧 Final categories from API: ${_categories.length} items');

        // Don't use default categories - only use what API returns
        if (_categories.isEmpty) {
          print('⚠️ No categories from API, keeping empty list');
        }
      } else {
        print('⚠️ API failed or returned no data');
        _categories = []; // Don't use defaults, keep empty
      }
    } catch (e) {
      print('Error loading shop data: $e');
      _categories = _getDefaultCategories();
      if (mounted) {
        Helpers.showSnackBar(context, 'Using default categories', isError: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {
        'id': '1',
        'name': 'Fresh Vegetables',
        'description': 'Farm fresh vegetables',
        'productCount': 45,
        'icon': Icons.eco,
        'color': const Color(0xFF4CAF50),
      },
      {
        'id': '2',
        'name': 'Fruits',
        'description': 'Seasonal & exotic fruits',
        'productCount': 32,
        'icon': Icons.apple,
        'color': const Color(0xFFFF9800),
      },
      {
        'id': '3',
        'name': 'Dairy & Eggs',
        'description': 'Milk, cheese, yogurt & eggs',
        'productCount': 28,
        'icon': Icons.egg,
        'color': const Color(0xFF2196F3),
      },
      {
        'id': '4',
        'name': 'Bakery & Bread',
        'description': 'Fresh bread & bakery items',
        'productCount': 24,
        'icon': Icons.bakery_dining,
        'color': const Color(0xFF795548),
      },
      {
        'id': '5',
        'name': 'Rice & Grains',
        'description': 'Rice, wheat & pulses',
        'productCount': 36,
        'icon': Icons.rice_bowl,
        'color': const Color(0xFFFFC107),
      },
      {
        'id': '6',
        'name': 'Oil & Ghee',
        'description': 'Cooking oils & ghee',
        'productCount': 18,
        'icon': Icons.water_drop,
        'color': const Color(0xFFFFEB3B),
      },
      {
        'id': '7',
        'name': 'Spices & Masala',
        'description': 'Indian spices & masalas',
        'productCount': 42,
        'icon': Icons.scatter_plot,
        'color': const Color(0xFFE91E63),
      },
      {
        'id': '8',
        'name': 'Snacks & Beverages',
        'description': 'Chips, biscuits & drinks',
        'productCount': 56,
        'icon': Icons.fastfood,
        'color': const Color(0xFF9C27B0),
      },
      {
        'id': '9',
        'name': 'Personal Care',
        'description': 'Health & hygiene products',
        'productCount': 38,
        'icon': Icons.face,
        'color': const Color(0xFF00BCD4),
      },
      {
        'id': '10',
        'name': 'Home Care',
        'description': 'Cleaning & household items',
        'productCount': 29,
        'icon': Icons.cleaning_services,
        'color': const Color(0xFF607D8B),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: VillageTheme.primaryGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _showSearchDialog,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shopName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_categories.fold(0, (sum, cat) => sum + (cat['productCount'] as int))} Products',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),

          // Shop Info Card
          if (_shopDetails != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildInfoItem(
                      Icons.star,
                      '${_shopDetails!['rating'] ?? '4.5'}',
                      'Rating',
                      Colors.orange,
                    ),
                    _buildDivider(),
                    _buildInfoItem(
                      Icons.access_time,
                      '${_shopDetails!['deliveryTime'] ?? '30'} min',
                      'Delivery',
                      Colors.blue,
                    ),
                    _buildDivider(),
                    _buildInfoItem(
                      Icons.currency_rupee,
                      '${_shopDetails!['minimumOrder'] ?? '100'}',
                      'Min Order',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),

          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _isLoading
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : _categories.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Text('🏪', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'No categories found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildCategoryCard(_categories[index]),
                          childCount: _categories.length,
                        ),
                      ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final Color cardColor = category['color'] is Color
        ? category['color'] as Color
        : _parseColor(category['color']?.toString());
    final IconData cardIcon = category['icon'] is IconData
        ? category['icon'] as IconData
        : _getIconFromString(category['icon']?.toString());
    final int productCount = category['productCount'] as int? ?? 0;
    final String displayName = category['displayName']?.toString() ?? category['name']?.toString() ?? 'Category';
    final String description = category['description']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailsModernScreen(
              shopId: int.parse(widget.shopId),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored header with icon
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Background pattern circle
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(cardIcon, size: 44, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Bottom info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$productCount Items',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cardColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
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

  IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'apple':
        return Icons.apple;
      case 'egg':
        return Icons.egg;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'rice_bowl':
        return Icons.rice_bowl;
      case 'water_drop':
        return Icons.water_drop;
      case 'scatter_plot':
        return Icons.scatter_plot;
      case 'fastfood':
        return Icons.fastfood;
      case 'face':
        return Icons.face;
      case 'cleaning_services':
        return Icons.cleaning_services;
      default:
        return Icons.shopping_bag;
    }
  }

  IconData _getDefaultIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('grocery') || name.contains('general')) {
      return Icons.shopping_bag;
    } else if (name.contains('vegetable') || name.contains('veggie')) {
      return Icons.eco;
    } else if (name.contains('fruit')) {
      return Icons.apple;
    } else if (name.contains('dairy') || name.contains('milk')) {
      return Icons.egg;
    } else if (name.contains('bakery') || name.contains('bread')) {
      return Icons.bakery_dining;
    } else if (name.contains('rice') || name.contains('grain')) {
      return Icons.rice_bowl;
    } else if (name.contains('oil') || name.contains('ghee')) {
      return Icons.water_drop;
    } else if (name.contains('spice') || name.contains('masala')) {
      return Icons.scatter_plot;
    } else if (name.contains('snack') || name.contains('beverage')) {
      return Icons.fastfood;
    } else if (name.contains('personal') || name.contains('care')) {
      return Icons.face;
    } else if (name.contains('home') || name.contains('clean')) {
      return Icons.cleaning_services;
    } else {
      return Icons.shopping_bag;
    }
  }

  Color _getDefaultColorForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('grocery') || name.contains('general')) {
      return const Color(0xFF4CAF50);
    } else if (name.contains('vegetable') || name.contains('veggie')) {
      return const Color(0xFF4CAF50);
    } else if (name.contains('fruit')) {
      return const Color(0xFFFF9800);
    } else if (name.contains('dairy') || name.contains('milk')) {
      return const Color(0xFF2196F3);
    } else if (name.contains('bakery') || name.contains('bread')) {
      return const Color(0xFF795548);
    } else if (name.contains('rice') || name.contains('grain')) {
      return const Color(0xFFFFC107);
    } else if (name.contains('oil') || name.contains('ghee')) {
      return const Color(0xFFFFEB3B);
    } else if (name.contains('spice') || name.contains('masala')) {
      return const Color(0xFFE91E63);
    } else if (name.contains('snack') || name.contains('beverage')) {
      return const Color(0xFF9C27B0);
    } else if (name.contains('personal') || name.contains('care')) {
      return const Color(0xFF00BCD4);
    } else if (name.contains('home') || name.contains('clean')) {
      return const Color(0xFF607D8B);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFF4CAF50);
    }

    try {
      // Remove # if present
      String colorCode = colorString.replaceAll('#', '');

      // Add alpha if not present (FF for full opacity)
      if (colorCode.length == 6) {
        colorCode = 'FF$colorCode';
      }

      return Color(int.parse(colorCode, radix: 16));
    } catch (e) {
      print('Error parsing color $colorString: $e');
      return const Color(0xFF4CAF50);
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter product name...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement search functionality
              if (_searchController.text.isNotEmpty) {
                // Navigate to search results
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}