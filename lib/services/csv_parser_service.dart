import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import '../models/trade_record.dart';

class CsvParserService {
  static const expectedHeaders = ['Trade_ID', 'Amount', 'Client_Name'];

  /// Parses CSV bytes into a list of TradeRecord.
  /// - Expects headers including Trade_ID and Amount; Client_Name is optional.
  /// - Accepts commas and semicolons as separators.
  static Future<List<TradeRecord>> parseCsvBytes(Uint8List bytes) async {
    // Attempt to decode with UTF8; fall back to latin1 if needed.
    String content;
    try {
      content = utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final converter = CsvToListConverter(
      fieldDelimiter: _detectDelimiter(content),
      eol: _detectEol(content),
    );

    final rows = converter.convert(content);
    if (rows.isEmpty) return [];

    final headerRow = rows.first.map((e) => e.toString().trim()).toList();
    final idxTradeId = _findHeader(headerRow, 'Trade_ID');
    final idxAmount = _findHeader(headerRow, 'Amount');
    final idxClient = _findHeader(headerRow, 'Client_Name', optional: true);

    if (idxTradeId == -1 || idxAmount == -1) {
      throw const FormatException(
          'Missing required headers. Expected at least Trade_ID and Amount.');
    }

    final records = <TradeRecord>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final tradeId = row.length > idxTradeId ? row[idxTradeId].toString() : '';
      if (tradeId.isEmpty) continue;

      final amountRaw =
          row.length > idxAmount ? row[idxAmount].toString() : '0';
      final amount = _parseAmount(amountRaw);
      final clientName = (idxClient >= 0 && row.length > idxClient) 
          ? row[idxClient]?.toString() 
          : null;

      records.add(TradeRecord(tradeId: tradeId, amount: amount, clientName: clientName));
    }
    return records;
  }

  static String _detectDelimiter(String content) {
    // Simple heuristic: check first non-empty line
    final firstLine = content.split(RegExp(r'(\r\n|\n|\r)')).firstWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => ',',
    );
    final commaCount = RegExp(',').allMatches(firstLine).length;
    final semiCount = RegExp(';').allMatches(firstLine).length;
    return semiCount > commaCount ? ';' : ',';
  }

  static String _detectEol(String content) {
    if (content.contains('\r\n')) return '\r\n';
    if (content.contains('\r')) return '\r';
    return '\n';
  }

  static int _findHeader(List<String> headerRow, String key, {bool optional = false}) {
    final idx = headerRow.indexWhere(
        (h) => h.toLowerCase() == key.toLowerCase());
    if (idx == -1 && !optional) {
      return -1;
    }
    return idx;
    }

  static double _parseAmount(String raw) {
    // Remove thousands separators and normalize decimal separators
    final cleaned = raw
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(',', '')
        .replaceAll('\u00A0', '');
    return double.tryParse(cleaned) ??
        double.tryParse(raw.replaceAll(',', '.')) ??
        0.0;
  }
}

