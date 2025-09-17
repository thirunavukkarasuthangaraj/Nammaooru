import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAgentOnline = false;
  String _agentName = 'Support Agent';

  @override
  void initState() {
    super.initState();
    _loadChatMessages();
    _simulateAgentOnline();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _supportService.getChatMessages();
      setState(() {
        _messages = messages.map((msg) => ChatMessage.fromJson(msg)).toList();
        _isLoading = false;
      });

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      senderId: 'agent',
      senderName: _agentName,
      message: 'Hi! Welcome to NammaOoru Support. How can I help you today?',
      timestamp: DateTime.now(),
      isFromUser: false,
      messageType: MessageType.text,
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    _scrollToBottom();
  }

  void _simulateAgentOnline() {
    setState(() {
      _isAgentOnline = true;
      _agentName = 'Priya - Support Agent';
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'user',
      senderName: 'You',
      message: messageText,
      timestamp: DateTime.now(),
      isFromUser: true,
      messageType: MessageType.text,
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      await _supportService.sendChatMessage(messageText);

      // Simulate agent response
      await Future.delayed(const Duration(seconds: 2));
      _addAgentResponse(messageText);
    } catch (e) {
      _addAgentResponse(messageText);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _addAgentResponse(String userMessage) {
    String response = _generateAgentResponse(userMessage);

    final agentMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'agent',
      senderName: _agentName,
      message: response,
      timestamp: DateTime.now(),
      isFromUser: false,
      messageType: MessageType.text,
    );

    setState(() {
      _messages.add(agentMessage);
    });

    _scrollToBottom();
  }

  String _generateAgentResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('order') || lowerMessage.contains('delivery')) {
      return 'I can help you with your order. Could you please provide your order ID? You can find it in the "My Orders" section of the app.';
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('refund')) {
      return 'For payment-related queries, I can assist you. Could you please describe the specific issue you\'re facing with your payment?';
    } else if (lowerMessage.contains('account') || lowerMessage.contains('profile')) {
      return 'I can help with account-related issues. What specifically would you like help with regarding your account?';
    } else if (lowerMessage.contains('cancel')) {
      return 'To cancel your order, go to "My Orders" and select the order you want to cancel. If the order has already been picked up, cancellation may not be possible.';
    } else if (lowerMessage.contains('track')) {
      return 'You can track your order in real-time through the "My Orders" section. The app will show your delivery partner\'s location and estimated arrival time.';
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      return 'Hello! I\'m here to help you with any questions or issues you may have. What can I assist you with today?';
    } else if (lowerMessage.contains('thank')) {
      return 'You\'re welcome! Is there anything else I can help you with today?';
    } else {
      return 'I understand your concern. Let me look into this for you. Could you provide more details so I can assist you better?';
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
              'Live Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_isAgentOnline)
              Text(
                '$_agentName • Online',
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
          if (_isAgentOnline)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(
                Icons.circle,
                color: Colors.green,
                size: 12,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat Status Bar
          _buildChatStatusBar(),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: VillageTheme.primaryGreen.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            _isAgentOnline ? Icons.support_agent : Icons.schedule,
            size: 16,
            color: _isAgentOnline ? VillageTheme.successGreen : VillageTheme.warningOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isAgentOnline
                  ? 'Our support team is online and ready to help'
                  : 'Average response time: 5-10 minutes',
              style: TextStyle(
                fontSize: 12,
                color: VillageTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Start a conversation with our support team',
          style: TextStyle(
            color: VillageTheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isFromUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isFromUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
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
                  if (!message.isFromUser && _agentName.isNotEmpty)
                    Text(
                      _agentName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  if (!message.isFromUser && _agentName.isNotEmpty)
                    const SizedBox(height: 4),

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

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: VillageTheme.primaryGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(3),
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
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromUser;
  final MessageType messageType;
  final List<String>? attachments;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
    required this.messageType,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isFromUser: json['isFromUser'] ?? false,
      messageType: MessageType.fromString(json['messageType'] ?? 'text'),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isFromUser': isFromUser,
      'messageType': messageType.value,
      'attachments': attachments,
    };
  }
}

enum MessageType {
  text,
  image,
  file;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }
}