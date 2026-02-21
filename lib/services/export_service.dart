import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart';

import '../models/trade_record.dart';

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);
  
  @override
  String toString() => 'ExportException: $message';
}

class ExportService {
  /// Generates CSV bytes for the reconciliation results.
  static Uint8List buildCsvBytes(List<ReconciliationRow> rows) {
    final buffer = StringBuffer();
    buffer.writeln('Trade_ID,Amount_File_A,Amount_File_B,Status');
    for (final r in rows) {
      final a = r.amountFileA?.toStringAsFixed(2) ?? '';
      final b = r.amountFileB?.toStringAsFixed(2) ?? '';
      buffer.writeln('${r.tradeId},$a,$b,${r.status.name}');
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Generates Excel bytes for the reconciliation results.
  static Uint8List buildExcelBytes(List<ReconciliationRow> rows) {
    final excel = Excel.createExcel();
    final sheet = excel['Reconciliation'];

    sheet.appendRow([
      TextCellValue('Trade_ID'),
      TextCellValue('Amount_File_A'),
      TextCellValue('Amount_File_B'),
      TextCellValue('Status'),
    ]);

    for (final r in rows) {
      sheet.appendRow([
        TextCellValue(r.tradeId),
        TextCellValue(r.amountFileA?.toStringAsFixed(2) ?? ''),
        TextCellValue(r.amountFileB?.toStringAsFixed(2) ?? ''),
        TextCellValue(r.status.name),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw const ExportException('Failed to encode Excel document.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Prompts user to save a CSV file with the reconciliation results.
  /// Throws [ExportException] if the save operation fails.
  static Future<void> saveCsv(List<ReconciliationRow> rows) async {
    try {
      final bytes = buildCsvBytes(rows);
      await FileSaver.instance.saveFile(
        name: 'reconciliation_results',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
    } catch (e) {
      throw ExportException('Failed to save CSV file: $e');
    }
  }

  /// Prompts user to save an Excel file with the reconciliation results.
  /// Throws [ExportException] if the save operation fails.
  static Future<void> saveExcel(List<ReconciliationRow> rows) async {
    try {
      final bytes = buildExcelBytes(rows);
      await FileSaver.instance.saveFile(
        name: 'reconciliation_results',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      throw ExportException('Failed to save Excel file: $e');
    }
  }
}
