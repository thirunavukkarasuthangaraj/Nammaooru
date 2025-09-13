import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool showOtpField = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.delivery_dining,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              
              // Title
              Text(
                'NammaOoru Delivery',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                'Partner Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              
              // Phone Number Field
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 20),
              
              // OTP Field (show after sending OTP)
              if (showOtpField) ...[
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.security),
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Send OTP / Verify Button
              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleButtonPress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          showOtpField ? 'VERIFY OTP' : 'SEND OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              // Resend OTP (if OTP field is shown)
              if (showOtpField) ...[
                SizedBox(height: 15),
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleButtonPress() {
    if (!showOtpField) {
      _sendOtp();
    } else {
      _verifyOtp();
    }
  }

  void _sendOtp() {
    if (phoneController.text.length != 10) {
      _showError('Please enter valid mobile number');
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Mock API call
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
        showOtpField = true;
      });
      _showSuccess('OTP sent to +91 ${phoneController.text}');
    });
  }

  void _verifyOtp() {
    if (otpController.text.length != 6) {
      _showError('Please enter valid OTP');
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Mock verification
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
      
      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  void _resendOtp() {
    _sendOtp();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}