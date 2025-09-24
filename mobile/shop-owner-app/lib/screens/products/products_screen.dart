import 'package:flutter/material.dart';
import '../../services/api_service_simple.dart';

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
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getProducts(
        shopId: '1',
        page: 0,
        size: 50,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _products = response.data['content'] ?? response.data ?? [];
          _isLoading = false;
        });
      } else {
        _setMockData();
      }
    } catch (e) {
      print('Error fetching products: $e');
      _setMockData();
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
    if (_searchQuery.isEmpty) return _products;
    return _products.where((product) =>
        product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Color _getStockColor(String? status, int stock) {
    if (status == 'OUT_OF_STOCK' || stock == 0) return Colors.red;
    if (status == 'LOW_STOCK' || stock < 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(String? status, int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock < 10) return 'Low Stock ($stock)';
    return 'In Stock ($stock)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Product feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
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
                        onRefresh: _fetchProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: product['image'] != null
                                      ? ClipOval(child: Image.network(product['image'], fit: BoxFit.cover))
                                      : Icon(Icons.inventory, color: Theme.of(context).primaryColor),
                                ),
                                title: Text(
                                  product['name'] ?? 'Unknown Product',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(product['description'] ?? 'No description'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${product['category'] ?? 'Uncategorized'}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStockColor(product['status'], product['stock'] ?? 0).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStockColor(product['status'], product['stock'] ?? 0),
                                            ),
                                          ),
                                          child: Text(
                                            _getStockText(product['status'], product['stock'] ?? 0),
                                            style: TextStyle(
                                              color: _getStockColor(product['status'], product['stock'] ?? 0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${product['price'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(Icons.edit, color: Colors.grey[600]),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Edit ${product['name']} feature coming soon!')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new product feature coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}