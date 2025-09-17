import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/shop_api_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
import 'cart_screen.dart';

class ShopDetailsScreen extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic>? shop;

  const ShopDetailsScreen({
    super.key,
    required this.shopId,
    this.shop,
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen>
    with TickerProviderStateMixin {
  final ShopApiService _shopApi = ShopApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<String> _categories = [];
  final List<Map<String, dynamic>> _categoryData = [
    {'name': 'All Items', 'tamil': 'அனைத்து பொருட்கள்', 'emoji': '🛒', 'key': 'all'},
    {'name': 'Grocery', 'tamil': 'மளிகை', 'emoji': '🥬', 'key': 'grocery'},
    {'name': 'Milk', 'tamil': 'பால்', 'emoji': '🥛', 'key': 'milk'},
    {'name': 'Snacks', 'tamil': 'சிற்றுண்டி', 'emoji': '🍿', 'key': 'snacks'},
  ];
  String _selectedCategory = 'all';
  bool _isLoadingShop = false;
  bool _isLoadingProducts = false;
  bool _hasError = false;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryData.length, vsync: this);
    _shop = widget.shop;
    _loadShopDetails();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadShopDetails() async {
    if (_shop != null) return;

    setState(() {
      _isLoadingShop = true;
      _hasError = false;
    });

    try {
      final response = await _shopApi.getShopById(widget.shopId);
      
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        setState(() {
          _shop = response['data'];
          _isLoadingShop = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingShop = false;
        });
        Helpers.showSnackBar(context, 'Failed to load shop details', isError: true);
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _hasError = false;
    });

    try {
      final response = await _shopApi.getShopProducts(
        shopId: widget.shopId.toString(),
        page: 0,
        size: 100,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      
      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        setState(() {
          _products = response['data']['content'] ?? [];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingProducts = false;
        });
        Helpers.showSnackBar(context, 'Failed to load products', isError: true);
      }
    }
  }

  void _onSearchChanged() {
    // Implement search functionality if needed
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5A96),
              Color(0xFF6B4F72),
              Color(0xFF5D4E75),
            ],
          ),
        ),
        child: _isLoadingShop
            ? const Center(child: LoadingWidget())
            : _hasError
                ? _buildErrorState()
                : _buildShopDetails(),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Only show floating button when cart has items
          if (cartProvider.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
            backgroundColor: VillageTheme.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: Text(
              'Cart (${cartProvider.itemCount})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😞', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load shop details',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadShopDetails();
                _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDetails() {
    if (_shop == null) {
      return const Center(child: LoadingWidget());
    }

    final shopName = _shop!['name']?.toString() ?? 'Shop';
    final businessType = _shop!['businessType']?.toString() ?? 'Store';
    final rating = double.tryParse(_shop!['averageRating']?.toString() ?? '0.0') ?? 0.0;
    final isActive = _shop!['isActive'] ?? true;
    final address = _shop!['addressLine1']?.toString() ?? '';
    final city = _shop!['city']?.toString() ?? '';
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;
    final minOrder = _shop!['minOrderAmount']?.toString() ?? '';
    final deliveryFee = _shop!['deliveryFee']?.toString() ?? '';

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(shopName, businessType, rating, isActive),
        SliverToBoxAdapter(child: _buildShopInfo(fullAddress, minOrder, deliveryFee)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryTabDelegate(
            tabController: _tabController,
            categoryData: _categoryData,
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),
        ),
        SliverToBoxAdapter(child: _buildSearchBar()),
        _buildProductGrid(),
      ],
    );
  }

  Widget _buildSliverAppBar(String shopName, String businessType, double rating, bool isActive) {
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

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      // Cart actions removed - using floating action button instead
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  getBusinessEmoji(businessType),
                  style: const TextStyle(fontSize: 120),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            businessType,
                            style: const TextStyle(
                              color: VillageTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isActive ? '✅' : '❌',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'திறந்து' : 'மூடியது',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (rating > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfo(String address, String minOrder, String deliveryFee) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (address.isNotEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: VillageTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          if (address.isNotEmpty) const SizedBox(height: 12),
          Row(
            children: [
              if (minOrder.isNotEmpty)
                Expanded(
                  child: _buildInfoChip('🛍️', 'Min Order', '₹$minOrder'),
                ),
              if (minOrder.isNotEmpty && deliveryFee.isNotEmpty) const SizedBox(width: 12),
              if (deliveryFee.isNotEmpty)
                Expanded(
                  child: _buildInfoChip('🚚', 'Delivery', '₹$deliveryFee'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VillageTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: VillageTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '🔍 பொருட்களைத் தேடுங்கள் / Search products...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: VillageTheme.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: LoadingWidget()),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Center(
                  child: Text('📦', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'பொருட்கள் இல்லை\nNo Products Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(_products[index]),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Get display name from customName or displayName or master product name
    final productName = product['customName']?.toString() ?? 
                       product['displayName']?.toString() ?? 
                       product['masterProduct']?['name']?.toString() ?? 
                       'Product';
    
    // Get description
    final description = product['customDescription']?.toString() ?? 
                       product['displayDescription']?.toString() ??
                       product['masterProduct']?['description']?.toString() ?? '';
    
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
    final isInStock = product['inStock'] ?? true;
    final stockQuantity = int.tryParse(product['stockQuantity']?.toString() ?? '0') ?? 0;
    
    // Get image URL from primaryImageUrl or master product images
    final imageUrl = product['primaryImageUrl']?.toString() ?? 
                    product['masterProduct']?['primaryImageUrl']?.toString() ?? '';
    
    // Debug: print image URL
    print('Product: $productName, Image URL: $imageUrl');

    final hasDiscount = originalPrice > price;
    final discountPercentage = hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with discount badge
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(imageUrl),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $imageUrl - Error: $error');
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, 
                                         size: 30, 
                                         color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Image not available',
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: Colors.grey[600],
                                         )),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: VillageTheme.primaryGreen,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.inventory_2, 
                                   size: 40, 
                                   color: Colors.grey),
                            ),
                          ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$discountPercentage% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!isInStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Add brand and unit info if available
                  if (product['masterProduct']?['brand'] != null || product['masterProduct']?['baseUnit'] != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (product['masterProduct']?['brand'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product['masterProduct']['brand'].toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (product['masterProduct']?['baseUnit'] != null) 
                          Text(
                            '${product['masterProduct']['baseWeight'] ?? ''} ${product['masterProduct']['baseUnit']}'.trim(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${originalPrice.toStringAsFixed(originalPrice == originalPrice.roundToDouble() ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Add stock status
                  if (isInStock && stockQuantity > 0 && stockQuantity <= 10) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Only $stockQuantity left',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final productModel = ProductModel(
                        id: product['id'].toString(),
                        name: productName,
                        description: description,
                        price: price,
                        category: product['masterProduct']?['category']?.toString() ?? '',
                        shopId: _shop?['shopId']?.toString() ?? widget.shopId.toString(),
                        shopName: _shop?['name']?.toString() ?? 'Shop',
                        images: imageUrl.isNotEmpty ? [imageUrl] : [],
                        stockQuantity: stockQuantity,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      
                      final cartQuantity = cartProvider.getQuantity(productModel.id);
                      
                      if (!isInStock) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of Stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      
                      if (cartQuantity == 0) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _handleAddToCart(context, cartProvider, productModel);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'ADD TO CART',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                      
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {
                                cartProvider.removeFromCart(productModel.id);
                              },
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$cartQuantity',
                                style: const TextStyle(
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _handleAddToCart(context, cartProvider, productModel);
                              },
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleAddToCart(BuildContext context, CartProvider cartProvider, ProductModel product) async {
    final success = await cartProvider.addToCart(product);
    
    if (success) {
      // Successfully added to cart
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Show dialog for different shop
      if (context.mounted) {
        final currentShopName = cartProvider.getCurrentShopName();
        final shouldClearCart = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Different Shop'),
            content: Text(
              'Your cart contains items from "$currentShopName".\n\n'
              'Adding items from "${product.shopName}" will clear your current cart.\n\n'
              'Do you want to continue?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text('Clear Cart & Add'),
              ),
            ],
          ),
        );
        
        if (shouldClearCart == true) {
          cartProvider.clearCart();
          await cartProvider.addToCart(product, clearCartConfirmed: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cart cleared. ${product.name} added to cart'),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }
}

class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Map<String, dynamic>> categoryData;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  _CategoryTabDelegate({
    required this.tabController,
    required this.categoryData,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categoryData.length,
          itemBuilder: (context, index) {
            final category = categoryData[index];
            final isSelected = selectedCategory == category['key'];
            
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : VillageTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  onCategoryChanged(category['key']);
                },
                backgroundColor: Colors.white,
                selectedColor: VillageTheme.primaryGreen,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? VillageTheme.primaryGreen : VillageTheme.primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}