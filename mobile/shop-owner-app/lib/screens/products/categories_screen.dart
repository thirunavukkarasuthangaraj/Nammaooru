import 'package:flutter/material.dart';
import '../../services/api_service_simple.dart';
import '../../utils/constants.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
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
            // The shop-categories endpoint this screen calls returns the
            // category image as 'imageUrl' (see api_service_simple.dart
            // getCategories() comment) - 'iconUrl' is a different, legacy
            // field that's usually empty, which was silently forcing every
            // category to fall back to its emoji/letter placeholder.
            final iconUrl = (cat['imageUrl'] ?? cat['iconUrl'] ?? '').toString();
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Product Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
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

    // Simplified to a plain Card (radius 12, single soft shadow) so this
    // matches the flat, low-noise card style used across the rest of the
    // app instead of the heavy double-shadow/gradient-border look.
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCategoryProducts(categoryName, productCount),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Image/Icon Display
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          AppConfig.getImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackIcon(iconEmoji, icon, categoryColor),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
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
            ),

            // Category Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    productCount > 0 ? '$productCount items' : 'Empty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback when a category has no valid image: the real emoji if the API
  // gave us one, else a plain letter badge (never a generic dummy icon).
  Widget _buildFallbackIcon(String? iconEmoji, String defaultIcon, Color categoryColor) {
    final displayIcon = iconEmoji ?? defaultIcon;

    return Center(
      child: Text(
        displayIcon,
        style: const TextStyle(fontSize: 36),
        textAlign: TextAlign.center,
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
