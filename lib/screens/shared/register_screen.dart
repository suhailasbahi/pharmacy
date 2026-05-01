import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../company/company_home.dart';
import '../pharmacy/pharmacy_home.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  String _userType = 'pharmacy';
  String _selectedRegion = 'sanaa';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<Map<String, String>> regions = [
    {'id': 'sanaa', 'name': 'صنعاء'},
    {'id': 'aden', 'name': 'عدن'},
    {'id': 'taiz', 'name': 'تعز'},
    {'id': 'hodeidah', 'name': 'الحديدة'},
    {'id': 'ibb', 'name': 'إب'},
    {'id': 'mukalla', 'name': 'المكلا'},
    {'id': 'sayun', 'name': 'سيئون'},
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('كلمة المرور غير متطابقة'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _userType,
        licenseNumber: _licenseController.text.trim(),
        regionId: _selectedRegion,
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء الحساب بنجاح!'), backgroundColor: Colors.green));
      if (authService.currentUserType == 'company') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompanyHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: _selectedRegion, isGuest: false)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إنشاء حساب جديد'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'اسم المنشأة', prefixIcon: Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'أدخل اسم المنشأة' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'أدخل البريد الإلكتروني' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'أدخل رقم الهاتف' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(labelText: 'رقم الترخيص', prefixIcon: Icon(Icons.verified), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'أدخل رقم الترخيص' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'العنوان (اختياري)', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: regions.map((reg) => DropdownMenuItem(value: reg['id']!, child: Text(reg['name']!))).toList(),
                  onChanged: (value) => setState(() => _selectedRegion = value!),
                  validator: (value) => value == null ? 'اختر المحافظة' : null,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _userType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'pharmacy', child: Text('صيدلية (مشتري)')),
                        DropdownMenuItem(value: 'company', child: Text('شركة أدوية (بائع)')),
                      ],
                      onChanged: (value) => setState(() => _userType = value!),
                    ),
                  ),
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
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'أكد كلمة المرور' : null,
                ),
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('إنشاء حساب', style: TextStyle(fontSize: 18)),
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}