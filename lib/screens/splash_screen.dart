import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/region.dart';
import 'pharmacy/pharmacy_home.dart';
import 'company/company_home.dart';
import 'shared/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _selectedRegionId;
  final List<Region> _regions = Region.allRegions;

  Future<void> _proceedAsGuest() async {
    if (_selectedRegionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المحافظة للتصفح'), backgroundColor: Colors.orange),
      );
      return;
    }
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.enterAsGuest(_selectedRegionId!);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: _selectedRegionId!, isGuest: true)),
    );
  }

  Future<void> _checkLoggedInUser() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.isLoggedIn) {
      if (auth.currentUserType == 'company') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompanyHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: auth.currentRegionId ?? 'sanaa', isGuest: false)));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isLoggedIn) {
        _checkLoggedInUser();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (auth.isLoggedIn) {
      return Container();
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'سوق الأدوية بالجملة',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text('تصفح كزائر أو قم بتسجيل الدخول', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegionId,
                      hint: const Text('اختر المحافظة للتصفح'),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      iconSize: 30,
                      items: _regions.map((region) {
                        return DropdownMenuItem(value: region.id, child: Text(region.name));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedRegionId = value),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _proceedAsGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('تصفح كزائر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                  },
                  child: const Text('لديك حساب؟ تسجيل الدخول', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}