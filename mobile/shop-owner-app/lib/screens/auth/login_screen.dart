import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/main_navigation.dart';
import '../../services/api_service_simple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // Extract token - backend returns 'accessToken' field
        final token = data['data']?['accessToken'] ?? data['data']?['token'] ?? data['accessToken'] ?? data['token'] ?? '';
        final username = data['data']?['username'] ?? data['username'] ?? 'Shop Owner';

        print('Token from response: $token');
        print('Token type: ${token.runtimeType}');
        print('Login successful, navigating to dashboard...');
        print('Token to save: $token');
        print('Token length: ${token.length}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', response.data.toString());

        print('Token saved to storage: ${await prefs.getString('auth_token')}');

        if (!mounted) return;

        print('Navigating to MainNavigation with token: $token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userName: username,
              token: token,
            ),
          ),
        );
      } else {
        _showError(response.error ?? 'Login failed');
      }
    } catch (e) {
      _showError('Network error: Please check your connection');
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 24),
                  const Text('NammaOoru Shop Owner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Manage your shop efficiently', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Demo Credentials'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username: shopowner'),
                              Text('Password: password123'),
                              SizedBox(height: 8),
                              Text('Note: Make sure backend is running on port 8080'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _usernameController.text = 'shopowner';
                                _passwordController.text = 'password123';
                              },
                              child: const Text('Use Demo'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('View Demo Credentials'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}