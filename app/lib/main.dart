import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/calibration/calibration_screen.dart';
import 'features/capture/capture_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/exams/exam_create_screen.dart';
import 'features/help/help_screen.dart';
import 'features/review/review_queue_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/students/roster_screen.dart';
import 'src/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.boot();
  runApp(OmrApp(state: state));
}

/// Material shell. Kept constructible with an injected [AppState] so widget
/// tests pump the real tree over an in-memory `AppDb` (plan §9).
class OmrApp extends StatelessWidget {
  const OmrApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        title: 'OMR Evaluator',
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: ThemeMode.system,
        initialRoute: DashboardScreen.routeName,
        routes: <String, WidgetBuilder>{
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          ExamCreateScreen.routeName: (_) => const ExamCreateScreen(),
          RosterScreen.routeName: (_) => const RosterScreen(),
          ReviewQueueScreen.routeName: (_) => const ReviewQueueScreen(),
          CaptureScreen.routeName: (_) => const CaptureScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          CalibrationScreen.routeName: (_) => const CalibrationScreen(),
          HelpScreen.routeName: (_) => const HelpScreen(),
        },
      ),
    );
  }

  /// M3 with the sheet's drop-out orange as the brand seed — the same ink
  /// the operator sees printed on every sheet. Comfortable density + padded
  /// tap targets: this app is used standing, all day, often one-handed.
  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD64000),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
