import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'counter/counter_home_screen.dart';
import 'doctor/doctor_home_screen.dart';
import 'pharmacy/pharmacy_home_screen.dart';
import 'test/test_home_screen.dart';
import '../theme/app_theme.dart';

class StaffAuthorisationScreen extends StatefulWidget {
  final String role;
  final String fullName;
  final int staffId;

  const StaffAuthorisationScreen({
    super.key,
    required this.role,
    required this.fullName,
    required this.staffId,
  });

  @override
  State<StaffAuthorisationScreen> createState() =>
      _StaffAuthorisationScreenState();
}

class _StaffAuthorisationScreenState extends State<StaffAuthorisationScreen> {
  final _hospitalController = TextEditingController();
  final _staffIdController = TextEditingController();
  bool _isLoading = false;
  String staffCode = "";

  @override
  void initState() {
    super.initState();
    _loadStaffCode();
  }

  Future<void> _loadStaffCode() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/admin/staff/${widget.staffId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          staffCode = data['staff']['digiswasth_staff_id'] ?? "";
          _staffIdController.text = staffCode;
        });
      }
    } catch (_) {}
  }

  Future<void> _authorise() async {
    if (_hospitalController.text.isEmpty || _staffIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/counter/authorise-staff'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "digiswasth_staff_id": _staffIdController.text.trim(),
          "hospital_name": _hospitalController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final staff = data['staff'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('staff_id', staff['digiswasth_staff_id']);
        await prefs.setString('staff_full_name', staff['full_name']);
        await prefs.setInt('staff_hospital_id', staff['hospital_id']);
        await prefs.setString('staff_hospital_name', staff['hospital_name']);
        await prefs.setString('staff_role', staff['role']);

        if (!mounted) return;

        if (staff['role'] == 'counter') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => CounterHomeScreen(
                fullName: staff['full_name'],
                hospitalId: staff['hospital_id'],
              ),
            ),
            (route) => false,
          );
        } else if (staff['role'] == 'doctor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorHomeScreen(
                fullName: staff['full_name'],
                doctorId: staff['staff_id'],
              ),
            ),
            (route) => false,
          );
        } else if (staff['role'] == 'pharmacy') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyHomeScreen(
                fullName: staff['full_name'],
                hospitalId: staff['hospital_id'],
                staffId: staff['staff_id'],
              ),
            ),
            (route) => false,
          );
        } else if (staff['role'] == 'test') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TestHomeScreen(
                fullName: staff['full_name'],
                hospitalId: staff['hospital_id'],
                staffId: staff['staff_id'],
              ),
            ),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Authorisation failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Authorisation"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              "Welcome, ${widget.fullName}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              staffCode.isEmpty ? "Loading Staff ID..." : staffCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please authorise yourself to continue",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: "Hospital Name",
                border: OutlineInputBorder(),
                hintText: "e.g. Apollo Hospital",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _staffIdController,
              decoration: const InputDecoration(
                labelText: "DigiSwasth Staff ID",
                border: OutlineInputBorder(),
                hintText: "DSS-2026-XXXXXX",
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authorise,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Authorise", style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}