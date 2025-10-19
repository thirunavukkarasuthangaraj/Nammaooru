import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service_simple.dart';
import '../../utils/constants.dart';
import '../../utils/app_config.dart';

class AddProductFromCatalogScreen extends StatefulWidget {
  const AddProductFromCatalogScreen({super.key});

  @override
  State<AddProductFromCatalogScreen> createState() => _AddProductFromCatalogScreenState();
}

class _AddProductFromCatalogScreenState extends State<AddProductFromCatalogScreen> {
  List<dynamic> _masterProducts = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchMasterProducts();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        // Handle paginated response: {data: {content: [...]}}
        final categoriesData = data['data'] ?? data;
        final content = categoriesData['content'] ?? categoriesData ?? [];

        setState(() {
          _categories = content is List ? content : [];
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchMasterProducts({String? categoryId}) async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getMasterProducts(
        page: 0,
        size: 100,
        categoryId: categoryId,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final productsData = data['data'] ?? data;
        final content = productsData['content'] ?? productsData ?? [];

        setState(() {
          _masterProducts = content;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching master products: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _masterProducts;
    return _masterProducts.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final description = (product['description'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || description.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product from Catalog'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search master products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Categories - Horizontal Scroll
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip('All', null);
                  }
                  final category = _categories[index - 1];
                  return _buildCategoryChip(
                    category['name'] ?? 'Category',
                    category['id'].toString(),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchMasterProducts(categoryId: _selectedCategoryId),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = (_selectedCategoryId == categoryId) || (categoryId == null && _selectedCategoryId == null);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = categoryId;
        });
        _fetchMasterProducts(categoryId: categoryId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final primaryImageUrl = product['primaryImageUrl'];
    final imageUrl = AppConfig.getImageUrl(primaryImageUrl);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showAddProductDialog(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.inventory, size: 48, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.inventory, size: 48, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['name'] ?? 'Unknown Product',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product['category']?['name'] ?? 'Uncategorized',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SKU: ${product['sku'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog(dynamic masterProduct) {
    final priceController = TextEditingController(
      text: (masterProduct['suggestedPrice'] ?? 0).toString(),
    );
    final stockController = TextEditingController(text: '10');
    final minStockController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${masterProduct['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                masterProduct['description'] ?? 'No description',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Your Price *',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                  helperText: 'Set your custom selling price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: 'Initial Stock Quantity *',
                  border: const OutlineInputBorder(),
                  suffixText: masterProduct['unit']?['name'] ?? 'unit',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minStockController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock Level',
                  border: OutlineInputBorder(),
                  helperText: 'Alert when stock falls below this',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              final stock = int.tryParse(stockController.text);
              final minStock = int.tryParse(minStockController.text);

              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              if (stock == null || stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid stock quantity')),
                );
                return;
              }

              Navigator.pop(context);
              await _addProductToShop(masterProduct, price, stock, minStock ?? 5);
            },
            child: const Text('Add to My Shop'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProductToShop(dynamic masterProduct, double price, int stock, int minStock) async {
    try {
      final response = await ApiService.createShopProduct(
        masterProductId: masterProduct['id'],
        price: price,
        stockQuantity: stock,
        minStockLevel: minStock,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${masterProduct['name']} added to your shop successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add product: ${response.error ?? 'Unknown error'}'),
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
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
