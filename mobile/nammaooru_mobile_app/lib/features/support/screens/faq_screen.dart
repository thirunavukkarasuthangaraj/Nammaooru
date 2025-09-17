import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';
import '../models/faq_model.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _searchController = TextEditingController();

  List<FAQ> _faqs = [];
  List<FAQ> _filteredFAQs = [];
  List<FAQCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFAQData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQData() async {
    setState(() => _isLoading = true);

    try {
      final [faqs, categories] = await Future.wait([
        _supportService.getFAQs(),
        _supportService.getFAQCategories(),
      ]);

      setState(() {
        _faqs = faqs as List<FAQ>;
        _filteredFAQs = _faqs;
        _categories = categories as List<FAQCategory>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _faqs = _getDefaultFAQs();
        _filteredFAQs = _faqs;
        _categories = _getDefaultCategories();
      });
    }
  }

  void _filterFAQs() {
    setState(() {
      _filteredFAQs = _faqs.where((faq) {
        final matchesSearch = _searchQuery.isEmpty ||
            faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesCategory = _selectedCategory == null ||
            faq.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Section
                _buildSearchAndFilterSection(),

                // FAQ List
                Expanded(
                  child: _filteredFAQs.isEmpty
                      ? _buildEmptyState()
                      : _buildFAQList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _filterFAQs();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: VillageTheme.primaryGreen),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: VillageTheme.primaryGreen, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterFAQs();
            },
          ),

          const SizedBox(height: 16),

          // Category Filter
          if (_categories.isNotEmpty) _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() => _selectedCategory = null);
                  _filterFAQs();
                },
                selectedColor: VillageTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: _selectedCategory == null ? Colors.white : VillageTheme.textPrimary,
                ),
              ),
            );
          }

          final category = _categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.name),
              selected: _selectedCategory == category.id,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category.id : null;
                });
                _filterFAQs();
              },
              selectedColor: VillageTheme.primaryGreen,
              labelStyle: TextStyle(
                color: _selectedCategory == category.id ? Colors.white : VillageTheme.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFAQs.length,
      itemBuilder: (context, index) {
        final faq = _filteredFAQs[index];
        return _buildFAQCard(faq);
      },
    );
  }

  Widget _buildFAQCard(FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: VillageTheme.cardDecoration,
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: VillageTheme.textPrimary,
          ),
        ),
        subtitle: faq.tags.isNotEmpty
            ? Wrap(
                children: faq.tags.take(3).map((tag) => Container(
                  margin: const EdgeInsets.only(right: 4, top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                )).toList(),
              )
            : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: VillageTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.help_outline,
            color: VillageTheme.primaryGreen,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.answer,
                  style: const TextStyle(
                    color: VillageTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                if (faq.videoUrl != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Open video URL
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Was this helpful section
                Row(
                  children: [
                    const Text(
                      'Was this helpful?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: VillageTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _markHelpful(faq.id, true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Yes'),
                      style: TextButton.styleFrom(
                        foregroundColor: VillageTheme.successGreen,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _markHelpful(faq.id, false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('No'),
                      style: TextButton.styleFrom(
                        foregroundColor: VillageTheme.errorRed,
                      ),
                    ),
                  ],
                ),

                if (faq.relatedFAQs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Related Questions:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: VillageTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...faq.relatedFAQs.take(2).map((relatedId) {
                    final relatedFAQ = _faqs.firstWhere(
                      (f) => f.id == relatedId,
                      orElse: () => FAQ(
                        id: '',
                        question: 'Related question',
                        answer: '',
                        category: '',
                        tags: [],
                        viewCount: 0,
                        isHelpful: false,
                        createdAt: DateTime.now(),
                        relatedFAQs: [],
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () {
                          // Navigate to related FAQ
                        },
                        child: Text(
                          '• ${relatedFAQ.question}',
                          style: TextStyle(
                            color: VillageTheme.primaryGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No FAQs found for "$_searchQuery"'
                : 'No FAQs available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try different keywords or contact support'
                : 'FAQs will be loaded here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _filterFAQs();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  void _markHelpful(String faqId, bool isHelpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHelpful ? 'Thank you for your feedback!' : 'We\'ll improve this answer'),
        backgroundColor: isHelpful ? VillageTheme.successGreen : VillageTheme.warningOrange,
      ),
    );
  }

  List<FAQ> _getDefaultFAQs() {
    return [
      FAQ(
        id: '1',
        question: 'How do I place an order?',
        answer: 'To place an order, browse through our shops, select products you want, add them to your cart, and proceed to checkout. You can pay online or choose cash on delivery.',
        category: 'orders',
        tags: ['order', 'cart', 'checkout'],
        viewCount: 150,
        isHelpful: true,
        createdAt: DateTime.now(),
        relatedFAQs: ['2', '3'],
      ),
      FAQ(
        id: '2',
        question: 'How can I track my order?',
        answer: 'You can track your order in the "My Orders" section of the app. You\'ll receive real-time updates about your order status and delivery partner location.',
        category: 'orders',
        tags: ['tracking', 'delivery', 'status'],
        viewCount: 120,
        isHelpful: true,
        createdAt: DateTime.now(),
        relatedFAQs: ['1', '4'],
      ),
      FAQ(
        id: '3',
        question: 'What payment methods are accepted?',
        answer: 'We accept various payment methods including UPI, credit/debit cards, net banking, and cash on delivery. All online payments are secure and encrypted.',
        category: 'payment',
        tags: ['payment', 'upi', 'card', 'cod'],
        viewCount: 200,
        isHelpful: true,
        createdAt: DateTime.now(),
        relatedFAQs: ['1'],
      ),
      FAQ(
        id: '4',
        question: 'How do I cancel my order?',
        answer: 'You can cancel your order before it\'s picked up by the delivery partner. Go to "My Orders", select your order, and tap "Cancel Order". Refunds will be processed within 3-5 business days.',
        category: 'orders',
        tags: ['cancel', 'refund', 'orders'],
        viewCount: 85,
        isHelpful: true,
        createdAt: DateTime.now(),
        relatedFAQs: ['2', '3'],
      ),
      FAQ(
        id: '5',
        question: 'How do I contact customer support?',
        answer: 'You can contact our support team through the Help & Support section. We offer phone support, WhatsApp chat, email, and live chat options. Our team is available 24/7 to help you.',
        category: 'support',
        tags: ['support', 'contact', 'help'],
        viewCount: 95,
        isHelpful: true,
        createdAt: DateTime.now(),
        relatedFAQs: [],
      ),
    ];
  }

  List<FAQCategory> _getDefaultCategories() {
    return [
      FAQCategory(
        id: 'orders',
        name: 'Orders',
        description: 'Questions about placing and managing orders',
        icon: 'shopping_bag',
        faqCount: 8,
        order: 1,
      ),
      FAQCategory(
        id: 'payment',
        name: 'Payment',
        description: 'Payment methods and billing questions',
        icon: 'payment',
        faqCount: 5,
        order: 2,
      ),
      FAQCategory(
        id: 'delivery',
        name: 'Delivery',
        description: 'Delivery and shipping information',
        icon: 'delivery_dining',
        faqCount: 6,
        order: 3,
      ),
      FAQCategory(
        id: 'account',
        name: 'Account',
        description: 'Account and profile related questions',
        icon: 'account_circle',
        faqCount: 4,
        order: 4,
      ),
      FAQCategory(
        id: 'support',
        name: 'Support',
        description: 'General support and contact information',
        icon: 'support',
        faqCount: 3,
        order: 5,
      ),
    ];
  }
}