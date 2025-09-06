import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../screens/orders_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/shop_listing_screen.dart';

class VillageCustomerDashboard extends StatefulWidget {
  const VillageCustomerDashboard({Key? key}) : super(key: key);

  @override
  _VillageCustomerDashboardState createState() => _VillageCustomerDashboardState();
}

class _VillageCustomerDashboardState extends State<VillageCustomerDashboard> {
  String _selectedLocation = 'என் ஊர் / My Village';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildVillageHeader(),
              const SizedBox(height: VillageTheme.spacingL),
              _buildLocationCard(),
              const SizedBox(height: VillageTheme.spacingXL),
              _buildMainCategories(),
              const SizedBox(height: VillageTheme.spacingXL),
              _buildQuickActions(),
              const SizedBox(height: VillageTheme.spacingXL),
              _buildFeaturedServices(),
              const SizedBox(height: VillageTheme.spacingXL),
              _buildSupportCard(),
              const SizedBox(height: VillageTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVillageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VillageTheme.spacingL),
      decoration: BoxDecoration(
        gradient: VillageTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(VillageTheme.spacingL),
          bottomRight: Radius.circular(VillageTheme.spacingL),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VillageTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.account_circle,
                  size: VillageTheme.iconLarge,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: VillageTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'வணக்கம்! 🙏',
                      style: VillageTheme.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Good Morning! Welcome to NammaOoru',
                      style: VillageTheme.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: VillageTheme.iconLarge,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: VillageTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageTheme.spacingM),
          Text(
            'என்ன வேண்டும்? / What do you need?',
            style: VillageTheme.headingSmall.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      padding: const EdgeInsets.all(VillageTheme.spacingL),
      decoration: VillageTheme.elevatedCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(VillageTheme.spacingS),
            decoration: BoxDecoration(
              color: VillageTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
            ),
            child: const Icon(
              Icons.location_on,
              color: VillageTheme.primaryGreen,
              size: VillageTheme.iconLarge,
            ),
          ),
          const SizedBox(width: VillageTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'வழங்கும் இடம் / Deliver to',
                  style: VillageTheme.bodySmall.copyWith(
                    color: VillageTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: VillageTheme.spacingXS),
                Text(
                  _selectedLocation,
                  style: VillageTheme.headingSmall.copyWith(
                    color: VillageTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLocationPicker(),
            icon: const Icon(
              Icons.edit_location,
              color: VillageTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategories() {
    final categories = [
      {
        'name': 'மளிகை கடை\nGrocery Store',
        'icon': Icons.store,
        'color': VillageTheme.categoryColors['grocery']!,
        'image': '🛒',
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopListingScreen())),
      },
      {
        'name': 'மருந்து கடை\nMedical Store', 
        'icon': Icons.local_pharmacy,
        'color': VillageTheme.categoryColors['medical']!,
        'image': '💊',
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopListingScreen())),
      },
      {
        'name': 'உணவு கடை\nFood & Snacks',
        'icon': Icons.restaurant,
        'color': VillageTheme.categoryColors['food']!,
        'image': '🍽️',
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopListingScreen())),
      },
      {
        'name': 'பொது கடை\nGeneral Store',
        'icon': Icons.store_mall_directory,
        'color': VillageTheme.categoryColors['default']!,
        'image': '🏪',
        'route': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopListingScreen())),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'கடைகள் / Shop Categories',
            style: VillageTheme.headingMedium.copyWith(
              color: VillageTheme.primaryText,
            ),
          ),
          const SizedBox(height: VillageTheme.spacingM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: VillageTheme.spacingM,
              mainAxisSpacing: VillageTheme.spacingM,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildVillageCategoryCard(
                title: category['name'] as String,
                icon: category['icon'] as IconData,
                color: category['color'] as Color,
                emoji: category['image'] as String,
                onTap: category['route'] as VoidCallback,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVillageCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        boxShadow: VillageTheme.cardShadow,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(VillageTheme.spacingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large Emoji for visual recognition
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: VillageTheme.spacingS),
                // Category Name in Tamil and English
                Text(
                  title,
                  style: VillageTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VillageTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: VillageTheme.spacingXS),
                // Visual indicator
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      padding: const EdgeInsets.all(VillageTheme.spacingL),
      decoration: VillageTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'விரைவு செயல்கள் / Quick Actions',
            style: VillageTheme.headingSmall.copyWith(
              color: VillageTheme.primaryText,
            ),
          ),
          const SizedBox(height: VillageTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                title: 'ஆர்டர்கள்\nMy Orders',
                icon: Icons.receipt_long,
                color: VillageTheme.infoBlue,
                emoji: '📋',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen())),
              ),
              _buildQuickActionButton(
                title: 'வண்டி\nMy Cart',
                icon: Icons.shopping_cart,
                color: VillageTheme.accentOrange,
                emoji: '🛒',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
              ),
              _buildQuickActionButton(
                title: 'உதவி\nHelp',
                icon: Icons.support_agent,
                color: VillageTheme.warningOrange,
                emoji: '🆘',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingXS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
          child: Container(
            padding: const EdgeInsets.all(VillageTheme.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: VillageTheme.spacingS),
                Text(
                  title,
                  style: VillageTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VillageTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedServices() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      padding: const EdgeInsets.all(VillageTheme.spacingL),
      decoration: BoxDecoration(
        gradient: VillageTheme.accentGradient,
        borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        boxShadow: VillageTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            '🎉 இன்றைய சிறப்பு / Today\'s Special',
            style: VillageTheme.headingSmall.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VillageTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureItem(
                emoji: '🚚',
                title: 'இலவச டெலிவரி\nFree Delivery',
                subtitle: 'Above ₹200',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildFeatureItem(
                emoji: '💰',
                title: 'கை पर भुगतान\nCash on Delivery',
                subtitle: 'Pay at home',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildFeatureItem(
                emoji: '📞',
                title: 'தமிழ் ஆதரவு\nTamil Support',
                subtitle: '24/7 Help',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: VillageTheme.spacingXS),
          Text(
            title,
            style: VillageTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: VillageTheme.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
      padding: const EdgeInsets.all(VillageTheme.spacingL),
      decoration: VillageTheme.elevatedCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VillageTheme.spacingM),
                decoration: BoxDecoration(
                  color: VillageTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  '📞',
                  style: TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: VillageTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'உதவி தேவையா? / Need Help?',
                      style: VillageTheme.headingSmall.copyWith(
                        color: VillageTheme.primaryText,
                      ),
                    ),
                    Text(
                      'Call us anytime for support',
                      style: VillageTheme.bodyMedium.copyWith(
                        color: VillageTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageTheme.spacingM),
          VillageWidgets.bigButton(
            text: 'இப்போது அழைக்கவும் / Call Now',
            icon: Icons.phone,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
            backgroundColor: VillageTheme.successGreen,
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VillageTheme.cardRadius)),
      ),
      builder: (context) {
        final locations = [
          'என் ஊர் / My Village',
          'சென்னை / Chennai',
          'மதுரை / Madurai',
          'கோவை / Coimbatore',
          'திருச்சி / Trichy',
        ];

        return Container(
          padding: const EdgeInsets.all(VillageTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'இடம் தேர்ந்தெடுக்கவும் / Choose Location',
                style: VillageTheme.headingMedium,
              ),
              const SizedBox(height: VillageTheme.spacingM),
              ...locations.map((location) => ListTile(
                leading: const Icon(Icons.location_on, color: VillageTheme.primaryGreen),
                title: Text(
                  location,
                  style: VillageTheme.bodyLarge,
                ),
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                  Navigator.pop(context);
                },
                trailing: _selectedLocation == location
                    ? const Icon(Icons.check, color: VillageTheme.successGreen)
                    : null,
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}