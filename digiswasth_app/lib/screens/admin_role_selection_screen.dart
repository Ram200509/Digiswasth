import 'package:flutter/material.dart';
import 'counter/counter_login_screen.dart';
import 'doctor/doctor_login_screen.dart';
import 'pharmacy/pharmacy_login_screen.dart';
import 'test/test_login_screen.dart';
import '../theme/app_theme.dart';

class AdminRoleSelectionScreen extends StatelessWidget {
  const AdminRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select Role",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildRoleButton(
              context,
              title: "Reception / Counter Login",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CounterLoginScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildRoleButton(
              context,
              title: "Doctor Login",
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorLoginScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildRoleButton(
              context,
              title: "Pharmacy Login",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PharmacyLoginScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildRoleButton(
              context,
              title: "Test Ward Login",
              color: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestLoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}