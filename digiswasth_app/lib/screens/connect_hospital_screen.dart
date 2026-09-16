import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ConnectHospitalScreen extends StatefulWidget {
  const ConnectHospitalScreen({super.key});

  @override
  State<ConnectHospitalScreen> createState() => _ConnectHospitalScreenState();
}

class _ConnectHospitalScreenState extends State<ConnectHospitalScreen> {
  final _hospitalController = TextEditingController();
  final _digiswasthIdController = TextEditingController();
  bool _isLoading = false;

Future<void> _requestOTP() async {
  if (_hospitalController.text.isEmpty || _digiswasthIdController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Call real backend API
    final response = await ApiService.requestHospitalOTP(
      digiswasthId: _digiswasthIdController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
    );

    if (response['success'] == true) {
      // Valid DigiSwasth ID → Go to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            hospitalName: _hospitalController.text.trim(),
            digiswasthId: _digiswasthIdController.text.trim(),
          ),
        ),
      );
    } else {
      // Invalid DigiSwasth ID → Show error, do NOT go to OTP screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Invalid DigiSwasth ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Hospital'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Hospital Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: 'Hospital Name',
                border: OutlineInputBorder(),
                hintText: 'e.g. Apollo Hospital',
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _digiswasthIdController,
              decoration: const InputDecoration(
                labelText: 'DigiSwasth ID',
                border: OutlineInputBorder(),
                hintText: 'DS-2026-XXXXXX',
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestOTP,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Request OTP', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Note: Hospital counter staff will also verify your DigiSwasth ID.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}