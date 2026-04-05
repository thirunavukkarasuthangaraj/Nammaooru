import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/post_filter_bar.dart';
import '../../../core/services/contact_view_service.dart';
import '../services/local_shops_service.dart';
import '../widgets/renewal_payment_handler.dart';
import 'create_local_shop_screen.dart';
import 'local_shop_post_detail_screen.dart';

class LocalShopsScreen extends StatefulWidget {
  const LocalShopsScreen({super.key});

  @override
  State<LocalShopsScreen> createState() => _LocalShopsScreenState();
}

class _LocalShopsScreenState extends State<LocalShopsScreen> with SingleTickerProviderStateMixin {
  final LocalShopsService _service = LocalShopsService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  double? _userLatitude;
  double? _userLongitude;
  double _selectedRadius = 50.0;
  String _searchText = '';

  late TabController _tabController;
  List<dynamic> _myPosts = [];
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;

  static const Color _shopColor = Color(0xFFFF6F00);

  static const Map<String, String> _categoryLabels = {
    'All': 'All',
    'GROCERY': 'Grocery',
    'MEDICAL': 'Medical',
    'HARDWARE': 'Hardware',
    'ELECTRONICS': 'Electronics',
    'CLOTHING': 'Clothing',
    'STATIONERY': 'Stationery',
    'RESTAURANT': 'Restaurant',
    'BAKERY': 'Bakery',
    'VEGETABLES': 'Vegetables',
    'MEAT_FISH': 'Meat / Fish',
    'SALON': 'Salon',
    'GYM': 'Gym',
    'LAUNDRY': 'Laundry',
    'TAILORING': 'Tailoring',
    'PRINTING': 'Printing',
    'MOBILE_SHOP': 'Mobile Shop',
    'COMPUTER_SHOP': 'Computer Shop',
    'AUTO_PARTS': 'Auto Parts',
    'PETROL_BUNK': 'Petrol Bunk',
    'JEWELLERY': 'Jewellery',
    'COURIER': 'Courier',
    'OTHER': 'Other',
  };

  static const Map<String, String> _categoryTamilMap = {
    'All': 'அனைத்தும்',
    'GROCERY': 'மளிகை',
    'MEDICAL': 'மருந்தகம்',
    'HARDWARE': 'ஹார்டுவேர்',
    'ELECTRONICS': 'எலக்ட்ரானிக்ஸ்',
    'CLOTHING': 'துணி',
    'STATIONERY': 'ஸ்டேஷனரி',
    'RESTAURANT': 'ஹோட்டல்',
    'BAKERY': 'பேக்கரி',
    'VEGETABLES': 'காய்கறி',
    'MEAT_FISH': 'இறைச்சி / மீன்',
    'SALON': 'சலூன்',
    'GYM': 'ஜிம்',
    'LAUNDRY': 'லாண்டரி',
    'TAILORING': 'தையல்',
    'PRINTING': 'பிரிண்டிங்',
    'MOBILE_SHOP': 'மொபைல் கடை',
    'COMPUTER_SHOP': 'கம்ப்யூட்டர்',
    'AUTO_PARTS': 'ஆட்டோ பாகங்கள்',
    'PETROL_BUNK': 'பெட்ரோல்',
    'JEWELLERY': 'நகை',
    'COURIER': 'கூரியர்',
    'OTHER': 'பிற',
  };

