import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../welcome_screen.dart';
import '../../widgets/staff_id_bar.dart';
import '../../theme/app_theme.dart';

class TestHomeScreen extends StatefulWidget {
  final String fullName;
  final int hospitalId;
  final int staffId;

  const TestHomeScreen({
    super.key,
    required this.fullName,
    required this.hospitalId,
    required this.staffId,
  });

  @override
  State<TestHomeScreen> createState() => _TestHomeScreenState();
}

class _TestHomeScreenState extends State<TestHomeScreen> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final res = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/test/pending/${widget.hospitalId}'),
    );
    final data = jsonDecode(res.body);
    setState(() {
      items = data['tests'] ?? [];
      loading = false;
    });
  }

  Future<void> _complete(int prescriptionId) async {
    final res = await http.put(
      Uri.parse('http://10.0.2.2:5000/api/test/complete/$prescriptionId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"staff_id": widget.staffId}),
    );
    final data = jsonDecode(res.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Done')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: StaffIdBar(
        title: 'Test Ward',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'No pending tests',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: WidgetColors.test.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['patient_name'] ?? '',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['digiswasth_id'] ?? ''}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          Text(
                            'Doctor: ${item['doctor_name'] ?? ''}',
                            style: const TextStyle(color: AppColors.text),
                          ),
                          Text(
                            'Tests: ${item['tests'] ?? ''}',
                            style: const TextStyle(color: AppColors.text),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WidgetColors.test,
                                foregroundColor: AppColors.bg,
                              ),
                              onPressed: () =>
                                  _complete(item['prescription_id']),
                              child: const Text('Complete Test'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}