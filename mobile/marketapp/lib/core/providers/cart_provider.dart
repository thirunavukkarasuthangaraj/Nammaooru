import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final String shopId;
  final String shopName;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.shopId,
    required this.shopName,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'image': image,
    'shopId': shopId,
    'shopName': shopName,
    'quantity': quantity,
  };
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  int get totalQuantity {
    var total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, String name, double price, String image, 
               String shopId, String shopName) {
    if (_items.containsKey(productId)) {
      // Update quantity
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          image: existingCartItem.image,
          shopId: existingCartItem.shopId,
          shopName: existingCartItem.shopName,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: name,
          price: price,
          image: image,
          shopId: shopId,
          shopName: shopName,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          image: existingCartItem.image,
          shopId: existingCartItem.shopId,
          shopName: existingCartItem.shopName,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  List<CartItem> get cartItems => _items.values.toList();
  
  // Convenience method for adding to cart with a Map
  void addToCart(Map<String, dynamic> product) {
    final id = product['id']?.toString() ?? '';
    final name = product['name']?.toString() ?? '';
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final image = product['image']?.toString() ?? '';
    final shopId = product['shopId']?.toString() ?? '';
    final shopName = product['shopName']?.toString() ?? 'Unknown Shop';
    
    addItem(id, name, price, image, shopId, shopName);
  }
  
  // Group items by shop for better organization
  Map<String, List<CartItem>> get itemsByShop {
    Map<String, List<CartItem>> grouped = {};
    for (var item in _items.values) {
      if (grouped[item.shopId] == null) {
        grouped[item.shopId] = [];
      }
      grouped[item.shopId]!.add(item);
    }
    return grouped;
  }
}