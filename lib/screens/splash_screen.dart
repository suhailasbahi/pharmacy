import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'pharmacy/pharmacy_home.dart';
import 'company/company_home.dart';
import 'shared/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _selectedCityForGuest;
  final List<String> _cities = [
    'صنعاء', 'عدن', 'تعز', 'الحديدة', 'إب', 'المكلا', 'سيئون',
    'البيضاء', 'عمران', 'ذمار', 'حضرموت', 'المهرة', 'شبوة',
    'لحج', 'أبين', 'الجوف', 'مأرب', 'صعدة', 'ريمة', 'حجة',
  ];

  Future<void> _proceedAsGuest() async {
    if (_selectedCityForGuest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المحافظة للتصفح'), backgroundColor: Colors.orange),
      );
      return;
    }
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.enterAsGuest(_selectedCityForGuest!);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: _selectedCityForGuest!, isGuest: true)),
    );
  }

  Future<void> _checkLoggedInUser() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.isLoggedIn) {
      if (auth.currentUserType == 'company') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompanyHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: auth.currentRegionId ?? 'صنعاء', isGuest: false)));
      }
    } else {
      // Show login screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    // After a short delay, check auth status or show guest selection
    Future.delayed(Duration(seconds: 1), () {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isLoggedIn) {
        _checkLoggedInUser();
      } else {
        // Show guest selection UI
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (auth.isLoggedIn) {
      return Container(); // will be replaced in initState
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
                Icon(Icons.medical_services, size: 100, color: Colors.white),
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
                      value: _selectedCityForGuest,
                      hint: const Text('اختر المحافظة للتصفح'),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      iconSize: 30,
                      items: _cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCityForGuest = value),
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