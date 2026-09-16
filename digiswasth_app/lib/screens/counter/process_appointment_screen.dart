import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

class ProcessAppointmentScreen extends StatefulWidget {
  final int appointmentId;

  const ProcessAppointmentScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<ProcessAppointmentScreen> createState() =>
      _ProcessAppointmentScreenState();
}

class _ProcessAppointmentScreenState extends State<ProcessAppointmentScreen> {
  Map<String, dynamic>? appointment;
  bool isLoading = true;
  bool isSaving = false;
  bool isWorking = false;

  final _bpController = TextEditingController();
  final _sugarController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _patientIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/counter/appointment/${widget.appointmentId}'),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          appointment = data['appointment'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _acceptAppointment() async {
    setState(() => isWorking = true);
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:5000/api/counter/accept-appointment/${widget.appointmentId}'),
        headers: {"Content-Type": "application/json"},
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Appointment accepted. Patient notified."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to accept")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isWorking = false);
    }
  }

  Future<void> _saveVitals() async {
    if (appointment == null) return;
    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/counter/save-vitals'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "appointment_id": widget.appointmentId,
          "patient_id": appointment!['patient_id'],
          "bp": _bpController.text.trim(),
          "sugar": _sugarController.text.trim(),
          "oxygen": _oxygenController.text.trim(),
          "weight": _weightController.text.trim(),
          "temperature": _temperatureController.text.trim(),
          "created_by": 3
        }),
      );
      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? "Vitals update finished"),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _forwardToDoctor() async {
    if (appointment == null) return;

    if (_patientIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter patient DigiSwasth ID")),
      );
      return;
    }

    setState(() => isWorking = true);
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:5000/api/counter/forward-to-doctor/${widget.appointmentId}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "doctor_id": appointment!['doctor_id'],
          "digiswasth_id": _patientIdController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authorised and forwarded to doctor"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to forward")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment?['status'];

    return Scaffold(
      appBar: AppBar(
        title: Text(status == 'pending'
            ? "Upcoming Appointment"
            : "Accepted Appointment"),
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
                      Text("Patient: ${appointment!['patient_name']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("DigiSwasth ID: ${appointment!['digiswasth_id']}"),
                      Text(
                          "Doctor: ${appointment!['doctor_name']} (${appointment!['specialization']})"),
                      Text("Slot: ${appointment!['time_slot']}"),
                      Text("Status: $status"),
                      const SizedBox(height: 24),

                      if (status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isWorking ? null : _acceptAppointment,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Text("Accept Appointment"),
                          ),
                        ),

                      if (status == 'accepted') ...[
                        const Text("Enter Vitals",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bpController,
                          decoration: const InputDecoration(
                            labelText: "Blood Pressure",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sugarController,
                          decoration: const InputDecoration(
                            labelText: "Blood Sugar",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _oxygenController,
                          decoration: const InputDecoration(
                            labelText: "Oxygen Level (%)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: "Weight (kg)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _temperatureController,
                          decoration: const InputDecoration(
                            labelText: "Temperature (°F)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveVitals,
                            child: const Text("Save Vitals"),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text("Authorise Patient before forwarding"),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _patientIdController,
                          decoration: const InputDecoration(
                            labelText: "Enter Patient DigiSwasth ID",
                            border: OutlineInputBorder(),
                            hintText: "DS-2026-XXXXXX",
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isWorking ? null : _forwardToDoctor,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text("Forward to Doctor"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}