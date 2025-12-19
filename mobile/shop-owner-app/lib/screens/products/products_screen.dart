import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service_simple.dart';
import '../../services/voice_search_service.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import 'product_form_screen.dart';
import 'add_product_from_catalog_screen.dart';
import 'browse_products_screen.dart';
import 'create_product_screen.dart';
import 'categories_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String token;

  const ProductsScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isLoadingCategories = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 2000;
  late ScrollController _scrollController;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final TextEditingController _searchController = TextEditingController();
  final VoiceSearchService _voiceService = VoiceSearchService();
  OverlayEntry? _voiceSearchOverlay;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadCategories();
    _fetchProducts();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  String _getCategoryEmoji(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('vegetable')) return '🥬';
    if (name.contains('fruit')) return '🍎';
    if (name.contains('dry fruit') || name.contains('nut')) return '🥜';
    if (name.contains('milk') || name.contains('dairy')) return '🥛';
    if (name.contains('rice') || name.contains('grain')) return '🌾';
    if (name.contains('snack')) return '🍿';
    if (name.contains('beverage') || name.contains('drink')) return '🥤';
    if (name.contains('spice') || name.contains('masala')) return '🌶️';
    if (name.contains('oil')) return '🫒';
    if (name.contains('medicine') || name.contains('health')) return '💊';
    if (name.contains('personal care') || name.contains('beauty')) return '🧴';
    if (name.contains('home care') || name.contains('clean')) return '🧹';
    if (name.contains('grocery')) return '🛒';
    if (name.contains('egg')) return '🥚';
    if (name.contains('bread') || name.contains('baker')) return '🍞';
    if (name.contains('frozen')) return '🧊';
    if (name.contains('meat') || name.contains('chicken')) return '🍗';
    if (name.contains('fish') || name.contains('seafood')) return '🐟';
    return '📦';
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await ApiService.getCategories();

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        // Shop categories API returns list directly under 'data', not paginated with 'content'
        final categoriesList = data['data'];
        final content = (categoriesList is List) ? categoriesList : [];

        print('📦 Products Screen - Categories loaded: ${content.length}');

        final List<dynamic> categoryList = [];

        // Add "All" category first
        categoryList.add({
          'id': null,
          'name': 'All',
          'displayName': 'All Items',
          'iconUrl': '📦',
          'productCount': _products.length,
        });

        if (content is List) {
          for (var cat in content) {
            // Use imageUrl from shop categories API (customer endpoint)
            final imageUrl = cat['imageUrl'] ?? cat['iconUrl'] ?? '';
            print('  📂 Category: ${cat['name']}, imageUrl: "$imageUrl", productCount: ${cat['productCount']}');

            categoryList.add({
              'id': cat['id'],
              'name': cat['name'] ?? 'Unknown',
              'displayName': cat['displayName'] ?? cat['name'] ?? 'Unknown',
              'iconUrl': imageUrl.isNotEmpty ? imageUrl : _getCategoryEmoji(cat['name'] ?? 'Unknown'),
              'productCount': cat['productCount'] ?? 0,
            });
          }
        }

        print('✅ Loaded ${categoryList.length} categories for Products screen');

        setState(() {
          _categories = categoryList;
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final response = await ApiService.getMyProducts(
        page: 0,
        size: _pageSize,
      );

      print('My Products API response: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        final data = response.data;

        // Handle nested data structure: {statusCode, message, data: {content: [...]}}
        final productsData = data['data'] ?? data;
        final content = productsData['content'] ?? productsData ?? [];

        print('Products count: ${content.length}');

        setState(() {
          _products = content;
          _hasMore = content.length >= _pageSize;
          _currentPage = 0;
          _isLoading = false;
        });
      } else {
        print('API error: ${response.error}');
        _setMockData();
      }
    } catch (e) {
      print('Error fetching products: $e');
      _setMockData();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.getMyProducts(
        page: nextPage,
        size: _pageSize,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsData = data['data'] ?? data;
        final content = productsData['content'] ?? productsData ?? [];

        setState(() {
          _products.addAll(content);
          _hasMore = content.length >= _pageSize;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });

        print('Loaded page $nextPage with ${content.length} products');
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more products: $e');
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  void _setMockData() {
    setState(() {
      _products = [
        {
          'id': 1,
          'name': 'Basmati Rice Premium',
          'description': 'High quality basmati rice',
          'price': 180.00,
          'stock': 25,
          'category': 'Grains & Rice',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 2,
          'name': 'Amul Fresh Milk',
          'description': 'Fresh dairy milk 500ml',
          'price': 32.00,
          'stock': 40,
          'category': 'Dairy',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 3,
          'name': 'Britannia Good Day Cookies',
          'description': 'Chocolate chip cookies pack',
          'price': 25.00,
          'stock': 15,
          'category': 'Snacks',
          'status': 'ACTIVE',
          'image': null,
        },
        {
          'id': 4,
          'name': 'Tata Salt Crystal',
          'description': 'Iodized salt 1kg pack',
          'price': 22.00,
          'stock': 8,
          'category': 'Condiments & Spices',
          'status': 'LOW_STOCK',
          'image': null,
        },
      ];
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredProducts {
    return _products.where((product) {
      final name = (product['displayName'] ?? product['name'] ?? '').toString().toLowerCase();
      final productCategoryName = (product['masterProduct']?['category']?['name'] ?? product['category'] ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
        name.contains(_searchQuery.toLowerCase()) ||
        productCategoryName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by category: null means "All", otherwise match by name
      final matchesCategory = _selectedCategoryName == null ||
                               _selectedCategoryName == 'All' ||
                               productCategoryName == _selectedCategoryName;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _getStockColor(dynamic product) {
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? false;

    if (!inStock || stock == 0) return Colors.red;
    if (lowStock || stock < 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(dynamic product) {
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? false;

    if (!inStock || stock == 0) return 'Out of Stock';
    if (lowStock || stock < 10) return 'Low Stock ($stock)';
    return 'In Stock ($stock)';
  }

  @override
  Widget build(BuildContext context) {
    final gridColumns = ResponsiveLayout.getGridColumns(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(languageProvider.products, style: AppTheme.h5.copyWith(color: Colors.white)),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: padding,
                color: AppTheme.surface,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: languageProvider.searchProducts,
                    prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.mic, color: Colors.green.shade700),
                          onPressed: _showVoiceSearchDialog,
                          tooltip: languageProvider.getText('Voice Search', 'குரல் தேடல்'),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

          // Category Filter with Images
          if (_categories.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryId = category['id']?.toString();
                  final categoryName = category['name']?.toString() ?? 'Category';
                  final displayName = category['displayName']?.toString() ?? categoryName;
                  final iconUrl = category['iconUrl']?.toString() ?? '';
                  final isSelected = _selectedCategoryId == categoryId;

                  print('🎨 Rendering category: $categoryName, iconUrl: "$iconUrl"');

                  // Check if iconUrl is an emoji or image path
                  final bool isEmoji = iconUrl.isNotEmpty &&
                                       !iconUrl.contains('/') &&
                                       !iconUrl.contains('http');
                  final bool hasImage = iconUrl.isNotEmpty &&
                                       (iconUrl.startsWith('/') || iconUrl.startsWith('http'));

                  if (hasImage) {
                    print('  🖼️ Has image: $iconUrl');
                  } else if (isEmoji) {
                    print('  😀 Has emoji: $iconUrl');
                  } else {
                    print('  📦 Using fallback icon');
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = categoryId;
                        _selectedCategoryName = categoryId == null ? null : categoryName;
                      });
                    },
                    child: Container(
                      width: 85,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primary, width: 2)
                            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Category Image/Icon/Emoji
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                            ),
                            child: hasImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      AppConfig.getImageUrl(iconUrl),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('  ❌ Image load error for $categoryName: $error');
                                        return Center(
                                          child: Icon(
                                            Icons.category,
                                            size: 28,
                                            color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          print('  ✅ Image loaded for $categoryName');
                                          return child;
                                        }
                                        return const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : isEmoji
                                ? Center(
                                    child: Text(
                                      iconUrl,
                                      style: TextStyle(fontSize: 28),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.category,
                                      size: 28,
                                      color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          // Category Name
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: isSelected ? AppTheme.primary : Colors.grey[800],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 9,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: AppTheme.space8),

              // Products Grid
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.green.shade700))
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: padding,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: AppTheme.textHint,
                                  ),
                                  const SizedBox(height: AppTheme.space16),
                                  Text(
                                    languageProvider.noProducts,
                                    style: AppTheme.h4.copyWith(color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: AppTheme.space8),
                                  Text(
                                    languageProvider.getText('Add your first product to get started', 'தொடங்க உங்கள் முதல் பொருளைச் சேர்க்கவும்'),
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.space24),
                                  ModernButton(
                                    text: languageProvider.addProduct,
                                    icon: Icons.add,
                                    variant: ButtonVariant.primary,
                                    size: ButtonSize.large,
                                    useGradient: true,
                                    onPressed: () => _showAddProductMenu(context),
                                  ),
                                ],
                              ),
                            ),
                          )
                    : RefreshIndicator(
                        onRefresh: _fetchProducts,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: padding,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns,
                            // Responsive spacing - smaller on mobile
                            crossAxisSpacing: screenWidth < 600 ? AppTheme.space12 : AppTheme.space16,
                            mainAxisSpacing: screenWidth < 600 ? AppTheme.space12 : AppTheme.space16,
                            // Responsive aspect ratio - taller cards on small screens
                            childAspectRatio: screenWidth < 600
                                ? 0.48  // Small phones: taller cards (e.g., 140px wide → 292px tall)
                                : screenWidth < 900
                                    ? 0.65  // Tablets: balanced ratio
                                    : 0.7,  // Desktop: current ratio
                          ),
                          itemCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredProducts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.space16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: ModernFAB(
            icon: Icons.add,
            label: languageProvider.addProduct,
            onPressed: () => _showAddProductMenu(context),
            useGradient: true,
          ),
        );
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final languageProvider = context.read<LanguageProvider>();
    final primaryImageUrl = product['primaryImageUrl'] ?? product['image'];
    // Use language provider to get Tamil name if available
    final productName = languageProvider.getDisplayName(product);
    final category = product['masterProduct']?['category']?['name'] ?? product['category'] ?? 'Uncategorized';
    final price = product['price'] ?? 0;
    final originalPrice = product['originalPrice'];
    final stock = product['stockQuantity'] ?? product['stock'] ?? 0;
    // Check shop-specific unit first, then fall back to master product's unit
    final unit = product['baseUnit'] ?? product['masterProduct']?['baseUnit'] ?? product['unit'];
    final weight = product['baseWeight'] ?? product['masterProduct']?['baseWeight'];
    final imageUrl = AppConfig.getImageUrl(primaryImageUrl);
    final inStock = product['inStock'] ?? true;
    final lowStock = product['lowStock'] ?? (stock < 10);

    return ProductCard(
      name: productName.isNotEmpty ? productName : (product['displayName'] ?? product['name'] ?? 'Unknown Product'),
      category: category,
      price: price.toDouble(),
      originalPrice: originalPrice?.toDouble(),
      stock: stock,
      unit: unit,
      weight: weight?.toDouble(),
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      onTap: () => _showEditProductDialog(product),
      onEdit: () => _showEditProductDialog(product),
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Product'),
            content: Text(
              'Are you sure you want to remove "$productName" from your shop?\n\nNote: Product can only be removed if all orders are completed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ModernButton(
                text: 'Remove',
                variant: ButtonVariant.error,
                size: ButtonSize.small,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final deleteResult = await ApiService.removeProductFromShop(
            productId: product['id'],
          );

          if (deleteResult.isSuccess) {
            _fetchProducts();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product removed from shop successfully'),
                backgroundColor: AppTheme.success,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: ${deleteResult.error ?? "Cannot remove product with pending orders"}',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  // Normalize unit values to match dropdown options
  String _normalizeUnit(String? unit) {
    if (unit == null || unit.isEmpty) return 'piece';

    final normalized = unit.toLowerCase().trim();

    // Map common variations to standard units
    final Map<String, String> unitMappings = {
      'pcs': 'piece',
      'pc': 'piece',
      'pieces': 'piece',
      'g': 'gram',
      'gm': 'gram',
      'gms': 'gram',
      'grams': 'gram',
      'kilogram': 'kg',
      'kgs': 'kg',
      'kilograms': 'kg',
      'l': 'liter',
      'litre': 'liter',
      'litres': 'liter',
      'liters': 'liter',
      'milliliter': 'ml',
      'millilitre': 'ml',
      'milliliters': 'ml',
      'millilitres': 'ml',
      'packs': 'pack',
      'packet': 'pack',
      'packets': 'pack',
      'bottles': 'bottle',
      'btl': 'bottle',
      'boxes': 'box',
      'bx': 'box',
      'dzn': 'dozen',
      'doz': 'dozen',
      'units': 'unit',
    };

    // Check if the normalized unit is in mappings
    if (unitMappings.containsKey(normalized)) {
      return unitMappings[normalized]!;
    }

    // Check if it's already a valid option
    const validUnits = ['piece', 'gram', 'kg', 'liter', 'ml', 'pack', 'bottle', 'box', 'dozen', 'unit'];
    if (validUnits.contains(normalized)) {
      return normalized;
    }

    // Default to piece if unknown
    return 'piece';
  }

  void _showAddProductMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: AppTheme.roundedRound,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Text('Add Product to Shop', style: AppTheme.h4),
            ),
            InfoCard(
              title: '',
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: AppTheme.roundedMedium,
                  ),
                  child: const Icon(Icons.library_add, color: AppTheme.textWhite),
                ),
                title: Text('Browse Master Catalog', style: AppTheme.h6),
                subtitle: Text(
                  'Browse existing products and add with custom price',
                  style: AppTheme.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductFromCatalogScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            InfoCard(
              title: '',
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.roundedMedium,
                  ),
                  child: const Icon(Icons.add_box, color: AppTheme.textWhite),
                ),
                title: Text('Create New Product', style: AppTheme.h6),
                subtitle: Text(
                  'Create a new product and add to catalog',
                  style: AppTheme.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateProductScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog(dynamic product) async {
    final nameController = TextEditingController(text: product['displayName'] ?? product['name'] ?? '');
    final priceController = TextEditingController(text: product['price'].toString());
    final originalPriceController = TextEditingController(text: product['originalPrice']?.toString() ?? '');
    final stockController = TextEditingController(text: (product['stockQuantity'] ?? product['stock'] ?? 0).toString());
    final minStockController = TextEditingController(text: (product['minStockLevel'] ?? 5).toString());
    // Check shop-specific unit first, then fall back to master product's unit
    final weightController = TextEditingController(text: (product['baseWeight'] ?? product['masterProduct']?['baseWeight'] ?? '').toString());

    // Normalize unit value to match dropdown options
    String rawUnit = product['baseUnit'] ?? product['masterProduct']?['baseUnit'] ?? 'piece';
    String selectedUnit = _normalizeUnit(rawUnit);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${product['displayName'] ?? product['name']}'),
          content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  helperText: 'Custom name (optional)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  helperText: 'Price customer pays',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: originalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Original Price / MRP (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  helperText: 'For showing discount (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minStockController,
                decoration: const InputDecoration(
                  labelText: 'Min Stock Level',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight/Quantity',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., 100, 250, 1, 5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  helperText: 'Select unit type',
                ),
                items: const [
                  DropdownMenuItem(value: 'piece', child: Text('Piece / PCS')),
                  DropdownMenuItem(value: 'gram', child: Text('Gram (g)')),
                  DropdownMenuItem(value: 'kg', child: Text('Kilogram (KG)')),
                  DropdownMenuItem(value: 'liter', child: Text('Liter (L)')),
                  DropdownMenuItem(value: 'ml', child: Text('Milliliter (ML)')),
                  DropdownMenuItem(value: 'pack', child: Text('Pack')),
                  DropdownMenuItem(value: 'bottle', child: Text('Bottle')),
                  DropdownMenuItem(value: 'box', child: Text('Box')),
                  DropdownMenuItem(value: 'dozen', child: Text('Dozen')),
                  DropdownMenuItem(value: 'unit', child: Text('Unit')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Product'),
                  content: Text('Are you sure you want to remove "${product['displayName'] ?? product['name']}" from your shop?\n\nNote: Product can only be removed if all orders are completed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                final deleteResult = await ApiService.removeProductFromShop(
                  productId: product['id'],
                );

                if (deleteResult.isSuccess) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product removed from shop successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${deleteResult.error ?? "Cannot remove product with pending orders"}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove from Shop'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final originalPrice = originalPriceController.text.trim().isEmpty
                  ? null
                  : double.tryParse(originalPriceController.text);
              final stock = int.tryParse(stockController.text);
              final minStock = int.tryParse(minStockController.text);
              final weight = weightController.text.trim().isEmpty
                  ? null
                  : double.tryParse(weightController.text);

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter product name')),
                );
                return;
              }

              if (price == null || stock == null || minStock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid numbers')),
                );
                return;
              }

              // Validate originalPrice if provided
              if (originalPrice != null && originalPrice <= price) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Original price must be greater than selling price')),
                );
                return;
              }

              // Update product
              final updateResult = await ApiService.updateShopProduct(
                productId: product['id'],
                masterProductId: product['masterProduct']?['id'] ?? product['masterProductId'],
                price: price,
                originalPrice: originalPrice,
                stockQuantity: stock,
                minStockLevel: minStock,
                customName: name != (product['displayName'] ?? product['name']) ? name : null,
                baseWeight: weight,
                baseUnit: selectedUnit,
              );

              if (updateResult.isSuccess) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${updateResult.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      ),
    );

    if (result == true) {
      _fetchProducts(); // Refresh the list
    }
  }

  @override
  void dispose() {
    _voiceSearchOverlay?.remove();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showVoiceSearchDialog() {
    _voiceSearchOverlay?.remove();

    _voiceSearchOverlay = OverlayEntry(
      builder: (context) => _VoiceSearchDialogWidget(
        token: widget.token,
        voiceService: _voiceService,
        onSearchResult: (query) {
          setState(() {
            _searchQuery = query;
            _searchController.text = query;
          });
        },
        onClose: () {
          _voiceSearchOverlay?.remove();
          _voiceSearchOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_voiceSearchOverlay!);
  }
}

// Voice Search Dialog Widget
class _VoiceSearchDialogWidget extends StatefulWidget {
  final String token;
  final VoiceSearchService voiceService;
  final Function(String) onSearchResult;
  final VoidCallback onClose;

  const _VoiceSearchDialogWidget({
    required this.token,
    required this.voiceService,
    required this.onSearchResult,
    required this.onClose,
  });

  @override
  State<_VoiceSearchDialogWidget> createState() => _VoiceSearchDialogWidgetState();
}

class _VoiceSearchDialogWidgetState extends State<_VoiceSearchDialogWidget> {
  bool _isListening = false;
  String _spokenText = '';
  String _statusText = 'Tap to speak';

  @override
  void initState() {
    super.initState();
    _startVoiceListening();
  }

  @override
  void dispose() {
    widget.voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startVoiceListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    final spokenText = await widget.voiceService.listen();

    setState(() {
      _isListening = false;
      _spokenText = spokenText ?? '';
      _statusText = spokenText?.isNotEmpty == true
          ? 'Searching for: $spokenText'
          : 'No speech detected';
    });

    if (spokenText != null && spokenText.isNotEmpty) {
      widget.onSearchResult(spokenText);
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onClose,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: _isListening ? Colors.green : Colors.grey.shade300,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: _isListening ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isListening ? Colors.green : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (_spokenText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _spokenText,
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_isListening)
                ElevatedButton.icon(
                  onPressed: _startVoiceListening,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}