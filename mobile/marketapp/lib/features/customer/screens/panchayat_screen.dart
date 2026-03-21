import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PanchayatScreen extends StatefulWidget {
  const PanchayatScreen({super.key});

  @override
  State<PanchayatScreen> createState() => _PanchayatScreenState();
}

class _PanchayatScreenState extends State<PanchayatScreen> {
  String? _selectedVillage;
  String? _webViewUrl;
  bool _isLoading = false;
  bool _isFetchingVillages = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _villages = [];

  @override
  void initState() {
    super.initState();
    _fetchVillages();
  }

  Future<void> _fetchVillages() async {
    setState(() {
      _isFetchingVillages = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get('/villages', includeAuth: false);
      final data = response['data'] as List<dynamic>? ?? [];
      setState(() {
        _villages = data.map<Map<String, dynamic>>((v) {
          return {
            'id': v['id'],
            'name': v['name'] ?? '',
            'nameTamil': v['nameTamil'] ?? '',
            'district': v['district'] ?? '',
            'panchayatName': v['panchayatName'] ?? '',
            'panchayatUrl': v['panchayatUrl'] ?? '',
            'description': v['description'] ?? '',
          };
        }).toList();
        _isFetchingVillages = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingVillages = false;
        _errorMessage = 'Failed to load villages. Pull to retry.';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredVillages {
    if (_searchQuery.isEmpty) return _villages;
    return _villages.where((v) {
      final name = (v['name'] as String).toLowerCase();
      final nameTamil = v['nameTamil'] as String;
      final district = (v['district'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || nameTamil.contains(query) || district.contains(query);
    }).toList();
  }

  void _openVillage(Map<String, dynamic> village) {
    final url = village['panchayatUrl'] as String? ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Panchayat details for ${village['name']} coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _selectedVillage = village['name'] as String;
      _webViewUrl = url;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_webViewUrl != null) {
      return _buildWebViewPage(languageProvider);
    }
    return _buildVillageListPage(languageProvider);
  }

  Widget _buildVillageListPage(LanguageProvider languageProvider) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.getText('Village / Panchayat', 'கிராமம் / பஞ்சாயத்து'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchVillages,
        child: Column(
          children: [
            // Search bar
            Container(
              color: VillageTheme.primaryGreen,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: languageProvider.getText('Search village...', 'கிராமம் தேடுக...'),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isFetchingVillages
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState(languageProvider)
                      : _buildVillageList(languageProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(LanguageProvider languageProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchVillages,
            icon: const Icon(Icons.refresh),
            label: Text(languageProvider.getText('Retry', 'மீண்டும் முயற்சி')),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageList(LanguageProvider languageProvider) {
    final filtered = _filteredVillages;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              languageProvider.getText('No villages found', 'கிராமங்கள் இல்லை'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final village = filtered[index];
        return _buildVillageCard(village, languageProvider);
      },
    );
  }

  Widget _buildVillageCard(Map<String, dynamic> village, LanguageProvider languageProvider) {
    final hasUrl = ((village['panchayatUrl'] as String?) ?? '').isNotEmpty;
    final name = village['name'] as String;
    final nameTamil = village['nameTamil'] as String;
    final district = village['district'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openVillage(village),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasUrl
                      ? VillageTheme.primaryGreen.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: hasUrl ? VillageTheme.primaryGreen : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.currentLanguage == 'ta' ? nameTamil : name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageProvider.currentLanguage == 'ta' ? name : nameTamil,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (district.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        district,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                hasUrl ? Icons.arrow_forward_ios : Icons.schedule,
                size: 18,
                color: hasUrl ? VillageTheme.primaryGreen : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebViewPage(LanguageProvider languageProvider) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_webViewUrl!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedVillage ?? languageProvider.getText('Panchayat Details', 'பஞ்சாயத்து விவரங்கள்'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedVillage = null;
              _webViewUrl = null;
            });
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
