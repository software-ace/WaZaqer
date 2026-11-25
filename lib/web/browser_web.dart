import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab.
void openLink(String url) => web.window.open(url, '_blank');

/// The position from the browser's own permission prompt, as (lat, lng);
/// null when refused, unavailable or timed out.
Future<(double, double)?> browserLocation() {
  final done = Completer<(double, double)?>();
  web.window.navigator.geolocation.getCurrentPosition(
    ((web.GeolocationPosition p) {
      if (!done.isCompleted) {
        done.complete((p.coords.latitude, p.coords.longitude));
      }
    }).toJS,
    ((web.GeolocationPositionError _) {
      if (!done.isCompleted) done.complete(null);
    }).toJS,
    // a city-level fix is plenty for prayer times; a recent one is fine
    web.PositionOptions(timeout: 20000, maximumAge: 600000),
  );
  return done.future;
}
