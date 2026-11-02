import 'tts_service_interface.dart';
import 'tts_service_stub.dart'
    if (dart.library.js_interop) 'tts_service_web.dart'
    if (dart.library.io) 'tts_service_io.dart';

export 'tts_service_interface.dart';

AppTtsService getAppTtsService() => createTtsService();
