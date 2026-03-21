import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/product_model.dart';

class ProductService {
  static Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.products);
      final List<dynamic> data = response.data;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
  
  static Future<List<ProductModel>> getShopProducts(String shopId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.shopProducts(shopId));
      final List<dynamic> data = response.data;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load shop products: $e');
    }
  }
  
  static Future<ProductModel> getProductDetails(String productId) async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.products}/$productId');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load product details: $e');
    }
  }
  
  static Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.products,
        queryParameters: {'search': query},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
  
  static Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.products,
        queryParameters: {'categoryId': categoryId},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load category products: $e');
    }
  }
  
  // Shop owner methods
  static Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.products,
        data: productData,
      );
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }
  
  static Future<ProductModel> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.put(
        '${ApiEndpoints.products}/$productId',
        data: productData,
      );
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }
  
  static Future<bool> deleteProduct(String productId) async {
    try {
      await ApiClient.delete('${ApiEndpoints.products}/$productId');
      return true;
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
  
  static Future<bool> updateStock(String productId, int quantity) async {
    try {
      await ApiClient.put(
        ApiEndpoints.updateStock(productId),
        data: {'quantity': quantity},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String categoryId;
  final String shopId;
  final int stockQuantity;
  final bool isAvailable;
  final double? discount;
  final double rating;
  final int reviewCount;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    required this.shopId,
    required this.stockQuantity,
    required this.isAvailable,
    this.discount,
    this.rating = 0.0,
    this.reviewCount = 0,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId'] ?? '',
      shopId: json['shopId'] ?? '',
      stockQuantity: json['stockQuantity'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      discount: json['discount']?.toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'shopId': shopId,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'discount': discount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}