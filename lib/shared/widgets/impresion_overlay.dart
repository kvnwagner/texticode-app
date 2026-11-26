import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tipo de archivo que se "imprime" (igual que useImpresion.js de la web).
enum TipoImpresion { comprobante, reporte, excel }

/// Animación de "impresora" en todas las descargas, igual a la web
/// (PrintHost.vue + useImpresion.js).
///
/// Uso:
/// ```dart
/// await ImpresionOverlay.ejecutar<Uint8List>(
///   context: context,
///   tipo: TipoImpresion.comprobante,
///   numero: 'ORD-0009',
///   detalle: 'Restaurante Brasa',
///   generar: () => ComprobantePdfService.generar(...),
///   entregar: (bytes) => Printing.layoutPdf(onLayout: (_) async => bytes),
/// );
/// ```
///
/// Mientras la hoja sale de la impresora se genera el archivo. Al terminar
/// muestra "¡Listo!" con el sello, se cierra sola y luego se entrega el
/// archivo (vista previa / compartir). Si algo falla muestra el error y
/// devuelve false.
class ImpresionOverlay {
  ImpresionOverlay._();

  static const _duracionImpresion = Duration(milliseconds: 2600);
  static const _duracionListo = Duration(milliseconds: 1100);
  static const _duracionError = Duration(milliseconds: 1600);

  static Future<bool> ejecutar<T>({
    required BuildContext context,
    required TipoImpresion tipo,
    String numero = '',
    String detalle = '',
    required Future<T> Function() generar,
    required Future<void> Function(T resultado) entregar,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final menosMovimiento = MediaQuery.of(context).disableAnimations;
    final fase = ValueNotifier<_Fase>(_Fase.imprimiendo);

    unawaited(showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Imprimiendo',
      // .ph { background: rgba(15, 23, 42, 0.55) }
      barrierColor: const Color(0x8C0F172A),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => _PrintHost(
        tipo: tipo,
        numero: numero,
        detalle: detalle,
        fase: fase,
        menosMovimiento: menosMovimiento,
      ),
      transitionBuilder: (_, anim, __, child) {
        final curva =
            CurvedAnimation(parent: anim, curve: const Cubic(0.22, 1, 0.36, 1));
        return FadeTransition(
          opacity: anim,
          child: AnimatedBuilder(
            animation: curva,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, 16 * (1 - curva.value)),
              child: Transform.scale(
                  scale: 0.96 + 0.04 * curva.value, child: c),
            ),
            child: child,
          ),
        );
      },
    ));

    final salida = Future<void>.delayed(menosMovimiento
        ? const Duration(milliseconds: 300)
        : _duracionImpresion);

    T resultado;
    try {
      // Se genera el archivo mientras la hoja sale.
      resultado = await generar();
      await salida;
    } catch (_) {
      await salida;
      fase.value = _Fase.error;
      await Future<void>.delayed(_duracionError);
      if (navigator.mounted) navigator.pop();
      return false;
    }

    fase.value = _Fase.listo;
    await Future<void>.delayed(menosMovimiento
        ? const Duration(milliseconds: 400)
        : _duracionListo);
    if (navigator.mounted) navigator.pop();

    // Ya cerrada la animación se abre la vista previa / compartir.
    // Si esto falla, el error le llega a quien llamó.
    await entregar(resultado);
    return true;
  }
}

enum _Fase { imprimiendo, listo, error }

class _Textos {
  final String imprimiendo, listo, error, sello;
  const _Textos(this.imprimiendo, this.listo, this.error, this.sello);
}

const _textos = {
  TipoImpresion.comprobante: _Textos('Imprimiendo comprobante…',
      '¡Listo! Descargando PDF', 'No se pudo imprimir', 'ENTREGADO'),
  TipoImpresion.reporte: _Textos('Imprimiendo reporte…',
      '¡Listo! Descargando PDF', 'No se pudo generar el reporte', 'PDF'),
  TipoImpresion.excel: _Textos('Exportando a Excel…',
      '¡Listo! Descargando Excel', 'No se pudo exportar', 'XLSX'),
};

// ════════════════════════════════════════════════════════════════
// Tarjeta con la impresora
// ════════════════════════════════════════════════════════════════

class _PrintHost extends StatefulWidget {
  final TipoImpresion tipo;
  final String numero;
  final String detalle;
  final ValueNotifier<_Fase> fase;
  final bool menosMovimiento;

