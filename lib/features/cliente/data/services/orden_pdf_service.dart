import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../admin/data/models/orden_model.dart';

/// Genera el PDF de "Ficha de Pedido" para el cliente, con el mismo
/// lenguaje visual que ComprobantePdfService (cabecera azul con logo,
/// bloques de info, tabla de producto, barra de progreso y pie de
/// página), pero enfocado en los datos de una [Orden].
class OrdenPdfService {
  static const _azul = PdfColor.fromInt(0xFF0F2236);
  static const _azulClaro = PdfColor.fromInt(0xFF93C5FD);
  static const _grisTexto = PdfColor.fromInt(0xFF4B5563);
  static const _negro = PdfColor.fromInt(0xFF111827);
  static const _grisBg = PdfColor.fromInt(0xFFF9FAFB);
  static const _grisLinea = PdfColor.fromInt(0xFFE5E7EB);

  static const _verdeBg = PdfColor.fromInt(0xFFD1FAE5);
  static const _verdeTexto = PdfColor.fromInt(0xFF065F46);

  static const _amarilloBg = PdfColor.fromInt(0xFFFFEDD5);
  static const _amarilloTexto = PdfColor.fromInt(0xFF92400E);

  static const _rojoBg = PdfColor.fromInt(0xFFFEE2E2);
  static const _rojoTexto = PdfColor.fromInt(0xFF991B1B);

  static const _moradoBg = PdfColor.fromInt(0xFFEDE9FE);
  static const _moradoTexto = PdfColor.fromInt(0xFF7C3AED);

  static Future<Uint8List> generar({
    required Orden orden,
  }) async {
    final doc = pw.Document();

    pw.MemoryImage? logo;

    try {
      final logoBytes = await rootBundle.load(
        'assets/images/logo_texticode.png',
      );

      logo = pw.MemoryImage(
        logoBytes.buffer.asUint8List(),
      );
    } catch (_) {
      logo = null;
    }

    final (estadoBg, estadoTexto) = _estadoColores(orden);
    final (prioBg, prioTexto) = _prioridadColores(orden);

    final numero = orden.idOrden.toString().padLeft(4, '0');

    final fechaHoy = _fechaLarga(DateTime.now());

    final materiales = orden.materiales.isEmpty
        ? 'Sin materiales asignados'
        : orden.materiales.join(', ');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Container(
            color: _grisBg,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Cabecera azul ──
                pw.Container(
                  width: double.infinity,
                  color: _azul,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 40,
                            height: 40,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: logo != null
                                  ? pw.Image(
                                      logo,
                                      width: 30,
                                      height: 30,
                                    )
                                  : pw.Text(
                                      'TC',
                                      style: pw.TextStyle(
                                        color: _azul,
                                        fontWeight:
                                            pw.FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'TEXTICODE',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Bogotá, Colombia · texticode@correo.com · +57 300 000 0000',
                                style: const pw.TextStyle(
                                  color: _azulClaro,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'FICHA DE PEDIDO',
                            style: const pw.TextStyle(
                              color: _azulClaro,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            orden.codigoOrden.isEmpty
                                ? '#$numero'
                                : orden.codigoOrden,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight:
                                  pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Bloque: producto / fechas / estado ──
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: _grisLinea,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            _label('PRODUCTO'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              orden.producto,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    pw.FontWeight.bold,
                                color: _negro,
                              ),
                            ),
                            if ((orden.descripcion ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(
                                orden.descripcion!,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: _grisTexto,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            _label('FECHA DE CREACIÓN'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              _fechaSimple(
                                orden.fechaCreacion,
                              ),
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _negro,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            _label('FECHA LÍMITE'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              orden.fechaCorta.isEmpty
                                  ? 'Sin fecha'
                                  : orden.fechaCorta,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _negro,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.end,
                          children: [
                            _label('ESTADO'),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding:
                                  const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: estadoBg,
                                borderRadius:
                                    pw.BorderRadius.circular(
                                  10,
                                ),
                              ),
                              child: pw.Text(
                                orden.estadoLabel,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                  color: estadoTexto,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            _label('PRIORIDAD'),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding:
                                  const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: prioBg,
                                borderRadius:
                                    pw.BorderRadius.circular(
                                  10,
                                ),
                              ),
                              child: pw.Text(
                                orden.prioridadLabel,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                  color: prioTexto,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Progreso de fabricación ──
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(
                    32,
                    18,
                    32,
                    12,
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'PROGRESO DE FABRICACIÓN',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  pw.FontWeight.bold,
                              color: _grisTexto,
                              letterSpacing: 1,
                            ),
                          ),
                          pw.Text(
                            '${orden.progresoPorcentaje}%',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  pw.FontWeight.bold,
                              color: _azul,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: _progresoFlex(
                                orden.progreso,
                              ),
                              child: pw.Container(
                                height: 8,
                                color: _azul,
                              ),
                            ),
                            pw.Expanded(
                              flex: 100 -
                                  _progresoFlex(
                                    orden.progreso,
                                  ),
                              child: pw.Container(
                                height: 8,
                                color: _grisLinea,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '${orden.cantidadActual} de ${orden.cantidadTotal} prendas completadas',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _grisTexto,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabla de materiales ──
                pw.Container(
                  margin: const pw.EdgeInsets.fromLTRB(
                    32,
                    6,
                    32,
                    0,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: _grisLinea,
                    ),
                    borderRadius:
                        pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding:
                            const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: _azul,
                        ),
                        child: pw.Text(
                          'MATERIALES',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight:
                                pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          materiales,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: _negro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ── Pie de página ──
                pw.Container(
                  width: double.infinity,
                  color: _azul,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 10,
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Documento informativo · TEXTICODE S.A.S.',
                        style: const pw.TextStyle(
                          color: _azulClaro,
                          fontSize: 8,
                        ),
                      ),
                      pw.Text(
                        'Generado el $fechaHoy',
                        style: const pw.TextStyle(
                          color: _azulClaro,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static (PdfColor, PdfColor) _estadoColores(Orden o) {
    if (o.isCompletada) {
      return (_verdeBg, _verdeTexto);
    }

    if (o.isEnProceso) {
      return (_moradoBg, _moradoTexto);
    }

    if (o.isRetrasada) {
      return (_rojoBg, _rojoTexto);
    }

    return (_amarilloBg, _amarilloTexto);
  }

  static (PdfColor, PdfColor) _prioridadColores(Orden o) {
    if (o.isAlta) {
      return (_rojoBg, _rojoTexto);
    }

    if (o.isBaja) {
      return (_verdeBg, _verdeTexto);
    }

    return (_amarilloBg, _amarilloTexto);
  }

  static pw.Widget _label(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _grisTexto,
        letterSpacing: 1,
      ),
    );
  }

  /// Convierte el progreso (0.0 - 1.0) a un valor de flex entre 1 y 99
  /// para dibujar la barra con dos Expanded.
  static int _progresoFlex(double progreso) {
    final pct = (progreso.clamp(0.0, 1.0) * 100).round();

    return pct.clamp(1, 99);
  }

  static String _fechaSimple(String? iso) {
    if (iso == null || iso.isEmpty) {
      return 'Sin fecha';
    }

    try {
      final d = DateTime.parse(iso);

      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _fechaLarga(DateTime d) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}