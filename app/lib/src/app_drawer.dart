import 'package:flutter/material.dart';

import '../features/calibration/calibration_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/help/help_screen.dart';
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
            decoration: BoxDecoration(color: Color(0xFFB33600)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'OMR Evaluator',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => _replace(context, DashboardScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Students'),
            onTap: () => _replace(context, RosterScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Sheets to check'),
            onTap: () => _replace(context, ReviewQueueScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Printer check'),
            onTap: () => _replace(context, CalibrationScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => _replace(context, SettingsScreen.routeName),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How to use'),
            onTap: () => _replace(context, HelpScreen.routeName),
          ),
        ],
      ),
    );
  }

  /// Every destination opens on top of Home, so the back arrow (and the
  /// phone's back button) always leads home instead of closing the app.
  void _replace(BuildContext context, String routeName) {
    Navigator.pop(context); // close the drawer first, always
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    if (routeName != DashboardScreen.routeName) {
      navigator.pushNamed(routeName);
    }
  }
}
