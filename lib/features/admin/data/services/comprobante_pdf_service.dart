import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../models/comprobante_model.dart';
import '../models/orden_model.dart';
import '../models/usuario_model.dart';
import 'documento_pdf.dart';

class ComprobantePdfService {
  static Future<Uint8List> generar({
    required Comprobante comprobante,
    Orden? orden,
    Usuario? cliente,
    List<String> detalles = const [],
  }) async {
    final usuario = await AuthRepository().getUsuarioGuardado();
    final pdf = _ComprobantePdf(await DocumentoPdf.crear(
      titulo: 'Comprobante de entrega',
      subtitulo: 'N.º ${comprobante.numero}',
      pie: 'Documento de uso oficial · TEXTICODE S.A.S.',
    ));
    pdf.dibujar(
      empresa: usuario?.empresa,
      referencia: comprobante.referenciaOrden,
      estado: orden?.estado ?? comprobante.estadoPedido,
      entregado: (orden?.isCompletada ?? comprobante.isCompletado) ||
          comprobante.estado.toLowerCase() == 'entregado',
      cliente: cliente?.nombreCompleto ?? comprobante.cliente,
      correo: cliente?.correo,
      telefono: cliente?.telefono,
      fechaLimite: orden?.fechaLimite ?? comprobante.fechaLimite,
      producto: orden?.producto ?? comprobante.ordenProducto,
      descripcion: orden?.descripcion ?? comprobante.ordenDescripcion,
      cantidad: orden?.cantidadTotal ?? comprobante.ordenCantidad,
      observaciones: orden?.observaciones,
      detalles: detalles,
    );
    return pdf.documento.guardar();
  }
}

class _ComprobantePdf {
  static const _izquierda = DocumentoPdf.izquierda;
  static const _ancho = DocumentoPdf.ancho;
  static const _limite = DocumentoPdf.limite;
  static const _gris = DocumentoPdf.gris;
  static const _textoTabla = DocumentoPdf.textoTabla;

  final DocumentoPdf documento;
  late double _y;

  _ComprobantePdf(this.documento);

