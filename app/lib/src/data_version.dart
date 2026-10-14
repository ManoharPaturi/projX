import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

/// [AppState.version] as a screen should see it: live while the screen's
/// route is on top, frozen while another route covers it.
///
/// Every captured sheet bumps the version, and every screen keys its data
/// loads on it — so while the camera is up, the dashboard and exam page
/// underneath were re-querying the database after every sheet for nobody
/// to see. A covered screen now keeps the version it last showed and
/// catches up (one reload) when it is uncovered: `ModalRoute.of` rebuilds
/// it when its route becomes current again.
extension DataVersion on BuildContext {
  int watchDataVersion() {
    final version = watch<AppState>().version;
    final route = ModalRoute.of(this);
    if (route == null) return version;
    if (route.isCurrent) return _shownVersion[route] = version;
    return _shownVersion[route] ??= version;
  }
}

final Expando<int> _shownVersion = Expando('shownDataVersion');
