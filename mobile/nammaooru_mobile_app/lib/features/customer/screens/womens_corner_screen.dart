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
import '../widgets/renewal_payment_handler.dart';
import 'womens_corner_detail_screen.dart';
import 'create_womens_corner_screen.dart';

class WomensCornerScreen extends StatefulWidget {
  const WomensCornerScreen({super.key});

  @override
  State<WomensCornerScreen> createState() => _WomensCornerScreenState();
}

class _WomensCornerScreenState extends State<WomensCornerScreen> with SingleTickerProviderStateMixin {
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

  // My Posts tab
  late TabController _tabController;
  List<dynamic> _myPosts = [];
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;
  Set<int> _selectedForRenewal = {};
  bool _isRenewing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_myPostsLoaded) {
        _loadMyPosts();
      }
      setState(() {}); // Update tab count badge
    });
    _loadCategories();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _loadMyPosts() async {
    setState(() => _isLoadingMyPosts = true);
    try {
      final response = await _service.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = response['data'] ?? [];
          _myPostsLoaded = true;
          _isLoadingMyPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyPosts = false);
      }
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: langProvider.getText('All Posts', '\u0B85\u0BA9\u0BC8\u0BA4\u0BCD\u0BA4\u0BC1 \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD')),
            Tab(text: '${langProvider.getText('My Posts', '\u0B8E\u0BA9\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BCD')}${_myPosts.isNotEmpty ? ' (${_myPosts.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Posts
          _buildAllPostsTab(),
          // Tab 2: My Posts
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      GoRouter.of(context).go('/login');
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWomensCornerScreen()),
    );
    if (result == true) {
      _loadPosts();
      _myPostsLoaded = false;
      _loadMyPosts();
      // Switch to My Posts tab
      _tabController.animateTo(1);
    }
  }

  // ─── Tab 1: All Posts ───

  Widget _buildAllPostsTab() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Column(
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
    );
  }

  // ─── Tab 2: My Posts ───

  Widget _buildMyPostsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('Please log in to see your posts', '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BC8 \u0BAA\u0BBE\u0BB0\u0BCD\u0B95\u0BCD\u0B95 \u0BB2\u0BBE\u0B95\u0BBF\u0BA9\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BB5\u0BC1\u0BAE\u0BCD'),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
              child: Text(langProvider.getText('Log In', '\u0BB2\u0BBE\u0B95\u0BBF\u0BA9\u0BCD')),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMyPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              langProvider.getText("You haven't posted anything yet", '\u0BA8\u0BC0\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0BA9\u0BCD\u0BA9\u0BC1\u0BAE\u0BCD \u0B8E\u0BA4\u0BC1\u0BB5\u0BC1\u0BAE\u0BCD \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BB5\u0BBF\u0BB2\u0BCD\u0BB2\u0BC8'),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add),
              label: Text(langProvider.getText('Post Something', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD')),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    // Count expired/expiring posts for bulk selection
    final expiredPostIds = _myPosts.where((p) {
      final vTo = p['validTo'] != null ? DateTime.tryParse(p['validTo'].toString()) : null;
      if (vTo == null) return false;
      final now = DateTime.now();
      return vTo.isBefore(now) || (vTo.isAfter(now) && vTo.difference(now).inDays <= 3);
    }).map((p) => p['id'] as int).toList();

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        _myPostsLoaded = false;
        setState(() => _selectedForRenewal.clear());
        await _loadMyPosts();
      },
      child: Column(
        children: [
          if (expiredPostIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedForRenewal.length == expiredPostIds.length && expiredPostIds.isNotEmpty,
                      tristate: true,
                      onChanged: (val) {
                        setState(() {
                          if (_selectedForRenewal.length == expiredPostIds.length) {
                            _selectedForRenewal.clear();
                          } else {
                            _selectedForRenewal = expiredPostIds.toSet();
                          }
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedForRenewal.isEmpty
                        ? langProvider.getText('Select expired posts to renew', '\u0B95\u0BBE\u0BB2\u0BBE\u0BB5\u0BA4\u0BBF\u0BAF\u0BBE\u0BA9 \u0BAA\u0BA4\u0BBF\u0BB5\u0BC1\u0B95\u0BB3\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BB5\u0BC1\u0BAE\u0BCD')
                        : '${_selectedForRenewal.length} ${langProvider.getText('selected', '\u0BA4\u0BC7\u0BB0\u0BCD\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1')}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  if (_selectedForRenewal.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isRenewing ? null : _renewSelectedPosts,
                      icon: _isRenewing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_isRenewing ? 'Renewing...' : 'Renew All (${_selectedForRenewal.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                final post = _myPosts[index];
                return _buildMyPostCard(post);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostCard(Map<String, dynamic> post) {
    final status = post['status'] ?? 'PENDING_APPROVAL';
    final imageUrls = post['imageUrls']?.toString() ?? '';
    final firstImage = imageUrls.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(imageUrls.split(',').first.trim())
        : null;
    final price = post['price'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'SOLD':
        statusColor = Colors.blue;
        statusText = 'Sold';
        statusIcon = Icons.sell;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'FLAGGED':
        statusColor = const Color(0xFFB71C1C);
        statusText = 'Flagged';
        statusIcon = Icons.flag;
        break;
      case 'HOLD':
        statusColor = Colors.amber.shade700;
        statusText = 'On Hold';
        statusIcon = Icons.pause_circle;
        break;
      case 'HIDDEN':
        statusColor = Colors.grey;
        statusText = 'Hidden';
        statusIcon = Icons.visibility_off;
        break;
      case 'CORRECTION_REQUIRED':
        statusColor = Colors.deepOrange;
        statusText = 'Correction Required';
        statusIcon = Icons.edit;
        break;
      case 'REMOVED':
        statusColor = const Color(0xFFB71C1C);
        statusText = 'Removed';
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
        statusIcon = Icons.hourglass_empty;
    }

    // Validity dates and expiry status
    final validFrom = post['validFrom'] != null ? DateTime.tryParse(post['validFrom'].toString()) : null;
    final validTo = post['validTo'] != null ? DateTime.tryParse(post['validTo'].toString()) : null;
    final now = DateTime.now();
    final bool isExpiringSoon = validTo != null && validTo.isAfter(now) && validTo.difference(now).inDays <= 3;
    final bool isExpired = validTo != null && validTo.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          // Validity & expiry info
          if (validTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isExpired ? Colors.red.withOpacity(0.08) : isExpiringSoon ? Colors.orange.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Valid: ${validFrom != null ? "${validFrom.day}/${validFrom.month}/${validFrom.year}" : "\u2014"} - ${validTo.day}/${validTo.month}/${validTo.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: const Text('EXPIRING SOON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          // Image
          if (firstImage != null)
            CachedNetworkImage(
              imageUrl: firstImage,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180, color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180, color: Colors.grey[200],
                child: Icon(Icons.auto_awesome, size: 50, color: _primaryColor.withOpacity(0.3)),
              ),
            ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price != null)
                      Text(_formatPrice(price), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
                  ],
                ),
                if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(post['description'], style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (isExpiringSoon || isExpired) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _selectedForRenewal.contains(post['id']),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedForRenewal.add(post['id']);
                              } else {
                                _selectedForRenewal.remove(post['id']);
                              }
                            });
                          },
                          activeColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRenewing ? null : () => _renewSinglePost(post['id']),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Renew Post'),
                          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await _service.markAsSold(post['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                              );
                              if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                            }
                          },
                          icon: const Icon(Icons.sell, size: 16),
                          label: const Text('Mark Sold'),
                          style: OutlinedButton.styleFrom(foregroundColor: _primaryColor),
                        ),
                      ),
                    if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED')
                      const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showEditSheet(post),
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Post?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final result = await _service.deletePost(post['id']);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                            );
                            if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
    final priceController = TextEditingController(text: post['price']?.toString() ?? '');
    final phoneController = TextEditingController(text: post['phone'] ?? post['sellerPhone'] ?? '');
    final locationController = TextEditingController(text: post['location'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      final updates = <String, dynamic>{};
                      if (titleController.text != (post['title'] ?? '')) updates['title'] = titleController.text;
                      if (descController.text != (post['description'] ?? '')) updates['description'] = descController.text;
                      if (priceController.text != (post['price']?.toString() ?? '')) updates['price'] = priceController.text;
                      if (phoneController.text != (post['phone'] ?? post['sellerPhone'] ?? '')) updates['phone'] = phoneController.text;
                      if (locationController.text != (post['location'] ?? '')) updates['location'] = locationController.text;
                      if (updates.isEmpty) { Navigator.pop(ctx); return; }
                      final result = await _service.editPost(post['id'], updates);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _renewSinglePost(int postId) {
    final handler = RenewalPaymentHandler(context: context, postType: 'WOMENS_CORNER');
    handler.renewSingle(
      onTokenReceived: (paidTokenId) async {
        final result = await _service.renewPost(postId, paidTokenId: paidTokenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
          );
          if (result['success'] == true) {
            setState(() { _myPostsLoaded = false; _selectedForRenewal.remove(postId); });
            _loadMyPosts();
          }
        }
        handler.dispose();
      },
      onCancelled: () => handler.dispose(),
    );
  }

  void _renewSelectedPosts() {
    if (_selectedForRenewal.isEmpty) return;
    final selectedIds = _selectedForRenewal.toList();
    final count = selectedIds.length;

    setState(() => _isRenewing = true);
    final handler = RenewalPaymentHandler(context: context, postType: 'WOMENS_CORNER');
    handler.renewBulk(
      count: count,
      onTokensReceived: (paidTokenIds) async {
        int successCount = 0;
        for (int i = 0; i < selectedIds.length && i < paidTokenIds.length; i++) {
          final result = await _service.renewPost(selectedIds[i], paidTokenId: paidTokenIds[i]);
          if (result['success'] == true) successCount++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successCount of $count posts renewed successfully'), backgroundColor: successCount > 0 ? Colors.green : Colors.red),
          );
          setState(() { _isRenewing = false; _selectedForRenewal.clear(); _myPostsLoaded = false; });
          _loadMyPosts();
        }
        handler.dispose();
      },
      onCancelled: () {
        setState(() => _isRenewing = false);
        handler.dispose();
      },
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
                            imageUrl: ImageUrlHelper.getFullImageUrl(firstImage),
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
