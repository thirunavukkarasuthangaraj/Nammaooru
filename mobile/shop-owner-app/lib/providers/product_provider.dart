import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _masterProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedStatus = '';

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  List<Product> get masterProducts => _masterProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  // Statistics
  int get totalProducts => _products.length;
  int get activeProducts => _products.where((p) => p.isActive).length;
  int get lowStockProducts => _products.where((p) => p.isLowStock).length;
  int get outOfStockProducts => _products.where((p) => p.isOutOfStock).length;

  List<String> get categories => _products
      .map((p) => p.category)
      .toSet()
      .toList()
      ..sort();

  // Initialize with mock data
  Future<void> initialize() async {
    await loadProducts();
    await loadMasterProducts();
  }

  // Load products
  Future<void> loadProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Load from API or use mock data
      await _loadMockProducts();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load master products (browse products)
  Future<void> loadMasterProducts() async {
    try {
      await _loadMockMasterProducts();
    } catch (e) {
      print('Failed to load master products: $e');
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedStatus = '';
    _applyFilters();
    notifyListeners();
  }

  // Apply filters to products
  void _applyFilters() {
    List<Product> filtered = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Apply status filter
    if (_selectedStatus.isNotEmpty) {
      filtered = filtered.where((product) => product.status == _selectedStatus).toList();
    }

    _filteredProducts = filtered;
  }

  // Create product
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await ApiService.createProduct(productData);

      if (response.isSuccess) {
        final newProduct = Product.fromJson(response.data['product']);
        _products.insert(0, newProduct);
        _applyFilters();
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to create product');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Create product error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await ApiService.updateProduct(productId, updates);

      if (response.isSuccess) {
        final updatedProduct = Product.fromJson(response.data['product']);
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = updatedProduct;
          _applyFilters();
          notifyListeners();
        }
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to update product');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Update product error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await ApiService.deleteProduct(productId);

      if (response.isSuccess) {
        _products.removeWhere((p) => p.id == productId);
        _applyFilters();
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete product');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Delete product error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Toggle product status
  Future<bool> toggleProductStatus(String productId) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newStatus = product.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';

    return await updateProduct(productId, {'status': newStatus});
  }

  // Update stock
  Future<bool> updateStock(String productId, int newStock) async {
    return await updateProduct(productId, {'stock': newStock});
  }

  // Load mock products for development
  Future<void> _loadMockProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockProducts = [
      Product(
        id: 'prod_1',
        name: 'Potato Chips',
        description: 'Crispy and delicious potato chips, perfect snack for any time of the day.',
        price: 100.0,
        stock: 25,
        category: 'Snacks',
        status: 'ACTIVE',
        image: '🥔',
        sku: 'SNACK001',
        tags: ['snacks', 'chips', 'crispy'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        minStock: 5,
        unit: 'pcs',
      ),
      Product(
        id: 'prod_2',
        name: 'Cough Syrup',
        description: 'Effective cough syrup for quick relief from dry and wet cough.',
        price: 100.0,
        stock: 15,
        category: 'Medicine',
        status: 'ACTIVE',
        image: '💊',
        sku: 'MED001',
        tags: ['medicine', 'cough', 'syrup'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        minStock: 3,
        unit: 'bottle',
      ),
      Product(
        id: 'prod_3',
        name: 'Magliavan',
        description: 'Premium quality magliavan for authentic cooking experience.',
        price: 150.0,
        stock: 8,
        category: 'Spices',
        status: 'ACTIVE',
        image: '🌶️',
        sku: 'SPICE001',
        tags: ['spices', 'cooking', 'authentic'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        minStock: 2,
        unit: 'pack',
      ),
      Product(
        id: 'prod_4',
        name: 'Coffee',
        description: 'Rich and aromatic coffee powder for the perfect cup of coffee.',
        price: 10.0,
        stock: 50,
        category: 'Beverages',
        status: 'ACTIVE',
        image: '☕',
        sku: 'BEV001',
        tags: ['coffee', 'beverages', 'aromatic'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        minStock: 10,
        unit: 'pack',
      ),
      Product(
        id: 'prod_5',
        name: 'ABC',
        description: 'Multi-purpose household item for various daily needs.',
        price: 100.0,
        stock: 12,
        category: 'Household',
        status: 'ACTIVE',
        image: '🏠',
        sku: 'HOUSE001',
        tags: ['household', 'multipurpose', 'daily'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        minStock: 3,
        unit: 'pcs',
      ),
    ];

    _products = mockProducts;
  }

  // Load mock master products
  Future<void> _loadMockMasterProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final mockMasterProducts = [
      Product(
        id: 'master_1',
        name: 'TATA TEA',
        description: 'Premium quality tea leaves for the perfect cup of tea.',
        price: 200.0,
        stock: 100,
        category: 'Beverages',
        status: 'ACTIVE',
        image: '🍵',
        sku: 'TEA001',
        tags: ['tea', 'tata', 'premium'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        minStock: 20,
        unit: 'pack',
      ),
      Product(
        id: 'master_2',
        name: 'Phone',
        description: 'Latest smartphone with advanced features and high performance.',
        price: 15000.0,
        stock: 50,
        category: 'Electronics',
        status: 'ACTIVE',
        image: '📱',
        sku: 'ELEC001',
        tags: ['phone', 'smartphone', 'electronics'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        minStock: 5,
        unit: 'pcs',
      ),
      Product(
        id: 'master_3',
        name: 'Water',
        description: 'Pure and clean drinking water bottles for hydration.',
        price: 20.0,
        stock: 200,
        category: 'Beverages',
        status: 'ACTIVE',
        image: '💧',
        sku: 'WATER001',
        tags: ['water', 'drinking', 'pure'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        minStock: 50,
        unit: 'bottle',
      ),
      Product(
        id: 'master_4',
        name: 'ABU Milk',
        description: 'Fresh and nutritious milk for daily consumption.',
        price: 60.0,
        stock: 80,
        category: 'Dairy',
        status: 'ACTIVE',
        image: '🥛',
        sku: 'DAIRY001',
        tags: ['milk', 'dairy', 'fresh'],
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
        minStock: 15,
        unit: 'liter',
      ),
      Product(
        id: 'master_5',
        name: 'Cookies',
        description: 'Delicious and crunchy cookies for snack time.',
        price: 80.0,
        stock: 40,
        category: 'Snacks',
        status: 'ACTIVE',
        image: '🍪',
        sku: 'SNACK002',
        tags: ['cookies', 'snacks', 'crunchy'],
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        minStock: 8,
        unit: 'pack',
      ),
      Product(
        id: 'master_6',
        name: 'Medicine',
        description: 'General purpose medicine for common health issues.',
        price: 250.0,
        stock: 30,
        category: 'Medicine',
        status: 'ACTIVE',
        image: '💉',
        sku: 'MED002',
        tags: ['medicine', 'health', 'general'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 16)),
        minStock: 5,
        unit: 'pack',
      ),
    ];

    _masterProducts = mockMasterProducts;
  }

  // Add master product to shop
  Future<bool> addMasterProductToShop(Product masterProduct) async {
    try {
      _setLoading(true);
      _clearError();

      final productData = {
        'name': masterProduct.name,
        'description': masterProduct.description,
        'price': masterProduct.price,
        'stock': 0, // Start with 0 stock
        'category': masterProduct.category,
        'image': masterProduct.image,
        'sku': masterProduct.sku,
        'tags': masterProduct.tags,
        'unit': masterProduct.unit,
      };

      final success = await createProduct(productData);
      return success;
    } catch (e) {
      _setError('Failed to add product to shop: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear data
  void clear() {
    _products.clear();
    _filteredProducts.clear();
    _masterProducts.clear();
    _searchQuery = '';
    _selectedCategory = '';
    _selectedStatus = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}