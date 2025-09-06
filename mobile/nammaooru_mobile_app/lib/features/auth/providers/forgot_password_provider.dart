import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

enum ForgotPasswordStep { email, otp, password }

class ForgotPasswordProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;
  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';

  ForgotPasswordProvider(this._apiService);

  ForgotPasswordStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _nextStep() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        _currentStep = ForgotPasswordStep.otp;
        break;
      case ForgotPasswordStep.otp:
        _currentStep = ForgotPasswordStep.password;
        break;
      case ForgotPasswordStep.password:
        break;
    }
    notifyListeners();
  }

  void goBack() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        break;
      case ForgotPasswordStep.otp:
        _currentStep = ForgotPasswordStep.email;
        break;
      case ForgotPasswordStep.password:
        _currentStep = ForgotPasswordStep.otp;
        break;
    }
    _setError(null);
    notifyListeners();
  }

  Future<bool> sendOtp(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.sendPasswordResetOtp(email);
      
      if (response['statusCode'] == '0000') {
        _email = email;
        _nextStep();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.verifyPasswordResetOtp(_email, otp);
      
      if (response['statusCode'] == '0000') {
        _nextStep();
        return true;
      } else {
        _setError(response['message'] ?? 'Invalid or expired OTP');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String otp, String newPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.resetPasswordWithOtp(_email, otp, newPassword);
      
      if (response['statusCode'] == '0000') {
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to reset password');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendOtp() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.resendPasswordResetOtp(_email);
      
      if (response['statusCode'] == '0000') {
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to resend OTP');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void reset() {
    _currentStep = ForgotPasswordStep.email;
    _isLoading = false;
    _errorMessage = null;
    _email = '';
    notifyListeners();
  }
}