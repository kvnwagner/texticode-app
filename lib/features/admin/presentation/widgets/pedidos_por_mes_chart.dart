import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

typedef PedidosDelMes = ({
  String clave,
  String abreviatura,
  String nombre,
  int completados,
  int pendientes,
});

class PedidosPorMesChart extends StatefulWidget {
  final List<PedidosDelMes> meses;

  const PedidosPorMesChart({super.key, required this.meses});

  @override
  State<PedidosPorMesChart> createState() => _PedidosPorMesChartState();
}

class _PedidosPorMesChartState extends State<PedidosPorMesChart> {
  String? _mesSeleccionado;

  @override
  void didUpdateWidget(covariant PedidosPorMesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meses.lastOrNull?.clave != widget.meses.lastOrNull?.clave) {
      _mesSeleccionado = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = widget.meses;
    final seleccionado =
        meses.indexWhere((mes) => mes.clave == _mesSeleccionado);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedidos por mes',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ),
              Text('Últimos 6 meses',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          if (meses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No hay pedidos con fecha para mostrar.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else ...[
            SizedBox(
              height: 164,
              child: TapRegion(
                onTapOutside: seleccionado < 0
                    ? null
                    : (_) => setState(() => _mesSeleccionado = null),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tamano =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    final trazado = _TrazadoPedidos(meses, tamano);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (evento) {
                              if (!trazado.area
                                  .inflate(6)
                                  .contains(evento.localPosition)) {
                                return;
                              }
                              final indice = trazado
                                  .mesMasCercano(evento.localPosition.dx);
                              setState(
                                  () => _mesSeleccionado = meses[indice].clave);
                            },
                            child: CustomPaint(
                              painter: _PedidosPainter(
                                trazado: trazado,
                                seleccionado: seleccionado,
                                direccion: Directionality.of(context),
                                completados: AppColors.iconOp,
                                pendientes: AppColors.textFaint,
                                guias: AppColors.cardBorder,
                                estiloEjes: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 9),
                                fondo: AppColors.surface,
                                relleno: const Color(0xFFB8D9FF)
                                    .withValues(alpha: 0.38),
                              ),
                            ),
                          ),
                        ),
                        if (seleccionado >= 0)
                          _posicionarDetalle(trazado, tamano, seleccionado),
                        Positioned(
                          left: trazado.area.left,
                          width: trazado.area.width,
                          bottom: 0,
                          height: 27,
                          child: Row(
                            children: [
                              for (final (i, mes) in meses.indexed)
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    selected: i == seleccionado,
                                    label:
                                        '${mes.nombre}, ${mes.completados} completados, ${mes.pendientes} pendientes',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(
                                          () => _mesSeleccionado = mes.clave),
                                      child: Center(
                                        child: ExcludeSemantics(
                                          child: Text(
                                            mes.abreviatura,
                                            style: TextStyle(
                                              color: i == seleccionado
                                                  ? AppColors.textPrimary
                                                  : AppColors.textMuted,
                                              fontWeight: i == seleccionado
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 9),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 4,
                children: [
                  _Leyenda(color: AppColors.iconOp, nombre: 'Completados'),
                  _Leyenda(
                      color: AppColors.textFaint,
                      nombre: 'Pendientes',
                      discontinua: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _posicionarDetalle(_TrazadoPedidos trazado, Size tamano, int indice) {
    final mes = widget.meses[indice];
    final punto = trazado.punto(indice, mes.completados);
    final ancho = math.min(128.0, tamano.width);
    final izquierda = (punto.dx - ancho - 9).clamp(0.0, tamano.width - ancho);
    final arriba = (punto.dy + 8).clamp(
      4.0,
      math.max(4.0, trazado.area.bottom - 85.0),
    );
    return Positioned(
      left: izquierda.toDouble(),
      top: arriba.toDouble(),
      width: ancho,
      child: IgnorePointer(child: _DetalleMes(mes: mes)),
    );
  }
}

class _DetalleMes extends StatelessWidget {
  final PedidosDelMes mes;

  const _DetalleMes({required this.mes});

  @override
  Widget build(BuildContext context) {
    final total = mes.completados + mes.pendientes;
    final porcentaje = total == 0 ? 0 : (100 * mes.completados / total).round();
    const claro = AppColors.onBrand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.perfilCardGradient.first,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: AppColors.perfilCardShadow,
              blurRadius: 9,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mes.nombre,
              style: const TextStyle(
                  color: claro, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${mes.completados} completados',
              style: const TextStyle(color: claro, fontSize: 10)),
          Text('${mes.pendientes} pendientes',
              style: const TextStyle(color: claro, fontSize: 10)),
          Text('$porcentaje% completado',
              style: const TextStyle(
                  color: Color(0xFFB8D9FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String nombre;
  final bool discontinua;

  const _Leyenda(
      {required this.color, required this.nombre, this.discontinua = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: discontinua ? 5 : 14, height: 2, color: color),
        if (discontinua) ...[
          const SizedBox(width: 3),
          Container(width: 5, height: 2, color: color),
        ],
        const SizedBox(width: 5),
        Text(nombre,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _TrazadoPedidos {
  final List<PedidosDelMes> meses;
  final Rect area;
  final int intervalo;

  _TrazadoPedidos(this.meses, Size tamano)
      : area = Rect.fromLTRB(
            26, 10, math.max(tamano.width - 8, 27), tamano.height - 28),
        intervalo = _intervalo(meses);

  static int _intervalo(List<PedidosDelMes> meses) {
    final pico = meses.fold(
        0,
        (pico, mes) =>
            math.max(pico, math.max(mes.completados, mes.pendientes)));
    final objetivo = math.max(1, (pico / 3).ceil());
    var potencia = 1;
    while (objetivo > 10 * potencia) {
      potencia *= 10;
    }
    return [1, 2, 5, 10]
        .map((paso) => paso * potencia)
        .firstWhere((paso) => paso >= objetivo);
  }

  Offset punto(int indice, int valor) => Offset(
        area.left + (indice + 0.5) * area.width / meses.length,
        area.bottom - area.height * valor / (3 * intervalo),
      );

  int mesMasCercano(double x) =>
      (((x - area.left) * meses.length / area.width).floor())
          .clamp(0, meses.length - 1);
}

class _PedidosPainter extends CustomPainter {
  final _TrazadoPedidos trazado;
  final int seleccionado;
  final TextDirection direccion;
  final Color completados;
  final Color pendientes;
  final Color guias;
  final TextStyle estiloEjes;
  final Color fondo;
  final Color relleno;

  const _PedidosPainter({
    required this.trazado,
    required this.seleccionado,
    required this.direccion,
    required this.completados,
    required this.pendientes,
    required this.guias,
    required this.estiloEjes,
    required this.fondo,
    required this.relleno,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final area = trazado.area;
    for (var i = 0; i <= 3; i++) {
      final valor = i * trazado.intervalo;
      final y = trazado.punto(0, valor).dy;
      canvas.drawLine(
          Offset(area.left, y), Offset(area.right, y), Paint()..color = guias);
      final etiqueta = TextPainter(
        text: TextSpan(text: '$valor', style: estiloEjes),
        textDirection: direccion,
      )..layout();
      etiqueta.paint(
          canvas,
          Offset(math.max(0, area.left - etiqueta.width - 7),
              y - etiqueta.height / 2));
    }

    final positivos = [
      for (final (i, mes) in trazado.meses.indexed)
        trazado.punto(i, mes.completados),
    ];
    final abiertos = [
      for (final (i, mes) in trazado.meses.indexed)
        trazado.punto(i, mes.pendientes),
    ];
    final curva = _curva(positivos);
    final areaRellena = Path.from(curva)
      ..lineTo(positivos.last.dx, area.bottom)
      ..lineTo(positivos.first.dx, area.bottom)
      ..close();
    canvas.drawPath(
      areaRellena,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [relleno, relleno.withValues(alpha: 0)],
        ).createShader(area),
    );

    if (seleccionado >= 0) {
      final x = positivos[seleccionado].dx;
      _discontinua(
        canvas,
        Path()
          ..moveTo(x, area.top)
          ..lineTo(x, area.bottom),
        Paint()
          ..color = (estiloEjes.color ?? guias).withValues(alpha: 0.65)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
        3,
        3,
      );
    }
    _discontinua(
      canvas,
      _curva(abiertos),
      Paint()
        ..color = pendientes
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      4,
      4,
    );
    canvas.drawPath(
      curva,
      Paint()
        ..color = completados
        ..strokeWidth = 2.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < positivos.length; i++) {
      canvas.drawCircle(abiertos[i], 3.4, Paint()..color = pendientes);
      canvas.drawCircle(abiertos[i], 2, Paint()..color = fondo);
      if (i == seleccionado) {
        canvas.drawCircle(positivos[i], 6.1, Paint()..color = fondo);
        canvas.drawCircle(positivos[i], 4.8, Paint()..color = completados);
      } else {
        canvas.drawCircle(positivos[i], 3.7, Paint()..color = completados);
        canvas.drawCircle(positivos[i], 1.7, Paint()..color = fondo);
      }
    }
  }

  Path _curva(List<Offset> puntos) {
    final path = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var i = 1; i < puntos.length; i++) {
      final anterior = puntos[i - 1];
      final actual = puntos[i];
      final mitad = (anterior.dx + actual.dx) / 2;
      path.cubicTo(mitad, anterior.dy, mitad, actual.dy, actual.dx, actual.dy);
    }
    return path;
  }

  void _discontinua(
      Canvas canvas, Path path, Paint paint, double raya, double espacio) {
    for (final tramo in path.computeMetrics()) {
      for (var inicio = 0.0; inicio < tramo.length; inicio += raya + espacio) {
        canvas.drawPath(
            tramo.extractPath(inicio, math.min(inicio + raya, tramo.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PedidosPainter anterior) =>
      anterior.trazado != trazado ||
      anterior.seleccionado != seleccionado ||
      anterior.completados != completados ||
      anterior.fondo != fondo ||
      anterior.direccion != direccion ||
      anterior.estiloEjes != estiloEjes;
}
