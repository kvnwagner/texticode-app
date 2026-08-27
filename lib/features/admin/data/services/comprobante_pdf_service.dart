import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import '../models/comprobante_model.dart';

import '../models/usuario_model.dart';

// Genera el PDF del comprobante de entrega replicando el diseño de la
// versión web (GestionClientes.vue → descargarPDF, con jsPDF).

class ComprobantePdfService {
  static const _azul = PdfColor.fromInt(0xFF0F2236);
  static const _grisTexto = PdfColor.fromInt(0xFF4B5563);
  static const _negro = PdfColor.fromInt(0xFF111827);
  static const _grisBg = PdfColor.fromInt(0xFFF9FAFB);
  static const _grisLinea = PdfColor.fromInt(0xFFE5E7EB);
  static const _verdeBg = PdfColor.fromInt(0xFFD1FAE5);
  static const _verdeTexto = PdfColor.fromInt(0xFF065F46);
  static const _amarilloBg = PdfColor.fromInt(0xFFFFEDD5);
  static const _amarilloTexto = PdfColor.fromInt(0xFF92400E);

  static Future<Uint8List> generar({
    required Comprobante comprobante,
    Usuario? cliente,
  }) async {
    final doc = pw.Document();

    final logoBytes =
        await rootBundle.load('assets/images/logo_texticode.png');

    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final entregado =
        comprobante.estado.toLowerCase().contains('entregado') ||
        comprobante.estado.toLowerCase().contains('completado');

    final estadoBg = entregado ? _verdeBg : _amarilloBg;
    final estadoTexto = entregado ? _verdeTexto : _amarilloTexto;
    final estadoLabel = entregado ? 'Entregado' : 'Pendiente';

    final numero =
        comprobante.idComprobante.toString().padLeft(4, '0');

    final fechaHoy = _fechaLarga(DateTime.now());

    final clienteEmail = cliente?.correo ?? '';
    final clienteTel = cliente?.telefono ?? '';

    final descripcion = comprobante.ordenDescripcion ?? '—';

    // ⚠️ Tu backend actual no expone la cantidad real de la orden.
    const cantidad = 1;

    const observaciones =
        'Ninguna observación registrada para este pedido.';

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
                              child: pw.Image(
                                logo,
                                width: 30,
                                height: 30,
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
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Bogotá, Colombia  ·  texticode@correo.com  ·  +57 300 000 0000',
                                style: const pw.TextStyle(
                                  color: PdfColor.fromInt(
                                    0xFF93C5FD,
                                  ),
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
                            'COMPROBANTE DE ENTREGA',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(
                                0xFF93C5FD,
                              ),
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'N.° $numero',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Bloque de info: cliente / fechas / estado ──
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
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            _label('CLIENTE'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              comprobante.usuario,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: _negro,
                              ),
                            ),
                            if (clienteEmail.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                clienteEmail,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: _grisTexto,
                                ),
                              ),
                            ],
                            if (clienteTel.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Tel: $clienteTel',
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
                            _label('FECHA DE EMISIÓN'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              fechaHoy,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _negro,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            _label('FECHA DE ENTREGA'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              comprobante.fechaCorta,
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
                            _label('ESTADO DEL PEDIDO'),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: estadoBg,
                                borderRadius:
                                    pw.BorderRadius.circular(2),
                              ),
                              child: pw.Text(
                                estadoLabel,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: estadoTexto,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            _label('ORDEN DE REFERENCIA'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '#$numero',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _negro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabla de producto/orden ──
                pw.Table(
                  border: null,
                  columnWidths: const {
                    0: pw.FixedColumnWidth(34),
                    1: pw.FlexColumnWidth(),
                    2: pw.FixedColumnWidth(60),
                    3: pw.FixedColumnWidth(90),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: _azul,
                      ),
                      children: [
                        _thCell(
                          '#',
                          align: pw.TextAlign.left,
                        ),
                        _thCell(
                          'DESCRIPCIÓN DEL PRODUCTO / SERVICIO',
                          align: pw.TextAlign.left,
                        ),
                        _thCell(
                          'CANTIDAD',
                          align: pw.TextAlign.center,
                        ),
                        _thCell(
                          'ESTADO ENTREGA',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                      ),
                      children: [
                        _tdCell(
                          '01',
                          color: const PdfColor.fromInt(
                            0xFF9CA3AF,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: pw.Text(
                            descripcion,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _negro,
                            ),
                          ),
                        ),
                        _tdCell(
                          '$cantidad',
                          align: pw.TextAlign.center,
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: pw.Align(
                            alignment:
                                pw.Alignment.centerRight,
                            child: pw.Container(
                              padding:
                                  const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: pw.BoxDecoration(
                                color: estadoBg,
                                borderRadius:
                                    pw.BorderRadius.circular(2),
                              ),
                              child: pw.Text(
                                estadoLabel,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                  color: estadoTexto,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Container(
                  height: 1,
                  color: _grisLinea,
                  margin: const pw.EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                ),

                // ── Observaciones + Firmas ──
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 32,
                  ),
                  child: pw.Row(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            _label('OBSERVACIONES'),
                            pw.SizedBox(height: 6),
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: _grisLinea,
                                ),
                              ),
                              child: pw.Text(
                                observaciones,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: _grisTexto,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 24),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 110,
                            height: 1,
                            color: _negro,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Entregado por',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: _grisTexto,
                            ),
                          ),
                          pw.Text(
                            'TEXTICODE S.A.S.',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _azul,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 24),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 110,
                            height: 1,
                            color: _negro,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Recibido por',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: _grisTexto,
                            ),
                          ),
                          pw.Text(
                            comprobante.usuario,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _azul,
                            ),
                          ),
                        ],
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
                        'Documento de uso oficial · TEXTICODE S.A.S.',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(
                            0xFF93C5FD,
                          ),
                          fontSize: 8,
                        ),
                      ),
                      pw.Text(
                        'Generado el $fechaHoy',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(
                            0xFF93C5FD,
                          ),
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

  static pw.Widget _thCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _tdCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = _negro,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
        ),
      ),
    );
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