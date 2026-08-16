import 'package:flutter/material.dart';
import '../../data/models/comprobante_model.dart';
import '../../data/models/usuario_model.dart';

/// Vista previa del comprobante dentro de la app (icono de ojito).
/// Replica el mismo diseño usado en el PDF (ComprobantePdfService):
/// cabecera azul con logo, bloque cliente/fechas/estado, tabla de
/// producto/orden, observaciones y firmas.
///
/// Uso: en el botón de ojito de la lista de comprobantes, reemplaza el
/// onPressed actual por:
///
/// onPressed: () => ComprobantePreviewSheet.show(
///   context,
///   comprobante: comprobante,
///   cliente: cliente, // opcional
/// ),

class _ComprobanteColors {
  static const azul = Color(0xFF0F2236);
  static const azulClaro = Color(0xFF93C5FD);
  static const grisTexto = Color(0xFF4B5563);
  static const negro = Color(0xFF111827);
  static const grisBg = Color(0xFFF9FAFB);
  static const grisLinea = Color(0xFFE5E7EB);
  static const verdeBg = Color(0xFFD1FAE5);
  static const verdeTexto = Color(0xFF065F46);
  static const amarilloBg = Color(0xFFFFEDD5);
  static const amarilloTexto = Color(0xFF92400E);
}

class ComprobantePreviewSheet extends StatelessWidget {
  final Comprobante comprobante;
  final Usuario? cliente;

  const ComprobantePreviewSheet({
    super.key,
    required this.comprobante,
    this.cliente,
  });

  static Future<void> show(
      BuildContext context, {
        required Comprobante comprobante,
        Usuario? cliente,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComprobantePreviewSheet(
        comprobante: comprobante,
        cliente: cliente,
      ),
    );
  }

  bool get _entregado =>
      comprobante.estado.toLowerCase().contains('entregado') ||
          comprobante.estado.toLowerCase().contains('completado');

  @override
  Widget build(BuildContext context) {
    final estadoBg = _entregado ? _ComprobanteColors.verdeBg : _ComprobanteColors.amarilloBg;
    final estadoTexto = _entregado ? _ComprobanteColors.verdeTexto : _ComprobanteColors.amarilloTexto;
    final estadoLabel = _entregado ? 'Entregado' : 'Pendiente';
    final numero = comprobante.idComprobante.toString().padLeft(4, '0');
    final descripcion = comprobante.ordenDescripcion ?? '—';
    final clienteEmail = cliente?.correo ?? '';
    final clienteTel = cliente?.telefono ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Cabecera azul ──
                      Container(
                        color: _ComprobanteColors.azul,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.qr_code_2, color: _ComprobanteColors.azul, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TEXTICODE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Bogotá, Colombia · texticode@correo.com\n+57 300 000 0000',
                                        style: TextStyle(
                                          color: _ComprobanteColors.azulClaro,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close, color: Colors.white70),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'COMPROBANTE DE ENTREGA',
                                        style: TextStyle(
                                          color: _ComprobanteColors.azulClaro,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'N.° $numero',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _EstadoPill(label: estadoLabel, bg: estadoBg, texto: estadoTexto),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Cliente / fechas ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _ComprobanteColors.grisLinea)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('CLIENTE'),
                            const SizedBox(height: 4),
                            Text(
                              comprobante.usuario,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _ComprobanteColors.negro,
                              ),
                            ),
                            if (clienteEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(clienteEmail,
                                  style: const TextStyle(fontSize: 12, color: _ComprobanteColors.grisTexto)),
                            ],
                            if (clienteTel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Tel: $clienteTel',
                                  style: const TextStyle(fontSize: 12, color: _ComprobanteColors.grisTexto)),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('FECHA DE EMISIÓN'),
                                      const SizedBox(height: 4),
                                      Text(_fechaHoy(),
                                          style: const TextStyle(fontSize: 13, color: _ComprobanteColors.negro)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('FECHA DE ENTREGA'),
                                      const SizedBox(height: 4),
                                      Text(comprobante.fechaCorta,
                                          style: const TextStyle(fontSize: 13, color: _ComprobanteColors.negro)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Estado del pedido / orden de referencia ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _ComprobanteColors.grisLinea)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('ESTADO DEL PEDIDO'),
                                  const SizedBox(height: 6),
                                  _EstadoPill(label: estadoLabel, bg: estadoBg, texto: estadoTexto),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('ORDEN DE REFERENCIA'),
                                  const SizedBox(height: 6),
                                  Text('#$numero',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _ComprobanteColors.negro)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Productos / servicios ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('PRODUCTOS / SERVICIOS'),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: [
                                  Container(
                                    color: _ComprobanteColors.azul,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          child: Text('#',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('DESCRIPCIÓN',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('CANTIDAD',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('ESTADO',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          child: Text('01',
                                              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            descripcion,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _ComprobanteColors.negro,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text('1',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 13, color: _ComprobanteColors.negro)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _EstadoPill(
                                                label: estadoLabel, bg: estadoBg, texto: estadoTexto, small: true),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Observaciones ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('OBSERVACIONES'),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _ComprobanteColors.grisBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _ComprobanteColors.grisLinea),
                              ),
                              child: const Text(
                                'Ninguna observación registrada para este pedido.',
                                style: TextStyle(fontSize: 12, color: _ComprobanteColors.grisTexto),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Firmas ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('ENTREGADO POR',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: _ComprobanteColors.grisTexto,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  const Text('TEXTICODE S.A.S.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _ComprobanteColors.azul)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('RECIBIDO POR',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: _ComprobanteColors.grisTexto,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(comprobante.usuario,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _ComprobanteColors.azul)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Pie de página ──
                      Container(
                        width: double.infinity,
                        color: _ComprobanteColors.azul,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          'Este documento es un comprobante oficial de entrega emitido por TEXTICODE. · Generado el ${_fechaHoy()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _ComprobanteColors.azulClaro, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _ComprobanteColors.grisTexto,
        letterSpacing: 0.5,
      ),
    );
  }

  String _fechaHoy() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final d = DateTime.now();
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}

class _EstadoPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color texto;
  final bool small;

  const _EstadoPill({
    required this.label,
    required this.bg,
    required this.texto,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: texto,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}