import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/image_url_helper.dart';
import '../services/travel_service.dart';

class TravelPostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const TravelPostDetailScreen({super.key, required this.post});

  @override
  State<TravelPostDetailScreen> createState() => _TravelPostDetailScreenState();
}

class _TravelPostDetailScreenState extends State<TravelPostDetailScreen> {
  static const Color _travelTeal = Color(0xFF00897B);
  late PageController _pageController;
  int _currentImageIndex = 0;

  Map<String, dynamic> get post => widget.post;

  List<String> get _imageUrls => _parseImageUrls(post);

  static List<String> _parseImageUrls(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];
    if (imageUrls != null && imageUrls.toString().isNotEmpty) {
      return imageUrls
          .toString()
          .split(',')
          .map((url) => ImageUrlHelper.getFullImageUrl(url.trim()))
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  static const Map<String, String> _vehicleTypeLabels = {
    'CAR': 'Car',
    'SMALL_BUS': 'Small Bus',
    'BUS': 'Bus',
  };

  static const Map<String, IconData> _vehicleTypeIcons = {
    'CAR': Icons.directions_car,
    'SMALL_BUS': Icons.airport_shuttle,
    'BUS': Icons.directions_bus,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _openFullScreenGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _TravelFullScreenGallery(
          imageUrls: _imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showReportDialog() {
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
                  'Why are you reporting "${post['title']}"?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: _travelTeal,
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
                      final travelService = TravelService();
                      final result = await travelService.reportPost(
                        post['id'],
                        selectedReason!,
                        details: detailsController.text,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Reported'),
                            backgroundColor: result['success'] == true ? _travelTeal : Colors.red,
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
    final isUnavailable = post['status'] == 'SOLD';
    final vehicleType = post['vehicleType']?.toString() ?? '';
    final vehicleIcon = _vehicleTypeIcons[vehicleType] ?? Icons.directions_bus;
    final vehicleLabel = _vehicleTypeLabels[vehicleType] ?? vehicleType;
    final imageUrls = _imageUrls;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          post['title'] ?? langProvider.getText('Travel Details', '\u0BAA\u0BAF\u0BA3 \u0BB5\u0BBF\u0BB5\u0BB0\u0B99\u0BCD\u0B95\u0BB3\u0BCD'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: _travelTeal,
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
            // Image Carousel
            if (imageUrls.isNotEmpty)
              GestureDetector(
                onTap: () => _openFullScreenGallery(_currentImageIndex),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: imageUrls[index],
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
                          );
                        },
                      ),
                      if (imageUrls.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${imageUrls.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
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
                      if (isUnavailable)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('UNAVAILABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(vehicleIcon, size: 80, color: Colors.grey[400]),
                    if (isUnavailable) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text('UNAVAILABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),

            // Dot indicators
            if (imageUrls.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (index) {
                  return Container(
                    width: _currentImageIndex == index ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? _travelTeal : Colors.grey[350],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Vehicle Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                          return isLoggedIn
                              ? Text(
                                  post['title'] ?? '',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                )
                              : ClipRect(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Text(
                                      post['title'] ?? '',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _travelTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vehicleIcon, size: 18, color: _travelTeal),
                            const SizedBox(width: 4),
                            Text(
                              vehicleLabel,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _travelTeal),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detail rows
                  if ((post['fromLocation'] != null && post['fromLocation'].toString().isNotEmpty) ||
                      (post['toLocation'] != null && post['toLocation'].toString().isNotEmpty))
                    _buildDetailRow(
                      Icons.route,
                      langProvider.getText('Route', '\u0BAA\u0BBE\u0BA4\u0BC8'),
                      '${post['fromLocation'] ?? ''} \u2192 ${post['toLocation'] ?? ''}',
                    ),

                  if (post['price'] != null && post['price'].toString().isNotEmpty)
                    _buildDetailRow(Icons.currency_rupee, langProvider.getText('Price', '\u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD'), post['price'].toString()),

                  if (post['seatsAvailable'] != null)
                    _buildDetailRow(Icons.event_seat, langProvider.getText('Seats Available', '\u0B87\u0BB0\u0BC1\u0B95\u0BCD\u0B95\u0BC8\u0B95\u0BB3\u0BCD'), post['seatsAvailable'].toString()),

                  if (post['phone'] != null && post['phone'].toString().isNotEmpty)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final phone = post['phone'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('${langProvider.getText('Phone', '\u0BA4\u0BCA\u0BB2\u0BC8\u0BAA\u0BC7\u0B9A\u0BBF')}: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
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

                  if (post['sellerName'] != null)
                    Builder(builder: (context) {
                      final isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                      final sellerName = post['sellerName'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('${langProvider.getText('Posted by', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BBF\u0B9F\u0BCD\u0B9F\u0BB5\u0BB0\u0BCD')}: ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
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

                  if (post['createdAt'] != null)
                    _buildDetailRow(Icons.access_time, langProvider.getText('Posted', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BBF\u0B9F\u0BCD\u0B9F \u0BA8\u0BBE\u0BB3\u0BCD'), _formatDate(post['createdAt'])),

                  // Description
                  if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(langProvider.getText('Description', '\u0BB5\u0BBF\u0BB5\u0BB0\u0BAE\u0BCD'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      post['description'],
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Contact buttons
                  if (!isUnavailable)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final phone = post['phone']?.toString() ?? '';
                              if (phone.isNotEmpty) {
                                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                                final uri = Uri.parse('tel:$cleanPhone');
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open phone dialer')),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.call),
                            label: Text(langProvider.getText('Call', '\u0B85\u0BB4\u0BC8\u0B95\u0BCD\u0B95')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _travelTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final phone = post['phone']?.toString() ?? '';
                              if (phone.isNotEmpty) {
                                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                final whatsappPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
                                final message = Uri.encodeComponent('Hi, I am interested in: ${post['title']} ($vehicleLabel)');
                                final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$message');
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open WhatsApp')),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _travelTeal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: _travelTeal),
                            ),
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

// Full Screen Gallery with InteractiveViewer

class _TravelFullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _TravelFullScreenGallery({required this.imageUrls, required this.initialIndex});

  @override
  State<_TravelFullScreenGallery> createState() => _TravelFullScreenGalleryState();
}

class _TravelFullScreenGalleryState extends State<_TravelFullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
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
              );
            },
          ),
          // Thumbnail strip at bottom
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentIndex == index ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrls[index],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.broken_image, size: 20, color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
