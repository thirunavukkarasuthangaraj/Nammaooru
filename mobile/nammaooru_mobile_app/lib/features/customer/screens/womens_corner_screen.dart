import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingCategories = true;
  bool _isLoadingPosts = true;
  String? _selectedCategory;
  String _searchQuery = '';
  double _radiusKm = 50;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  static const List<double> _radiusOptions = [10, 25, 50, 100, 200];

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
    _searchController.dispose();
    _searchDebounce?.cancel();
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
        radiusKm: _radiusKm,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query.trim());
      _loadPosts();
    });
  }

  void _showRadiusFilter(LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                langProvider.getText('Filter by Radius', '\u0B86\u0BB0\u0BC8 \u0BB5\u0B9F\u0BBF\u0B95\u0B9F\u0BCD\u0B9F\u0BC1'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _radiusOptions.map((r) {
                  final isSelected = _radiusKm == r;
                  return ChoiceChip(
                    label: Text('${r.toInt()} km'),
                    selected: isSelected,
                    selectedColor: _primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _radiusKm = r);
                      Navigator.pop(ctx);
                      _loadPosts();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
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
        actions: [
          // Radius filter button
          GestureDetector(
            onTap: () => _showRadiusFilter(langProvider),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${_radiusKm.toInt()} km',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: langProvider.getText('Search services...', '\u0B9A\u0BC7\u0BB5\u0BC8\u0B95\u0BB3\u0BC8 \u0BA4\u0BC7\u0B9F\u0BC1...'),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: _primaryColor.withOpacity(0.6)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadPosts();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // Categories Grid
            SliverToBoxAdapter(
              child: _buildCategoriesSection(langProvider),
            ),

            // Active Filters
            if (_selectedCategory != null || _searchQuery.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_selectedCategory != null)
                        Chip(
                          label: Text(_selectedCategory!, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _onCategoryTap(null),
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          deleteIconColor: _primaryColor,
                          labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ),
                      if (_searchQuery.isNotEmpty)
                        Chip(
                          label: Text('"$_searchQuery"', style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadPosts();
                          },
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          deleteIconColor: Colors.blue,
                          labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ),
              ),

            // Posts Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCategory != null
                            ? _selectedCategory!
                            : langProvider.getText('Near You', '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B85\u0BB0\u0BC1\u0B95\u0BBF\u0BB2\u0BCD'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Post count
                    if (!_isLoadingPosts)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_posts.length}',
                          style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Posts Grid
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
                      if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = null;
                            });
                            _loadPosts();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(langProvider.getText('Clear filters', '\u0BB5\u0B9F\u0BBF\u0B95\u0B9F\u0BCD\u0B9F\u0BBF \u0B85\u0BB4\u0BBF')),
                          style: TextButton.styleFrom(foregroundColor: _primaryColor),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _posts.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      return _buildPostGridCard(_posts[index], langProvider);
                    },
                    childCount: _posts.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
          if (!isLoggedIn) {
            GoRouter.of(context).go('/login');
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          final color = _parseColor(cat['color']) ?? _primaryColor;
          final imageUrl = cat['imageUrl'];

          return GestureDetector(
            onTap: () => _onCategoryTap(cat['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? color.withOpacity(0.3) : Colors.black.withOpacity(0.06),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Icon / Image
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: imageUrl != null && imageUrl.toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.auto_awesome,
                                  size: 28,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.auto_awesome,
                              size: 28,
                              color: isSelected ? Colors.white : color,
                            ),
                    ),
                    const SizedBox(width: 10),
                    // Text
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          if (cat['tamilName'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              cat['tamilName'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Selection indicator
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostGridCard(Map<String, dynamic> post, LanguageProvider langProvider) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    firstImage != null
                        ? CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: _primaryColor.withOpacity(0.08),
                              child: Icon(Icons.auto_awesome, size: 40, color: _primaryColor.withOpacity(0.3)),
                            ),
                          )
                        : Container(
                            color: _primaryColor.withOpacity(0.08),
                            child: Icon(Icons.auto_awesome, size: 40, color: _primaryColor.withOpacity(0.3)),
                          ),
                    // Category badge
                    if (category.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    // Price badge
                    if (price.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            price,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primaryColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const Spacer(),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
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
