import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';
import '../models/support_ticket_model.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final SupportService _supportService = SupportService();
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final tickets = await _supportService.getSupportTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show demo tickets for UI testing
      _tickets = _getDemoTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Support Tickets',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTicketScreen(),
                ),
              );
              if (result == true) {
                _loadTickets();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? _buildEmptyState()
                  : _buildTicketsList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTicketScreen(),
            ),
          );
          if (result == true) {
            _loadTickets();
          }
        },
        backgroundColor: VillageTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t created any support tickets yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTicketScreen(),
                  ),
                );
                if (result == true) {
                  _loadTickets();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Support Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: VillageTheme.cardDecoration,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(ticket.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(ticket.priority),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.priority.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(ticket.priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ticket Title
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: VillageTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Category
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(ticket.category),
                    size: 16,
                    color: VillageTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.category.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: VillageTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description Preview
              Text(
                ticket.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: VillageTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: VillageTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: VillageTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (ticket.messages.isNotEmpty) ...[
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: VillageTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.messages.length} messages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: VillageTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: VillageTheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SupportStatus status) {
    switch (status) {
      case SupportStatus.open:
        return VillageTheme.warningOrange;
      case SupportStatus.inProgress:
        return VillageTheme.infoBlue;
      case SupportStatus.waitingForUser:
        return VillageTheme.accentOrange;
      case SupportStatus.resolved:
        return VillageTheme.successGreen;
      case SupportStatus.closed:
        return VillageTheme.textSecondary;
    }
  }

  Color _getPriorityColor(SupportPriority priority) {
    switch (priority) {
      case SupportPriority.low:
        return Colors.green;
      case SupportPriority.medium:
        return Colors.orange;
      case SupportPriority.high:
        return Colors.red;
      case SupportPriority.urgent:
        return Colors.deepOrange;
    }
  }

  IconData _getCategoryIcon(SupportCategory category) {
    switch (category) {
      case SupportCategory.general:
        return Icons.help_outline;
      case SupportCategory.orderIssue:
        return Icons.shopping_bag;
      case SupportCategory.paymentIssue:
        return Icons.payment;
      case SupportCategory.deliveryIssue:
        return Icons.delivery_dining;
      case SupportCategory.accountIssue:
        return Icons.account_circle;
      case SupportCategory.technicalIssue:
        return Icons.bug_report;
      case SupportCategory.feedback:
        return Icons.feedback;
      case SupportCategory.featureRequest:
        return Icons.lightbulb_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  List<SupportTicket> _getDemoTickets() {
    return [
      SupportTicket(
        id: '1',
        userId: 'user1',
        userType: 'customer',
        title: 'Order not delivered',
        description: 'My order #ORD123 was supposed to be delivered yesterday but I haven\'t received it yet.',
        category: SupportCategory.orderIssue,
        priority: SupportPriority.high,
        status: SupportStatus.inProgress,
        messages: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SupportTicket(
        id: '2',
        userId: 'user1',
        userType: 'customer',
        title: 'Payment refund pending',
        description: 'I cancelled my order but the refund hasn\'t been processed yet. It\'s been 3 days.',
        category: SupportCategory.paymentIssue,
        priority: SupportPriority.medium,
        status: SupportStatus.waitingForUser,
        messages: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SupportTicket(
        id: '3',
        userId: 'user1',
        userType: 'customer',
        title: 'App crashes on login',
        description: 'The app keeps crashing whenever I try to log in with my phone number.',
        category: SupportCategory.technicalIssue,
        priority: SupportPriority.urgent,
        status: SupportStatus.resolved,
        messages: [],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}