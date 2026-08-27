import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Genera PDFs para la pantalla de Reportes (Pedidos, Eficiencia,
/// Inventario), reutilizando el mismo diseño de los comprobantes.
class ReportePdfService {
  static const _azul = PdfColor.fromInt(0xFF0F2236);
  static const _grisTexto = PdfColor.fromInt(0xFF4B5563);
  static const _negro = PdfColor.fromInt(0xFF111827);
  static const _grisBg = PdfColor.fromInt(0xFFF9FAFB);
  static const _grisLinea = PdfColor.fromInt(0xFFE5E7EB);
  static const _azulClaro = PdfColor.fromInt(0xFF93C5FD);

  static Future<Uint8List> generar({
    required String titulo,
    required String subtitulo,
    required List<String> headers,
    required List<List<String>> filas,
  }) async {
    final doc = pw.Document();

    final logoBytes =
        await rootBundle.load('assets/images/logo_texticode.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final fechaHoy = _fechaLarga(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,

        // Header para páginas siguientes
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox();

          return pw.Container(
            width: double.infinity,
            color: _azul,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 10,
            ),
            child: pw.Text(
              'TEXTICODE — $titulo (cont.)',
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
              ),
            ),
          );
        },

        // Footer
        footer: (context) {
          return pw.Container(
            width: double.infinity,
            color: _azul,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 10,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Documento de uso oficial · TEXTICODE S.A.S.',
                  style: const pw.TextStyle(
                    color: _azulClaro,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(
                    color: _azulClaro,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) => [
          // CABECERA
          pw.Container(
            width: double.infinity,
            color: _azul,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 18,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                      'REPORTE',
                      style: const pw.TextStyle(
                        color: _azulClaro,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      titulo,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BLOQUE DE INFORMACIÓN
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _grisLinea),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    _label('RESUMEN'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      subtitulo,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _negro,
                      ),
                    ),
                  ],
                ),

                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                  children: [
                    _label('FECHA DE GENERACIÓN'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      fechaHoy,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _negro,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // TABLA
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: pw.TableHelper.fromTextArray(
              headers: headers,
              data: filas,

              border: null,

              headerDecoration: const pw.BoxDecoration(
                color: _azul,
              ),

              headerStyle: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.5,
              ),

              headerPadding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: _negro,
              ),

              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              cellAlignment: pw.Alignment.centerLeft,

              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),

              oddRowDecoration: const pw.BoxDecoration(
                color: _grisBg,
              ),
            ),
          ),

          pw.SizedBox(height: 24),
        ],
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