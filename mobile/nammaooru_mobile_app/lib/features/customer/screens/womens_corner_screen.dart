import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/post_filter_bar.dart';
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

  List<String> _categories = ['All'];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String _searchText = '';
  double _selectedRadius = 50.0;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  double? _userLatitude;
  double? _userLongitude;

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
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    if (mounted) {
      final names = categories
          .map((c) => c['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      setState(() {
        _categories = ['All', ...names];
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    // Fetch GPS in background
    if (_userLatitude == null || _userLongitude == null) {
      LocationService.instance.getCurrentPosition().then((position) {
        if (position != null && position.latitude != null && position.longitude != null) {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        }
      }).catchError((_) {});
    }

    try {
      final response = await _service.getApprovedPosts(
        page: 0,
        category: _selectedCategory,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
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
          _posts = newPosts;
          _hasMore = (data is Map ? data['hasNext'] : null) ?? newPosts.length >= 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    _currentPage++;
    try {
      final response = await _service.getApprovedPosts(
        page: _currentPage,
        category: _selectedCategory,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
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
          _posts.addAll(newPosts);
          _hasMore = (data is Map ? data['hasNext'] : null) ?? newPosts.length >= 20;
        });
      }
    } catch (e) {
      _currentPage--;
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
    _loadPosts();
  }

  String _getCategoryLabel(String cat) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    // Return Tamil if available, else original
    return langProvider.getText(cat, cat);
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    if (numPrice <= 0) return '';
    return '\u20B9${numPrice.toStringAsFixed(0)}';
  }

  List<Map<String, dynamic>> _buildCarouselPosts() {
    return _posts
        .where((post) => post['featured'] == true)
        .take(8)
        .toList();
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
      body: Column(
        children: [
          PostFilterBar(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (cat) => _onCategorySelected(cat ?? 'All'),
            selectedRadius: _selectedRadius,
            onRadiusChanged: (radius) {
              setState(() => _selectedRadius = radius ?? 50.0);
              _loadPosts();
            },
            searchText: _searchText,
            onSearchSubmitted: (text) {
              setState(() => _searchText = text);
              _loadPosts();
            },
            accentColor: _primaryColor,
            categoryLabelBuilder: _getCategoryLabel,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? _buildEmptyState(langProvider)
                    : RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: _loadPosts,
                        child: Builder(builder: (context) {
                          final carouselPosts = _buildCarouselPosts();
                          final hasCarousel = carouselPosts.isNotEmpty;
                          final offset = hasCarousel ? 1 : 0;
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _posts.length + offset + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (hasCarousel && index == 0) {
                                return _FeaturedBannerCarousel(
                                  posts: carouselPosts,
                                  onPostTap: (post) => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WomensCornerDetailScreen(post: post)),
                                  ),
                                  accentColor: _primaryColor,
                                );
                              }
                              final postIndex = index - offset;
                              if (postIndex == _posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _buildPostCard(_posts[postIndex]);
                            },
                          );
                        }),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider langProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            langProvider.getText('No posts yet', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD \u0B87\u0BB2\u0BCD\u0BB2\u0BC8'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            langProvider.getText('Be the first to post!', '\u0BAE\u0BC1\u0BA4\u0BB2\u0BBF\u0BB2\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD!'),
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (_searchText.isNotEmpty || _selectedCategory != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchText = '';
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
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls']?.toString() ?? '';
    final firstImage = imageUrls.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(imageUrls.split(',').first.trim())
        : null;
    final price = _formatPrice(post['price']);
    final category = post['category'] ?? '';
    final location = post['location'] ?? '';
    final title = post['title'] ?? '';
    final description = post['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WomensCornerDetailScreen(post: post)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (firstImage != null)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: firstImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: _primaryColor.withOpacity(0.08),
                      child: Icon(Icons.auto_awesome, size: 50, color: _primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  // Category badge
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  // Price badge
                  if (price.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          price,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _primaryColor),
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: _primaryColor.withOpacity(0.08),
                child: Icon(Icons.auto_awesome, size: 50, color: _primaryColor.withOpacity(0.3)),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (location.isNotEmpty) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                      if (category.isNotEmpty && location.isNotEmpty)
                        const SizedBox(width: 12),
                      if (category.isNotEmpty && firstImage == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(fontSize: 11, color: _primaryColor),
                          ),
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
}

// ─── Featured Banner Carousel ───

class _FeaturedBannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final Function(Map<String, dynamic>) onPostTap;
  final Color accentColor;

  const _FeaturedBannerCarousel({
    required this.posts,
    required this.onPostTap,
    required this.accentColor,
  });

  @override
  State<_FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<_FeaturedBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && widget.posts.length > 1) {
        final nextPage = (_currentPage + 1) % widget.posts.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<String> _parseImageUrls(Map<String, dynamic> post) {
    final raw = post['imageUrls'] ?? post['imageUrl'] ?? '';
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    return raw.toString().split(',').where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Icon(Icons.star, color: widget.accentColor, size: 20),
              const SizedBox(width: 6),
              Text(
                'Featured',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.accentColor),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              final imageUrls = _parseImageUrls(post);
              final firstImage = imageUrls.isNotEmpty ? imageUrls.first : null;

              return GestureDetector(
                onTap: () => widget.onPostTap(post),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstImage != null)
                          CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Text(
                            post['title'] ?? post['name'] ?? post['serviceName'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        if (widget.posts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.posts.length, (index) {
              return Container(
                width: _currentPage == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage == index ? widget.accentColor : Colors.grey[350],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
