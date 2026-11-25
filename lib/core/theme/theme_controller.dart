import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Modo de color de la app, igual que en la web (useTheme.js):
/// 'claro' | 'oscuro' | 'auto' (sigue al sistema operativo).
enum ModoTema { claro, oscuro, auto }

/// Estado global del tema. Vive como singleton para que [AppColors]
/// pueda leerlo sin necesitar un BuildContext.
///
/// La preferencia se guarda en el almacenamiento seguro con la misma
/// clave que usa la web (`texticode.theme`).
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _storageKey = 'texticode.theme';
  static const _storage = FlutterSecureStorage();

  ModoTema _modo = ModoTema.claro;
  bool _sistemaOscuro = false;
  bool _iniciado = false;

  ModoTema get modo => _modo;

  bool get isDark =>
      _modo == ModoTema.oscuro || (_modo == ModoTema.auto && _sistemaOscuro);

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  /// Carga la preferencia guardada. Se llama una vez en `main()`.
  Future<void> init() async {
    if (_iniciado) return;
    _iniciado = true;
    WidgetsBinding.instance.addObserver(this);
    _sistemaOscuro = SchedulerBinding
            .instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    try {
      final guardado = await _storage.read(key: _storageKey);
      _modo = ModoTema.values.firstWhere(
        (m) => m.name == guardado,
        orElse: () => ModoTema.claro,
      );
    } catch (_) {
      _modo = ModoTema.claro;
    }
  }

  Future<void> setModo(ModoTema modo) async {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();
    try {
      await _storage.write(key: _storageKey, value: modo.name);
    } catch (_) {
      // Si no se puede guardar, el cambio igual aplica en esta sesión.
    }
  }

  /// Botón sol/luna: fija el modo contrario al que se ve ahora.
  Future<void> alternar() =>
      setModo(isDark ? ModoTema.claro : ModoTema.oscuro);

  @override
  void didChangePlatformBrightness() {
    final antes = isDark;
    _sistemaOscuro = SchedulerBinding
            .instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    if (antes != isDark) notifyListeners();
  }
}

/// Envuelve la app y, cuando cambia el tema, vuelve a construir todo el
/// árbol **sin perder el estado** de las pantallas (datos cargados,
/// pestaña activa, scroll...). Es necesario porque [AppColors] se lee
/// como valor estático y no como `Theme.of(context)`.
class ThemeRebuilder extends StatefulWidget {
  final Widget child;
  const ThemeRebuilder({super.key, required this.child});

  @override
  State<ThemeRebuilder> createState() => _ThemeRebuilderState();
}

class _ThemeRebuilderState extends State<ThemeRebuilder> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onTema);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onTema);
    super.dispose();
  }

  void _onTema() {
    if (!mounted) return;
    void reconstruir(Element el) {
      el.markNeedsBuild();
      el.visitChildren(reconstruir);
    }

    (context as Element).visitChildren(reconstruir);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
