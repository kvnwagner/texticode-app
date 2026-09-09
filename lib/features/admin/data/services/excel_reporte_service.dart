import 'package:excel/excel.dart';

/// Genera archivos .xlsx REALES (no CSV) para la pantalla de Reportes,
/// con el mismo lenguaje visual que ReportePdfService: encabezado en
/// navy con texto blanco en negrita, y filas zebra para que sea fácil
/// de leer al abrirlo en Excel/Sheets.
class ExcelReporteService {
  static const _navyHex = '#0F2236';
  static const _grisBgHex = '#F9FAFB';
  static const _blancoHex = '#FFFFFF';

  /// [titulo] se usa como nombre de la hoja (ej. "Pedidos").
  /// [headers]/[filas] arman la tabla — todo texto, tal como llega.
  /// [columnWidths] permite dar más espacio a columnas de texto largo
  /// (ej. "Producto"/"Cliente") y menos a columnas cortas (ej.
  /// "Progreso"/"Stock"). Si no se pasa, o su largo no coincide con
  /// [headers], se usa 22 para todas como antes.
  static List<int> generar({
    required String titulo,
    required List<String> headers,
    required List<List<String>> filas,
    List<double>? columnWidths,
  }) {
    final excel = Excel.createExcel();

    // ⚠️ Antes se creaba la hoja con excel[titulo] y al final se borraba
    // la hoja por defecto 'Sheet1' con excel.delete('Sheet1'). El método
    // delete() de este paquete tiene bugs conocidos que corrompen las
    // referencias internas del archivo — el estilo del encabezado
    // sobrevive (se guarda distinto) pero las filas de datos quedan
    // vacías al abrir el .xlsx en Excel real. La forma segura de tener
    // una sola hoja con el nombre del reporte es RENOMBRAR la hoja por
    // defecto en vez de crear una nueva y borrar la sobrante.
    final nombreHojaOriginal = excel.getDefaultSheet() ?? 'Sheet1';
    if (nombreHojaOriginal != titulo) {
      excel.rename(nombreHojaOriginal, titulo);
    }
    final sheet = excel[titulo];

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString(_blancoHex),
      backgroundColorHex: ExcelColor.fromHexString(_navyHex),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final zebraStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString(_grisBgHex),
    );

    // ── Fila de encabezados ──
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(0, 22);

    // ── Filas de datos, con zebra en las filas impares ──
    for (var row = 0; row < filas.length; row++) {
      final esImpar = row % 2 == 1;
      for (var col = 0; col < filas[row].length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
        );
        cell.value = TextCellValue(filas[row][col]);
        if (esImpar) cell.cellStyle = zebraStyle;
      }
    }

    // Ancho de columna: usa el valor dado por columna si viene, si no
    // cae al 22 genérico de antes.
    final anchosValidos = columnWidths != null && columnWidths.length == headers.length;
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, anchosValidos ? columnWidths[col] : 22);
    }

    return excel.encode()!;
  }
}