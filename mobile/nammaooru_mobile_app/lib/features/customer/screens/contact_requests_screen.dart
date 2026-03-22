import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/contact_request_service.dart';
import '../../../core/localization/language_provider.dart';

class ContactRequestsScreen extends StatefulWidget {
  const ContactRequestsScreen({super.key});

  @override
  State<ContactRequestsScreen> createState() => _ContactRequestsScreenState();
}

class _ContactRequestsScreenState extends State<ContactRequestsScreen> {
  static const Color _primaryColor = Color(0xFFE91E63);

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track which requests are being actioned to show per-row loading
  final Set<dynamic> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final requests = await ContactRequestService.getIncoming();
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load requests. Please try again.';
        });
      }
    }
  }

  Future<void> _handleAction({
    required dynamic requestId,
    required bool approve,
    required LanguageProvider lang,
  }) async {
    final actionLabel = approve
        ? lang.getText('Approve', 'அனுமதி')
        : lang.getText('Deny', 'மறுக்க');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionLabel ${lang.getText('Request', 'கோரிக்கை')}?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          approve
              ? lang.getText(
                  'The requester will be able to see your phone number.',
                  'கோரிக்கையாளர் உங்கள் தொலைபேசி எண்ணை பார்க்க முடியும்.',
                )
              : lang.getText(
                  'The requester will not be able to see your phone number.',
                  'கோரிக்கையாளர் உங்கள் தொலைபேசி எண்ணை பார்க்க முடியாது.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('Cancel', 'ரத்து')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green[600] : Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(requestId));

    final success = approve
        ? await ContactRequestService.approve(requestId)
        : await ContactRequestService.deny(requestId);

    if (mounted) {
      setState(() => _processingIds.remove(requestId));

      if (success) {
        // Update the status locally
        final idx = _requests.indexWhere((r) => r['id'] == requestId);
        if (idx != -1) {
          setState(() {
            _requests[idx] = {
              ..._requests[idx],
              'status': approve ? 'APPROVED' : 'DENIED',
            };
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? lang.getText('Request approved!', 'கோரிக்கை அனுமதிக்கப்பட்டது!')
                : lang.getText('Request denied.', 'கோரிக்கை மறுக்கப்பட்டது.')),
            backgroundColor: approve ? Colors.green[700] : Colors.red[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.getText('Action failed. Please try again.', 'செயல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green[700]!;
      case 'DENIED':
        return Colors.red[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  String _statusLabel(String? status, LanguageProvider lang) {
    switch (status) {
      case 'APPROVED':
        return lang.getText('Approved', 'அனுமதிக்கப்பட்டது');
      case 'DENIED':
        return lang.getText('Denied', 'மறுக்கப்பட்டது');
      default:
        return lang.getText('Pending', 'நிலுவையில்');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          lang.getText('Contact Requests', 'தொடர்பு கோரிக்கைகள்'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: lang.getText('Refresh', 'புதுப்பி'),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _buildBody(lang),
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRequests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(lang.getText('Retry', 'மீண்டும் முயற்சி')),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[350]),
              const SizedBox(height: 16),
              Text(
                lang.getText('No contact requests yet.', 'இன்னும் தொடர்பு கோரிக்கைகள் இல்லை.'),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, index) => _buildRequestCard(_requests[index], lang),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, LanguageProvider lang) {
    final requestId = request['id'];
    final status = request['status']?.toString();
    final isPending = status == 'PENDING';
    final isProcessing = _processingIds.contains(requestId);

    final requesterName = request['requesterName']?.toString() ?? lang.getText('Unknown', 'தெரியாது');
    final requesterPhone = request['requesterPhone']?.toString() ?? '';
    final postTitle = request['postTitle']?.toString() ?? '';
    final createdAt = request['createdAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester info + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primaryColor.withOpacity(0.15),
                  child: Text(
                    requesterName.isNotEmpty ? requesterName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(requesterName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (requesterPhone.isNotEmpty)
                        Text(requesterPhone,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status, lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Post title
            if (postTitle.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      postTitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 6),

            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            // Action buttons (only for PENDING)
            if (isPending) ...[
              const SizedBox(height: 12),
              isProcessing
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(
                              requestId: requestId,
                              approve: false,
                              lang: lang,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(lang.getText('Deny', 'மறுக்க'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAction(
                              requestId: requestId,
                              approve: true,
                              lang: lang,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(lang.getText('Approve', 'அனுமதி'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
