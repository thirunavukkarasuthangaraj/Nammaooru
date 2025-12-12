import 'package:flutter/material.dart';
import '../../services/api_service_simple.dart';
import '../../utils/constants.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      // Fetch categories from API
      final response = await ApiService.getCategories();

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final categoriesData = data['data'] ?? data;
        final content = categoriesData['content'] ?? categoriesData ?? [];

        print('📦 Categories API Response:');
        print('Total categories: ${content is List ? content.length : 0}');
        if (content is List && content.isNotEmpty) {
          print('First category sample: ${content[0]}');
        }

        final List<Map<String, dynamic>> categoryList = [];
        if (content is List) {
          for (var cat in content) {
            final iconUrl = cat['iconUrl'] ?? '';
            final imageUrl = iconUrl.isNotEmpty && (iconUrl.startsWith('/') || iconUrl.startsWith('http'))
                ? iconUrl
                : null;

            print('📂 Category: ${cat['name']}, iconUrl: $iconUrl, imageUrl: $imageUrl, productCount: ${cat['productCount']}');

            categoryList.add({
              'name': cat['name'] ?? 'Unknown',
              'displayName': cat['nameTamil'] != null && cat['nameTamil'].toString().isNotEmpty
                  ? '${cat['name']} / ${cat['nameTamil']}'
                  : cat['name'] ?? 'Unknown',
              'count': cat['productCount'] ?? 0,
              'icon': _getCategoryIcon(cat['name'] ?? ''),
              'iconEmoji': iconUrl.isNotEmpty && !iconUrl.contains('/') && !iconUrl.contains('http') ? iconUrl : null,
              'imageUrl': imageUrl,
              'id': cat['id'],
              'color': _getCategoryColor(cat['name'] ?? ''),
            });
          }
        }

        print('✅ Processed ${categoryList.length} categories');
        setState(() {
          _categories = categoryList;
          _isLoading = false;
        });
      } else {
        print('❌ API response failed or no data');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getCategoryIcon(String category) {
    final icons = {
      'Snacks': '🍿',
      'Medicine': '💊',
      'Spices': '🌶️',
      'Beverages': '☕',
      'Household': '🏠',
      'Electronics': '📱',
      'Dairy': '🥛',
      'Groceries': '🛒',
      'Bakery': '🍞',
      'Fruits': '🍎',
      'Vegetables': '🥬',
      'Meat': '🍖',
      'Seafood': '🐟',
      'Frozen': '🧊',
      'Personal Care': '🧴',
      'Baby Products': '👶',
      'Pet Supplies': '🐾',
      'Stationery': '✏️',
      'Oil, Ghee & Masala': '🌶️',
      'Dairy, Bread & Eggs': '🥛',
      'Atta, Rice & Dal': '🌾',
      'Bakery & Biscuits': '🍪',
      'Chips & Namkeen': '🍿',
      'Vegetables & Fruits': '🥬',
    };
    return icons[category] ?? '📦';
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Vegetables & Fruits': Color(0xFF4CAF50),
      'Oil, Ghee & Masala': Color(0xFFFF9800),
      'Dairy, Bread & Eggs': Color(0xFF2196F3),
      'Atta, Rice & Dal': Color(0xFF9C27B0),
      'Bakery & Biscuits': Color(0xFFE91E63),
      'Chips & Namkeen': Color(0xFFF44336),
    };
    return colors[category] ?? Color(0xFF00897B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Product Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Browse by Category',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_categories.length} Categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Categories Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return _buildModernCategoryCard(category);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildModernCategoryCard(Map<String, dynamic> category) {
    final categoryName = category['name'] as String;
    final displayName = category['displayName'] as String;
    final productCount = category['count'] as int;
    final imageUrl = category['imageUrl'] as String?;
    final iconEmoji = category['iconEmoji'] as String?;
    final icon = category['icon'] as String;
    final categoryColor = category['color'] as Color;

    return InkWell(
      onTap: () => _navigateToCategoryProducts(categoryName, productCount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              categoryColor.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Image/Icon Display
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.15),
                          categoryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Image.network(
                              imageUrl.startsWith('http')
                                  ? imageUrl
                                  : 'http://localhost:8080${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                print('❌ Error loading category image: $imageUrl');
                                print('   Error details: $error');
                                return _buildFallbackIcon(iconEmoji, icon, categoryColor);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('✅ Category image loaded: $imageUrl');
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: categoryColor,
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          )
                        : _buildFallbackIcon(iconEmoji, icon, categoryColor),
                  ),
                ],
              ),
            ),

            // Category Info with Enhanced Design
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withOpacity(0.15),
                                categoryColor.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 14,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  productCount > 0 ? '$productCount items' : 'Empty',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: categoryColor,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: categoryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build fallback icon when image is not available
  Widget _buildFallbackIcon(String? iconEmoji, String defaultIcon, Color categoryColor) {
    final displayIcon = iconEmoji ?? defaultIcon;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            categoryColor.withOpacity(0.2),
            categoryColor.withOpacity(0.1),
            categoryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.25),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Text(
            displayIcon,
            style: const TextStyle(fontSize: 42),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageGrid(List products, String icon, Color categoryColor) {
    // If we have products with images, show a 2x2 grid
    if (products.isNotEmpty) {
      final productImages = products
          .where((p) => p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty)
          .take(4)
          .toList();

      if (productImages.length >= 2) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              if (index < productImages.length) {
                return Stack(
                  children: [
                    Image.network(
                      productImages[index]['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withOpacity(0.15),
                                categoryColor.withOpacity(0.08),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: categoryColor.withOpacity(0.4),
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                    // Subtle overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Empty grid cell with subtle background
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withOpacity(0.08),
                        categoryColor.withOpacity(0.03),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: categoryColor.withOpacity(0.25),
                      size: 24,
                    ),
                  ),
                );
              }
            },
          ),
        );
      }
    }

    // Fallback to large emoji icon with gradient background
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            categoryColor.withOpacity(0.15),
            categoryColor.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Categories Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Categories will appear here once added',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToCategoryProducts(String categoryName, int productCount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsScreen(
          categoryName: categoryName,
          productCount: productCount,
        ),
      ),
    );
  }
}
