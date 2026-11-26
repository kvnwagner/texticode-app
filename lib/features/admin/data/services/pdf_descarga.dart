import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class PdfDescarga {
  static const _canal = MethodChannel('texticode/archivos');

  static Future<bool> guardar(Uint8List bytes, String nombre) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _canal.invokeMethod<bool>('guardarPdf', {
            'bytes': bytes,
            'nombre': nombre,
          }) ??
          false;
    }

    return Printing.sharePdf(bytes: bytes, filename: nombre);
  }
}
