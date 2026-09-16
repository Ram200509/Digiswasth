import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic>? appointment;
  Map<String, dynamic>? vitals;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Get appointment details
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/counter/appointment/${widget.appointmentId}'),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          appointment = data['appointment'];
        });
      }

      // TODO: Later we can add a separate API to fetch vitals
      // For now we just show appointment info

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'confirmed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return "Your appointment request is waiting for hospital confirmation.";
      case 'accepted':
        return "Your appointment has been accepted.\nPlease visit 2 hours before the consultation time recommended by you.";
      case 'confirmed':
        return "Your appointment is confirmed. Please visit the hospital as scheduled.";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointment == null
              ? const Center(child: Text("Appointment not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment!['status'])
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(appointment!['status']),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              appointment!['status'].toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(appointment!['status']),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStatusMessage(appointment!['status']),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hospital & Doctor Info
                      _buildInfoCard(
                        title: "Hospital & Doctor",
                        children: [
                          _buildInfoRow("Hospital", appointment!['hospital_name']),
                          _buildInfoRow("Doctor",
                              "${appointment!['doctor_name']} (${appointment!['specialization']})"),
                          _buildInfoRow("Date",
                              appointment!['appointment_date'].toString().substring(0, 10)),
                          _buildInfoRow("Time Slot", appointment!['time_slot']),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Patient Info
                      _buildInfoCard(
                        title: "Patient Information",
                        children: [
                          _buildInfoRow("Name", appointment!['patient_name']),
                          _buildInfoRow(
                              "DigiSwasth ID", appointment!['digiswasth_id']),
                          _buildInfoRow("Phone", appointment!['patient_phone']),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Not available",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}