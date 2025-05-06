import 'package:dio/dio.dart';
import 'package:elastik/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../user/home_screen.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  final ApiService apiService = ApiService();

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await storage.read(key: 'token');
    final role = await storage.read(key: 'role');

    // Optionally validate token expiry (JWT decode logic can be added here)

    if (token != null && role != null) {
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Construct the full email with the domain suffix
      final String fullEmail = '${emailController.text.trim()}@elastikteams.com';

      final response = await apiService.login(
        fullEmail,
        passwordController.text.trim(),
      );

      final token = response.data['token'];
      final role = response.data['role'];
      final redirectUrl = response.data['redirectUrl'];

      if (token != null && role != null && redirectUrl != null) {
        await storage.write(key: 'token', value: token);
        await storage.write(key: 'role', value: role);

        if (redirectUrl == '/admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() => errorMessage = 'Invalid response from server.');
      }
    } catch (e) {
      print('Full error details: $e');
      if (e is DioException) {
      print('Dio error details:');
      print('- Type: ${e.type}');
      print('- Message: ${e.message}');
      print('- Response: ${e.response}');
      print('- Error: ${e.error}');
    }
      setState(() => errorMessage = 'Login failed. Check credentials.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Welcome to Elastik!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              // Email field with suffix
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  suffixText: '@elastikteams.com',
                  suffixStyle: TextStyle(
                    color: Color.fromARGB(255, 92, 92, 92),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}