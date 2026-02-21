class TradeRecord {
  final String tradeId;
  final double amount;
  final String? clientName;

  const TradeRecord({
    required this.tradeId,
    required this.amount,
    this.clientName,
  });
}

enum ReconciliationStatus {
  matched,
  missingInA,
  missingInB,
  amountMismatch,
}

class ReconciliationRow {
  final String tradeId;
  final double? amountFileA;
  final double? amountFileB;
  final ReconciliationStatus status;

  const ReconciliationRow({
    required this.tradeId,
    required this.amountFileA,
    required this.amountFileB,
    required this.status,
  });
}

class ReconciliationSummary {
  final int totalA;
  final int totalB;
  final int totalMatched;
  final int totalMismatched;
  final int totalMissing;

  const ReconciliationSummary({
    required this.totalA,
    required this.totalB,
    required this.totalMatched,
    required this.totalMismatched,
    required this.totalMissing,
  });
}

