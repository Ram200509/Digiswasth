import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class RecordFolderScreen extends StatelessWidget {
  final String title;
  final String hospitalName;
  final int appointmentId;
  final String date;
  final List items;

  const RecordFolderScreen({
    super.key,
    required this.title,
    required this.hospitalName,
    required this.appointmentId,
    required this.date,
    required this.items,
  });

  Map<String, dynamic> _parse(dynamic raw) {
    try {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String) return jsonDecode(raw);
    } catch (_) {}
    return {"data": raw.toString()};
  }

  String _pretty(Map data) {
    return data.entries.map((e) => "${e.key}: ${e.value}").join("\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(hospitalName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("Appointment #$appointmentId"),
          Text(date),
          const SizedBox(height: 16),
          ...items.map((rec) {
            final parsed = _parse(rec['record_data']);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  (rec['record_type'] ?? 'item').toString().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${_pretty(parsed)}\nBy: ${rec['created_by_name'] ?? 'Hospital staff'}",
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}