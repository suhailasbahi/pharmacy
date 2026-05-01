import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userType = auth.currentUserType;
    final name = userType == 'company' ? 'شركة الأدوية العربية' : (auth.currentPharmacyName ?? 'صيدلية تجريبية');
    final email = userType == 'company' ? 'company@example.com' : 'pharmacy@example.com';

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي'), centerTitle: true, backgroundColor: Colors.teal),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) =>  SplashScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}