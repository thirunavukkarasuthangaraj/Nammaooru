import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/env_config.dart';
import '../../../core/constants/colors.dart';

class MyPostsScreen extends StatefulWidget {
  final String? initialModule;

  const MyPostsScreen({super.key, this.initialModule});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  bool _isLoading = true;
  List<_PostItem> _allPosts = [];
  List<_ModuleConfig> _activeModules = [];
  String _selectedModule = 'All';

  // Icon string -> IconData mapping (same as dashboard)
  static const _iconMap = <String, IconData>{
    'shopping_basket_rounded': Icons.shopping_basket_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'storefront_rounded': Icons.storefront_rounded,
    'eco_rounded': Icons.eco_rounded,
    'construction_rounded': Icons.construction_rounded,
    'directions_bus_rounded': Icons.directions_bus_rounded,
    'local_shipping_rounded': Icons.local_shipping_rounded,
    'directions_car_rounded': Icons.directions_car_rounded,
    'home_work_rounded': Icons.home_work_rounded,
    'vpn_key_rounded': Icons.vpn_key_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule ?? 'All';
    _loadActiveModulesAndPosts();
  }

  static IconData _mapIcon(String? iconName) {
    return _iconMap[iconName] ?? Icons.grid_view_rounded;
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF2196F3);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  /// Derive API slug from the route field (e.g. "/customer/marketplace" -> "marketplace")
  static String _slugFromRoute(String? route) {
    if (route == null || route.isEmpty) return '';
    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : '';
  }

  Future<void> _loadActiveModulesAndPosts() async {
    setState(() => _isLoading = true);

    // Fetch my-stats API — includes modules metadata, counts, limits, pricing
    final activeModules = <_ModuleConfig>[];
    try {
      final response = await ApiClient.get('/posts/my-stats');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final statsData = data['data'] as Map;

          // Parse module metadata from API
          final modulesData = statsData['modules'] as Map? ?? {};
          for (final entry in modulesData.entries) {
            final key = entry.key.toString();
            final meta = entry.value as Map? ?? {};
            final displayName = meta['displayName'] ?? key;
            final slug = _slugFromRoute(meta['route']?.toString());
            if (slug.isNotEmpty) {
              activeModules.add(_ModuleConfig(
                name: displayName,
                featureKey: key,
                listEndpoint: '/$slug/my',
                deleteEndpoint: slug,
                icon: _mapIcon(meta['icon']?.toString()),
                color: _parseColor(meta['color']?.toString()),
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching my-stats: $e');
    }

    _activeModules = activeModules;

    // Fetch posts only for active modules
    final posts = <_PostItem>[];
    final futures = _activeModules.map((m) => _fetchModulePosts(m));
    final results = await Future.wait(futures);
    for (final list in results) {
      posts.addAll(list);
    }

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _allPosts = posts;
        _isLoading = false;
      });
    }
  }

  Future<List<_PostItem>> _fetchModulePosts(_ModuleConfig module) async {
    try {
      final response = await ApiClient.get(module.listEndpoint);
      if (response.statusCode == 200) {
        final data = response.data;
        List items = [];
        if (data is Map && data['data'] != null) {
          items = data['data'] is List ? data['data'] : [];
        } else if (data is List) {
          items = data;
        }

        return items.map((item) {
          final map = item as Map<String, dynamic>;
          final title = map['title'] ?? map['name'] ?? map['serviceName'] ?? 'Untitled';
          final status = map['status'] ?? 'UNKNOWN';
          final id = map['id'];
          final createdAt = map['createdAt'] ?? '';

          String? imageUrl;
          if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
            imageUrl = map['imageUrl'];
          } else if (map['imageUrls'] != null && map['imageUrls'].toString().isNotEmpty) {
            imageUrl = map['imageUrls'].toString().split(',').first.trim();
          }

          return _PostItem(
            id: id,
            title: title,
            status: status,
            module: module.name,
            moduleColor: module.color,
            moduleIcon: module.icon,
            deleteEndpoint: module.deleteEndpoint,
            imageUrl: imageUrl,
            createdAt: createdAt,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching ${module.name} posts: $e');
    }
    return [];
  }

  Future<void> _deletePost(_PostItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.delete('/${post.deleteEndpoint}/${post.id}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully'), backgroundColor: Colors.green),
          );
          _loadActiveModulesAndPosts();
        }
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<_PostItem> get _filteredPosts {
    if (_selectedModule == 'All') return _allPosts;
    return _allPosts.where((p) => p.module == _selectedModule).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Module filter chips (dynamic from API)
          if (_activeModules.isNotEmpty)
            Container(
              color: AppColors.primary.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildFilterChip('All', Icons.select_all_rounded, AppColors.primary),
                    ..._activeModules.map((m) => _buildFilterChip(m.name, m.icon, m.color)),
                  ],
                ),
              ),
            ),
          // Posts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _selectedModule == 'All' ? 'No posts yet' : 'No $_selectedModule posts',
                              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadActiveModulesAndPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) => _buildPostCard(_filteredPosts[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color) {
    final isSelected = _selectedModule == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: color.withOpacity(0.1),
        selectedColor: color,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? color : color.withOpacity(0.3)),
        onSelected: (_) => setState(() => _selectedModule = label),
      ),
    );
  }

  Widget _buildPostCard(_PostItem post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: post.moduleColor.withOpacity(0.1),
                child: post.imageUrl != null
                    ? Image.network(
                        _resolveImageUrl(post.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(post.moduleIcon, color: post.moduleColor, size: 28),
                      )
                    : Icon(post.moduleIcon, color: post.moduleColor, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: post.moduleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.module,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: post.moduleColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusBadge(post.status),
                    ],
                  ),
                  if (post.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _deletePost(post),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'PENDING_APPROVAL':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'APPROVED':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'REJECTED':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'SOLD':
      case 'RENTED':
        color = Colors.grey;
        label = status[0] + status.substring(1).toLowerCase();
        break;
      case 'FLAGGED':
        color = Colors.deepOrange;
        label = 'Flagged';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${EnvConfig.baseUrl}$url';
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _ModuleConfig {
  final String name;
  final String featureKey;
  final String listEndpoint;
  final String deleteEndpoint;
  final IconData icon;
  final Color color;

  const _ModuleConfig({
    required this.name,
    required this.featureKey,
    required this.listEndpoint,
    required this.deleteEndpoint,
    required this.icon,
    required this.color,
  });
}

class _PostItem {
  final dynamic id;
  final String title;
  final String status;
  final String module;
  final Color moduleColor;
  final IconData moduleIcon;
  final String deleteEndpoint;
  final String? imageUrl;
  final String createdAt;

  const _PostItem({
    required this.id,
    required this.title,
    required this.status,
    required this.module,
    required this.moduleColor,
    required this.moduleIcon,
    required this.deleteEndpoint,
    this.imageUrl,
    required this.createdAt,
  });
}
