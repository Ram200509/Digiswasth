import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffIdBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const StaffIdBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? 70 : 118);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          final staffId = snapshot.data?.getString('staff_id') ?? '';
          final hospital = snapshot.data?.getString('staff_hospital_name') ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18)),
              Text(
                "$hospital  |  $staffId",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          );
        },
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}