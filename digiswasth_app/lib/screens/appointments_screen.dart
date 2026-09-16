import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'register_appointment_screen.dart';
import 'appointment_details_screen.dart';
import 'register_appointment_screen.dart'; 
import '../theme/app_theme.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? digiswasthId;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

 Future<void> _loadAppointments() async {
  final prefs = await SharedPreferences.getInstance();
  digiswasthId = prefs.getString('digiswasthId');

  // Show DigiSwasth ID on screen for debugging
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("DigiSwasth ID: ${digiswasthId ?? 'NULL'}"),
      duration: const Duration(seconds: 4),
    ),
  );

  if (digiswasthId == null) {
    setState(() => isLoading = false);
    return;
  }

  try {
    final response = await ApiService.getAppointments(digiswasthId!);

    // Show API response on screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("API Success: ${response['success']} | Count: ${response['appointments']?.length ?? 0}"),
        duration: const Duration(seconds: 5),
      ),
    );

    if (response['success'] == true) {
      setState(() {
        appointments = response['appointments'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
    setState(() => isLoading = false);
  }
}

  String _getButtonText(String status) {
    switch (status) {
      case 'draft':
        return 'Register Appointment';
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'View Details';
      default:
        return 'View';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    'No connected hospitals yet.\nConnect to a hospital first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final status = appointment['status'] ?? 'draft';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment['hospital_name'] ?? 'Unknown Hospital',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final status = appointment['status'] ?? 'draft';

                                     if (status == 'draft') {
                                        // Open Register form
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RegisterAppointmentScreen(
                                              appointmentId: appointment['appointment_id'],
                                              hospitalId: appointment['hospital_id'],
                                              hospitalName: appointment['hospital_name'],
                                            ),
                                          ),
                                        ).then((_) {
                                          _loadAppointments();
                                        });
                                      } else {
                                        // Open Details screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AppointmentDetailsScreen(
                                              appointmentId: appointment['appointment_id'],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  child: Text(_getButtonText(status)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}