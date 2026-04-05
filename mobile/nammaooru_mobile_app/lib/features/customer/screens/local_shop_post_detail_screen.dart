import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/services/contact_view_service.dart';
import 'package:go_router/go_router.dart';

class LocalShopPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const LocalShopPostDetailScreen({super.key, required this.post});

  static const Color _shopColor = Color(0xFFFF6F00);

  static const Map<String, String> _categoryLabels = {
    'GROCERY': 'Grocery',
    'MEDICAL': 'Medical / Pharmacy',
    'HARDWARE': 'Hardware',
    'ELECTRONICS': 'Electronics',
    'CLOTHING': 'Clothing / Textiles',
    'STATIONERY': 'Stationery',
    'RESTAURANT': 'Hotel / Restaurant',
    'BAKERY': 'Bakery',
    'VEGETABLES': 'Vegetables / Fruits',
    'MEAT_FISH': 'Meat / Fish',
    'SALON': 'Salon / Parlour',
    'GYM': 'Gym / Yoga',
    'LAUNDRY': 'Laundry',
    'TAILORING': 'Tailoring',
    'PRINTING': 'Printing / Xerox',
    'MOBILE_SHOP': 'Mobile Shop',
    'COMPUTER_SHOP': 'Computer Shop',
    'AUTO_PARTS': 'Auto Spare Parts',
    'PETROL_BUNK': 'Petrol Bunk',
    'JEWELLERY': 'Jewellery',
    'COURIER': 'Courier Service',
    'OTHER': 'Other',
  };

  static const Map<String, String> _categoryTamil = {
    'GROCERY': 'மளிகை கடை',
    'MEDICAL': 'மருந்தகம்',
    'HARDWARE': 'ஹார்டுவேர்',
    'ELECTRONICS': 'எலக்ட்ரானிக்ஸ்',
    'CLOTHING': 'துணிக்கடை',
    'STATIONERY': 'ஸ்டேஷனரி',
    'RESTAURANT': 'ஹோட்டல்',
    'BAKERY': 'பேக்கரி',
    'VEGETABLES': 'காய்கறி / பழம்',
    'MEAT_FISH': 'இறைச்சி / மீன்',
    'SALON': 'சலூன்',
    'GYM': 'ஜிம்',
    'LAUNDRY': 'லாண்டரி',
    'TAILORING': 'தையல்',
    'PRINTING': 'பிரிண்டிங்',
    'MOBILE_SHOP': 'மொபைல் கடை',
    'COMPUTER_SHOP': 'கம்ப்யூட்டர் கடை',
    'AUTO_PARTS': 'ஆட்டோ பாகங்கள்',
    'PETROL_BUNK': 'பெட்ரோல் பங்க்',
    'JEWELLERY': 'நகைக்கடை',
    'COURIER': 'கூரியர்',
    'OTHER': 'மற்றவை',
  };

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final shopName = post['shopName'] ?? '';
    final phone = post['phone'] ?? '';
    final category = post['category'] ?? '';
    final address = post['address'] ?? '';
    final timings = post['timings'] ?? '';
    final description = post['description'] ?? '';
    final sellerName = post['sellerName'] ?? '';
    final imageUrlsRaw = post['imageUrls'] ?? '';
    final imageUrls = imageUrlsRaw.toString().isNotEmpty
        ? imageUrlsRaw.toString().split(',').where((u) => u.trim().isNotEmpty).toList()
        : <String>[];

    final categoryLabel = lang.getText(
      _categoryLabels[category] ?? category,
      _categoryTamil[category] ?? category,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName, overflow: TextOverflow.ellipsis),
        backgroundColor: _shopColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: ImageUrlHelper.getFullUrl(imageUrls[index].trim()),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.store, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: _shopColor.withOpacity(0.1),
                child: const Icon(Icons.store, size: 64, color: _shopColor),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name & Category
                  Text(shopName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _shopColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(categoryLabel, style: const TextStyle(color: _shopColor, fontWeight: FontWeight.w500)),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Details
                  if (address.isNotEmpty) ...[
                    _buildDetailRow(Icons.location_on, lang.getText('Address', 'முகவரி'), address),
                    const SizedBox(height: 10),
                  ],
                  if (timings.isNotEmpty) ...[
                    _buildDetailRow(Icons.access_time, lang.getText('Timings', 'நேரம்'), timings),
                    const SizedBox(height: 10),
                  ],
                  if (phone.isNotEmpty) ...[
                    _buildDetailRow(Icons.phone, lang.getText('Phone', 'தொலைபேசி'), phone),
                    const SizedBox(height: 10),
                  ],
                  if (sellerName.isNotEmpty) ...[
                    _buildDetailRow(Icons.person, lang.getText('Posted by', 'இடுகையிட்டவர்'), sellerName),
                    const SizedBox(height: 10),
                  ],
                  if (description.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(lang.getText('About This Shop', 'கடையைப் பற்றி'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                  ],

                  const SizedBox(height: 24),

                  // Call Button
                  if (phone.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!authProvider.isAuthenticated) {
                            context.go('/register');
                            return;
                          }
                          ContactViewService.log(
                            postType: 'LOCAL_SHOP',
                            postId: post['id'] ?? 0,
                            postTitle: shopName,
                            sellerPhone: phone,
                            ownerUserId: post['sellerUserId'] != null
                                ? int.tryParse(post['sellerUserId'].toString())
                                : null,
                          );
                          _callPhone(context, phone);
                        },
                        icon: const Icon(Icons.phone),
                        label: Text(lang.getText('Call Shop', 'கடையை அழை')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _shopColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _shopColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
