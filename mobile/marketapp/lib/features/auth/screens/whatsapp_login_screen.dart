import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/whatsapp_otp_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../home/screens/home_screen.dart';

class WhatsAppLoginScreen extends StatefulWidget {
  const WhatsAppLoginScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppLoginScreen> createState() => _WhatsAppLoginScreenState();
}

class _WhatsAppLoginScreenState extends State<WhatsAppLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _useWhatsApp = true;
  int _resendTimer = 0;
  Timer? _timer;
  String? _testOTP; // For development testing
  
  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await WhatsAppOTPService.sendOTP(
      mobileNumber: _mobileController.text.trim(),
      channel: _useWhatsApp ? 'whatsapp' : 'sms',
      purpose: 'login',
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      setState(() {
        _otpSent = true;
        _testOTP = result['data']?['testOTP']; // For testing
      });
      _startResendTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show test OTP in development
      if (_testOTP != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test OTP: $_testOTP'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await WhatsAppOTPService.verifyOTP(
      mobileNumber: _mobileController.text.trim(),
      otp: _otpController.text.trim(),
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login successful'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['attemptsLeft'] != null
                ? '${result['message']} (${result['attemptsLeft']} attempts left)'
                : result['message'] ?? 'Invalid OTP',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await WhatsAppOTPService.resendOTP(
      mobileNumber: _mobileController.text.trim(),
      channel: _useWhatsApp ? 'whatsapp' : 'sms',
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      _startResendTimer();
      setState(() {
        _testOTP = result['data']?['testOTP']; // For testing
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show test OTP in development
      if (_testOTP != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test OTP: $_testOTP'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to resend OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Header
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _useWhatsApp ? Icons.chat : Icons.message,
                        size: 80,
                        color: _useWhatsApp ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to NammaOoru',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent 
                            ? 'Enter the OTP sent to your ${_useWhatsApp ? "WhatsApp" : "SMS"}'
                            : 'Login with ${_useWhatsApp ? "WhatsApp" : "SMS"} OTP',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Mobile Number Input
                if (!_otpSent) ...[
                  CustomTextField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    hint: 'Enter 10-digit mobile number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      if (value.length != 10) {
                        return 'Please enter valid 10-digit number';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                        return 'Please enter valid Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Channel Selection
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('WhatsApp'),
                          value: true,
                          groupValue: _useWhatsApp,
                          onChanged: (value) {
                            setState(() {
                              _useWhatsApp = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('SMS'),
                          value: false,
                          groupValue: _useWhatsApp,
                          onChanged: (value) {
                            setState(() {
                              _useWhatsApp = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Send OTP Button
                  CustomButton(
                    text: 'Send OTP',
                    onPressed: _isLoading ? null : _sendOTP,
                    isLoading: _isLoading,
                    icon: Icons.send,
                  ),
                ],
                
                // OTP Input
                if (_otpSent) ...[
                  // Mobile Number Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          '+91 ${_mobileController.text}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _timer?.cancel();
                            });
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // OTP Input Field
                  CustomTextField(
                    controller: _otpController,
                    label: 'Enter OTP',
                    hint: 'Enter 6-digit OTP',
                    prefixIcon: Icons.lock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (value) {
                      if (value.length == 6) {
                        _verifyOTP();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Resend OTP
                  Center(
                    child: TextButton(
                      onPressed: _resendTimer > 0 ? null : _resendOTP,
                      child: Text(
                        _resendTimer > 0
                            ? 'Resend OTP in $_resendTimer seconds'
                            : 'Resend OTP',
                        style: TextStyle(
                          color: _resendTimer > 0 ? Colors.grey : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Verify Button
                  CustomButton(
                    text: 'Verify & Login',
                    onPressed: _isLoading ? null : _verifyOTP,
                    isLoading: _isLoading,
                    icon: Icons.check,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Terms and Conditions
                Center(
                  child: Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}