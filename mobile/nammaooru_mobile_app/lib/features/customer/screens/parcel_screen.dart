import 'dart:ui';
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
import '../services/parcel_service.dart';
import '../widgets/renewal_payment_handler.dart';
import 'create_parcel_screen.dart';
import 'parcel_post_detail_screen.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

final _nameBlurFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5);

class _ParcelScreenState extends State<ParcelScreen> with SingleTickerProviderStateMixin {
  final ParcelService _parcelService = ParcelService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _selectedServiceType;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  double? _userLatitude;
  double? _userLongitude;
  double _selectedRadius = 50.0;
  String _searchText = '';

  // My Posts tab
  late TabController _tabController;
  List<dynamic> _myPosts = [];
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;
  Set<int> _selectedForRenewal = {};
  bool _isRenewing = false;

  static const Color _parcelOrange = Color(0xFFE65100);

  static const Map<String, String> _serviceTypeLabels = {
    'All': 'All',
    'DOOR_TO_DOOR': 'Door to Door',
    'PICKUP_POINT': 'Pickup Point',
    'BOTH': 'Both',
  };

  static const Map<String, String> _serviceTypeTamilMap = {
    'All': 'அனைத்தும்',
    'DOOR_TO_DOOR': 'வீடு வீடாக',
    'PICKUP_POINT': 'பிக்கப் பாயிண்ட்',
    'BOTH': 'இரண்டும்',
  };

