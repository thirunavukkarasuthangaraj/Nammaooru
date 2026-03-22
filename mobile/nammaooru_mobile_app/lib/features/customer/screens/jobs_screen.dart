import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/post_filter_bar.dart';
import '../../../core/services/location_service.dart';
import '../services/job_service.dart';
import 'create_job_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  final JobService _jobService = JobService();
  List<dynamic> _posts = [];
  List<dynamic> _myPosts = [];
  bool _isLoading = true;
  bool _isLoadingMyPosts = false;
  bool _myPostsLoaded = false;
  String? _selectedCategory;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  double? _userLatitude;
  double? _userLongitude;
  double _selectedRadius = 50.0;
  String _searchText = '';
  late TabController _tabController;

  static const Color _jobGreen = Color(0xFF2E7D32);

  // Jobs = employment/salary positions only
  // Skilled trades (Electrician, Plumber, Carpenter etc.) belong in Labour module
  static const Map<String, String> _categories = {
    'All': 'All',
    'SHOP_WORKER': 'Shop Worker',
    'WOMEN_SHOP_WORKER': 'Women for Shop',
    'SALES_PERSON': 'Sales',
    'DELIVERY_BOY': 'Delivery',
    'CASHIER': 'Cashier',
    'RECEPTIONIST': 'Receptionist',
    'ACCOUNTANT': 'Accountant',
    'DRIVER': 'Driver',
    'AUTO_DRIVER': 'Auto Driver',
    'COOK': 'Cook',
    'HELPER': 'Helper',
    'TEACHER': 'Teacher',
    'NURSE': 'Nurse',
    'BEAUTICIAN': 'Beautician',
    'TAILOR': 'Tailor',
    'WATCHMAN': 'Watchman',
    'COMPUTER_OPERATOR': 'Computer',
    'MANAGER': 'Manager',
    'OTHER': 'Other',
  };

  static const Map<String, String> _categoryTamil = {
    'All': 'அனைத்தும்',
    'SHOP_WORKER': 'கடை ஊழியர்',
    'WOMEN_SHOP_WORKER': 'பெண் கடை ஊழியர்',
    'SALES_PERSON': 'விற்பனையாளர்',
    'DELIVERY_BOY': 'டெலிவரி',
    'CASHIER': 'கேஷியர்',
    'RECEPTIONIST': 'ரிசெப்ஷனிஸ்ட்',
    'ACCOUNTANT': 'கணக்காளர்',
    'DRIVER': 'டிரைவர்',
    'AUTO_DRIVER': 'ஆட்டோ டிரைவர்',
    'COOK': 'சமையல்காரர்',
    'HELPER': 'உதவியாளர்',
    'TEACHER': 'ஆசிரியர்',
    'NURSE': 'செவிலியர்',
    'BEAUTICIAN': 'அழகுக்கலை',
    'TAILOR': 'தையல்காரர்',
    'WATCHMAN': 'காவலன்',
    'COMPUTER_OPERATOR': 'கம்ப்யூட்டர்',
    'MANAGER': 'மேலாளர்',
    'OTHER': 'பிற',
  };

  static const Map<String, IconData> _categoryIcons = {
    'SHOP_WORKER': Icons.storefront,
    'WOMEN_SHOP_WORKER': Icons.store,
    'SALES_PERSON': Icons.trending_up,
    'DELIVERY_BOY': Icons.delivery_dining,
    'CASHIER': Icons.point_of_sale,
    'RECEPTIONIST': Icons.assignment_ind,
    'ACCOUNTANT': Icons.account_balance,
    'DRIVER': Icons.drive_eta,
    'AUTO_DRIVER': Icons.electric_rickshaw,
    'COOK': Icons.restaurant,
    'HELPER': Icons.handyman,
    'TEACHER': Icons.school,
    'NURSE': Icons.medical_services,
    'BEAUTICIAN': Icons.face_retouching_natural,
    'TAILOR': Icons.content_cut,
    'WATCHMAN': Icons.visibility,
    'COMPUTER_OPERATOR': Icons.computer,
    'MANAGER': Icons.manage_accounts,
    'OTHER': Icons.work,
  };

  static const Map<String, Color> _categoryColors = {
    'SHOP_WORKER': Color(0xFF1565C0),
    'WOMEN_SHOP_WORKER': Color(0xFFE91E63),
    'SALES_PERSON': Color(0xFFE65100),
    'DELIVERY_BOY': Color(0xFF00897B),
    'CASHIER': Color(0xFF2E7D32),
    'RECEPTIONIST': Color(0xFFAD1457),
    'ACCOUNTANT': Color(0xFF0277BD),
    'DRIVER': Color(0xFF4E342E),
    'AUTO_DRIVER': Color(0xFF6D4C41),
    'COOK': Color(0xFFBF360C),
    'HELPER': Color(0xFF37474F),
    'TEACHER': Color(0xFF1B5E20),
    'NURSE': Color(0xFFC62828),
    'BEAUTICIAN': Color(0xFFAD1457),
    'TAILOR': Color(0xFF6A1B9A),
    'WATCHMAN': Color(0xFF4527A0),
    'COMPUTER_OPERATOR': Color(0xFF1565C0),
    'MANAGER': Color(0xFF37474F),
    'OTHER': Color(0xFF455A64),
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
      if (!_isLoading && _hasMore) _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    if (_userLatitude == null) {
      LocationService.instance.getCurrentPosition().then((pos) {
        if (pos != null && mounted) {
          _userLatitude = pos.latitude;
          _userLongitude = pos.longitude;
          _loadPosts();
        }
      }).catchError((_) {});
    }

    try {
      final response = await _jobService.getApprovedPosts(
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
      final response = await _jobService.getApprovedPosts(
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
    } catch (_) {
      _currentPage--;
    }
  }

  Future<void> _loadMyPosts() async {
    setState(() => _isLoadingMyPosts = true);
    try {
      final response = await _jobService.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = response['data'] ?? [];
          _myPostsLoaded = true;
          _isLoadingMyPosts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMyPosts = false);
    }
  }

  String _getCategoryLabel(String? cat) {
    if (cat == null) return '';
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return lang.currentLanguage == 'en'
        ? (_categories[cat] ?? cat)
        : (_categoryTamil[cat] ?? _categories[cat] ?? cat);
  }

  void _callOrLogin(Map<String, dynamic> post) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) { context.go('/login'); return; }
    _call(post['phone'] ?? '');
  }

  Future<void> _call(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    try {
      await launchUrl(Uri.parse('tel:$clean'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _whatsApp(Map<String, dynamic> post) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) { context.go('/login'); return; }
    final phone = (post['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    final jobTitle = post['jobTitle'] ?? post['title'] ?? 'Job';
    final company = post['companyName'] ?? '';
    final message = Uri.encodeComponent('Hi, I saw your job posting for "$jobTitle" at $company on NammaOoru. I am interested.');
    try {
      await launchUrl(Uri.parse('https://wa.me/91$phone?text=$message'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _navigateToCreate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) { context.go('/login'); return; }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobScreen()),
    );
    if (result == true) {
      _loadPosts();
      _myPostsLoaded = false;
      _loadMyPosts();
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          lang.getText('Jobs', 'வேலை வாய்ப்புகள்'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _jobGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: lang.getText('Browse Jobs', 'வேலைகள் பார்')),
            Tab(text: lang.getText('My Postings', 'என் பதிவுகள்') +
                (_myPosts.isNotEmpty ? ' (${_myPosts.length})' : '')),
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
        onPressed: _navigateToCreate,
        backgroundColor: _jobGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        PostFilterBar(
          categories: _categories.keys.toList(),
          selectedCategory: _selectedCategory,
          onCategoryChanged: (cat) {
            setState(() => _selectedCategory = (cat == null || cat == 'All') ? null : cat);
            _loadPosts();
          },
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
          accentColor: _jobGreen,
          categoryLabelBuilder: (cat) => _getCategoryLabel(cat),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: _jobGreen,
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
                          return _buildJobCard(_posts[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }


  Widget _buildJobCard(Map<String, dynamic> post) {
    final category = post['category']?.toString() ?? 'OTHER';
    final jobTitle = post['jobTitle']?.toString() ?? post['title']?.toString() ?? 'Job Opening';
    final company = post['companyName']?.toString() ?? '';
    final location = post['location']?.toString() ?? '';
    final salary = post['salary']?.toString() ?? '';
    final salaryType = post['salaryType']?.toString() ?? '';
    final jobType = post['jobType']?.toString() ?? '';
    final vacancies = post['vacancies']?.toString() ?? '';
    final description = post['description']?.toString() ?? '';
    final requirements = post['requirements']?.toString() ?? '';
    final color = _categoryColors[category] ?? _jobGreen;
    final icon = _categoryIcons[category] ?? Icons.work;
    final isExpired = post['status']?.toString() == 'EXPIRED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showJobDetail(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Category label badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryLabel(category),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (salary.isNotEmpty)
                        _infoChip(
                          Icons.currency_rupee,
                          '₹$salary${salaryType.isNotEmpty ? "/$salaryType" : ""}',
                          Colors.green[700]!,
                        ),
                      if (jobType.isNotEmpty)
                        _infoChip(Icons.access_time, _formatJobType(jobType), Colors.blue[700]!),
                      if (vacancies.isNotEmpty)
                        _infoChip(Icons.people, '$vacancies Vacancies', Colors.orange[700]!),
                      if (location.isNotEmpty)
                        _infoChip(Icons.location_on, location, Colors.red[600]!),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  if (requirements.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.checklist, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            requirements,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Action buttons
                  if (!isExpired)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: () => _callOrLogin(post),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _jobGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () => _whatsApp(post),
                              icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                              label: const Text(
                                'WhatsApp',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF25D366)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF25D366)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 38,
                          width: 38,
                          child: OutlinedButton(
                            onPressed: () => _showJobDetail(post),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Position Filled / Expired',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatJobType(String type) {
    switch (type) {
      case 'FULL_TIME': return 'Full Time';
      case 'PART_TIME': return 'Part Time';
      case 'CONTRACT': return 'Contract';
      case 'DAILY_WAGE': return 'Daily Wage';
      case 'INTERNSHIP': return 'Internship';
      default: return type;
    }
  }

  void _showJobDetail(Map<String, dynamic> post) {
    final category = post['category']?.toString() ?? 'OTHER';
    final color = _categoryColors[category] ?? _jobGreen;
    final icon = _categoryIcons[category] ?? Icons.work;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['jobTitle']?.toString() ?? 'Job Opening',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if ((post['companyName'] ?? '').toString().isNotEmpty)
                        Text(
                          post['companyName'].toString(),
                          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Detail rows
            _detailRow(Icons.category, 'Category', _getCategoryLabel(category)),
            if ((post['location'] ?? '').toString().isNotEmpty)
              _detailRow(Icons.location_on, 'Location', post['location'].toString()),
            if ((post['salary'] ?? '').toString().isNotEmpty)
              _detailRow(
                Icons.currency_rupee,
                'Salary',
                '₹${post['salary']}${(post['salaryType'] ?? '').toString().isNotEmpty ? " / ${post['salaryType']}" : ""}',
              ),
            if ((post['jobType'] ?? '').toString().isNotEmpty)
              _detailRow(Icons.access_time, 'Job Type', _formatJobType(post['jobType'].toString())),
            if ((post['vacancies'] ?? '').toString().isNotEmpty)
              _detailRow(Icons.people, 'Vacancies', post['vacancies'].toString()),
            if ((post['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Job Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(post['description'].toString(), style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            ],
            if ((post['requirements'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Requirements / தகுதிகள்', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(post['requirements'].toString(), style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            ],
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _callOrLogin(post); },
                    icon: const Icon(Icons.call),
                    label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _jobGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _whatsApp(post); },
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25D366))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _jobGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            lang.getText('No job postings yet', 'வேலை வாய்ப்பு இல்லை'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            lang.getText('Be the first to post a job!', 'முதலில் வேலை பதிவிடுங்கள்!'),
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreate,
            icon: const Icon(Icons.add),
            label: Text(lang.getText('Post a Job', 'வேலை பதிவிடு')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _jobGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostsTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Please log in to see your job postings', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: _jobGreen, foregroundColor: Colors.white),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMyPosts) return const Center(child: LoadingWidget());

    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("You haven't posted any jobs yet", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Post a Job'),
              style: ElevatedButton.styleFrom(backgroundColor: _jobGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) => _buildMyPostCard(_myPosts[index]),
    );
  }

  Widget _buildMyPostCard(Map<String, dynamic> post) {
    final category = post['category']?.toString() ?? 'OTHER';
    final color = _categoryColors[category] ?? _jobGreen;
    final jobTitle = post['jobTitle']?.toString() ?? 'Job Opening';
    final company = post['companyName']?.toString() ?? '';
    final status = post['status']?.toString() ?? 'PENDING';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'APPROVED': statusColor = Colors.green; statusLabel = '✅ Active'; break;
      case 'PENDING': statusColor = Colors.orange; statusLabel = '⏳ Pending'; break;
      case 'EXPIRED': statusColor = Colors.grey; statusLabel = '❌ Expired'; break;
      default: statusColor = Colors.blue; statusLabel = status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(_categoryIcons[category] ?? Icons.work, color: color, size: 24),
        ),
        title: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.isNotEmpty) Text(company, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[400]),
          onPressed: () => _confirmDelete(post),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job Posting'),
        content: Text('Remove "${post['jobTitle'] ?? "this job"}" posting?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = post['id'];
              if (id != null) {
                await _jobService.deletePost(int.parse(id.toString()));
                _myPostsLoaded = false;
                _loadMyPosts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
