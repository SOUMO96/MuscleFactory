import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Pulls plain text out of an uploaded file, based on its extension, as the
/// first step before PlanTextParser runs.
class FileTextExtractor {
  FileTextExtractor._();

  /// Keeps a single upload from loading an unbounded amount of data into
  /// memory on the device -- a real workout plan is at most a few KB of
  /// text; this is generous headroom, not a realistic plan size.
  static const _maxBytes = 15 * 1024 * 1024;

  static String extract({required Uint8List bytes, required String fileName}) {
    if (bytes.length > _maxBytes) {
      throw FormatException('That file is too large (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB). Please use a file under 15MB.');
    }
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return _fromPdf(bytes);
      case 'xlsx':
      case 'xls':
        return _fromExcel(bytes);
      case 'csv':
      case 'txt':
        // utf8.decode, not String.fromCharCodes, which mangles non-ASCII text.
        // allowMalformed tolerates stray bad bytes; a leading BOM (written by
        // Excel's CSV UTF-8 export) is stripped so it doesn't corrupt the header.
        final decoded = utf8.decode(bytes, allowMalformed: true);
        return decoded.startsWith('﻿') ? decoded.substring(1) : decoded;
      default:
        throw FormatException('Unsupported file type ".$ext". Use a .csv, .xlsx, or .pdf file.');
    }
  }

  static String _fromPdf(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  static String _fromExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    final buffer = StringBuffer();
    for (final table in workbook.tables.values) {
      final structured = _structuredRows(table.rows);
      if (structured != null) {
        buffer.write(structured);
        continue;
      }
      // No Day/Exercise header found: flatten to plain text and let the
      // free-text parser have a go.
      for (final row in table.rows) {
        final cells = row.map((c) => c?.value?.toString() ?? '').where((s) => s.isNotEmpty);
        if (cells.isEmpty) continue;
        buffer.writeln(cells.join(', '));
      }
    }
    return buffer.toString();
  }

  /// Handles tracking-log spreadsheets: a Day column, an Exercise column, and
  /// blank Weight/Reps or "SET n" columns to fill in later. There's no "4x8"
  /// text to match, so this reads the structure by header and emits
  /// "exercise setsxreps" lines. Uses the sheet's own numbers when present,
  /// otherwise a 3x10 default.
  static String? _structuredRows(List<List<Data?>> rows) {
    int? dayCol, exerciseCol, repsCol;
    var headerRowIndex = -1;
    for (var r = 0; r < rows.length && r < 10; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final text = rows[r][c]?.value?.toString().trim().toLowerCase() ?? '';
        if (text == 'day') dayCol = c;
        if (text.contains('exercise')) exerciseCol = c;
        if (text == 'reps') repsCol ??= c;
      }
      if (dayCol != null && exerciseCol != null) {
        headerRowIndex = r;
        break;
      }
    }
    if (headerRowIndex == -1 || dayCol == null || exerciseCol == null) return null;

    final buffer = StringBuffer();
    var currentDay = '';
    for (var r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      if (exerciseCol >= row.length) continue;
      final dayCell = dayCol < row.length ? row[dayCol]?.value?.toString().trim() ?? '' : '';
      if (dayCell.isNotEmpty && dayCell != currentDay) {
        currentDay = dayCell;
        // The day label goes on its own line so the parser sees a header; merged
        // onto the exercise line, every row would fall into one default day.
        buffer.writeln(currentDay);
      }
      final exerciseName = row[exerciseCol]?.value?.toString().trim() ?? '';
      if (exerciseName.isEmpty || currentDay.isEmpty) continue;

      // Filled numeric columns after the exercise count as sets; the reps column
      // supplies reps. A blank log falls back to the defaults.
      var setsFound = 0;
      String? repsFound;
      for (var c = exerciseCol + 1; c < row.length; c++) {
        final raw = row[c]?.value;
        if (raw == null) continue;
        final numeric = num.tryParse(raw.toString());
        if (numeric == null) continue;
        if (repsCol != null && c == repsCol) repsFound = numeric.toString();
        setsFound++;
      }
      final sets = setsFound > 0 ? setsFound : 3;
      final reps = repsFound ?? '10';
      buffer.writeln('$exerciseName ${sets}x$reps');
    }
    return buffer.isEmpty ? null : buffer.toString();
  }
}
