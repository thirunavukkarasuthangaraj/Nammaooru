import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/services/location_service.dart';
import '../services/rental_service.dart';
import 'create_rental_screen.dart';
import 'rental_post_detail_screen.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> with SingleTickerProviderStateMixin {
  final RentalService _rentalService = RentalService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;
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

  static const Color _rentalOrange = Color(0xFFFF6F00);

  static const Map<String, String> _categoryLabels = {
    'All': 'All',
    'SHOP': 'Shop',
    'AUTO': 'Auto',
    'BIKE': 'Bike',
    'HOUSE': 'House',
    'LAND': 'Land',
    'EQUIPMENT': 'Equipment',
    'FURNITURE': 'Furniture',
  };

  static const Map<String, String> _categoryTamilMap = {
    'All': 'அனைத்தும்',
    'SHOP': 'கடை',
    'AUTO': 'ஆட்டோ',
    'BIKE': 'பைக்',
    'HOUSE': 'வீடு',
    'LAND': 'நிலம்',
    'EQUIPMENT': 'உபகரணம்',
    'FURNITURE': 'மரச்சாமான்',
  };

  static const Map<String, String> _priceUnitLabels = {
    'per_hour': '/hr',
    'per_day': '/day',
    'per_month': '/mo',
  };

  static const Map<String, IconData> _categoryIcons = {
    'SHOP': Icons.storefront,
    'AUTO': Icons.electric_rickshaw,
    'BIKE': Icons.two_wheeler,
    'HOUSE': Icons.home,
    'LAND': Icons.landscape,
    'EQUIPMENT': Icons.construction,
    'FURNITURE': Icons.chair,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _getUserLocation();
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_myPostsLoaded) {
      _loadMyPosts();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading && _tabController.index == 0) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && position.latitude != null && position.longitude != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      }
    } catch (e) {
      // Location is optional
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _posts = [];
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _rentalService.getApprovedPosts(
        page: _currentPage,
        size: 20,
        category: _selectedCategory,
        latitude: _userLatitude,
        longitude: _userLongitude,
      );

      if (mounted) {
        final data = response['data'];
        final content = data?['content'] ?? [];
        final totalPages = data?['totalPages'] ?? 0;

        setState(() {
          if (refresh || _currentPage == 0) {
            _posts = content;
          } else {
            _posts.addAll(content);
          }
          _hasMore = _currentPage < totalPages - 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    _currentPage++;
    _loadPosts();
  }

  Future<void> _loadMyPosts() async {
    setState(() {
      _isLoadingMyPosts = true;
    });

    try {
      final response = await _rentalService.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = response['data'] ?? [];
          _isLoadingMyPosts = false;
          _myPostsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMyPosts = false;
          _myPostsLoaded = true;
        });
      }
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
      _posts = [];
    });
    _loadPosts();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    if (numPrice >= 100000) {
      return '\u20B9${(numPrice / 100000).toStringAsFixed(1)}L';
    } else if (numPrice >= 1000) {
      return '\u20B9${(numPrice / 1000).toStringAsFixed(numPrice % 1000 == 0 ? 0 : 1)}K';
    }
    return '\u20B9${numPrice.toStringAsFixed(0)}';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getFirstImageUrl(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];
    if (imageUrls != null && imageUrls.toString().isNotEmpty) {
      final first = imageUrls.toString().split(',').first.trim();
      return ImageUrlHelper.getFullImageUrl(first);
    }
    return '';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING_APPROVAL':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'RENTED':
        return Colors.blue;
      case 'FLAGGED':
        return Colors.deepOrange;
      case 'HOLD':
        return Colors.grey;
      case 'CORRECTION_REQUIRED':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'APPROVED':
        return 'Active';
      case 'PENDING_APPROVAL':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'RENTED':
        return 'Rented';
      case 'FLAGGED':
        return 'Flagged';
      case 'HOLD':
        return 'On Hold';
      case 'CORRECTION_REQUIRED':
        return 'Fix Required';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Rent', 'வாடகை'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _rentalOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: isLoggedIn
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: langProvider.getText('All Rentals', 'அனைத்து வாடகை')),
                  Tab(text: langProvider.getText('My Posts', 'என் பதிவுகள்')),
                ],
              )
            : null,
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateRentalScreen()),
                ).then((_) {
                  _loadPosts(refresh: true);
                  if (_myPostsLoaded) _loadMyPosts();
                });
              },
              backgroundColor: _rentalOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: isLoggedIn
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildAllRentalsTab(langProvider),
                _buildMyPostsTab(langProvider),
              ],
            )
          : _buildAllRentalsTab(langProvider),
    );
  }

  Widget _buildAllRentalsTab(LanguageProvider langProvider) {
    return RefreshIndicator(
      color: _rentalOrange,
      onRefresh: () => _loadPosts(refresh: true),
      child: Column(
        children: [
          // Category filter chips
          _buildCategoryChips(langProvider),

          // Posts list
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(child: LoadingWidget())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              langProvider.getText('No rental posts yet', 'இன்னும் வாடகை பதிவுகள் இல்லை'),
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildPostCard(_posts[index], langProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(LanguageProvider langProvider) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _categoryLabels.entries.map((entry) {
          final isSelected = (entry.key == 'All' && _selectedCategory == null) ||
              entry.key == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                langProvider.getText(entry.value, _categoryTamilMap[entry.key] ?? entry.value),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: _rentalOrange,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                _onCategorySelected(entry.key == 'All' ? null : entry.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, LanguageProvider langProvider) {
    final imageUrl = _getFirstImageUrl(post);
    final isRented = post['status'] == 'RENTED';
    final price = post['price'];
    final priceUnit = post['priceUnit']?.toString() ?? 'per_month';
    final category = post['category']?.toString() ?? '';
    final categoryIcon = _categoryIcons[category] ?? Icons.vpn_key;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RentalPostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(categoryIcon, size: 40, color: Colors.grey[400]),
                            ),
                          )
                        : Container(
                            color: _rentalOrange.withOpacity(0.1),
                            child: Icon(categoryIcon, size: 40, color: _rentalOrange),
                          ),
                    if (isRented)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Text(
                            'RENTED',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + date
                    Row(
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _rentalOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              langProvider.getText(
                                _categoryLabels[category] ?? category,
                                _categoryTamilMap[category] ?? category,
                              ),
                              style: TextStyle(fontSize: 11, color: _rentalOrange, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _formatDate(post['createdAt']),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      post['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    // Price + unit
                    if (price != null)
                      Text(
                        '${_formatPrice(price)}${_priceUnitLabels[priceUnit] ?? '/$priceUnit'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _rentalOrange,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Location
                    if (post['location'] != null && post['location'].toString().isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post['location'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildMyPostsTab(LanguageProvider langProvider) {
    if (_isLoadingMyPosts) {
      return const Center(child: LoadingWidget());
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('You haven\'t posted anything yet', 'நீங்கள் இன்னும் எதுவும் பதிவிடவில்லை'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateRentalScreen()),
                ).then((_) {
                  _loadMyPosts();
                  _loadPosts(refresh: true);
                });
              },
              icon: const Icon(Icons.add),
              label: Text(langProvider.getText('Post for Rent', 'வாடகைக்கு பதிவிடு')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rentalOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _rentalOrange,
      onRefresh: _loadMyPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myPosts.length,
        itemBuilder: (context, index) {
          return _buildMyPostCard(_myPosts[index], langProvider);
        },
      ),
    );
  }

  Widget _buildMyPostCard(Map<String, dynamic> post, LanguageProvider langProvider) {
    final status = post['status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final imageUrl = _getFirstImageUrl(post);
    final price = post['price'];
    final priceUnit = post['priceUnit']?.toString() ?? 'per_month';
    final isApproved = status == 'APPROVED';
    final category = post['category']?.toString() ?? '';
    final categoryIcon = _categoryIcons[category] ?? Icons.vpn_key;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Post content row
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RentalPostDetailScreen(post: post)),
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14)),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(categoryIcon, size: 30, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: _rentalOrange.withOpacity(0.1),
                            child: Icon(categoryIcon, size: 30, color: _rentalOrange),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (price != null)
                          Text(
                            '${_formatPrice(price)}${_priceUnitLabels[priceUnit] ?? '/$priceUnit'}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _rentalOrange),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(post['createdAt']),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isApproved)
                  _buildActionChip(
                    langProvider.getText('Mark Rented', 'வாடகைக்கு'),
                    Icons.check_circle_outline,
                    Colors.blue,
                    () => _markAsRented(post['id']),
                  ),
                if (isApproved || status == 'CORRECTION_REQUIRED')
                  _buildActionChip(
                    langProvider.getText('Edit', 'திருத்து'),
                    Icons.edit_outlined,
                    Colors.teal,
                    () => _showEditDialog(post, langProvider),
                  ),
                _buildActionChip(
                  langProvider.getText('Delete', 'நீக்கு'),
                  Icons.delete_outline,
                  Colors.red,
                  () => _confirmDelete(post['id'], langProvider),
                ),
                if (status == 'RENTED' || status == 'REJECTED')
                  _buildActionChip(
                    langProvider.getText('Renew', 'புதுப்பி'),
                    Icons.refresh,
                    _rentalOrange,
                    () => _renewPost(post['id']),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(fontSize: 11, color: color)),
        backgroundColor: color.withOpacity(0.08),
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
      ),
    );
  }

  Future<void> _markAsRented(dynamic postId) async {
    final result = await _rentalService.markAsRented(postId is int ? postId : int.parse(postId.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Done'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) _loadMyPosts();
    }
  }

  Future<void> _confirmDelete(dynamic postId, LanguageProvider langProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langProvider.getText('Delete Post?', 'பதிவை நீக்கவா?')),
        content: Text(langProvider.getText(
          'This will permanently delete this rental post.',
          'இது இந்த வாடகை பதிவை நிரந்தரமாக நீக்கும்.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(langProvider.getText('Cancel', 'ரத்து')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(langProvider.getText('Delete', 'நீக்கு')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _rentalService.deletePost(postId is int ? postId : int.parse(postId.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Done'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (result['success'] == true) {
          _loadMyPosts();
          _loadPosts(refresh: true);
        }
      }
    }
  }

  Future<void> _renewPost(dynamic postId) async {
    final result = await _rentalService.renewPost(postId is int ? postId : int.parse(postId.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Done'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) _loadMyPosts();
    }
  }

  void _showEditDialog(Map<String, dynamic> post, LanguageProvider langProvider) {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
    final priceController = TextEditingController(text: post['price']?.toString() ?? '');
    final phoneController = TextEditingController(text: post['sellerPhone'] ?? '');
    final locationController = TextEditingController(text: post['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langProvider.getText('Edit Post', 'பதிவைத் திருத்து')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: langProvider.getText('Title', 'தலைப்பு')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: langProvider.getText('Description', 'விவரம்')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: langProvider.getText('Price', 'விலை')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: langProvider.getText('Phone', 'தொலைபேசி')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: langProvider.getText('Location', 'இடம்')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(langProvider.getText('Cancel', 'ரத்து')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final updates = <String, dynamic>{};
              if (titleController.text.isNotEmpty) updates['title'] = titleController.text;
              if (descController.text.isNotEmpty) updates['description'] = descController.text;
              if (priceController.text.isNotEmpty) updates['price'] = double.tryParse(priceController.text);
              if (phoneController.text.isNotEmpty) updates['phone'] = phoneController.text;
              if (locationController.text.isNotEmpty) updates['location'] = locationController.text;

              final result = await _rentalService.editPost(
                post['id'] is int ? post['id'] : int.parse(post['id'].toString()),
                updates,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Done'),
                    backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                  ),
                );
                if (result['success'] == true) _loadMyPosts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _rentalOrange, foregroundColor: Colors.white),
            child: Text(langProvider.getText('Save', 'சேமி')),
          ),
        ],
      ),
    );
  }
}
