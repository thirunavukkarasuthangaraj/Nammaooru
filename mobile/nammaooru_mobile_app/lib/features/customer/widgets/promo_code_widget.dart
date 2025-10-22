import 'package:flutter/material.dart';
import '../../../core/services/promo_code_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/theme/village_theme.dart';

class PromoCodeWidget extends StatefulWidget {
  final double orderAmount;
  final String? shopId;
  final String? customerId;
  final String? customerPhone;
  final Function(PromoCodeValidationResult) onPromoApplied;
  final Function() on PromoRemoved;

  const PromoCodeWidget({
    super.key,
    required this.orderAmount,
    this.shopId,
    this.customerId,
    this.customerPhone,
    required this.onPromoApplied,
    required this.onPromoRemoved,
  });

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final TextEditingController _promoController = TextEditingController();
  final PromoCodeService _promoService = PromoCodeService();
  final DeviceInfoService _deviceService = DeviceInfoService();

  bool _isValidating = false;
  bool _isExpanded = false;
  PromoCodeValidationResult? _appliedPromo;
  List<PromoCode> _availablePromos = [];
  bool _loadingPromos = false;

  @override
  void initState() {
    super.initState();
    _loadAvailablePromos();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePromos() async {
    setState(() => _loadingPromos = true);
    try {
      final promos = await _promoService.getActivePromotions(
        shopId: widget.shopId,
      );
      setState(() {
        _availablePromos = promos;
        _loadingPromos = false;
      });
    } catch (e) {
      setState(() => _loadingPromos = false);
    }
  }

  Future<void> _validatePromoCode(String code) async {
    if (code.trim().isEmpty) {
      _showMessage('Please enter a promo code', isError: true);
      return;
    }

    setState(() => _isValidating = true);

    try {
      // Get device UUID
      final deviceUuid = await _deviceService.getDeviceUuid();

      // Validate promo code
      final result = await _promoService.validatePromoCode(
        promoCode: code.trim().toUpperCase(),
        orderAmount: widget.orderAmount,
        customerId: widget.customerId,
        deviceUuid: deviceUuid,
        phone: widget.customerPhone,
        shopId: widget.shopId,
      );

      setState(() {
        _isValidating = false;
        if (result.isValid) {
          _appliedPromo = result;
          _isExpanded = false;
        }
      });

      if (result.isValid) {
        widget.onPromoApplied(result);
        _showMessage(result.message, isError: false);
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      setState(() => _isValidating = false);
      _showMessage('Failed to validate promo code', isError: true);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoController.clear();
    });
    widget.onPromoRemoved();
    _showMessage('Promo code removed', isError: false);
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedPromo != null) {
      return _buildAppliedPromoCard();
    }

    return _buildPromoInputCard();
  }

  Widget _buildAppliedPromoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promo Applied: ${_promoController.text.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _appliedPromo!.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'You saved ₹${_appliedPromo!.discountAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _removePromo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: VillageTheme.primaryGreen),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Have a promo code?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: VillageTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo code input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.discount),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (value) => _validatePromoCode(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isValidating
                            ? null
                            : () => _validatePromoCode(_promoController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VillageTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isValidating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),

                  // Available promos
                  if (_availablePromos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Available Offers:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._availablePromos.take(3).map((promo) => _buildPromoChip(promo)),
                  ],

                  if (_loadingPromos)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoChip(PromoCode promo) {
    return InkWell(
      onTap: () {
        _promoController.text = promo.code;
        _validatePromoCode(promo.code);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                promo.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${promo.formattedDiscount} • ${promo.formattedMinOrder}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: VillageTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
