import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final int appointmentId;
  final int doctorId;

  const DoctorConsultationScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
  });

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  Map<String, dynamic>? appointment;
  Map<String, dynamic>? vitals;
  String medaiSummary = "";
  bool isLoading = true;
  bool isGenerating = false;
  bool isSaving = false;

  final _diagnosisController = TextEditingController();
  final _medicinesController = TextEditingController();
  final _testsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/doctor/appointment/${widget.appointmentId}'),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          appointment = data['appointment'];
          vitals = data['vitals'];
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

  Future<void> _generateMedAI() async {
  try {
    final response = await http.post(
      Uri.parse(
        'http://10.0.2.2:5000/api/doctor/medai-summary/${widget.appointmentId}',
      ),
      headers: {"Content-Type": "application/json"},
    );

    print("MEDAI STATUS: ${response.statusCode}");
    print("MEDAI BODY: ${response.body}");

    if (response.body.trim().startsWith("<")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong MedAI URL. Check backend route.")),
      );
      return;
    }

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      setState(() {
        _notesController.text = data['summary'] ?? "";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "MedAI failed")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("MedAI error: $e")),
    );
  }
}

  Future<void> _completeConsultation() async {
    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/doctor/complete-consultation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "appointment_id": widget.appointmentId,
          "doctor_id": widget.doctorId,
          "diagnosis": _diagnosisController.text.trim(),
          "medicines": _medicinesController.text.trim(),
          "tests": _testsController.text.trim(),
          "notes": _notesController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Consultation completed"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consultation"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointment == null
              ? const Center(child: Text("Appointment not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Patient: ${appointment!['patient_name']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("ID: ${appointment!['digiswasth_id']}"),
                      Text("Slot: ${appointment!['time_slot']}"),
                      const SizedBox(height: 16),
                      const Text("Vitals",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("BP: ${vitals?['bp'] ?? 'N/A'}"),
                      Text("Sugar: ${vitals?['sugar'] ?? 'N/A'}"),
                      Text("Oxygen: ${vitals?['oxygen'] ?? 'N/A'}"),
                      Text("Weight: ${vitals?['weight'] ?? 'N/A'}"),
                      Text("Temp: ${vitals?['temperature'] ?? 'N/A'}"),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isGenerating ? null : _generateMedAI,
                          child: isGenerating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Generate MedAI Summary"),
                        ),
                      ),
                      if (medaiSummary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.teal.shade50,
                          child: Text(medaiSummary),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: _diagnosisController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Diagnosis",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _medicinesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Medicines",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _testsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Tests",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Notes",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _completeConsultation,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Complete Consultation"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}