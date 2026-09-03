import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../../core/storage/local_storage.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/device_info_service.dart';
import '../../core/services/delivery_fee_service.dart';
import '../../core/services/location_service.dart';
import '../../services/shop_api_service.dart';
import '../../core/models/cart_model.dart' as CoreCart;
import '../../core/config/env_config.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {

  List<CartItem> _items = [];
  double _deliveryFee = 30.0;
  double _freeDeliveryAbove = 0.0; // Shop's free delivery threshold (0 = no free delivery)
  double _taxRate = 0.0; // Tax disabled for now
  String? _promoCode;
  double _promoDiscount = 0.0;
  final CartService _cartService = CartService();
  bool _isLoading = false;
  bool _isShopOpen = true; // Track if current shop is open
  String? _shopName; // Track current shop name for error messages
  // Per-shop minimum order amount (shop.minOrderAmount from the backend).
  // Null until a shop's details are loaded; checkout falls back to a safe
  // default in that case rather than treating "unknown" as "no minimum".
  double? _minOrderAmount;

  List<CartItem> get items => List.unmodifiable(_items);
  /// Total units across the cart (sum of quantities) - for order payloads etc.
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Number of DISTINCT products - what badges and "N items" labels should
  /// show. A cart with 2 products x4 and x5 reads "2", not "9"; showing unit
  /// totals confused customers ("I have 4 products, badge says 11").
  int get productCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  double get freeDeliveryAbove => _freeDeliveryAbove;

  double get subtotal => _items.fold(0.0, (sum, item) =>
      sum + (item.product.effectivePrice * item.quantity));

  // Free delivery if shop has threshold set and subtotal exceeds it
  double get deliveryFee => (_freeDeliveryAbove > 0 && subtotal >= _freeDeliveryAbove) ? 0.0 : _deliveryFee;
  double get taxAmount => subtotal * _taxRate;
  double get promoDiscount => _promoDiscount;

  // Amount remaining for free delivery
  double get amountForFreeDelivery => _freeDeliveryAbove > 0 ? (_freeDeliveryAbove - subtotal).clamp(0, double.infinity) : 0;

  double get total => subtotal + deliveryFee + taxAmount - promoDiscount;

  // Set shop's free delivery threshold
  void setFreeDeliveryAbove(double amount) {
    _freeDeliveryAbove = amount;
    notifyListeners();
  }

  // Set delivery fee
  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    notifyListeners();
  }

  /// Refreshes the delivery fee for whichever shop is currently in the cart,
  /// using the shop's self-delivery fee or the platform's distance-based
  /// table (same resolution checkout uses). The cart screen otherwise only
  /// ever shows the ₹30 placeholder default above until checkout recalculates
  /// it, which is confusing when a shop's real fee (or self-delivery fee)
  /// differs, so this lets the cart screen show the true figure too.
  Future<void> recalculateDeliveryFeeForCurrentShop() async {
    if (_items.isEmpty) return;
    final shopId = int.tryParse(_items.first.product.shopDatabaseId.toString());
    if (shopId == null) return;

    try {
      final shopResponse = await ShopApiService().getShopById(shopId);
      final shopData = shopResponse['data'];

      // Independent of location/distance below - otherwise a cart item added
      // before minOrderAmount was wired up (or before this shop visit) stays
      // stuck on the 100 fallback even after the fix ships.
      final minOrderAmount = (shopData?['minOrderAmount'] as num?)?.toDouble();
      if (minOrderAmount != null) {
        setShopStatus(isOpen: _isShopOpen, minOrderAmount: minOrderAmount);
      }

      final customerLat = LocationService.cachedLatitude;
      final customerLng = LocationService.cachedLongitude;
      final shopLat = (shopData?['latitude'] as num?)?.toDouble();
      final shopLng = (shopData?['longitude'] as num?)?.toDouble();
      if (customerLat == null || customerLng == null || shopLat == null || shopLng == null) return;

      final result = await DeliveryFeeService.instance.calculateDeliveryFee(
        shopLatitude: shopLat,
        shopLongitude: shopLng,
        customerLatitude: customerLat,
        customerLongitude: customerLng,
        shopId: shopId,
      );
      if (result != null && result.success) {
        setDeliveryFee(result.deliveryFee);
      }
    } catch (e) {
      debugPrint('Cart delivery fee recalculation failed: $e');
    }
  }

  // Shop open status - set when entering shop, checked at checkout
  bool get isShopOpen => _isShopOpen;
  String? get shopName => _shopName;
  double? get minOrderAmount => _minOrderAmount;

  void setShopStatus({required bool isOpen, String? shopName, double? minOrderAmount}) {
    _isShopOpen = isOpen;
    if (shopName != null) _shopName = shopName;
    if (minOrderAmount != null) _minOrderAmount = minOrderAmount;
    _saveCartToStorage();
    notifyListeners();
  }

  CartProvider() {
    _loadCartFromStorage();
    // Only pull the backend's cart on a genuinely empty local cart (fresh
    // install/new device). The backend sync on addToCart is fire-and-forget
    // with no retry, so it can drift out of sync with local storage - blindly
    // overwriting a non-empty local cart with it on every app start would
    // silently drop items whenever a past sync had failed.
    if (_items.isEmpty) {
      loadCartFromBackend();
    }
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1, bool clearCartConfirmed = false}) async {
    if (kDebugMode) {
      print('🛒 CartProvider: Adding ${product.name} (qty: $quantity) to cart');
    }

    // Check if cart has items from different shop
    if (_items.isNotEmpty && !clearCartConfirmed && !_isSameShopAsCart(product)) {
      if (kDebugMode) {
        print('🛒 Different shop detected. Current: ${_items.first.product.shopId}, New: ${product.shopId}');
      }
      return false; // Return false to indicate shop conflict
    }

    _isLoading = true;
    notifyListeners();

    try {
      // ALWAYS add to local storage first for immediate UI feedback
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

      if (existingIndex >= 0) {
        // Check stock limit before adding more. stockQuantity <= 0 means the
        // shop doesn't track stock - rejecting the add here made the second
        // tap on such a product silently do nothing.
        final newQuantity = _items[existingIndex].quantity + quantity;
        if (product.stockQuantity > 0 && newQuantity > product.stockQuantity) {
          if (kDebugMode) {
            print('🛒 Stock limit reached. Available: ${product.stockQuantity}, Requested: $newQuantity');
          }
          _isLoading = false;
          notifyListeners();
          return false; // Stock limit exceeded
        }
        // Update both quantity AND product (to get latest data like nameTamil)
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: newQuantity,
          product: product,  // Update product to get latest Tamil name
        );
        if (kDebugMode) {
          print('🛒 Updated existing item, new qty: ${_items[existingIndex].quantity}, nameTamil: ${product.nameTamil}');
        }
      } else {
        // Check stock for new item
        if (quantity > product.stockQuantity) {
          if (kDebugMode) {
            print('🛒 Stock limit exceeded. Available: ${product.stockQuantity}, Requested: $quantity');
          }
          _isLoading = false;
          notifyListeners();
          return false; // Stock limit exceeded
        }
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

      // Sync with backend in the background. The item is already in the local
      // cart, so the UI (add button, related-products sheet) must not wait on
      // the network round-trip; the result was only ever logged anyway.
      final request = CoreCart.AddToCartRequest(
        shopProductId: product.id,
        quantity: quantity,
      );
      _cartService.addToCart(request).then((response) {
        if (kDebugMode) {
          print('🛒 Backend sync result: ${response['success']}');
        }
      }).catchError((backendError) {
        if (kDebugMode) {
          print('🛒 Backend sync failed (item still in local cart): $backendError');
        }
      });

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
      // stockQuantity <= 0 means "stock not tracked", not "sold out" - some
      // APIs send 0 when trackInventory is off. Blocking + here made the
      // button silently dead for such items.
      final maxStock = item.product.stockQuantity;
      if (maxStock <= 0 || item.quantity < maxStock) {
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
        // <=0 stock = "not tracked": clamping against it set quantities to 0
        final maxQuantity = item.product.stockQuantity;
        final validQuantity = (maxQuantity > 0 && quantity > maxQuantity)
            ? maxQuantity
            : quantity;
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
    _isShopOpen = true;
    _shopName = null;
    _minOrderAmount = null;
    _saveCartToStorage();
    notifyListeners();

    // Also clear the BACKEND cart (fire-and-forget). Without this, ordering
    // cleared only the local cart; on the next app start loadCartFromBackend()
    // resurrected the already-ordered items - with backend id/shopId formats
    // that no product screen matches, so +/- and re-add silently did nothing.
    _cartService.clearCart().catchError((e) {
      if (kDebugMode) print('🛒 Backend cart clear failed (local cleared): $e');
      return <String, dynamic>{'success': false};
    });
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
    // MUST NEVER THROW. Every mutator calls this BETWEEN changing _items and
    // notifyListeners() - an exception here (un-encodable product field,
    // storage failure) silently killed the notify, so the screen froze while
    // the state had actually changed ("+/- does nothing until I leave and
    // come back"). Persistence is best-effort; the UI update is not.
    try {
      final cartData = {
        'items': _items.map((item) => item.toJson()).toList(),
        'promoCode': _promoCode,
        'promoDiscount': _promoDiscount,
        'isShopOpen': _isShopOpen,
        'shopName': _shopName,
        'minOrderAmount': _minOrderAmount,
      };
      LocalStorage.setString('cart_data', jsonEncode(cartData));
    } catch (e) {
      if (kDebugMode) print('🛒 Cart save to storage failed (UI unaffected): $e');
    }
  }

  Future<void> loadCartFromBackend() async {
    try {
      final response = await _cartService.getCart();
      if (response['success'] == true) {
        // CartService.getCart() already parses the response into a Cart object
        // before returning it as 'data' - it is not raw JSON, so indexing into
        // it with ['cart'] or re-parsing via Cart.fromJson fails at runtime.
        final backendCart = response['data'] as CoreCart.Cart;
        
        if (kDebugMode) {
          print('Loaded cart from backend: ${backendCart.items.length} items');
        }
        
        // Convert backend cart items to local cart items
        final List<CartItem> convertedItems = [];
        final seenProductIds = <String>{};

        for (final backendItem in backendCart.items) {
          // A backend item without a usable product id can never be matched by
          // the +/- controls or re-add checks on any screen - skip it rather
          // than seeding the cart with un-editable zombie rows. Duplicate ids
          // are equally toxic (every lookup hits the first match), so keep
          // only the first occurrence of each id.
          if (backendItem.productId.trim().isEmpty ||
              !seenProductIds.add(backendItem.productId)) {
            if (kDebugMode) print('Skipping backend cart item with empty/duplicate productId: ${backendItem.productName}');
            continue;
          }
          // Create a ProductModel from the backend cart item data
          final product = ProductModel(
            id: backendItem.productId,
            name: backendItem.productName,
            nameTamil: backendItem.productNameTamil,
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
        // Drop items with an empty product id AND collapse duplicate ids.
        // All cart operations look items up by product.id, so duplicates make
        // every +/-/remove hit the FIRST matching row instead of the tapped
        // one ("row 1 quantity climbs while my row does nothing"). Devices
        // that cached a broken backend-cart restore self-heal on next launch.
        final loaded = (cartData['items'] as List)
            .map((item) => CartItem.fromJson(item))
            .where((item) => item.product.id.trim().isNotEmpty)
            .toList();
        final seenIds = <String>{};
        _items = loaded.where((item) => seenIds.add(item.product.id)).toList();
        _promoCode = cartData['promoCode'];
        _promoDiscount = cartData['promoDiscount']?.toDouble() ?? 0.0;
        _isShopOpen = cartData['isShopOpen'] ?? true;
        _shopName = cartData['shopName'];
        _minOrderAmount = (cartData['minOrderAmount'] as num?)?.toDouble();
        notifyListeners();
      } catch (e) {
        print('Error loading cart from storage: $e');
      }
    }
  }

  /// Normalized grouping key: different add paths encode the shop differently
  /// ("SHOP004" / "4" / empty), which split the SAME shop into multiple cart
  /// sections on screen. Group by numeric id when available, else by digits.
  String _shopGroupKey(ProductModel p) {
    if (p.shopDatabaseId != null) return p.shopDatabaseId.toString();
    final digits = p.shopId.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isNotEmpty ? digits : p.shopId;
  }

  Map<String, List<CartItem>> getItemsByShop() {
    final itemsByShop = <String, List<CartItem>>{};

    for (final item in _items) {
      final shopKey = _shopGroupKey(item.product);
      if (itemsByShop.containsKey(shopKey)) {
        itemsByShop[shopKey]!.add(item);
      } else {
        itemsByShop[shopKey] = [item];
      }
    }

    return itemsByShop;
  }

  List<String> getUniqueShopIds() {
    return _items.map((item) => item.product.shopId).toSet().toList();
  }

  double getShopSubtotal(String shopId) {
    // shopId here is the normalized group key from getItemsByShop()
    return _items
        .where((item) => _shopGroupKey(item.product) == shopId)
        .fold(0.0, (sum, item) => sum + (item.product.effectivePrice * item.quantity));
  }

  bool canCheckout() {
    // stockQuantity <= 0 = "shop doesn't track stock" - such items must not
    // block checkout (they silently disabled the Proceed to Checkout button).
    return _items.isNotEmpty && _items.every((item) =>
        item.product.isAvailable &&
        (item.product.stockQuantity <= 0 ||
            item.quantity <= item.product.stockQuantity));
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
    return _items.isEmpty || _isSameShopAsCart(product);
  }

  /// Robust same-shop check. Different add paths encode the shop differently
  /// (numeric DB id vs shop-code string vs empty), so a raw shopId string
  /// comparison called "different shop" for the SAME shop and WIPED the
  /// customer's cart when they opened the voice assistant. Prefer the numeric
  /// shopDatabaseId when both sides carry it; treat unknown as same-shop
  /// (never destroy a cart on missing data).
  bool _isSameShopAsCart(ProductModel product) {
    if (_items.isEmpty) return true;
    final current = _items.first.product;
    if (current.shopDatabaseId != null && product.shopDatabaseId != null) {
      return current.shopDatabaseId == product.shopDatabaseId;
    }
    final a = current.shopId.trim();
    final b = product.shopId.trim();
    if (a.isEmpty || b.isEmpty) return true;
    if (a == b) return true;
    // "SHOP004" vs "4" style mismatches: compare the numeric parts
    final ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
    final bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
    if (ai != null && bi != null) return ai == bi;
    return false;
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