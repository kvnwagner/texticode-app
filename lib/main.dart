import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(const TexticodeApp());
}

class TexticodeApp extends StatefulWidget {
  const TexticodeApp({super.key});

  @override
  State<TexticodeApp> createState() => _TexticodeAppState();
}

class _TexticodeAppState extends State<TexticodeApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    debugPrint('[DEEPLINK] Inicializando listener...');

    try {
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('[DEEPLINK] getInitialLink() devolvió: $initialUri');
      if (initialUri != null) _manejarUri(initialUri);
    } catch (e) {
      debugPrint('[DEEPLINK] ERROR en getInitialLink: $e');
    }

    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[DEEPLINK] uriLinkStream recibió: $uri');
        _manejarUri(uri);
      },
      onError: (e) => debugPrint('[DEEPLINK] ERROR en uriLinkStream: $e'),
    );
  }

  void _manejarUri(Uri uri) {
    debugPrint('[DEEPLINK] Procesando URI -> host: ${uri.host}, query: ${uri.queryParameters}');
    if (uri.host == 'cambiar-contrasena') {
      final token = uri.queryParameters['token'] ?? '';
      debugPrint('[DEEPLINK] Navegando a /cambiar-contrasena con token: $token');
      AppRouter.router.go('/cambiar-contrasena?token=$token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}