// Browser features for the web layout. Other platforms get no-op stubs, so
// the dart:js_interop code is only compiled into the web build.
export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';
