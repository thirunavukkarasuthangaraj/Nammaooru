import '../core/services/api_service.dart';
import '../core/utils/logger.dart';

class CartApiService {
  final ApiService _apiService = ApiService();

  // Get Customer Cart
  Future<Map<String, dynamic>> getCart() async {
    try {
      Logger.cart('Fetching customer cart');
      
      final response = await _apiService.get('/customers/cart');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch cart', 'CART', e);
      rethrow;
    }
  }

  // Add Item to Cart
  Future<Map<String, dynamic>> addToCart({
    required int shopProductId,
    required int quantity,
  }) async {
    try {
      Logger.cart('Adding item to cart: product=$shopProductId, quantity=$quantity');
      
      final response = await _apiService.post(
        '/customers/cart/add',
        body: {
          'shopProductId': shopProductId,
          'quantity': quantity,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to add item to cart', 'CART', e);
      rethrow;
    }
  }

  // Update Cart Item Quantity
  Future<Map<String, dynamic>> updateCartItem({
    required int productId,
    required int quantity,
  }) async {
    try {
      Logger.cart('Updating cart item: product=$productId, quantity=$quantity');
      
      final response = await _apiService.put(
        '/customers/cart/update/$productId',
        body: {
          'quantity': quantity,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to update cart item', 'CART', e);
      rethrow;
    }
  }

  // Remove Item from Cart
  Future<Map<String, dynamic>> removeFromCart({
    required int productId,
  }) async {
    try {
      Logger.cart('Removing item from cart: product=$productId');
      
      final response = await _apiService.delete('/customers/cart/remove/$productId');
      return response;
    } catch (e) {
      Logger.e('Failed to remove item from cart', 'CART', e);
      rethrow;
    }
  }

  // Clear Cart
  Future<Map<String, dynamic>> clearCart() async {
    try {
      Logger.cart('Clearing cart');
      
      final response = await _apiService.post('/customers/cart/clear');
      return response;
    } catch (e) {
      Logger.e('Failed to clear cart', 'CART', e);
      rethrow;
    }
  }

  // Validate Cart
  Future<Map<String, dynamic>> validateCart() async {
    try {
      Logger.cart('Validating cart');
      
      final response = await _apiService.post('/customers/cart/validate');
      return response;
    } catch (e) {
      Logger.e('Failed to validate cart', 'CART', e);
      rethrow;
    }
  }

  // Apply Promo Code
  Future<Map<String, dynamic>> applyPromoCode({
    required String promoCode,
  }) async {
    try {
      Logger.cart('Applying promo code: $promoCode');
      
      final response = await _apiService.post(
        '/customers/cart/apply-promo',
        body: {
          'promoCode': promoCode,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to apply promo code', 'CART', e);
      rethrow;
    }
  }

  // Remove Promo Code
  Future<Map<String, dynamic>> removePromoCode() async {
    try {
      Logger.cart('Removing promo code');
      
      final response = await _apiService.delete('/customers/cart/remove-promo');
      return response;
    } catch (e) {
      Logger.e('Failed to remove promo code', 'CART', e);
      rethrow;
    }
  }

  // Get Available Promo Codes
  Future<Map<String, dynamic>> getAvailablePromoCodes() async {
    try {
      Logger.cart('Fetching available promo codes');
      
      final response = await _apiService.get('/promotions/active');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch promo codes', 'CART', e);
      rethrow;
    }
  }
}