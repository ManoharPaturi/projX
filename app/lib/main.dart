import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/capture/capture_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/exams/exam_create_screen.dart';
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
        theme: _theme(),
        initialRoute: DashboardScreen.routeName,
        routes: <String, WidgetBuilder>{
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          ExamCreateScreen.routeName: (_) => const ExamCreateScreen(),
          RosterScreen.routeName: (_) => const RosterScreen(),
          ReviewQueueScreen.routeName: (_) => const ReviewQueueScreen(),
          CaptureScreen.routeName: (_) => const CaptureScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
        },
      ),
    );
  }

  /// M3 with the sheet's drop-out orange as the brand seed — the same ink
  /// the operator sees printed on every sheet.
  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFD64000));
    return ThemeData(
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
