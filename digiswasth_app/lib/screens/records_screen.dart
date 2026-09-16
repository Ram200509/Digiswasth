import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'record_folder_screen.dart';
import '../theme/app_theme.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;
  String debugText = "";

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  String _diagnosisFrom(List records) {
    for (final rec in records) {
      if (rec['record_type'] == 'prescription') {
        try {
          final data = rec['record_data'] is String
              ? jsonDecode(rec['record_data'])
              : rec['record_data'];
          if (data is Map && data['diagnosis'] != null && data['diagnosis'].toString().isNotEmpty) {
            return data['diagnosis'].toString();
          }
        } catch (_) {}
      }
    }
    return "Consultation";
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getUserData();
    final digiswasthId = user['digiswasthId'] ??
        prefs.getString('digiswasthId') ??
        prefs.getString('digiswasth_id');

    if (digiswasthId == null || digiswasthId.isEmpty) {
      setState(() {
        isLoading = false;
        debugText = "No DigiSwasth ID found";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/medical-records/by-digiswasth/$digiswasthId'),
      );
      final data = jsonDecode(response.body);
      final List records =
          data['success'] == true ? (data['records'] ?? []) : [];

      final Map<int, List<dynamic>> grouped = {};
      for (final rec in records) {
        final id = rec['appointment_id'] ?? 0;
        grouped.putIfAbsent(id, () => []);
        grouped[id]!.add(rec);
      }

      final built = grouped.entries.map((entry) {
        final items = entry.value;
        final first = items.first;
        return {
          "appointment_id": entry.key,
          "hospital_name": first['hospital_name'] ?? "Hospital",
          "date": (first['appointment_date'] ?? first['created_at'] ?? "")
              .toString(),
          "diagnosis": _diagnosisFrom(items),
          "items": items,
        };
      }).toList();

      setState(() {
        folders = built;
        isLoading = false;
        debugText = folders.isEmpty ? "No medical records yet" : "";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        debugText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Records"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : folders.isEmpty
              ? Center(child: Text(debugText))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final date = folder['date'].toString().split('T').first;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.orange),
                        title: Text(folder['diagnosis']),
                        subtitle: Text(
                          "${folder['hospital_name']}\nAppointment #${folder['appointment_id']}  |  $date",
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordFolderScreen(
                                title: folder['diagnosis'],
                                hospitalName: folder['hospital_name'],
                                appointmentId: folder['appointment_id'],
                                date: date,
                                items: folder['items'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}