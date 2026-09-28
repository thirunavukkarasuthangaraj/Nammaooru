import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/shop_service.dart';

/// Lets a shop owner browse the master product catalog and add items to
/// their own shop with their own selling price, MRP, cost price and stock.
class BrowseCatalogScreen extends StatefulWidget {
  const BrowseCatalogScreen({super.key});

  @override
  State<BrowseCatalogScreen> createState() => _BrowseCatalogScreenState();
}

class _BrowseCatalogScreenState extends State<BrowseCatalogScreen> {
  static const Color _primaryColor = Color(0xFFFF9800);

  final ShopService _shopService = ShopService();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 0;
        _items.clear();
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _shopService.getAvailableMasterProducts(
        page: _page,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      final items = result['items'] as List<Map<String, dynamic>>;
      setState(() {
        _items.addAll(items);
        _hasMore = result['hasMore'] as bool? ?? false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    _page += 1;
    _loadCatalog();
  }

  String? _imageUrl(Map<String, dynamic> item) {
    final url = item['primaryImageUrl'];
    if (url is String && url.isNotEmpty) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Add Product from Catalog',
        backgroundColor: _primaryColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Search catalog...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCatalog(reset: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (_) => _loadCatalog(reset: true),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadCatalog(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No catalog products found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCatalogCard(_items[index]);
        },
      ),
    );
  }

  Widget _buildCatalogCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Unnamed';
    final category = item['category'] is Map ? item['category']['name']?.toString() : null;
    final imageUrl = _imageUrl(item);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAddDialog(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 40),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 2),
                    Text(category, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(Map<String, dynamic> item) {
    final masterProductId = (item['id'] as num).toInt();
    final name = item['name']?.toString() ?? 'Product';
    final minPrice = (item['minPrice'] as num?)?.toDouble();

    final priceController = TextEditingController(text: minPrice != null ? minPrice.toString() : '');
    final originalPriceController = TextEditingController();
    final costPriceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final minStockController = TextEditingController(text: '5');
    final screenContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add $name'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Selling Price *',
                  border: OutlineInputBorder(),
                  helperText: 'Price customers will pay',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: originalPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Original Price / MRP (optional)',
                  border: OutlineInputBorder(),
                  helperText: 'For showing a discount (set higher than selling price)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost Price (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Stock Level', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                Helpers.showSnackBar(dialogContext, 'Please enter a valid price', isError: true);
                return;
              }
              final originalPrice = originalPriceController.text.isEmpty
                  ? null
                  : double.tryParse(originalPriceController.text);
              final costPrice =
                  costPriceController.text.isEmpty ? null : double.tryParse(costPriceController.text);
              final stock = int.tryParse(stockController.text) ?? 0;
              final minStock = int.tryParse(minStockController.text) ?? 5;

              Navigator.pop(dialogContext);
              try {
                await _shopService.addProductToShop(
                  masterProductId: masterProductId,
                  price: price,
                  originalPrice: originalPrice,
                  costPrice: costPrice,
                  stockQuantity: stock,
                  minStockLevel: minStock,
                );
                if (mounted) {
                  Helpers.showSnackBar(screenContext, '$name added to your shop');
                  setState(() => _items.removeWhere((i) => i['id'] == masterProductId));
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackBar(screenContext, '$e', isError: true);
                }
              }
            },
            child: const Text('Add to Shop'),
          ),
        ],
      ),
    );
  }
}
