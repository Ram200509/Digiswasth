import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../welcome_screen.dart';
import 'process_appointment_screen.dart';
import '../../widgets/staff_id_bar.dart';
import '../../theme/app_theme.dart';

class CounterHomeScreen extends StatefulWidget {
  final String fullName;
  final int hospitalId;

  const CounterHomeScreen({
    super.key,
    required this.fullName,
    required this.hospitalId,
  });

  @override
  State<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends State<CounterHomeScreen> {
  List<dynamic> upcoming = [];
  List<dynamic> accepted = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    try {
      final pendingRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/counter/pending-appointments/${widget.hospitalId}',
        ),
      );
      final acceptedRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/counter/accepted-appointments/${widget.hospitalId}',
        ),
      );

      final pendingData = jsonDecode(pendingRes.body);
      final acceptedData = jsonDecode(acceptedRes.body);

      setState(() {
        upcoming = pendingData['success'] == true
            ? (pendingData['appointments'] ?? [])
            : [];
        accepted = acceptedData['success'] == true
            ? (acceptedData['appointments'] ?? [])
            : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildList(List<dynamic> list, String emptyText, String buttonText) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final appt = list[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WidgetColors.counter.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt['patient_name'] ?? 'Unknown',
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
                  '${appt['doctor_name'] ?? 'No doctor'}  |  ${appt['time_slot'] ?? ''}',
                  style: const TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WidgetColors.counter,
                      foregroundColor: AppColors.bg,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProcessAppointmentScreen(
                            appointmentId: appt['appointment_id'],
                          ),
                        ),
                      ).then((_) => _loadAll());
                    },
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: StaffIdBar(
          title: 'Counter Desk',
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Accepted'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(upcoming, 'No upcoming appointments', 'Accept'),
                  _buildList(accepted, 'No accepted appointments', 'Process'),
                ],
              ),
      ),
    );
  }
}