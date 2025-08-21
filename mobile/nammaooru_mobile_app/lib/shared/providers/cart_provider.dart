import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../../core/storage/local_storage.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _deliveryFee = 30.0;
  double _taxRate = 0.05; // 5% tax
  String? _promoCode;
  double _promoDiscount = 0.0;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  double get subtotal => _items.fold(0.0, (sum, item) => 
      sum + (item.product.effectivePrice * item.quantity));
  
  double get deliveryFee => subtotal >= 500 ? 0.0 : _deliveryFee;
  double get taxAmount => subtotal * _taxRate;
  double get promoDiscount => _promoDiscount;
  
  double get total => subtotal + deliveryFee + taxAmount - promoDiscount;

  CartProvider() {
    _loadCartFromStorage();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      ));
    }
    
    _saveCartToStorage();
    notifyListeners();
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

  void clearCart() {
    _items.clear();
    _promoCode = null;
    _promoDiscount = 0.0;
    _saveCartToStorage();
    notifyListeners();
  }

  Future<bool> applyPromoCode(String code) async {
    // TODO: Implement API call to validate promo code
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    // Sample promo codes
    switch (code.toUpperCase()) {
      case 'SAVE10':
        _promoCode = code;
        _promoDiscount = subtotal * 0.1; // 10% discount
        break;
      case 'SAVE50':
        _promoCode = code;
        _promoDiscount = 50.0; // Flat ₹50 discount
        break;
      case 'FREESHIP':
        _promoCode = code;
        _promoDiscount = deliveryFee; // Free shipping
        break;
      default:
        return false;
    }
    
    _saveCartToStorage();
    notifyListeners();
    return true;
  }

  void removePromoCode() {
    _promoCode = null;
    _promoDiscount = 0.0;
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