  static const Map<String, IconData> _serviceTypeIcons = {
    'DOOR_TO_DOOR': Icons.home,
    'PICKUP_POINT': Icons.store,
    'BOTH': Icons.swap_horiz,
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

    // Fetch GPS in background (don't block the API call)
    if (_userLatitude == null || _userLongitude == null) {
      LocationService.instance.getCurrentPosition().then((position) {
        if (position != null && position.latitude != null && position.longitude != null) {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        }
      }).catchError((_) {});
    }

    try {
      final response = await _parcelService.getApprovedPosts(
        page: 0,
        size: 20,
        serviceType: _selectedServiceType,
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    _currentPage++;
    try {
      final response = await _parcelService.getApprovedPosts(
        page: _currentPage,
        size: 20,
        serviceType: _selectedServiceType,
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
      final response = await _parcelService.getMyPosts();
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

  String _getServiceTypeDisplay(String? serviceType) {
    if (serviceType == null) return '';
    return _serviceTypeLabels[serviceType] ?? serviceType;
  }

  String _getServiceTypeTamil(String type, BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final english = _serviceTypeLabels[type] ?? type;
    final tamil = _serviceTypeTamilMap[type] ?? type;
    return lang.getText(english, tamil);
  }

  void _onServiceTypeSelected(String serviceType) {
    setState(() {
      _selectedServiceType = serviceType == 'All' ? null : serviceType;
    });
    _loadPosts();
  }

  void _callOrLogin(Map<String, dynamic> post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }
    _callService(post['phone'] ?? '');
  }

  Future<void> _callService(String phone) async {
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
      'Not Available Anymore',
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
                  'Why are you reporting "${post['serviceName']}"?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _parcelOrange,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
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
                      await _submitReport(post, selectedReason!, detailsController.text);
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

  Future<void> _submitReport(Map<String, dynamic> post, String reason, String details) async {
    final postId = post['id'];
    if (postId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report listings'), backgroundColor: Colors.orange),
      );
      return;
    }

    final result = await _parcelService.reportPost(postId, reason, details: details);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] == true ? 'Listing reported' : 'Failed to report')),
          backgroundColor: result['success'] == true ? _parcelOrange : Colors.red,
        ),
      );
    }
  }

  void _navigateToCreatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateParcelScreen()),
    ).then((_) {
      _loadPosts();
      _myPostsLoaded = false;
      _loadMyPosts();
      _tabController.animateTo(1);
    });
  }

  void _showEditParcelSheet(Map<String, dynamic> post) {
    final serviceNameController = TextEditingController(text: post['serviceName'] ?? '');
    final phoneController = TextEditingController(text: post['phone'] ?? '');
    final fromController = TextEditingController(text: post['fromLocation'] ?? '');
    final toController = TextEditingController(text: post['toLocation'] ?? '');
    final priceInfoController = TextEditingController(text: post['priceInfo'] ?? '');
    final addressController = TextEditingController(text: post['address'] ?? '');
    final timingsController = TextEditingController(text: post['timings'] ?? '');
    final descController = TextEditingController(text: post['description'] ?? '');
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
                TextField(controller: serviceNameController, decoration: const InputDecoration(labelText: 'Service Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: fromController, decoration: const InputDecoration(labelText: 'From Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: toController, decoration: const InputDecoration(labelText: 'To Location', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: priceInfoController, decoration: const InputDecoration(labelText: 'Price Info', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: timingsController, decoration: const InputDecoration(labelText: 'Timings', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      final updates = <String, dynamic>{};
                      if (serviceNameController.text != (post['serviceName'] ?? '')) updates['serviceName'] = serviceNameController.text;
                      if (phoneController.text != (post['phone'] ?? '')) updates['phone'] = phoneController.text;
                      if (fromController.text != (post['fromLocation'] ?? '')) updates['fromLocation'] = fromController.text;
                      if (toController.text != (post['toLocation'] ?? '')) updates['toLocation'] = toController.text;
                      if (priceInfoController.text != (post['priceInfo'] ?? '')) updates['priceInfo'] = priceInfoController.text;
                      if (addressController.text != (post['address'] ?? '')) updates['address'] = addressController.text;
                      if (timingsController.text != (post['timings'] ?? '')) updates['timings'] = timingsController.text;
                      if (descController.text != (post['description'] ?? '')) updates['description'] = descController.text;
                      if (updates.isEmpty) { Navigator.pop(ctx); return; }
                      final result = await _parcelService.editPost(post['id'], updates);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                        if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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
    final handler = RenewalPaymentHandler(context: context, postType: 'PARCELS');
    handler.renewSingle(
      onTokenReceived: (paidTokenId) async {
        final result = await _parcelService.renewPost(postId, paidTokenId: paidTokenId);
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
    final handler = RenewalPaymentHandler(context: context, postType: 'PARCELS');
    handler.renewBulk(
      count: count,
      onTokensReceived: (paidTokenIds) async {
        int successCount = 0;
        for (int i = 0; i < selectedIds.length && i < paidTokenIds.length; i++) {
          final result = await _parcelService.renewPost(selectedIds[i], paidTokenId: paidTokenIds[i]);
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

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          langProvider.getText('Parcel Service', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _parcelOrange,
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
            Tab(text: langProvider.getText('Browse', '\u0baa\u0bbe\u0bb0\u0bcd\u0b95\u0bcd\u0b95')),
            Tab(text: '${langProvider.getText('My Posts', '\u0b8e\u0ba9\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1\u0b95\u0bb3\u0bcd')}${_myPosts.isNotEmpty ? ' (${_myPosts.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(),
        backgroundColor: _parcelOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // --- Tab 1: Browse Parcels ---

  Widget _buildBrowseTab() {
    return Column(
      children: [
        PostFilterBar(
          categories: _serviceTypeLabels.keys.toList(),
          selectedCategory: _selectedServiceType,
          onCategoryChanged: (type) => _onServiceTypeSelected(type ?? 'All'),
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
          accentColor: VillageTheme.primaryGreen,
          categoryLabelBuilder: (type) => _getServiceTypeTamil(type, context),
        ),
        // Posts list
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
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
                          return _buildPostCard(_posts[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            langProvider.getText('No parcel services listed yet', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8\u0b95\u0bb3\u0bcd \u0b87\u0ba9\u0bcd\u0ba9\u0bc1\u0bae\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bbf\u0b9f\u0baa\u0bcd\u0baa\u0b9f\u0bb5\u0bbf\u0bb2\u0bcd\u0bb2\u0bc8'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            langProvider.getText('Be the first to post!', '\u0bae\u0bc1\u0ba4\u0bb2\u0bbf\u0bb2\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd!'),
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(),
            icon: const Icon(Icons.add),
            label: Text(langProvider.getText('Add Parcel Service', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8 \u0b9a\u0bc7\u0bb0\u0bcd\u0b95\u0bcd\u0b95')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _parcelOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  static String? _getFirstImageUrl(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];
    if (imageUrls != null && imageUrls.toString().isNotEmpty) {
      final first = imageUrls.toString().split(',').first.trim();
      if (first.isNotEmpty) return ImageUrlHelper.getFullImageUrl(first);
    }
    return null;
  }

  void _navigateToDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelPostDetailScreen(post: post),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isUnavailable = post['status'] == 'SOLD';
    final fullImageUrl = _getFirstImageUrl(post);
    final serviceType = post['serviceType']?.toString() ?? '';
    final serviceTypeIcon = _serviceTypeIcons[serviceType] ?? Icons.local_shipping;

    return GestureDetector(
      onTap: () => _navigateToDetail(post),
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or icon
              if (fullImageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    width: 100,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 130,
                      color: _parcelOrange.withOpacity(0.1),
                      child: Icon(serviceTypeIcon, size: 40, color: _parcelOrange),
                    ),
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _parcelOrange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Icon(serviceTypeIcon, size: 40, color: _parcelOrange),
                ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      Builder(builder: (context) {
                        final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                        return isLoggedIn
                            ? Text(
                                post['serviceName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : ClipRect(
                                child: ImageFiltered(
                                  imageFilter: _nameBlurFilter,
                                  child: Text(
                                    post['serviceName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: VillageTheme.primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                      }),
                      const SizedBox(height: 4),
                      // Service type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _parcelOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getServiceTypeDisplay(serviceType),
                          style: const TextStyle(fontSize: 11, color: _parcelOrange, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // From -> To route
                      if ((post['fromLocation'] != null && post['fromLocation'].toString().isNotEmpty) ||
                          (post['toLocation'] != null && post['toLocation'].toString().isNotEmpty))
                        Row(
                          children: [
                            Icon(Icons.route, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${post['fromLocation'] ?? ''} \u2192 ${post['toLocation'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // Price info
                      if (post['priceInfo'] != null && post['priceInfo'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                post['priceInfo'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Address
                      if (post['address'] != null && post['address'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                post['address'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Call & Report buttons
                      if (!isUnavailable)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () => _callOrLogin(post),
                                  icon: const Icon(Icons.call, size: 16),
                                  label: const Text('Call', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _parcelOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 32,
                              width: 32,
                              child: IconButton(
                                onPressed: () => _showReportDialog(post),
                                icon: Icon(Icons.flag_outlined, color: Colors.grey[500], size: 18),
                                padding: EdgeInsets.zero,
                                tooltip: 'Report this listing',
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
          // UNAVAILABLE badge
          if (isUnavailable)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UNAVAILABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  // --- Tab 2: My Posts ---

  Widget _buildMyPostsTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Please log in to see your listings', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: _parcelOrange, foregroundColor: Colors.white),
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMyPosts) {
      return const Center(child: LoadingWidget());
    }

    if (_myPosts.isEmpty) {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              langProvider.getText('You haven\'t posted anything yet', '\u0ba8\u0bc0\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0b87\u0ba9\u0bcd\u0ba9\u0bc1\u0bae\u0bcd \u0b8e\u0ba4\u0bc1\u0bb5\u0bc1\u0bae\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bbf\u0b9f\u0bb5\u0bbf\u0bb2\u0bcd\u0bb2\u0bc8'),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.add),
              label: Text(langProvider.getText('Add Parcel Service', '\u0baa\u0bbe\u0bb0\u0bcd\u0b9a\u0bb2\u0bcd \u0b9a\u0bc7\u0bb5\u0bc8 \u0b9a\u0bc7\u0bb0\u0bcd\u0b95\u0bcd\u0b95')),
              style: ElevatedButton.styleFrom(backgroundColor: _parcelOrange, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    final expiredPostIds = _myPosts.where((p) {
      final vTo = p['validTo'] != null ? DateTime.tryParse(p['validTo'].toString()) : null;
      if (vTo == null) return false;
      final now = DateTime.now();
      return vTo.isBefore(now) || (vTo.isAfter(now) && vTo.difference(now).inDays <= 3);
    }).map((p) => p['id'] as int).toList();

    return RefreshIndicator(
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
                  SizedBox(width: 24, height: 24,
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
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedForRenewal.isEmpty ? 'Select expired posts to renew' : '${_selectedForRenewal.length} selected',
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 13)),
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
    final fullImageUrl = _getFirstImageUrl(post);
    final serviceType = post['serviceType']?.toString() ?? '';
    final serviceTypeIcon = _serviceTypeIcons[serviceType] ?? Icons.local_shipping;

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
        statusText = 'Unavailable';
        statusIcon = Icons.block;
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
                    'Valid: ${validFrom != null ? "${validFrom.day}/${validFrom.month}/${validFrom.year}" : "—"} - ${validTo.day}/${validTo.month}/${validTo.year}',
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
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or icon
              if (fullImageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: fullImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80, height: 80, color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80, height: 80, color: _parcelOrange.withOpacity(0.1),
                        child: Icon(serviceTypeIcon, size: 30, color: _parcelOrange),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _parcelOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(serviceTypeIcon, size: 30, color: _parcelOrange),
                  ),
                ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['serviceName'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getServiceTypeDisplay(serviceType),
                        style: TextStyle(fontSize: 13, color: _parcelOrange, fontWeight: FontWeight.w500),
                      ),
                      if ((post['fromLocation'] != null && post['fromLocation'].toString().isNotEmpty) ||
                          (post['toLocation'] != null && post['toLocation'].toString().isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${post['fromLocation'] ?? ''} \u2192 ${post['toLocation'] ?? ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                                activeColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isRenewing ? null : () => _renewSinglePost(post['id']),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Renew Post'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status == 'APPROVED' || status == 'CORRECTION_REQUIRED') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await _parcelService.markAsUnavailable(post['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                    );
                                    if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                                  }
                                },
                                icon: const Icon(Icons.block, size: 16),
                                label: const Text('Unavailable', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showEditParcelSheet(post),
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Listing?'),
                                    content: const Text('This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final result = await _parcelService.deletePost(post['id']);
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
                      if (status == 'SOLD') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await _parcelService.markAsAvailable(post['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                    );
                                    if (result['success'] == true) { _myPostsLoaded = false; _loadMyPosts(); _loadPosts(); }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Mark Available', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Listing?'),
                                    content: const Text('This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final result = await _parcelService.deletePost(post['id']);
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
