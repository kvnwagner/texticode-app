import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'documento_pdf.dart';

class ReportePdfService {
  static const _pesos = {
    'producto': 2.6,
    'cliente': 1.8,
    'operario': 1.8,
    'estado': 1.3,
    'material': 2.0,
    'categoria': 1.4,
    'unidades_producidas': 1.7,
    'prendas_dia': 1.3,
  };
  static const _coloresEstado = {
    'Completada': PdfColor.fromInt(0xFF166534),
    'En Proceso': PdfColor.fromInt(0xFF92400E),
    'Retrasada': PdfColor.fromInt(0xFF991B1B),
  };
  static const _altoLinea = 3.8;
  static const _margenFila = 5.0;
  static const _interlineadoTabla = 8 * 1.3 / PdfPageFormat.mm;
  static const _interlineadoDatos = 9 * 1.15 / PdfPageFormat.mm;

  static Future<Uint8List> generar({
    required String titulo,
    required String periodo,
    required List<String> claves,
    required List<List<String>> filas,
  }) async {
    final pdf = await DocumentoPdf.crear(
      titulo: titulo,
      pie: 'Documento de uso interno · TEXTICODE S.A.S.',
      numerar: true,
    );
    final inicioPagina = pdf.nuevaPagina();
    var y = _dibujarDatos(pdf, inicioPagina, periodo, filas.length);
    if (filas.isEmpty) {
      pdf.escribir(
          'Sin datos para este reporte.', DocumentoPdf.izquierda, y + 4,
          color: DocumentoPdf.gris);
      return pdf.guardar();
    }

    final pesoTotal =
        claves.fold<double>(0, (suma, clave) => suma + (_pesos[clave] ?? 1));
    var x = DocumentoPdf.izquierda;
    final columnas = claves.map((clave) {
      final ancho = DocumentoPdf.ancho * (_pesos[clave] ?? 1) / pesoTotal;
      final etiqueta =
          clave[0].toUpperCase() + clave.substring(1).replaceAll('_', ' ');
      final columna = (
        x: x + 2,
        ancho: ancho - 4,
        esEstado: clave == 'estado',
        encabezado: pdf.dividir(etiqueta, ancho - 4, tamano: 8, negrita: true),
      );
      x += ancho;
      return columna;
    }).toList();
    final altoEncabezado = _margenFila +
        _altoLinea * columnas.map((c) => c.encabezado.length).reduce(math.max);

    void encabezadoTabla() {
      pdf.rectangulo(
          DocumentoPdf.izquierda, y, DocumentoPdf.ancho, altoEncabezado,
          radio: 2, fondo: DocumentoPdf.fondoTabla, borde: DocumentoPdf.borde);
      for (final columna in columnas) {
        for (var i = 0; i < columna.encabezado.length; i++) {
          pdf.escribir(columna.encabezado[i], columna.x,
              y + 4.5 + i * _interlineadoTabla,
              tamano: 8, color: DocumentoPdf.textoTabla, negrita: true);
        }
      }
      y += altoEncabezado;
    }

    void nuevaPagina() {
      y = pdf.nuevaPagina();
      encabezadoTabla();
    }

    encabezadoTabla();
    final altoDisponible = DocumentoPdf.limite - inicioPagina - altoEncabezado;
    for (final fila in filas) {
      final contenido = [
        for (var i = 0; i < columnas.length; i++)
          pdf.dividir(
            _valor(fila[i]),
            columnas[i].ancho,
            tamano: 8,
            negrita: columnas[i].esEstado,
          ),
      ];
      final totalLineas =
          contenido.map((celda) => celda.length).reduce(math.max);
      final altoFila = _margenFila + _altoLinea * totalLineas;
      if (y + altoFila > DocumentoPdf.limite && altoFila <= altoDisponible) {
        nuevaPagina();
      }
      for (var inicio = 0; inicio < totalLineas;) {
        if (y + _margenFila + _altoLinea > DocumentoPdf.limite) nuevaPagina();
        final espacio =
            ((DocumentoPdf.limite - y - _margenFila) / _altoLinea).floor();
        final fin = math.min(inicio + espacio, totalLineas);
        final alto = _margenFila + (fin - inicio) * _altoLinea;
        pdf.rectangulo(DocumentoPdf.izquierda, y, DocumentoPdf.ancho, alto,
            borde: DocumentoPdf.borde);
        for (var i = 0; i < columnas.length; i++) {
          final columna = columnas[i];
          final colorEstado = columna.esEstado ? _coloresEstado[fila[i]] : null;
          for (var j = inicio; j < math.min(fin, contenido[i].length); j++) {
            pdf.escribir(contenido[i][j], columna.x,
                y + 4.5 + (j - inicio) * _interlineadoTabla,
                tamano: 8,
                color: colorEstado ?? DocumentoPdf.textoTabla,
                negrita: columna.esEstado);
          }
        }
        y += alto;
        inicio = fin;
      }
    }
    return pdf.guardar();
  }

  static double _dibujarDatos(
      DocumentoPdf pdf, double y, String periodo, int total) {
    final datos = [
      ('PERÍODO', periodo),
      (
        'FECHA DE GENERACIÓN',
        DocumentoPdf.fecha(DateTime.now().toIso8601String())
      ),
      ('TOTAL DE REGISTROS', '$total'),
    ];
    const anchoColumna = DocumentoPdf.ancho / 3;
    var maxLineas = 1;
    for (var i = 0; i < datos.length; i++) {
      final (etiqueta, valor) = datos[i];
      final x = DocumentoPdf.izquierda + i * anchoColumna;
      final lineas = pdf.dividir(_valor(valor), anchoColumna - 5, tamano: 9);
      maxLineas = math.max(maxLineas, lineas.length);
      pdf.escribir(etiqueta, x, y,
          tamano: 8, color: DocumentoPdf.gris, negrita: true);
      for (var j = 0; j < lineas.length; j++) {
        pdf.escribir(lineas[j], x, y + 5 + j * _interlineadoDatos, tamano: 9);
      }
    }
    return y + 11 + 4 * maxLineas;
  }

  static String _valor(String valor) => valor.trim().isEmpty ? '—' : valor;
}
