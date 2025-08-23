import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class CartService {
  static final List<CartItem> _cartItems = [];
  static final List<Function()> _listeners = [];
  
  static List<CartItem> get items => List.unmodifiable(_cartItems);
  
  static int get itemCount => _cartItems.length;
  
  static int get totalQuantity {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
  
  static double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  static void addToCart(CartItem item) {
    final existingIndex = _cartItems.indexWhere((i) => i.productId == item.productId);
    
    if (existingIndex != -1) {
      _cartItems[existingIndex] = CartItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: _cartItems[existingIndex].quantity + item.quantity,
        imageUrl: item.imageUrl,
        shopId: item.shopId,
      );
    } else {
      _cartItems.add(item);
    }
    
    _notifyListeners();
    _syncWithBackend();
  }
  
  static void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = CartItem(
          productId: _cartItems[index].productId,
          productName: _cartItems[index].productName,
          price: _cartItems[index].price,
          quantity: quantity,
          imageUrl: _cartItems[index].imageUrl,
          shopId: _cartItems[index].shopId,
        );
      }
      
      _notifyListeners();
      _syncWithBackend();
    }
  }
  
  static void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    _notifyListeners();
    _syncWithBackend();
  }
  
  static void clearCart() {
    _cartItems.clear();
    _notifyListeners();
    _syncWithBackend();
  }
  
  static bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }
  
  static int getItemQuantity(String productId) {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        price: 0,
        quantity: 0,
        shopId: '',
      ),
    );
    return item.quantity;
  }
  
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  static Future<void> _syncWithBackend() async {
    try {
      // Sync cart with backend if user is logged in
      await ApiClient.post(
        ApiEndpoints.cart,
        data: {
          'items': _cartItems.map((item) => item.toJson()).toList(),
        },
      );
    } catch (e) {
      // Handle error silently or show notification
      print('Failed to sync cart: $e');
    }
  }
  
  static Future<void> loadCartFromBackend() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.cart);
      final List<dynamic> data = response.data['items'] ?? [];
      
      _cartItems.clear();
      _cartItems.addAll(
        data.map((json) => CartItem.fromJson(json)).toList(),
      );
      
      _notifyListeners();
    } catch (e) {
      print('Failed to load cart: $e');
    }
  }
  
  static Map<String, List<CartItem>> getItemsByShop() {
    final Map<String, List<CartItem>> shopItems = {};
    
    for (final item in _cartItems) {
      if (!shopItems.containsKey(item.shopId)) {
        shopItems[item.shopId] = [];
      }
      shopItems[item.shopId]!.add(item);
    }
    
    return shopItems;
  }
}

class CartItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String shopId;
  
  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.shopId,
  });
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl'],
      shopId: json['shopId'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'shopId': shopId,
    };
  }
  
  double get subtotal => price * quantity;
}