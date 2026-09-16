import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RegisterAppointmentScreen extends StatefulWidget {
  final int appointmentId;
  final int hospitalId;
  final String hospitalName;

  const RegisterAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<RegisterAppointmentScreen> createState() => _RegisterAppointmentScreenState();
}

class _RegisterAppointmentScreenState extends State<RegisterAppointmentScreen> {
  List<dynamic> doctors = [];
  bool isLoading = true;
  bool isSubmitting = false;

  int? selectedDoctorId;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool consentMedicalHistory = false;

  final List<String> timeSlots = [
    "09:00 AM - 09:30 AM",
    "09:30 AM - 10:00 AM",
    "10:00 AM - 10:30 AM",
    "10:30 AM - 11:00 AM",
    "11:00 AM - 11:30 AM",
    "11:30 AM - 12:00 PM",
    "02:00 PM - 02:30 PM",
    "02:30 PM - 03:00 PM",
    "03:00 PM - 03:30 PM",
    "03:30 PM - 04:00 PM",
    "04:00 PM - 04:30 PM",
    "04:30 PM - 05:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final response = await ApiService.getDoctors(widget.hospitalId);

    if (response['success'] == true) {
      setState(() {
        doctors = response['doctors'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to load doctors')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (selectedDoctorId == null || selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final formattedDate =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    final response = await ApiService.updateAppointment(
      appointmentId: widget.appointmentId,
      doctorId: selectedDoctorId!,
      appointmentDate: formattedDate,
      timeSlot: selectedTimeSlot!,
      consentMedicalHistory: consentMedicalHistory,
    );

    setState(() => isSubmitting = false);

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to Appointments screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to submit appointment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Appointment'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Name
                  Text(
                    widget.hospitalName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),

                  // Select Doctor
                  const Text('Select Doctor', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedDoctorId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a doctor',
                    ),
                    items: doctors.map((doctor) {
                      return DropdownMenuItem<int>(
                        value: doctor['staff_id'],
                        child: Text("${doctor['full_name']} (${doctor['specialization'] ?? 'Doctor'})"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDoctorId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Select Date
                  const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate == null
                            ? 'Choose a date'
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Select Time Slot
                  const Text('Preferred Time Slot', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTimeSlot,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a time slot',
                    ),
                    items: timeSlots.map((slot) {
                      return DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTimeSlot = value;
                      });
                    },
                  ),
                  const SizedBox(height: 25),

                  // Consent Toggle
                  SwitchListTile(
                    title: const Text('Allow visibility of your medical history to the Counter?'),
                    subtitle: const Text('If turned off, only the doctor can see your history'),
                    value: consentMedicalHistory,
                    onChanged: (value) {
                      setState(() {
                        consentMedicalHistory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitAppointment,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Appointment', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}