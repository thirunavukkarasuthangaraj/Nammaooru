import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';
import '../models/support_ticket_model.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SupportTicket? _ticket;
  List<TicketMessage> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() => _isLoading = true);

    try {
      final [ticket, messages] = await Future.wait([
        _supportService.getSupportTicketDetails(widget.ticketId),
        _supportService.getTicketMessages(widget.ticketId),
      ]);

      setState(() {
        _ticket = ticket;
        _messages = messages as List<TicketMessage>;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _loadDemoTicket();
    }
  }

  void _loadDemoTicket() {
    setState(() {
      _ticket = SupportTicket(
        id: widget.ticketId,
        userId: 'user1',
        userType: 'customer',
        title: 'Order not delivered',
        description: 'My order #ORD123 was supposed to be delivered yesterday but I haven\'t received it yet.',
        category: SupportCategory.orderIssue,
        priority: SupportPriority.high,
        status: SupportStatus.inProgress,
        messages: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      );

      _messages = [
        TicketMessage(
          id: '1',
          ticketId: widget.ticketId,
          senderId: 'user1',
          senderName: 'You',
          message: 'My order #ORD123 was supposed to be delivered yesterday but I haven\'t received it yet.',
          isFromUser: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          attachments: [],
        ),
        TicketMessage(
          id: '2',
          ticketId: widget.ticketId,
          senderId: 'agent1',
          senderName: 'Support Agent',
          message: 'Hi! I understand your concern about the delayed delivery. Let me check the status of your order #ORD123 right away.',
          isFromUser: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
          attachments: [],
        ),
        TicketMessage(
          id: '3',
          ticketId: widget.ticketId,
          senderId: 'agent1',
          senderName: 'Support Agent',
          message: 'I\'ve checked with our delivery partner and your order is currently on the way. You should receive it within the next 2-3 hours. We apologize for the delay.',
          isFromUser: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          attachments: [],
        ),
      ];
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);

    try {
      final newMessage = TicketMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ticketId: widget.ticketId,
        senderId: 'user1',
        senderName: 'You',
        message: messageText,
        isFromUser: true,
        timestamp: DateTime.now(),
        attachments: [],
      );

      setState(() {
        _messages.add(newMessage);
      });

      _messageController.clear();
      _scrollToBottom();

      await _supportService.sendTicketMessage(widget.ticketId, messageText);

      // Simulate agent response
      await Future.delayed(const Duration(seconds: 3));
      _addAgentResponse(messageText);
    } catch (e) {
      _addAgentResponse(messageText);
    } finally {
      setState(() => _isSendingMessage = false);
    }
  }

  void _addAgentResponse(String userMessage) {
    final response = _generateAgentResponse(userMessage);

    final agentMessage = TicketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ticketId: widget.ticketId,
      senderId: 'agent1',
      senderName: 'Support Agent',
      message: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      attachments: [],
    );

    setState(() {
      _messages.add(agentMessage);
    });

    _scrollToBottom();
  }

  String _generateAgentResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('thank')) {
      return 'You\'re welcome! Is there anything else I can help you with regarding this ticket?';
    } else if (lowerMessage.contains('when') || lowerMessage.contains('time')) {
      return 'Based on the latest update, your order should arrive within the next 1-2 hours. I\'ll keep monitoring the delivery status.';
    } else if (lowerMessage.contains('cancel')) {
      return 'I understand you\'d like to cancel. However, since your order is already out for delivery, cancellation may not be possible. Would you like me to check the exact status?';
    } else {
      return 'Thank you for the additional information. I\'ve noted this in your ticket and will ensure our team addresses your concern promptly.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Ticket',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_ticket != null)
              Text(
                'ID: ${_ticket!.id}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_ticket != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(_ticket!.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _ticket!.status.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_ticket != null) _buildTicketHeader(),
                Expanded(child: _buildMessagesSection()),
                if (_ticket?.status != SupportStatus.closed) _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: VillageTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_ticket!.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(_ticket!.priority),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _ticket!.priority.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(_ticket!.priority),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  _getCategoryIcon(_ticket!.category),
                  size: 16,
                  color: VillageTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _ticket!.category.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VillageTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _ticket!.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VillageTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ticket!.description,
              style: const TextStyle(
                color: VillageTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: VillageTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(_ticket!.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: VillageTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: VillageTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(TicketMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: VillageTheme.primaryGreen,
              child: const Icon(
                Icons.support_agent,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? VillageTheme.primaryGreen
                    : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: message.isFromUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: message.isFromUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  if (!message.isFromUser) const SizedBox(height: 4),

                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isFromUser
                          ? Colors.white
                          : VillageTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isFromUser
                          ? Colors.white70
                          : VillageTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: VillageTheme.accentOrange,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: VillageTheme.primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: VillageTheme.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: VillageTheme.primaryGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _isSendingMessage ? null : _sendMessage,
              icon: _isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final List<String> attachments;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    required this.attachments,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      isFromUser: json['isFromUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments,
    };
  }
}