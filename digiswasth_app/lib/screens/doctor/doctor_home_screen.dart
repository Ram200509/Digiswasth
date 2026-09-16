import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../welcome_screen.dart';
import 'doctor_consultation_screen.dart';
import '../../widgets/staff_id_bar.dart';
import '../../theme/app_theme.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String fullName;
  final int doctorId;

  const DoctorHomeScreen({
    super.key,
    required this.fullName,
    required this.doctorId,
  });

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/doctor/appointments/${widget.doctorId}',
        ),
      );
      final data = jsonDecode(response.body);
      setState(() {
        appointments =
            data['success'] == true ? (data['appointments'] ?? []) : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: StaffIdBar(
        title: 'Doctor Desk',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    'No forwarded appointments',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: WidgetColors.doctor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt['patient_name'] ?? 'Patient',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appt['digiswasth_id'] ?? ''}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            Text(
                              '${appt['time_slot'] ?? ''}',
                              style: const TextStyle(color: AppColors.text),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WidgetColors.doctor,
                                  foregroundColor: AppColors.bg,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DoctorConsultationScreen(
                                        appointmentId: appt['appointment_id'],
                                        doctorId: widget.doctorId,
                                      ),
                                    ),
                                  ).then((_) => _loadAppointments());
                                },
                                child: const Text('Open'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}