  static const Map<String, IconData> _categoryIcons = {
    'GROCERY': Icons.shopping_basket,
    'MEDICAL': Icons.local_pharmacy,
    'HARDWARE': Icons.hardware,
    'ELECTRONICS': Icons.electrical_services,
    'CLOTHING': Icons.checkroom,
    'STATIONERY': Icons.book,
    'RESTAURANT': Icons.restaurant,
    'BAKERY': Icons.bakery_dining,
    'VEGETABLES': Icons.eco,
    'MEAT_FISH': Icons.set_meal,
    'SALON': Icons.content_cut,
    'GYM': Icons.fitness_center,
    'LAUNDRY': Icons.local_laundry_service,
    'TAILORING': Icons.design_services,
    'PRINTING': Icons.print,
    'MOBILE_SHOP': Icons.phone_android,
    'COMPUTER_SHOP': Icons.computer,
    'AUTO_PARTS': Icons.car_repair,
    'PETROL_BUNK': Icons.local_gas_station,
    'JEWELLERY': Icons.diamond,
    'COURIER': Icons.local_shipping,
    'OTHER': Icons.store,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_myPostsLoaded) {
        _loadMyPosts();
      }
    });
    _scrollController.addListener(_onScroll);
    _loadPosts();
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

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    if (_userLatitude == null || _userLongitude == null) {
      LocationService.instance.getCurrentPosition().then((position) {
        if (position != null && position.latitude != null && position.longitude != null) {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          if (mounted) _loadPosts();
        }
      }).catchError((_) {});
    }

    try {
      final response = await _service.getApprovedPosts(
        page: 0,
        size: 20,
        category: _selectedCategory,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
      );

      if (mounted) {
        final data = response['data'];
        setState(() {
          _posts = data?['content'] ?? [];
          _hasMore = data?['hasNext'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    _currentPage++;
    try {
      final response = await _service.getApprovedPosts(
        page: _currentPage,
        size: 20,
        category: _selectedCategory,
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: _selectedRadius,
        search: _searchText.isNotEmpty ? _searchText : null,
      );
      if (mounted) {
        final data = response['data'];
        setState(() {
          _posts.addAll(data?['content'] ?? []);
          _hasMore = data?['hasNext'] ?? false;
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
      if (mounted) setState(() => _isLoadingMyPosts = false);
    }
  }

  String _getCategoryDisplay(String? category) {
    if (category == null) return '';
    return _categoryLabels[category] ?? category;
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
    _loadPosts();
  }

  void _callOrLogin(Map<String, dynamic> post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/register');
      return;
    }
    final phone = post['phone'] ?? '';
    ContactViewService.log(
      postType: 'LOCAL_SHOP',
      postId: post['id'] ?? 0,
      postTitle: post['shopName'] ?? '',
      sellerPhone: phone,
      ownerUserId: post['sellerUserId'] != null ? int.tryParse(post['sellerUserId'].toString()) : null,
    );
    _callPhone(phone);
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _showReportDialog(Map<String, dynamic> post) {
    final reasons = [
      'Fake / Incorrect Information',
      'Wrong Contact Number',
      'Scam / Fraud',
      'Inappropriate Content',
      'Shop Closed Permanently',
      'Other',
    ];
    String? selectedReason;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.flag, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              const Text('Report Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting "${post['shopName']}"?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _shopColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) => setDialogState(() => selectedReason = value),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final postId = post['id'];
                      if (postId == null) return;
                      final result = await _service.reportPost(postId, selectedReason!, details: detailsController.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Reported'),
                            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final shopName = post['shopName'] ?? '';
    final category = post['category'] ?? '';
    final address = post['address'] ?? '';
    final timings = post['timings'] ?? '';
    final imageUrlsRaw = post['imageUrls'] ?? '';
    final imageUrls = imageUrlsRaw.toString().isNotEmpty
        ? imageUrlsRaw.toString().split(',').where((u) => u.trim().isNotEmpty).toList()
        : <String>[];
    final categoryIcon = _categoryIcons[category] ?? Icons.store;
    final categoryLabel = lang.getText(
      _categoryLabels[category] ?? category,
      _categoryTamilMap[category] ?? category,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocalShopPostDetailScreen(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: ImageUrlHelper.getFullUrl(imageUrls.first),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(categoryIcon, size: 18, color: _shopColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _shopColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(categoryLabel, style: TextStyle(fontSize: 12, color: _shopColor, fontWeight: FontWeight.w500)),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (timings.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(timings, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callOrLogin(post),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _shopColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showReportDialog(post),
                        icon: Icon(Icons.flag_outlined, color: Colors.grey[500], size: 20),
                        tooltip: 'Report',
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

  Widget _buildMyPostCard(Map<String, dynamic> post) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final shopName = post['shopName'] ?? '';
    final status = post['status'] ?? '';
    final category = post['category'] ?? '';
    final categoryLabel = lang.getText(
      _categoryLabels[category] ?? category,
      _categoryTamilMap[category] ?? category,
    );

    Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'PENDING_APPROVAL':
        statusColor = Colors.orange;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(categoryLabel, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                if (status == 'APPROVED')
                  TextButton.icon(
                    onPressed: () async {
                      final id = post['id'];
                      if (id == null) return;
                      final result = await _service.markAsUnavailable(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) _loadMyPosts();
                      }
                    },
                    icon: const Icon(Icons.store_mall_directory_outlined, size: 16),
                    label: const Text('Mark Closed'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                if (status == 'SOLD')
                  TextButton.icon(
                    onPressed: () async {
                      final id = post['id'];
                      if (id == null) return;
                      final result = await _service.markAsAvailable(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) _loadMyPosts();
                      }
                    },
                    icon: const Icon(Icons.store, size: 16),
                    label: const Text('Mark Open'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final id = post['id'];
                    if (id == null) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Listing'),
                        content: const Text('Are you sure you want to delete this listing?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final result = await _service.deletePost(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) _loadMyPosts();
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText('Local Shops', 'கடைகள்')),
        backgroundColor: _shopColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: lang.getText('All Shops', 'அனைத்து கடைகள்')),
            Tab(text: lang.getText('My Listings', 'என் விளம்பரங்கள்')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!authProvider.isAuthenticated) {
            context.go('/register');
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLocalShopScreen()),
          );
          if (result == true) {
            _loadPosts();
            if (_myPostsLoaded) _loadMyPosts();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(lang.getText('Post Shop', 'கடை சேர்')),
        backgroundColor: _shopColor,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Shops tab
          Column(
            children: [
              PostFilterBar(
                categories: _categoryLabels.keys.toList(),
                categoryLabels: _categoryLabels,
                categoryTamilMap: _categoryTamilMap,
                selectedCategory: _selectedCategory ?? 'All',
                onCategorySelected: _onCategorySelected,
                onSearchChanged: (text) {
                  _searchText = text;
                  _loadPosts();
                },
                themeColor: _shopColor,
              ),
              Expanded(
                child: _isLoading
                    ? const LoadingWidget()
                    : _posts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(lang.getText('No shops found', 'கடைகள் எதுவும் இல்லை'),
                                    style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPosts,
                            color: _shopColor,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _posts.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _posts.length) {
                                  return const Center(child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ));
                                }
                                return _buildPostCard(Map<String, dynamic>.from(_posts[index]));
                              },
                            ),
                          ),
              ),
            ],
          ),

          // My Listings tab
          _isLoadingMyPosts
              ? const LoadingWidget()
              : _myPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(lang.getText('You have no listings yet', 'உங்களுக்கு விளம்பரங்கள் இல்லை'),
                              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!authProvider.isAuthenticated) {
                                context.go('/register');
                                return;
                              }
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateLocalShopScreen()),
                              );
                              if (result == true) _loadMyPosts();
                            },
                            icon: const Icon(Icons.add),
                            label: Text(lang.getText('Post Your Shop', 'கடை சேர்')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _shopColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyPosts,
                      color: _shopColor,
                      child: ListView.builder(
                        itemCount: _myPosts.length,
                        itemBuilder: (context, index) {
                          return _buildMyPostCard(Map<String, dynamic>.from(_myPosts[index]));
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
