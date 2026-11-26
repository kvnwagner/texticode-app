import 'package:excel/excel.dart';

/// Genera archivos .xlsx REALES (no CSV) para la pantalla de Reportes,
/// con el mismo lenguaje visual que ReportePdfService: encabezado en
/// navy con texto blanco en negrita, y filas zebra para que sea fácil
/// de leer al abrirlo en Excel/Sheets.
class ExcelReporteService {
  static const _navyHex = '#0F2236';
  static const _grisBgHex = '#F9FAFB';
  static const _blancoHex = '#FFFFFF';

  // Mismos 3 estados y mismos tonos que ya usa Reportes.vue en la web
  // (verde/naranja/rojo pastel), para que el PDF/Excel se vea igual
  // sin importar desde dónde se genere.
  static const Map<String, List<String>> _estadoColores = {
    'Completada': ['#D1FAE5', '#065F46'],
    'En Proceso': ['#FEF3C7', '#92400E'],
    'Retrasada':  ['#FEE2E2', '#991B1B'],
  };

  /// [titulo] se usa como nombre de la hoja (ej. "Pedidos").
  /// [headers]/[filas] arman la tabla — todo texto, tal como llega.
  /// [columnWidths] permite dar más espacio a columnas de texto largo
  /// (ej. "Producto"/"Cliente") y menos a columnas cortas (ej.
  /// "Progreso"/"Stock"). Si no se pasa, o su largo no coincide con
  /// [headers], se usa 22 para todas como antes.
  /// [estadoColumnIndex] es el índice (0-based) de la columna "Estado"
  /// dentro de [headers]/cada fila. Cuando se pasa, esa columna se
  /// pinta según el valor (Completada/En Proceso/Retrasada) en vez de
  /// usar el zebra genérico. Pásalo null si el reporte no tiene una
  /// columna de estado (ej. Eficiencia, Inventario).
  static List<int> generar({
    required String titulo,
    required List<String> headers,
    required List<List<String>> filas,
    List<double>? columnWidths,
    int? estadoColumnIndex,
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

    // ── Filas de datos, con zebra en las filas impares — salvo la
    // columna de Estado, que se pinta según su valor. ──
    for (var row = 0; row < filas.length; row++) {
      final esImpar = row % 2 == 1;
      for (var col = 0; col < filas[row].length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
        );
        final valor = filas[row][col];
        cell.value = TextCellValue(valor);

        final colores = (estadoColumnIndex != null && col == estadoColumnIndex)
            ? _estadoColores[valor]
            : null;
        if (colores != null) {
          cell.cellStyle = CellStyle(
            bold: true,
            fontColorHex: ExcelColor.fromHexString(colores[1]),
            backgroundColorHex: ExcelColor.fromHexString(colores[0]),
            horizontalAlign: HorizontalAlign.Center,
          );
        } else if (esImpar) {
          cell.cellStyle = zebraStyle;
        }
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