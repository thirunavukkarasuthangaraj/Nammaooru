import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../../core/storage/local_storage.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/models/cart_model.dart' as CoreCart;
import '../../core/config/env_config.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _deliveryFee = 30.0;
  double _taxRate = 0.0; // Tax disabled for now
  String? _promoCode;
  double _promoDiscount = 0.0;
  final CartService _cartService = CartService();
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;

  double get subtotal => _items.fold(0.0, (sum, item) => 
      sum + (item.product.effectivePrice * item.quantity));
  
  double get deliveryFee => subtotal >= 500 ? 0.0 : _deliveryFee;
  double get taxAmount => subtotal * _taxRate;
  double get promoDiscount => _promoDiscount;
  
  double get total => subtotal + deliveryFee + taxAmount - promoDiscount;

  CartProvider() {
    _loadCartFromStorage();
    loadCartFromBackend();
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1, bool clearCartConfirmed = false}) async {
    if (kDebugMode) {
      print('🛒 CartProvider: Adding ${product.name} (qty: $quantity) to cart');
    }
    
    // Check if cart has items from different shop
    if (_items.isNotEmpty && !clearCartConfirmed) {
      final currentShopId = _items.first.product.shopId;
      if (currentShopId != product.shopId) {
        if (kDebugMode) {
          print('🛒 Different shop detected. Current: $currentShopId, New: ${product.shopId}');
        }
        return false; // Return false to indicate shop conflict
      }
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // ALWAYS add to local storage first for immediate UI feedback
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
      
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + quantity,
        );
        if (kDebugMode) {
          print('🛒 Updated existing item, new qty: ${_items[existingIndex].quantity}');
        }
      } else {
        _items.add(CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
          addedAt: DateTime.now(),
        ));
        if (kDebugMode) {
          print('🛒 Added new item to cart, total items: ${_items.length}');
        }
      }
      
      _saveCartToStorage();
      
      // Try to sync with backend (but don't fail if it doesn't work)
      try {
        final request = CoreCart.AddToCartRequest(
          shopProductId: product.id,
          quantity: quantity,
        );
        
        final response = await _cartService.addToCart(request);
        
        if (kDebugMode) {
          print('🛒 Backend sync result: ${response['success']}');
        }
      } catch (backendError) {
        if (kDebugMode) {
          print('🛒 Backend sync failed (item still in local cart): $backendError');
        }
      }
      
      return true; // Successfully added
      
    } catch (e) {
      if (kDebugMode) {
        print('🛒 Error in addToCart: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('🛒 Cart now has ${_items.length} items, isEmpty: $isEmpty');
      }
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCartToStorage();
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.product.stockQuantity) {
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        _saveCartToStorage();
        notifyListeners();
      }
    }
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      _saveCartToStorage();
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        final item = _items[index];
        final maxQuantity = item.product.stockQuantity;
        final validQuantity = quantity > maxQuantity ? maxQuantity : quantity;
        _items[index] = item.copyWith(quantity: validQuantity);
      }
      _saveCartToStorage();
      notifyListeners();
    }
  }

  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  int getQuantity(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }

  void clearCart() {
    _items.clear();
    _promoCode = null;
    _promoDiscount = 0.0;
    _saveCartToStorage();
    notifyListeners();
  }

  Future<bool> applyPromoCode(String code) async {
    try {
      // Get device UUID for tracking
      final deviceUuid = await DeviceInfoService().getDeviceUuid();

      if (kDebugMode) {
        print('🎟️ Validating promo code: $code');
        print('🎟️ Device UUID: $deviceUuid');
        print('🎟️ Order amount: $subtotal');
      }

      // Call backend API to validate promo code
      final response = await _cartService.validatePromoCode(
        promoCode: code.toUpperCase(),
        orderAmount: subtotal,
        deviceUuid: deviceUuid,
      );

      if (kDebugMode) {
        print('🎟️ Promo validation response: $response');
      }

      if (response != null && response['valid'] == true) {
        _promoCode = code.toUpperCase();
        _promoDiscount = (response['discountAmount'] as num?)?.toDouble() ?? 0.0;
        _saveCartToStorage();
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error applying promo code: $e');
      return false;
    }
  }

  void removePromoCode() {
    _promoCode = null;
    _promoDiscount = 0.0;
    _saveCartToStorage();
    notifyListeners();
  }

  void applyPromoDiscount(double discount) {
    _promoDiscount = discount;
    _saveCartToStorage();
    notifyListeners();
  }

  String? get appliedPromoCode => _promoCode;

  void _saveCartToStorage() {
    final cartData = {
      'items': _items.map((item) => item.toJson()).toList(),
      'promoCode': _promoCode,
      'promoDiscount': _promoDiscount,
    };
    LocalStorage.setString('cart_data', jsonEncode(cartData));
  }

  Future<void> loadCartFromBackend() async {
    try {
      final response = await _cartService.getCart();
      if (response['success'] == true) {
        final cartData = response['data']['cart'] as Map<String, dynamic>;
        final backendCart = CoreCart.Cart.fromJson(cartData);
        
        if (kDebugMode) {
          print('Loaded cart from backend: ${backendCart.items.length} items');
        }
        
        // Convert backend cart items to local cart items
        final List<CartItem> convertedItems = [];
        
        for (final backendItem in backendCart.items) {
          // Create a ProductModel from the backend cart item data
          final product = ProductModel(
            id: backendItem.productId,
            name: backendItem.productName,
            description: backendItem.productName, // Use name as description fallback
            price: backendItem.price,
            category: 'Unknown', // Backend doesn't provide category in cart
            shopId: backendItem.shopId,
            shopName: backendItem.shopName,
            images: backendItem.productImage.isNotEmpty ? [backendItem.productImage] : [],
            stockQuantity: 999, // Assume high stock since we don't get this from backend cart
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Create the UI CartItem with the ProductModel
          final cartItem = CartItem(
            id: backendItem.id,
            product: product,
            quantity: backendItem.quantity,
            addedAt: DateTime.now(),
          );
          
          convertedItems.add(cartItem);
        }
        
        // Update local cart with backend data
        _items = convertedItems;
        _saveCartToStorage();
        notifyListeners();
        
        if (kDebugMode) {
          print('🛒 Converted ${convertedItems.length} backend items to local cart items');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart from backend: $e');
      }
    }
  }

  void _loadCartFromStorage() {
    final cartDataString = LocalStorage.getString('cart_data');
    if (cartDataString != null) {
      try {
        final cartData = jsonDecode(cartDataString);
        _items = (cartData['items'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
        _promoCode = cartData['promoCode'];
        _promoDiscount = cartData['promoDiscount']?.toDouble() ?? 0.0;
        notifyListeners();
      } catch (e) {
        print('Error loading cart from storage: $e');
      }
    }
  }

  Map<String, List<CartItem>> getItemsByShop() {
    final itemsByShop = <String, List<CartItem>>{};
    
    for (final item in _items) {
      final shopId = item.product.shopId;
      if (itemsByShop.containsKey(shopId)) {
        itemsByShop[shopId]!.add(item);
      } else {
        itemsByShop[shopId] = [item];
      }
    }
    
    return itemsByShop;
  }

  List<String> getUniqueShopIds() {
    return _items.map((item) => item.product.shopId).toSet().toList();
  }

  double getShopSubtotal(String shopId) {
    return _items
        .where((item) => item.product.shopId == shopId)
        .fold(0.0, (sum, item) => sum + (item.product.effectivePrice * item.quantity));
  }

  bool canCheckout() {
    return _items.isNotEmpty && _items.every((item) => 
        item.product.isAvailable && item.quantity <= item.product.stockQuantity);
  }
  
  /// Get the shop ID of items currently in cart (null if cart is empty)
  String? getCurrentShopId() {
    return _items.isNotEmpty ? _items.first.product.shopId : null;
  }
  
  /// Get the shop name of items currently in cart (null if cart is empty)
  String? getCurrentShopName() {
    return _items.isNotEmpty ? _items.first.product.shopName : null;
  }
  
  /// Check if product is from same shop as current cart items
  bool isFromSameShop(ProductModel product) {
    final currentShopId = getCurrentShopId();
    return currentShopId == null || currentShopId == product.shopId;
  }

  List<String> getCheckoutIssues() {
    final issues = <String>[];
    
    if (_items.isEmpty) {
      issues.add('Cart is empty');
      return issues;
    }
    
    for (final item in _items) {
      if (!item.product.isAvailable) {
        issues.add('${item.product.name} is not available');
      } else if (item.quantity > item.product.stockQuantity) {
        issues.add('${item.product.name} has insufficient stock');
      }
    }
    
    return issues;
  }
}