  void dibujar({
    required String? empresa,
    required String referencia,
    required String estado,
    required bool entregado,
    required String cliente,
    required String? correo,
    required String? telefono,
    required String? fechaLimite,
    required String? producto,
    required String? descripcion,
    required int? cantidad,
    required String? observaciones,
    required List<String> detalles,
  }) {
    final colorEstado = entregado
        ? const PdfColor.fromInt(0xFF166534)
        : const PdfColor.fromInt(0xFF92400E);
    final fondoEstado = entregado
        ? const PdfColor.fromInt(0xFFDCFCE7)
        : const PdfColor.fromInt(0xFFFEF3C7);

    _y = documento.nuevaPagina();
    final contacto = telefono?.trim();
    _y = math.max(
      _campo(
          'CLIENTE',
          [
            cliente,
            correo,
            if (contacto != null && contacto.isNotEmpty && contacto != '-')
              'Tel: $contacto',
          ],
          _izquierda),
      _campo('ORDEN DE REFERENCIA', [referencia], 110),
    );
    _y = math.max(
      _campo('FECHA DE GENERACIÓN',
          [DocumentoPdf.fecha(DateTime.now().toIso8601String())], _izquierda),
      _campo('FECHA LÍMITE DE ENTREGA', [DocumentoPdf.fecha(fechaLimite)], 110),
    );

    _asegurarEspacio(14);
    documento.escribir('ESTADO DEL PEDIDO', _izquierda, _y,
        tamano: 8, color: _gris, negrita: true);
    final anchoEstado = documento.medir(estado, 10, negrita: true) + 7;
    documento.rectangulo(_izquierda, _y + 2, anchoEstado, 6,
        radio: 3, fondo: fondoEstado);
    documento.escribir(estado, _izquierda + 3.5, _y + 6.2,
        color: colorEstado, negrita: true);
    _y += 14;

    final nombre = _valor(producto) ?? _valor(descripcion) ?? '—';
    final lineas = [
      nombre,
      if (_valor(descripcion) case final String valor when valor != nombre)
        valor,
      ...detalles,
    ].expand((parrafo) => documento.dividir(parrafo, 105)).toList();
    _asegurarEspacio(20);
    _encabezadoTabla();
    for (var inicio = 0; inicio < lineas.length;) {
      final capacidad = ((_limite - _y - 5) / 4.4).floor();
      final fin = math.min(inicio + capacidad, lineas.length);
      final alto = (fin - inicio) * 4.4 + 5;
      documento.rectangulo(_izquierda, _y, _ancho, alto,
          borde: DocumentoPdf.borde);
      for (var i = inicio; i < fin; i++) {
        documento.escribir(lineas[i], 32, _y + 5 + (i - inicio) * 4.4);
      }
      if (inicio == 0) {
        documento.escribir('1', 21, _y + 5);
        documento.escribir(cantidad?.toString() ?? '—', 148, _y + 5,
            alineacion: 0.5);
        documento.escribir(entregado ? 'Entregado' : 'Pendiente', 188, _y + 5,
            tamano: 9, color: colorEstado, negrita: true, alineacion: 1);
      }
      _y += alto;
      inicio = fin;
      if (inicio < lineas.length) {
        _y = documento.nuevaPagina();
        _encabezadoTabla();
      }
    }

    _y += 9;
    _asegurarEspacio(14);
    documento.escribir('OBSERVACIONES', _izquierda, _y,
        tamano: 8, color: _gris, negrita: true);
    _y += 6;
    for (final linea in documento.dividir(
      _valor(observaciones) ?? 'Ninguna observación registrada.',
      _ancho,
    )) {
      _asegurarEspacio(5);
      documento.escribir(linea, _izquierda, _y, color: _textoTabla);
      _y += 4.4;
    }

    final firmas = [_valor(empresa) ?? '—', _valor(cliente) ?? '—']
        .map((nombre) => documento.dividir(nombre, 77, negrita: true))
        .toList();
    _asegurarEspacio(23 + math.max(firmas[0].length, firmas[1].length) * 4.4);
    _y += 15;
    for (var i = 0; i < firmas.length; i++) {
      final x = i == 0 ? 57.0 : 153.0;
      documento.linea(
          x - 40, x + 40, _y, const PdfColor.fromInt(0xFF9CA3AF), 0.25);
      documento.escribir(i == 0 ? 'Entregado por' : 'Recibido por', x, _y + 5,
          tamano: 9, color: _gris, alineacion: 0.5);
      for (var j = 0; j < firmas[i].length; j++) {
        documento.escribir(firmas[i][j], x, _y + 10 + j * 4.4,
            negrita: true, alineacion: 0.5);
      }
    }
  }

  double _campo(String titulo, List<String?> valores, double x) {
    documento.escribir(titulo, x, _y, tamano: 8, color: _gris, negrita: true);
    final lineas = valores
        .map(_valor)
        .whereType<String>()
        .expand((valor) => documento.dividir(valor, 81))
        .toList();
    if (lineas.isEmpty) lineas.add('—');
    for (var i = 0; i < lineas.length; i++) {
      documento.escribir(lineas[i], x, _y + 5 + i * 4.4);
    }
    return _y + lineas.length * 4.5 + 8;
  }

  void _encabezadoTabla() {
    documento.rectangulo(_izquierda, _y, _ancho, 9,
        radio: 2, fondo: DocumentoPdf.fondoTabla, borde: DocumentoPdf.borde);
    documento.escribir('#', 21, _y + 5.8,
        tamano: 9, color: _textoTabla, negrita: true);
    documento.escribir('Descripción del producto / servicio', 32, _y + 5.8,
        tamano: 9, color: _textoTabla, negrita: true);
    documento.escribir('Cantidad', 148, _y + 5.8,
        tamano: 9, color: _textoTabla, negrita: true, alineacion: 0.5);
    documento.escribir('Estado entrega', 188, _y + 5.8,
        tamano: 9, color: _textoTabla, negrita: true, alineacion: 1);
    _y += 9;
  }

  void _asegurarEspacio(double alto) {
    if (_y + alto > _limite) _y = documento.nuevaPagina();
  }

  static String? _valor(String? valor) {
    final limpio = valor?.trim();
    return limpio == null || limpio.isEmpty || limpio == '-' ? null : limpio;
  }
}
