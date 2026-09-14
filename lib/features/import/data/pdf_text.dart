import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Lo que sale de un PDF: sus líneas de texto en orden de lectura y cuántas
/// páginas tenía. `lines` vacío con `pages > 0` es un PDF escaneado como
/// imagen: hay páginas pero no hay texto que leer.
class PdfTextResult {
  const PdfTextResult({required this.lines, required this.pages});

  final List<String> lines;
  final int pages;

  bool get hasText => lines.any((l) => l.trim().isNotEmpty);
}

/// Se lanza cuando el archivo no es un PDF legible (dañado, cifrado, o no es
/// un PDF).
class PdfUnreadableException implements Exception {
  const PdfUnreadableException(this.cause);
  final Object cause;

  @override
  String toString() => 'PdfUnreadableException: $cause';
}

/// Extrae el texto en el teléfono. Syncfusion es Dart puro, así que corre en
/// un isolate con `compute` y la interfaz no se congela con un PDF gordo.
abstract final class PdfText {
  static Future<PdfTextResult> extract(Uint8List bytes) => compute(_extract, bytes);

  static PdfTextResult _extract(Uint8List bytes) {
    final PdfDocument doc;
    try {
      doc = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw PdfUnreadableException(e);
    }
    try {
      final pages = doc.pages.count;
      final textLines = PdfTextExtractor(doc).extractTextLines();

      // Orden de lectura: página, luego de arriba abajo, luego de izquierda a
      // derecha. El extractor ya agrupa por renglón; solo hay que ordenarlos.
      textLines.sort((a, b) {
        if (a.pageIndex != b.pageIndex) return a.pageIndex.compareTo(b.pageIndex);
        final dy = a.bounds.top.compareTo(b.bounds.top);
        if (dy != 0) return dy;
        return a.bounds.left.compareTo(b.bounds.left);
      });

      var lines = textLines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).toList();

      // Algunos PDF no traen estructura de renglón y el extractor devuelve una
      // sola línea por página. En ese caso el texto plano parte mejor.
      if (lines.length <= pages) {
        final plain = PdfTextExtractor(doc).extractText(layoutText: true);
        final split = plain.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        if (split.length > lines.length) lines = split;
      }

      return PdfTextResult(lines: lines, pages: pages);
    } finally {
      doc.dispose();
    }
  }
}
