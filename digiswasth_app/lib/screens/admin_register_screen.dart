import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _hospital = TextEditingController();
  final _specialization = TextEditingController();

  String _role = 'counter';
  bool _loading = false;

  Future<void> _register() async {
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty ||
        _hospital.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/admin/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": _name.text.trim(),
          "email": _email.text.trim(),
          "phone": _phone.text.trim(),
          "password": _password.text.trim(),
          "role": _role,
          "hospital_name": _hospital.text.trim(),
          "specialization": _specialization.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Account Created"),
            content: Text(
              "Role: ${data['role']}\nStaff ID: ${data['digiswasth_staff_id']}\n\nSave this Staff ID. It is required during authorisation.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Admin Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hospital,
              decoration: const InputDecoration(
                labelText: "Hospital Name",
                hintText: "Apollo Hospital",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'counter', child: Text("Reception / Counter")),
                DropdownMenuItem(value: 'doctor', child: Text("Doctor")),
                DropdownMenuItem(value: 'pharmacy', child: Text("Pharmacy")),
                DropdownMenuItem(value: 'test', child: Text("Test Ward")),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'counter'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialization,
              decoration: const InputDecoration(
                labelText: "Specialization (Doctors only)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}