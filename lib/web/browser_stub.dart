/// Opens [url] in a new browser tab. Web only; elsewhere it does nothing.
void openLink(String url) {}

/// The position from the browser's own permission prompt, as (lat, lng);
/// null when refused, unavailable or not on web.
Future<(double, double)?> browserLocation() async => null;
