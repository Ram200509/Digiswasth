import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String hospitalName;
  final String digiswasthId;

  const OtpVerificationScreen({
    super.key,
    required this.hospitalName,
    required this.digiswasthId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOTP() async {
  if (_otpController.text.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Dummy OTP acceptance (any 6 digits work for now)
    await Future.delayed(const Duration(seconds: 1));

    // Call backend to create draft appointment
    final response = await ApiService.createDraftAppointment(
      digiswasthId: widget.digiswasthId,
      hospitalName: widget.hospitalName,
    );

  if (response['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hospital connected successfully!')),
    );
  Navigator.popUntil(context, (route) => route.isFirst);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(response['message'] ?? 'Failed to connect to hospital'),
      backgroundColor: Colors.red,
    ),
  );
}
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter the 6-digit OTP sent to your registered mobile number',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '------',
                counterText: '',
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Connect', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP resent (dummy)')),
                );
              },
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}