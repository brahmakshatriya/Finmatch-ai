import 'package:collection/collection.dart';

import '../models/trade_record.dart';

class ReconciliationResult {
  final List<ReconciliationRow> rows;
  final ReconciliationSummary summary;

  const ReconciliationResult({required this.rows, required this.summary});
}

class ReconciliationService {
  /// Compares two lists of TradeRecord by Trade_ID and Amount.
  /// Returns row-level results and an aggregate summary.
  static ReconciliationResult reconcile({
    required List<TradeRecord> fileA,
    required List<TradeRecord> fileB,
  }) {
    final mapA = groupBy(fileA, (TradeRecord r) => r.tradeId)
        .map((k, v) => MapEntry(k, v.first));
    final mapB = groupBy(fileB, (TradeRecord r) => r.tradeId)
        .map((k, v) => MapEntry(k, v.first));

    final allIds = <String>{...mapA.keys, ...mapB.keys}.toList()..sort();
    final rows = <ReconciliationRow>[];
    var matched = 0;
    var mismatched = 0;
    var missing = 0;

    for (final id in allIds) {
      final recA = mapA[id];
      final recB = mapB[id];

      if (recA == null && recB != null) {
        rows.add(ReconciliationRow(
          tradeId: id,
          amountFileA: null,
          amountFileB: recB.amount,
          status: ReconciliationStatus.missingInA,
        ));
        missing++;
      } else if (recA != null && recB == null) {
        rows.add(ReconciliationRow(
          tradeId: id,
          amountFileA: recA.amount,
          amountFileB: null,
          status: ReconciliationStatus.missingInB,
        ));
        missing++;
      } else if (recA != null && recB != null) {
        if (_amountEqual(recA.amount, recB.amount)) {
          rows.add(ReconciliationRow(
            tradeId: id,
            amountFileA: recA.amount,
            amountFileB: recB.amount,
            status: ReconciliationStatus.matched,
          ));
          matched++;
        } else {
          rows.add(ReconciliationRow(
            tradeId: id,
            amountFileA: recA.amount,
            amountFileB: recB.amount,
            status: ReconciliationStatus.amountMismatch,
          ));
          mismatched++;
        }
      }
    }

    final summary = ReconciliationSummary(
      totalA: fileA.length,
      totalB: fileB.length,
      totalMatched: matched,
      totalMismatched: mismatched,
      totalMissing: missing,
    );

    return ReconciliationResult(rows: rows, summary: summary);
  }

  static bool _amountEqual(double a, double b, {double tolerance = 1e-9}) {
    return (a - b).abs() <= tolerance;
  }
}