  const _PrintHost({
    required this.tipo,
    required this.numero,
    required this.detalle,
    required this.fase,
    required this.menosMovimiento,
  });

  @override
  State<_PrintHost> createState() => _PrintHostState();
}

class _PrintHostState extends State<_PrintHost> with TickerProviderStateMixin {
  late final AnimationController _impresion; // hoja + barra (2.6 s)
  late final AnimationController _vibrar; //    cuerpo (0.16 s)
  late final AnimationController _parpadeo; //  luz (0.7 s)
  late final AnimationController _sello; //     sello (0.45 s)

  @override
  void initState() {
    super.initState();
    _impresion = AnimationController(
      vsync: this,
      duration: widget.menosMovimiento
          ? const Duration(milliseconds: 300)
          : ImpresionOverlay._duracionImpresion,
    );
    _vibrar = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _parpadeo = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _sello = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    if (widget.menosMovimiento) {
      _impresion.value = 1;
    } else {
      _impresion.forward();
      _vibrar.repeat();
      _parpadeo.repeat();
    }
    widget.fase.addListener(_onFase);
  }

  void _onFase() {
    if (!mounted) return;
    if (widget.fase.value != _Fase.imprimiendo) {
      _vibrar.stop();
      _vibrar.value = 0;
      _parpadeo.stop();
      _parpadeo.value = 0;
      _impresion.value = 1;
    }
    if (widget.fase.value == _Fase.listo) _sello.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    widget.fase.removeListener(_onFase);
    _impresion.dispose();
    _vibrar.dispose();
    _parpadeo.dispose();
    _sello.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fase = widget.fase.value;
    final textos = _textos[widget.tipo]!;
    final oscuro = AppColors.isDark;

    final titulo = switch (fase) {
      _Fase.imprimiendo => textos.imprimiendo,
      _Fase.listo => textos.listo,
      _Fase.error => textos.error,
    };
    final colorTitulo = switch (fase) {
      _Fase.imprimiendo => AppColors.textPrimary,
      _Fase.listo =>
        oscuro ? AppColors.darkSuccess : const Color(0xFF15803D),
      _Fase.error =>
        oscuro ? AppColors.darkDanger : const Color(0xFFB91C1C),
    };
    final sub = fase == _Fase.error
        ? 'Inténtalo de nuevo en un momento.'
        : [widget.numero, widget.detalle]
            .where((s) => s.trim().isNotEmpty)
            .join(' · ');

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000), // rgba(0,0,0,.35)
                  blurRadius: 80,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Impresora(
                  tipo: widget.tipo,
                  numero: widget.numero,
                  sello: textos.sello,
                  fase: fase,
                  impresion: _impresion,
                  vibrar: _vibrar,
                  parpadeo: _parpadeo,
                  selloAnim: _sello,
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.17,
                    color: colorTitulo,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 16),
                  child: Text(
                    sub,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                _BarraProgreso(fase: fase, impresion: _impresion),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  final _Fase fase;
  final AnimationController impresion;

  const _BarraProgreso({required this.fase, required this.impresion});

  // animation: progreso 2.6s cubic-bezier(0.45, 0, 0.25, 1)
  static const _curva = Cubic(0.45, 0, 0.25, 1);

  @override
  Widget build(BuildContext context) {
    final oscuro = AppColors.isDark;
    final color = switch (fase) {
      _Fase.imprimiendo => AppColors.navy,
      _Fase.listo =>
        oscuro ? AppColors.darkSuccessSolid : const Color(0xFF16A34A),
      _Fase.error => const Color(0xFFDC2626),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 4,
        color: AppColors.surfaceHover,
        child: AnimatedBuilder(
          animation: impresion,
          builder: (_, __) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fase == _Fase.imprimiendo
                ? _curva.transform(impresion.value)
                : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Impresora (220 × 250, mismas posiciones que PrintHost.vue)
// ════════════════════════════════════════════════════════════════

class _Impresora extends StatelessWidget {
  final TipoImpresion tipo;
  final String numero;
  final String sello;
  final _Fase fase;
  final AnimationController impresion;
  final AnimationController vibrar;
  final AnimationController parpadeo;
  final AnimationController selloAnim;

  const _Impresora({
    required this.tipo,
    required this.numero,
    required this.sello,
    required this.fase,
    required this.impresion,
    required this.vibrar,
    required this.parpadeo,
    required this.selloAnim,
  });

  /// Saltos de la hoja al salir (keyframes "salir" de la web).
  static const _keyframes = <(double, double)>[
    (0.00, -1.00),
    (0.12, -0.86),
    (0.20, -0.86),
    (0.34, -0.64),
    (0.42, -0.64),
    (0.56, -0.40),
    (0.64, -0.40),
    (0.80, -0.14),
    (0.86, -0.14),
    (1.00, 0.00),
  ];
  static const _curvaSalir = Cubic(0.5, 0, 0.5, 1);

  static double _salida(double t) {
    for (var i = 1; i < _keyframes.length; i++) {
      final (t1, v1) = _keyframes[i];
      if (t <= t1) {
        final (t0, v0) = _keyframes[i - 1];
        final local = t1 == t0 ? 1.0 : (t - t0) / (t1 - t0);
        return v0 + (v1 - v0) * _curvaSalir.transform(local.clamp(0.0, 1.0));
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final error = fase == _Fase.error;
    final luz = error ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return SizedBox(
      width: 220,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Hoja en blanco entrando por arriba ──
          Positioned(
            left: 35,
            top: 0,
            width: 150,
            height: 46,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: impresion,
                builder: (_, __) {
                  // steps(14, end)
                  final paso = (impresion.value * 14).floor() / 14;
                  return Transform.translate(
                    offset: Offset(0, 6 + 40 * paso),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // la hoja siempre es blanca
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Comprobante saliendo (detrás del cuerpo) ──
          Positioned(
            left: 30,
            top: 110,
            width: 160,
            height: 150,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: impresion,
                builder: (_, child) => FractionalTranslation(
                  translation: Offset(0, _salida(impresion.value)),
                  child: child,
                ),
                child: _Hoja(
                  tipo: tipo,
                  numero: numero,
                  sello: sello,
                  selloAnim: selloAnim,
                ),
              ),
            ),
          ),

          // ── Cuerpo de la impresora ──
          Positioned(
            left: 0,
            right: 0,
            top: 38,
            height: 92,
            child: AnimatedBuilder(
              animation: vibrar,
              builder: (_, child) {
                // @keyframes vibrar: ±0.6px en x, ±0.4px en y
                final dx = 0.6 * math.sin(vibrar.value * 2 * math.pi);
                return Transform.translate(
                  offset: Offset(dx, -dx * 0.66),
                  child: child,
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18),
                    bottom: Radius.circular(14),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF3B4756),
                      Color(0xFF2A333F),
                      Color(0xFF1F2731),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x590F172A), // rgba(15,23,42,.35)
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Brillo superior
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 10,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                    // Luz (parpadea mientras imprime)
                    Positioned(
                      right: 22,
                      top: 34,
                      child: AnimatedBuilder(
                        animation: parpadeo,
                        builder: (_, __) {
                          final p = parpadeo.value;
                          final opacidad = fase == _Fase.imprimiendo
                              ? 1 - 0.75 * math.sin(p * math.pi)
                              : 1.0;
                          return Opacity(
                            opacity: opacidad,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: luz,
                                boxShadow: [
                                  BoxShadow(color: luz, blurRadius: 10),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Botones
                    for (final derecha in const [40.0, 62.0])
                      Positioned(
                        right: derecha,
                        top: 33,
                        child: Container(
                          width: 16,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B5767),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    // Ranura
                    Positioned(
                      left: 26,
                      right: 26,
                      bottom: 16,
                      height: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10151B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Hoja impresa (colores del documento real, iguales en claro y oscuro)
// ════════════════════════════════════════════════════════════════

class _Hoja extends StatelessWidget {
  final TipoImpresion tipo;
  final String numero;
  final String sello;
  final AnimationController selloAnim;

  const _Hoja({
    required this.tipo,
    required this.numero,
    required this.sello,
    required this.selloAnim,
  });

  static const _linea = Color(0xFFCBD5E1);
  static const _azul = Color(0xFF1F3A52);
  static const _verdeExcel = Color(0xFF1D6F42);

  @override
  Widget build(BuildContext context) {
    final excel = tipo == TipoImpresion.excel;

    final (Color borde, Color texto, Color fondo) = switch (tipo) {
      TipoImpresion.comprobante => (
          const Color(0xFF16A34A),
          const Color(0xFF16A34A),
          const Color(0xD9DCFCE7), // rgba(220,252,231,.85)
        ),
      TipoImpresion.reporte => (
          _azul,
          _azul,
          const Color(0xE6E8EEF4), // rgba(232,238,244,.9)
        ),
      TipoImpresion.excel => (
          _verdeExcel,
          _verdeExcel,
          const Color(0xEBE2EFDA), // rgba(226,239,218,.92)
        ),
    };

    return Container(
      width: 160,
      height: 150,
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        color: Colors.white, // documento: blanco también en oscuro
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        border: Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
          right: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: excel ? _verdeExcel : const Color(0xFF0F2236),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'TEXTICODE',
                      style: TextStyle(
                        fontSize: 7,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.84,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        numero,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 7,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: excel
                              ? const Color(0xFFC6EFCE)
                              : const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // overflow: hidden, como en la web
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _cuerpo(),
                  ),
                ),
              ),
            ],
          ),
          // Sello al terminar
          Positioned(
            right: 10,
            bottom: 28,
            child: AnimatedBuilder(
              animation: selloAnim,
              builder: (_, child) {
                final t = const Cubic(0.3, 1.4, 0.5, 1)
                    .transform(selloAnim.value);
                return Opacity(
                  opacity: selloAnim.value.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: -12 * math.pi / 180,
                    child: Transform.scale(
                      scale: 2.2 + (1 - 2.2) * t,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: fondo,
                  border: Border.all(color: borde, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sello,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.64,
                    color: texto,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    switch (tipo) {
      case TipoImpresion.comprobante:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titulo('COMPROBANTE DE ENTREGA'),
              _fila(const [0.46, 0.28]),
              _fila(const [0.60]),
              _tabla(),
              _fila(const [0.70, 0.14]),
              _fila(const [0.52, 0.14]),
              const SizedBox(height: 14),
              // Líneas de firma
              LayoutBuilder(
                builder: (_, c) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 2; i++)
                      SizedBox(
                        width: c.maxWidth * 0.42,
                        height: 1,
                        child: const ColoredBox(color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case TipoImpresion.reporte:
        const alturas = [0.40, 0.70, 0.55, 0.90, 0.65, 0.80];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titulo('REPORTE'),
              Container(
                height: 34,
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < alturas.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: alturas[i],
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == 3 ? _azul : const Color(0xFF2D6A9F),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _tabla(),
              _fila(const [0.40, 0.22, 0.16]),
              _fila(const [0.52, 0.18, 0.12]),
              _fila(const [0.34, 0.24, 0.16]),
            ],
          ),
        );
      case TipoImpresion.excel:
        const marcadas = {2, 7, 9, 14, 19, 21, 26};
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filaExcel(
                      List.generate(4, (_) => _celdaEncabezado()), first: true),
                  for (var r = 0; r < 7; r++)
                    _filaExcel(List.generate(4, (c) {
                      final n = r * 4 + c + 1;
                      return _celda(marcadas.contains(n));
                    })),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            fontSize: 6.5,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: _azul,
          ),
        ),
      );

  /// Fila de líneas grises (justify-content: space-between).
  Widget _fila(List<double> anchos) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: LayoutBuilder(
          builder: (_, c) => Row(
            mainAxisAlignment: anchos.length == 1
                ? MainAxisAlignment.start
                : MainAxisAlignment.spaceBetween,
            children: [
              for (final a in anchos)
                Container(
                  width: c.maxWidth * a,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _linea,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _tabla() => Container(
        height: 9,
        margin: const EdgeInsets.only(top: 8, bottom: 7),
        decoration: BoxDecoration(
          color: _azul,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _filaExcel(List<Widget> celdas, {bool first = false}) => Padding(
        padding: EdgeInsets.only(top: first ? 0 : 1),
        child: Row(
          children: [
            for (var i = 0; i < celdas.length; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Expanded(child: celdas[i]),
            ],
          ],
        ),
      );

  Widget _celdaEncabezado() =>
      const SizedBox(height: 9, child: ColoredBox(color: _verdeExcel));

  Widget _celda(bool marcada) => Container(
        height: 11,
        color: marcada ? const Color(0xFFE2EFDA) : Colors.white,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 3, top: 4),
        child: const FractionallySizedBox(
          widthFactor: 0.6,
          child: SizedBox(height: 3, child: ColoredBox(color: _linea)),
        ),
      );
}
