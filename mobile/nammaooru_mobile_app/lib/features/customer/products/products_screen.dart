import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/models/product_model.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? categoryId;
  final String? shopId;
  
  const ProductsScreen({
    super.key,
    this.categoryId,
    this.shopId,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _sortBy = 'name';
  double _minPrice = 0;
  double _maxPrice = 1000;
  String? _selectedCategory;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement API call to fetch products
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      _products = _generateSampleProducts();
      _filteredProducts = List.from(_products);
      _applySortAndFilter();
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load products', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ProductModel> _generateSampleProducts() {
    return List.generate(20, (index) {
      return ProductModel(
        id: 'product_$index',
        name: 'Product ${index + 1}',
        description: 'Fresh and quality product with great taste and nutrition.',
        price: 50.0 + (index * 25),
        discountPrice: index % 3 == 0 ? 40.0 + (index * 20) : null,
        category: ['Vegetables', 'Fruits', 'Dairy', 'Snacks'][index % 4],
        shopId: 'shop_${index % 3}',
        shopName: 'Shop ${index % 3 + 1}',
        images: ['/api/uploads/products/product_${index + 1}.jpg'],
        stockQuantity: 10 + index,
        unit: 'kg',
        rating: 3.5 + (index % 2 * 0.8),
        reviewCount: 10 + index,
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now(),
      );
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        final matchesCategory = _selectedCategory == null ||
            product.category == _selectedCategory;

        final matchesPrice = product.effectivePrice >= _minPrice &&
            product.effectivePrice <= _maxPrice;

        final matchesStock = !_inStockOnly || product.isInStock;

        return matchesSearch && matchesCategory && matchesPrice && matchesStock;
      }).toList();
      
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price_low':
          _filteredProducts.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
          break;
        case 'rating':
          _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
          _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Products',
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortingChips(),
          Expanded(
            child: _isLoading ? const LoadingWidget() : _buildProductList(),
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
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // TODO: Implement voice search
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
      {'key': 'price_low', 'label': 'Price ↑'},
      {'key': 'price_high', 'label': 'Price ↓'},
      {'key': 'rating', 'label': 'Rating'},
      {'key': 'newest', 'label': 'Newest'},
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

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Products Found',
        message: 'Try adjusting your search or filters',
        icon: Icons.search_off,
      );
    }

    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductListTile(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToProductDetail(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
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
                    imageUrl: ImageUrlHelper.getFullImageUrl(
                        product.images.isNotEmpty ? product.images.first : null),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Helpers.formatCurrency(product.effectivePrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatCurrency(product.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        _buildAddToCartButton(product),
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

  Widget _buildProductListTile(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: ImageUrlHelper.getFullImageUrl(
                product.images.isNotEmpty ? product.images.first : null),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(color: Colors.white),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  Helpers.formatCurrency(product.effectivePrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text(
                    Helpers.formatCurrency(product.price),
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: _buildAddToCartButton(product),
        onTap: () => _navigateToProductDetail(product),
      ),
    );
  }

  Widget _buildAddToCartButton(ProductModel product) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItem = cartProvider.getCartItem(product.id);
        
        if (cartItem == null) {
          return IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: product.isInStock
                ? () => cartProvider.addToCart(product)
                : null,
            color: AppColors.primary,
          );
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => cartProvider.decreaseQuantity(product.id),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              cartItem.quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => cartProvider.increaseQuantity(product.id),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        );
      },
    );
  }

  void _navigateToProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
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
                
                // Category Filter
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Vegetables', 'Fruits', 'Dairy', 'Snacks']
                      .map((category) => FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == (category == 'All' ? null : category),
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = category == 'All' ? null : category;
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                
                // Price Range
                const Text('Price Range'),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  labels: RangeLabels(
                    Helpers.formatCurrency(_minPrice),
                    Helpers.formatCurrency(_maxPrice),
                  ),
                  onChanged: (values) {
                    setModalState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                const SizedBox(height: 20),
                
                // In Stock Only
                CheckboxListTile(
                  title: const Text('In Stock Only'),
                  value: _inStockOnly,
                  onChanged: (value) {
                    setModalState(() {
                      _inStockOnly = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 20),
                
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterProducts();
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