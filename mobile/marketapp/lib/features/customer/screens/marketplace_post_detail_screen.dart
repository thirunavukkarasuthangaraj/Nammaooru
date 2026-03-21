import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../services/marketplace_service.dart';

class MarketplacePostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const MarketplacePostDetailScreen({super.key, required this.post});

  @override
  State<MarketplacePostDetailScreen> createState() => _MarketplacePostDetailScreenState();
}

class _MarketplacePostDetailScreenState extends State<MarketplacePostDetailScreen> {
  static const Color _themeColor = VillageTheme.primaryGreen;

  Map<String, dynamic> get post => widget.post;

  String _getImageUrl() {
    final imageUrl = post['imageUrl'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return ImageUrlHelper.getFullImageUrl(imageUrl.toString());
    }
    return '';
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
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MarketplaceFullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  void _showReportDialog() {
    final reasons = [
      'Fake / Counterfeit Product',
      'Stolen Product',
      'Scam / Fraud',
      'Inappropriate Content',
      'Wrong Information',
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
              const Text('Report Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting "${post['title']}"?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _themeColor,
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
                      final service = MarketplaceService();
                      final result = await service.reportPost(
                        post['id'],
                        selectedReason!,
                        details: detailsController.text,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Reported'),
                            backgroundColor: result['success'] == true ? _themeColor : Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSold = post['status'] == 'SOLD';
    final price = post['price'];
    final imageUrl = _getImageUrl();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          post['title'] ?? langProvider.getText('Post Details', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0BB5\u0BBF\u0BB5\u0BB0\u0B99\u0BCD\u0B95\u0BB3\u0BCD'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showReportDialog,
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _openFullScreenImage(imageUrl),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 280,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 280,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      if (isSold)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('SOLD OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Icon(Icons.storefront, size: 80, color: Colors.grey[400]),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatPrice(price),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _themeColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category badge
                  if (post['category'] != null)
                    _buildDetailRow(Icons.category, 'Category', post['category']),

                  // Seller name (blurred if not logged in)
                  if (post['sellerName'] != null)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final sellerName = post['sellerName'] ?? 'Seller';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('Seller: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                            Expanded(
                              child: isLoggedIn
                                  ? Text(sellerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                                  : ClipRect(
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Text(sellerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Phone (blurred if not logged in)
                  if (post['sellerPhone'] != null && post['sellerPhone'].toString().isNotEmpty)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final phone = post['sellerPhone'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('Phone: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                            Expanded(
                              child: isLoggedIn
                                  ? Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                                  : ClipRect(
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Location
                  if (post['location'] != null && post['location'].toString().isNotEmpty)
                    _buildDetailRow(Icons.location_on, 'Location', post['location']),

                  // Posted date
                  if (post['createdAt'] != null)
                    _buildDetailRow(Icons.access_time, 'Posted', _formatDate(post['createdAt'])),

                  // Description
                  if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      post['description'],
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Call + WhatsApp buttons
                  if (!isSold)
                    Builder(builder: (ctx) {
                      final isLoggedIn = Provider.of<AuthProvider>(ctx, listen: false).isAuthenticated;
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!isLoggedIn) {
                                  GoRouter.of(context).go('/login');
                                  return;
                                }
                                final phone = post['sellerPhone']?.toString() ?? '';
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Phone number not available')),
                                  );
                                  return;
                                }
                                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                                final uri = Uri.parse('tel:$cleanPhone');
                                launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open phone dialer')),
                                    );
                                  }
                                  return false;
                                });
                              },
                              icon: Icon(isLoggedIn ? Icons.call : Icons.login),
                              label: Text(isLoggedIn ? 'Call' : 'Login to Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (!isLoggedIn) {
                                  GoRouter.of(context).go('/login');
                                  return;
                                }
                                final phone = post['sellerPhone']?.toString() ?? '';
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Phone number not available')),
                                  );
                                  return;
                                }
                                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                                final message = Uri.encodeComponent('Hi, I am interested in: ${post['title']}');
                                final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
                                launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open WhatsApp')),
                                    );
                                  }
                                  return false;
                                });
                              },
                              icon: Icon(isLoggedIn ? Icons.chat : Icons.login),
                              label: Text(isLoggedIn ? 'WhatsApp' : 'Login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _themeColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: _themeColor),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// Full Screen Image Viewer
class _MarketplaceFullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _MarketplaceFullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Image', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('Failed to load image', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
