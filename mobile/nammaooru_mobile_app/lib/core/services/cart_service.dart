import '../api/api_client.dart';
import '../models/cart_model.dart';
import '../storage/local_storage.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await ApiClient.get('/customers/cart');
      
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data ?? {});
        await _cacheCart(cart);
        
        return {
          'success': true,
          'data': cart,
          'message': 'Cart loaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to load cart',
          'data': Cart.empty()
        };
      }
    } catch (e) {
      print('Error loading cart: $e');
      
      final cachedCart = await _getCachedCart();
      return {
        'success': false,
        'message': 'Using cached cart data',
        'data': cachedCart,
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> addToCart(AddToCartRequest request) async {
    try {
      final response = await ApiClient.post(
        '/customers/cart/add',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data ?? {});
        await _cacheCart(cart);
        
        return {
          'success': true,
          'data': cart,
          'message': 'Item added to cart successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to add item to cart'
        };
      }
    } catch (e) {
      print('Error adding to cart: $e');
      
      await _addToOfflineCart(request);
      return {
        'success': false,
        'message': 'Item will be added when you\'re online',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> updateCartItem(String itemId, int quantity) async {
    try {
      final response = await ApiClient.put(
        '/customers/cart/update/$itemId',
        data: {'quantity': quantity},
      );
      
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data ?? {});
        await _cacheCart(cart);
        
        return {
          'success': true,
          'data': cart,
          'message': 'Cart updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to update cart'
        };
      }
    } catch (e) {
      print('Error updating cart: $e');
      return {
        'success': false,
        'message': 'Failed to update cart. Please try again.',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    try {
      final response = await ApiClient.delete('/customers/cart/remove/$itemId');
      
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data ?? {});
        await _cacheCart(cart);
        
        return {
          'success': true,
          'data': cart,
          'message': 'Item removed from cart'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to remove item'
        };
      }
    } catch (e) {
      print('Error removing from cart: $e');
      return {
        'success': false,
        'message': 'Failed to remove item. Please try again.',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await ApiClient.delete('/customers/cart/clear');
      
      if (response.statusCode == 200) {
        await _clearCachedCart();
        
        return {
          'success': true,
          'data': Cart.empty(),
          'message': 'Cart cleared successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to clear cart'
        };
      }
    } catch (e) {
      print('Error clearing cart: $e');
      return {
        'success': false,
        'message': 'Failed to clear cart. Please try again.',
        'error': e.toString()
      };
    }
  }

  Future<int> getCartItemCount() async {
    try {
      final cachedCart = await _getCachedCart();
      return cachedCart.totalItems;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _cacheCart(Cart cart) async {
    try {
      await LocalStorage.setMap('user_cart', {
        'items': cart.items.map((item) => item.toJson()).toList(),
        'subtotal': cart.subtotal,
        'deliveryFee': cart.deliveryFee,
        'tax': cart.tax,
        'total': cart.total,
        'totalItems': cart.totalItems,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error caching cart: $e');
    }
  }

  Future<Cart> _getCachedCart() async {
    try {
      final cachedData = await LocalStorage.getMap('user_cart');
      
      if (cachedData.isEmpty) {
        return Cart.empty();
      }
      
      final cachedAt = cachedData['cachedAt'] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cacheValidityMs = 5 * 60 * 1000; // 5 minutes
      
      if (now - cachedAt > cacheValidityMs) {
        return Cart.empty();
      }
      
      return Cart.fromJson(cachedData);
    } catch (e) {
      print('Error loading cached cart: $e');
      return Cart.empty();
    }
  }

  Future<void> _clearCachedCart() async {
    try {
      await LocalStorage.remove('user_cart');
      await LocalStorage.remove('offline_cart');
    } catch (e) {
      print('Error clearing cached cart: $e');
    }
  }

  Future<void> _addToOfflineCart(AddToCartRequest request) async {
    try {
      final offlineItems = await LocalStorage.getList('offline_cart');
      
      final newItem = {
        ...request.toJson(),
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      offlineItems.add(newItem);
      await LocalStorage.setList('offline_cart', offlineItems);
    } catch (e) {
      print('Error saving offline cart: $e');
    }
  }

  Future<void> syncOfflineCart() async {
    try {
      final offlineItems = await LocalStorage.getList('offline_cart');
      
      if (offlineItems.isEmpty) return;
      
      for (final item in offlineItems) {
        final request = AddToCartRequest(
          shopProductId: item['shopProductId'],
          quantity: item['quantity'],
        );
        
        await addToCart(request);
      }
      
      await LocalStorage.setList('offline_cart', []);
    } catch (e) {
      print('Error syncing offline cart: $e');
    }
  }
}