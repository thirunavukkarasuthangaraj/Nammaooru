import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/auth/auth_provider.dart';
import '../services/womens_corner_service.dart';
import 'womens_corner_detail_screen.dart';
import 'create_womens_corner_screen.dart';

class WomensCornerScreen extends StatefulWidget {
  const WomensCornerScreen({super.key});

  @override
  State<WomensCornerScreen> createState() => _WomensCornerScreenState();
}

class _WomensCornerScreenState extends State<WomensCornerScreen> {
  static const Color _primaryColor = Color(0xFFE91E63);
  final WomensCornerService _service = WomensCornerService();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingCategories = true;
  bool _isLoadingPosts = true;
  String? _selectedCategory;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadPosts({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoadingPosts = true;
        _currentPage = 0;
        _posts = [];
        _hasMore = true;
      });
    }

    try {
      double? lat, lng;
      try {
        final position = await LocationService.instance.getCurrentPosition();
        if (position != null && position.latitude != null && position.longitude != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (_) {}

      final response = await _service.getApprovedPosts(
        page: _currentPage,
        category: _selectedCategory,
        latitude: lat,
        longitude: lng,
        radiusKm: 50,
      );

      if (mounted) {
        final data = response['data'];
        List<Map<String, dynamic>> newPosts = [];
        if (data is Map && data['content'] is List) {
          newPosts = List<Map<String, dynamic>>.from(data['content']);
        } else if (data is List) {
          newPosts = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          if (reset) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _hasMore = newPosts.length >= 20;
          _isLoadingPosts = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    _isLoadingMore = true;
    _currentPage++;
    await _loadPosts(reset: false);
  }

  void _onCategoryTap(String? categoryName) {
    setState(() {
      _selectedCategory = _selectedCategory == categoryName ? null : categoryName;
    });
    _loadPosts();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    if (numPrice <= 0) return '';
    return '\u20B9${numPrice.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText("Women's Corner", '\u0BAA\u0BC6\u0BA3\u0BCD\u0B95\u0BB3\u0BCD \u0BAA\u0B95\u0BC1\u0BA4\u0BBF'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: () async {
          await _loadCategories();
          await _loadPosts();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Categories Grid
            SliverToBoxAdapter(
              child: _buildCategoriesSection(langProvider),
            ),

            // Posts Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory != null
                          ? _selectedCategory!
                          : langProvider.getText('Near You', '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B85\u0BB0\u0BC1\u0B95\u0BBF\u0BB2\u0BCD'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _onCategoryTap(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 14),
                              SizedBox(width: 2),
                              Text('Clear', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Posts List
            if (_isLoadingPosts)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        langProvider.getText('No posts yet', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD \u0B87\u0BB2\u0BCD\u0BB2\u0BC8'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildPostCard(_posts[index], langProvider);
                  },
                  childCount: _posts.length + (_hasMore ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
          if (!isLoggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(langProvider.getText('Please login to post', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BBF\u0B9F \u0B89\u0BB3\u0BCD\u0BA8\u0BC1\u0BB4\u0BC8\u0B95')),
              ),
            );
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateWomensCornerScreen()),
          );
          if (result == true) {
            _loadPosts();
          }
        },
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(langProvider.getText('Post', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1')),
      ),
    );
  }

  Widget _buildCategoriesSection(LanguageProvider langProvider) {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          final color = _parseColor(cat['color']) ?? _primaryColor;
          final imageUrl = cat['imageUrl'];

          return GestureDetector(
            onTap: () => _onCategoryTap(cat['name']),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageUrl != null && imageUrl.toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.auto_awesome, size: 36, color: color),
                      ),
                    )
                  else
                    Icon(Icons.auto_awesome, size: 36, color: color),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey[800],
                    ),
                  ),
                  if (cat['tamilName'] != null)
                    Text(
                      cat['tamilName'],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? color : Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, LanguageProvider langProvider) {
    final imageUrls = post['imageUrls']?.toString() ?? '';
    final firstImage = imageUrls.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(imageUrls.split(',').first.trim())
        : null;
    final price = _formatPrice(post['price']);
    final category = post['category'] ?? '';
    final location = post['location'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WomensCornerDetailScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: firstImage != null
                  ? CachedNetworkImage(
                      imageUrl: firstImage,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 110,
                        height: 110,
                        color: _primaryColor.withOpacity(0.1),
                        child: Icon(Icons.auto_awesome, size: 40, color: _primaryColor.withOpacity(0.4)),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: _primaryColor.withOpacity(0.1),
                      child: Icon(Icons.auto_awesome, size: 40, color: _primaryColor.withOpacity(0.4)),
                    ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 11, color: _primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFFE91E63);
  }
}
