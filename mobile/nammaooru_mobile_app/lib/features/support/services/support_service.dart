import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/support_ticket_model.dart';
import '../models/faq_model.dart';

class SupportService {
  static const String _baseUrl = 'http://192.168.1.6:8090/api';

  // FAQ Services
  Future<List<FAQ>> getFAQs({String? category}) async {
    try {
      final response = await ApiClient.get(
        '/support/faqs',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((faq) => FAQ.fromJson(faq))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      final response = await ApiClient.get('/support/faq-categories');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((category) => FAQCategory.fromJson(category))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching FAQ categories: $e');
      return [];
    }
  }

  Future<List<FAQ>> searchFAQs(String query) async {
    try {
      final response = await ApiClient.get(
        '/support/faqs/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((faq) => FAQ.fromJson(faq))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching FAQs: $e');
      return [];
    }
  }

  // Support Ticket Services
  Future<List<SupportTicket>> getSupportTickets() async {
    try {
      final userId = await LocalStorage.getUserId();
      final response = await ApiClient.get('/support/tickets/$userId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((ticket) => SupportTicket.fromJson(ticket))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching support tickets: $e');
      return [];
    }
  }

  Future<SupportTicket?> createSupportTicket({
    required String title,
    required String description,
    required SupportCategory category,
    required SupportPriority priority,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await LocalStorage.getUserId();
      final userType = await LocalStorage.getUserRole();

      final requestBody = {
        'userId': userId,
        'userType': userType,
        'title': title,
        'description': description,
        'category': category.value,
        'priority': priority.value,
        'metadata': metadata,
      };

      final response = await ApiClient.post(
        '/support/tickets',
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SupportTicket.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error creating support ticket: $e');
      return null;
    }
  }

  Future<SupportTicket?> getSupportTicket(String ticketId) async {
    try {
      final response = await ApiClient.get('/support/tickets/detail/$ticketId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SupportTicket.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching support ticket: $e');
      return null;
    }
  }

  Future<bool> addMessageToTicket(String ticketId, String message) async {
    try {
      final userId = await LocalStorage.getUserId();

      final requestBody = {
        'ticketId': ticketId,
        'senderId': userId,
        'senderType': 'user',
        'message': message,
        'attachments': [],
      };

      final response = await ApiClient.post(
        '/support/tickets/$ticketId/messages',
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding message to ticket: $e');
      return false;
    }
  }

  Future<bool> markTicketResolved(String ticketId) async {
    try {
      final response = await ApiClient.put(
        '/support/tickets/$ticketId/resolve',
        body: json.encode({'status': 'resolved'}),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking ticket as resolved: $e');
      return false;
    }
  }

  // Contact Methods
  Future<List<ContactMethod>> getContactMethods() async {
    try {
      final response = await ApiClient.get('/support/contact-methods');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((method) => ContactMethod.fromJson(method))
              .toList();
        }
      }

      // Return default contact methods if API fails
      return _getDefaultContactMethods();
    } catch (e) {
      print('Error fetching contact methods: $e');
      return _getDefaultContactMethods();
    }
  }

  List<ContactMethod> _getDefaultContactMethods() {
    return [
      ContactMethod(
        id: '1',
        name: 'Phone Support',
        type: 'phone',
        value: '+91-8000-123-456',
        description: 'Call us for immediate assistance',
        icon: 'phone',
        isAvailable: true,
        availableHours: '9:00 AM - 9:00 PM',
        responseTime: 5,
        order: 1,
      ),
      ContactMethod(
        id: '2',
        name: 'WhatsApp Support',
        type: 'whatsapp',
        value: '+91-8000-123-456',
        description: 'Message us on WhatsApp',
        icon: 'whatsapp',
        isAvailable: true,
        availableHours: '24/7',
        responseTime: 15,
        order: 2,
      ),
      ContactMethod(
        id: '3',
        name: 'Email Support',
        type: 'email',
        value: 'support@nammaooru.com',
        description: 'Send us an email',
        icon: 'email',
        isAvailable: true,
        availableHours: '24/7',
        responseTime: 60,
        order: 3,
      ),
      ContactMethod(
        id: '4',
        name: 'Live Chat',
        type: 'chat',
        value: 'chat',
        description: 'Chat with our support team',
        icon: 'chat',
        isAvailable: true,
        availableHours: '9:00 AM - 9:00 PM',
        responseTime: 10,
        order: 4,
      ),
    ];
  }

  // Support Ticket Detail Services
  Future<SupportTicket?> getSupportTicketDetails(String ticketId) async {
    return await getSupportTicket(ticketId);
  }

  Future<List<dynamic>> getTicketMessages(String ticketId) async {
    try {
      final response = await ApiClient.get('/support/tickets/$ticketId/messages');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching ticket messages: $e');
      return [];
    }
  }

  Future<bool> sendTicketMessage(String ticketId, String message) async {
    return await addMessageToTicket(ticketId, message);
  }

  // Feedback Services
  Future<Map<String, dynamic>?> submitFeedback({
    required dynamic type,
    required String title,
    required String message,
    required int rating,
    required bool allowContact,
  }) async {
    try {
      final userId = await LocalStorage.getUserId();

      final requestBody = {
        'userId': userId,
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'rating': rating,
        'allowContact': allowContact,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiClient.post(
        '/support/feedback',
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error submitting feedback: $e');
      return null;
    }
  }

  Future<bool> submitLegacyFeedback({
    required String feedback,
    required int rating,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await LocalStorage.getUserId();

      final requestBody = {
        'userId': userId,
        'feedback': feedback,
        'rating': rating,
        'category': category ?? 'general',
        'metadata': metadata,
      };

      final response = await ApiClient.post(
        '/support/feedback',
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Chat Services
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    try {
      final userId = await LocalStorage.getUserId();
      final response = await ApiClient.get('/support/chat/$userId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching chat messages: $e');
      return [];
    }
  }

  Future<bool> sendChatMessage(String message) async {
    try {
      final userId = await LocalStorage.getUserId();

      final requestBody = {
        'userId': userId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiClient.post(
        '/support/chat',
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error sending chat message: $e');
      return false;
    }
  }
}