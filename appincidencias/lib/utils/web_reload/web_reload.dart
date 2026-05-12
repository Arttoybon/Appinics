import 'web_reload_stub.dart'
    if (dart.library.js_interop) 'web_reload_web.dart'
    if (dart.library.io) 'web_reload_mobile.dart';

void reloadApp() {
  performReload();
}
