import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../company/company_home.dart';
import '../pharmacy/pharmacy_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.login(_emailController.text.trim(), _passwordController.text.trim());
      if (!mounted) return;
      if (authService.currentUserType == 'company') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompanyHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: authService.currentRegionId ?? 'صنعاء', isGuest: false)));
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل الدخول بنجاح'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 80, color: Colors.teal),
                SizedBox(height: 20),
                Text('سوق الأدوية بالجملة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'أدخل البريد الإلكتروني' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                ),
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
                      ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                  child: Text('ليس لديك حساب؟ إنشاء حساب جديد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}