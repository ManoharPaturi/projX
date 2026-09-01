import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/review/review_queue_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/students/roster_screen.dart';

/// The app's navigation drawer — the plan's twelve screens hang off four
/// top-level destinations plus per-exam tabs.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD64000)),
            child: Text(
              'OMR Evaluator',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => _replace(context, DashboardScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Students'),
            onTap: () => _replace(context, RosterScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Review queue'),
            onTap: () => _replace(context, ReviewQueueScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => _replace(context, SettingsScreen.routeName),
          ),
        ],
      ),
    );
  }

  void _replace(BuildContext context, String routeName) {
    Navigator.pop(context); // close the drawer first, always
    Navigator.pushReplacementNamed(context, routeName);
  }
}
