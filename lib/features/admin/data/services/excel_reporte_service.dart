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
  static List<int> generar({
    required String titulo,
    required List<String> headers,
    required List<List<String>> filas,
  }) {
    final excel = Excel.createExcel();

    // Excel.createExcel() ya trae una hoja "Sheet1" por defecto; creamos
    // la nuestra con el nombre del reporte y luego borramos la
    // sobrante para que quede una sola hoja limpia.
    final sheet = excel[titulo];
    final sheetPorDefectoExiste = excel.sheets.containsKey('Sheet1') && titulo != 'Sheet1';

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

    // Ancho de columna generoso para que el texto no quede cortado.
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 22);
    }

    if (sheetPorDefectoExiste) {
      excel.delete('Sheet1');
    }

    return excel.encode()!;
  }
}