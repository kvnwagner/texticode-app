import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';

/// Elementos comunes de los PDF de Texticode. Las coordenadas siguen
/// documentoPdf.js: milímetros desde el borde superior de una hoja A4.
class DocumentoPdf {
  static const _mm = PdfPageFormat.mm;
  static const izquierda = 17.0;
  static const derecha = 193.0;
  static const ancho = derecha - izquierda;
  static const limite = 275.0;
  static const azul = PdfColor.fromInt(0xFF1F3A52);
  static const gris = PdfColor.fromInt(0xFF4B5563);
  static const texto = PdfColor.fromInt(0xFF111827);
  static const textoTabla = PdfColor.fromInt(0xFF374151);
  static const borde = PdfColor.fromInt(0xFFE5E7EB);
  static const fondoTabla = PdfColor.fromInt(0xFFF1F5F9);

  final String _titulo;
  final String _subtitulo;
  final String _pie;
  final bool _numerar;
  final _documento = PdfDocument();
  late final _normal = PdfFont.helvetica(_documento);
  late final _negrita = PdfFont.helveticaBold(_documento);
  late final PdfImage _logo;
  final _paginas = <PdfGraphics>[];
  late PdfGraphics _pagina;

  DocumentoPdf._(
      this._titulo, this._subtitulo, this._pie, this._numerar, Uint8List logo) {
    PdfInfo(_documento,
        title: _subtitulo.isEmpty ? _titulo : '$_titulo $_subtitulo');
    _logo = PdfImage.file(_documento, bytes: logo);
  }

  static Future<DocumentoPdf> crear({
    required String titulo,
    required String pie,
    String subtitulo = '',
    bool numerar = false,
  }) async {
    final logo =
        await rootBundle.load('assets/images/logo_comprobante_web.png');
    return DocumentoPdf._(titulo, subtitulo, pie, numerar,
        logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes));
  }

  double nuevaPagina() {
    _pagina = PdfPage(_documento, pageFormat: PdfPageFormat.a4).getGraphics();
    _paginas.add(_pagina);
    rectangulo(
      0,
      0,
      PdfPageFormat.a4.width / _mm,
      PdfPageFormat.a4.height / _mm,
      fondo: PdfColors.white,
    );
    final escala = math.min(46 / _logo.width, 11 / _logo.height);
    final alto = _logo.height * escala;
    _pagina.drawImage(_logo, izquierda * _mm, _desdeAbajo(14 + alto),
        _logo.width * escala * _mm, alto * _mm);

    final lineas =
        dividir(_titulo.toUpperCase(), 114, tamano: 13, negrita: true);
    for (var i = 0; i < lineas.length; i++) {
      escribir(lineas[i], derecha, 19 + i * 5.5,
          tamano: 13, color: azul, negrita: true, alineacion: 1);
    }
    final finTitulo = 19 + (lineas.length - 1) * 5.5;
    if (_subtitulo.isNotEmpty) {
      escribir(_subtitulo, derecha, finTitulo + 6, color: gris, alineacion: 1);
    }
    final divisor = math.max(30.0, finTitulo + (_subtitulo.isEmpty ? 6 : 11));
    linea(izquierda, derecha, divisor, azul, 0.5);
    return divisor + 9;
  }

  Future<Uint8List> guardar() {
    const colorPie = PdfColor.fromInt(0xFF6B7280);
    for (var i = 0; i < _paginas.length; i++) {
      _pagina = _paginas[i];
      escribir(_pie, 105, 286, tamano: 8, color: colorPie, alineacion: 0.5);
      if (_numerar) {
        escribir('Página ${i + 1} de ${_paginas.length}', derecha, 286,
            tamano: 8, color: colorPie, alineacion: 1);
      }
    }
    return _documento.save();
  }

  static String fecha(String? valor) {
    final limpio = valor?.trim();
    if (limpio == null || limpio.isEmpty || limpio == '-') return '—';
    final fecha = DateTime.tryParse(limpio)?.toUtc();
    if (fecha == null) return limpio;
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  double _desdeAbajo(double y) => PdfPageFormat.a4.height - y * _mm;

  void linea(double x1, double x2, double y, PdfColor color, double grosor) {
    _pagina
      ..setStrokeColor(color)
      ..setLineWidth(grosor * _mm)
      ..drawLine(x1 * _mm, _desdeAbajo(y), x2 * _mm, _desdeAbajo(y))
      ..strokePath();
  }

  void rectangulo(
    double x,
    double y,
    double ancho,
    double alto, {
    double radio = 0,
    PdfColor? fondo,
    PdfColor? borde,
  }) {
    if (fondo != null) _pagina.setColor(fondo);
    if (borde != null) {
      _pagina
        ..setStrokeColor(borde)
        ..setLineWidth(0.25 * _mm);
    }
    if (radio > 0) {
      _pagina.drawRRect(x * _mm, _desdeAbajo(y + alto), ancho * _mm, alto * _mm,
          radio * _mm, radio * _mm);
    } else {
      _pagina.drawRect(x * _mm, _desdeAbajo(y + alto), ancho * _mm, alto * _mm);
    }
    if (fondo == null) {
      _pagina.strokePath();
    } else if (borde == null) {
      _pagina.fillPath();
    } else {
      _pagina.fillAndStrokePath();
    }
  }

  void escribir(
    String contenido,
    double x,
    double y, {
    double tamano = 10,
    PdfColor color = texto,
    bool negrita = false,
    double alineacion = 0,
  }) {
    final fuente = negrita ? _negrita : _normal;
    final valor = _ansi(contenido);
    final inicio = x - _medir(valor, tamano, fuente) * alineacion;
    _pagina
      ..setColor(color)
      ..drawString(fuente, tamano, valor, inicio * _mm, _desdeAbajo(y));
  }

  double medir(String texto, double tamano, {bool negrita = false}) =>
      _medir(_ansi(texto), tamano, negrita ? _negrita : _normal);

  double _medir(String texto, double tamano, PdfFont fuente) =>
      fuente.stringMetrics(texto).advanceWidth * tamano / _mm;

  List<String> dividir(
    String texto,
    double ancho, {
    double tamano = 10,
    bool negrita = false,
  }) {
    double medirLinea(String linea) => medir(linea, tamano, negrita: negrita);
    final lineas = <String>[];
    for (final parrafo in texto.split(RegExp(r'\r?\n'))) {
      var actual = '';
      for (final palabra in parrafo.trim().split(RegExp(r'\s+'))) {
        final candidato = actual.isEmpty ? palabra : '$actual $palabra';
        if (medirLinea(candidato) <= ancho) {
          actual = candidato;
          continue;
        }
        if (actual.isNotEmpty) lineas.add(actual);
        actual = palabra;
        while (medirLinea(actual) > ancho) {
          var corte = 1;
          while (corte < actual.length &&
              medirLinea(actual.substring(0, corte + 1)) <= ancho) {
            corte++;
          }
          lineas.add(actual.substring(0, corte));
          actual = actual.substring(corte);
        }
      }
      lineas.add(actual);
    }
    return lineas;
  }

  // PDF usa Helvetica con WinAnsi, igual que el generador web.
  static String _ansi(String texto) {
    const simbolos = '€\u0000‚ƒ„…†‡ˆ‰Š‹Œ\u0000Ž\u0000'
        '\u0000‘’“”•–—˜™š›œ\u0000žŸ';
    return String.fromCharCodes(texto.runes.map((runa) {
      if (runa <= 0xff) return runa;
      final indice = simbolos.indexOf(String.fromCharCode(runa));
      return indice < 0 ? 0x3f : 0x80 + indice;
    }));
  }
}
