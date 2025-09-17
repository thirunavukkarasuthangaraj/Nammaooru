import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/services/api_service.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDocumentVerificationSummary(String partnerId) async {
    try {
      final response = await _apiService.get('/delivery-partners/$partnerId/profile/documents/verification-summary');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get document verification summary: $e');
    }
  }

  Future<Map<String, dynamic>> getSettings(String partnerId) async {
    try {
      final response = await _apiService.get('/delivery-partners/$partnerId/profile/settings');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  Future<List<dynamic>> getPartnerDocuments(String partnerId) async {
    try {
      final response = await _apiService.get('/delivery-partners/$partnerId/profile/documents');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get partner documents: $e');
    }
  }

  Future<List<dynamic>> getLatestDocuments(String partnerId) async {
    try {
      final response = await _apiService.get('/delivery-partners/$partnerId/profile/documents/latest');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get latest documents: $e');
    }
  }

  Future<List<dynamic>> getDocumentsRequiringAction(String partnerId) async {
    try {
      final response = await _apiService.get('/delivery-partners/$partnerId/profile/documents/requiring-action');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get documents requiring action: $e');
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String partnerId,
    required String documentType,
    required File file,
    String? documentNumber,
    DateTime? expiryDate,
    String? uploadedBy,
  }) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/delivery-partners/$partnerId/profile/documents');

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add file
      final fileExtension = file.path.split('.').last.toLowerCase();
      MediaType? mediaType;

      switch (fileExtension) {
        case 'pdf':
          mediaType = MediaType('application', 'pdf');
          break;
        case 'jpg':
        case 'jpeg':
          mediaType = MediaType('image', 'jpeg');
          break;
        case 'png':
          mediaType = MediaType('image', 'png');
          break;
        default:
          mediaType = MediaType('application', 'octet-stream');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mediaType,
        ),
      );

      // Add form fields
      request.fields['documentType'] = documentType;

      if (documentNumber != null) {
        request.fields['documentNumber'] = documentNumber;
      }

      if (expiryDate != null) {
        request.fields['expiryDate'] = expiryDate.toIso8601String();
      }

      if (uploadedBy != null) {
        request.fields['uploadedBy'] = uploadedBy;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    required String partnerId,
    required bool pushEnabled,
    required bool emailEnabled,
    required bool smsEnabled,
    required bool orderEnabled,
    required bool earningsEnabled,
    required bool promotionalEnabled,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'orderEnabled': orderEnabled,
        'earningsEnabled': earningsEnabled,
        'promotionalEnabled': promotionalEnabled,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/notifications',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  Future<Map<String, dynamic>> updateWorkSchedule({
    required String partnerId,
    required bool scheduleEnabled,
    String? startTime,
    String? endTime,
    String? workDays,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'scheduleEnabled': scheduleEnabled,
        'startTime': startTime,
        'endTime': endTime,
        'workDays': workDays,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/work-schedule',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update work schedule: $e');
    }
  }

  Future<Map<String, dynamic>> updateAutoAcceptOrders({
    required String partnerId,
    required bool autoAccept,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'autoAccept': autoAccept,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/auto-accept',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update auto-accept orders: $e');
    }
  }

  Future<Map<String, dynamic>> updateLocationSettings({
    required String partnerId,
    required bool locationSharingEnabled,
    required int trackingFrequencySeconds,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'locationSharingEnabled': locationSharingEnabled,
        'trackingFrequencySeconds': trackingFrequencySeconds,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/location',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update location settings: $e');
    }
  }

  Future<Map<String, dynamic>> updateAppPreferences({
    required String partnerId,
    required String language,
    required String theme,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'language': language,
        'theme': theme,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/app-preferences',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update app preferences: $e');
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required String partnerId,
    required String contactName,
    required String contactPhone,
    required String contactRelation,
    String? updatedBy,
  }) async {
    try {
      final data = {
        'contactName': contactName,
        'contactPhone': contactPhone,
        'contactRelation': contactRelation,
        'updatedBy': updatedBy ?? 'mobile_app',
      };

      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/emergency-contact',
        data: data,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  Future<Map<String, dynamic>> markTutorialCompleted({
    required String partnerId,
    String? updatedBy,
  }) async {
    try {
      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/tutorial-completed',
        queryParameters: {
          'updatedBy': updatedBy ?? 'mobile_app',
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to mark tutorial completed: $e');
    }
  }

  Future<Map<String, dynamic>> resetSettings({
    required String partnerId,
    String? updatedBy,
  }) async {
    try {
      final response = await _apiService.put(
        '/delivery-partners/$partnerId/profile/settings/reset',
        queryParameters: {
          'updatedBy': updatedBy ?? 'mobile_app',
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  Future<Map<String, dynamic>> deleteDocument({
    required String partnerId,
    required int documentId,
    String? deletedBy,
  }) async {
    try {
      final response = await _apiService.delete(
        '/delivery-partners/$partnerId/profile/documents/$documentId',
        queryParameters: {
          'deletedBy': deletedBy ?? 'mobile_app',
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Helper methods for document types
  List<String> getSupportedDocumentTypes() {
    return [
      'DRIVING_LICENSE',
      'VEHICLE_REGISTRATION',
      'VEHICLE_INSURANCE',
      'AADHAR_CARD',
      'PAN_CARD',
      'BANK_ACCOUNT_PROOF',
      'PHOTO',
      'VEHICLE_PHOTO',
      'POLICE_VERIFICATION',
      'ADDRESS_PROOF',
    ];
  }

  List<String> getRequiredDocumentTypes() {
    return [
      'DRIVING_LICENSE',
      'VEHICLE_REGISTRATION',
      'VEHICLE_INSURANCE',
      'AADHAR_CARD',
      'PHOTO',
    ];
  }

  String getDocumentTypeDisplayName(String documentType) {
    switch (documentType) {
      case 'DRIVING_LICENSE':
        return 'Driving License';
      case 'VEHICLE_REGISTRATION':
        return 'Vehicle Registration';
      case 'VEHICLE_INSURANCE':
        return 'Vehicle Insurance';
      case 'AADHAR_CARD':
        return 'Aadhar Card';
      case 'PAN_CARD':
        return 'PAN Card';
      case 'BANK_ACCOUNT_PROOF':
        return 'Bank Account Proof';
      case 'PHOTO':
        return 'Profile Photo';
      case 'VEHICLE_PHOTO':
        return 'Vehicle Photo';
      case 'POLICE_VERIFICATION':
        return 'Police Verification';
      case 'ADDRESS_PROOF':
        return 'Address Proof';
      default:
        return documentType.replaceAll('_', ' ').toLowerCase();
    }
  }

  List<String> getSupportedLanguages() {
    return [
      'ENGLISH',
      'HINDI',
      'TAMIL',
      'TELUGU',
      'KANNADA',
      'MALAYALAM',
      'BENGALI',
      'GUJARATI',
      'MARATHI',
      'PUNJABI',
    ];
  }

  List<String> getSupportedThemes() {
    return [
      'LIGHT',
      'DARK',
      'AUTO',
    ];
  }

  String getLanguageDisplayName(String language) {
    switch (language) {
      case 'ENGLISH':
        return 'English';
      case 'HINDI':
        return 'हिंदी';
      case 'TAMIL':
        return 'தமிழ்';
      case 'TELUGU':
        return 'తెలుగు';
      case 'KANNADA':
        return 'ಕನ್ನಡ';
      case 'MALAYALAM':
        return 'മലയാളം';
      case 'BENGALI':
        return 'বাংলা';
      case 'GUJARATI':
        return 'ગુજરાતી';
      case 'MARATHI':
        return 'मराठी';
      case 'PUNJABI':
        return 'ਪੰਜਾਬੀ';
      default:
        return language;
    }
  }

  String getThemeDisplayName(String theme) {
    switch (theme) {
      case 'LIGHT':
        return 'Light';
      case 'DARK':
        return 'Dark';
      case 'AUTO':
        return 'Auto (System)';
      default:
        return theme;
    }
  }
}