import 'package:flutter/material.dart';
import '../models/trade_record.dart';

class ResultsTable extends StatefulWidget {
  final List<ReconciliationRow> rows;

  const ResultsTable({super.key, required this.rows});

  @override
  State<ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> {
  late List<ReconciliationRow> _sortedRows;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _sortedRows = List.of(widget.rows);
  }

  @override
  void didUpdateWidget(covariant ResultsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _sortedRows = List.of(widget.rows);
      _applySort();
    }
  }

  void _applySort() {
    if (_sortColumnIndex == null) {
      return;
    }
    switch (_sortColumnIndex) {
      case 0:
        _sortedRows.sort((a, b) {
          final cmp = a.tradeId.compareTo(b.tradeId);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case 1:
        _sortedRows.sort((a, b) {
          final aVal = a.amountFileA ?? 0;
          final bVal = b.amountFileA ?? 0;
          final cmp = aVal.compareTo(bVal);
          return _sortAscending ? cmp : -cmp;
        });
        break;
      case 2:
        _sortedRows.sort((a, b) {
          final aVal = a.amountFileB ?? 0;
          final bVal = b.amountFileB ?? 0;
          final cmp = aVal.compareTo(bVal);
          return _sortAscending ? cmp : -cmp;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final columns = <DataColumn>[
              DataColumn(
                label: const Text('Trade_ID'),
                onSort: (index, ascending) {
                  setState(() {
                    _sortColumnIndex = index;
                    _sortAscending = ascending;
                    _applySort();
                  });
                },
              ),
              DataColumn(
                label: const Text('Amount_File_A'),
                numeric: true,
                onSort: (index, ascending) {
                  setState(() {
                    _sortColumnIndex = index;
                    _sortAscending = ascending;
                    _applySort();
                  });
                },
              ),
              DataColumn(
                label: const Text('Amount_File_B'),
                numeric: true,
                onSort: (index, ascending) {
                  setState(() {
                    _sortColumnIndex = index;
                    _sortAscending = ascending;
                    _applySort();
                  });
                },
              ),
              const DataColumn(label: Text('Status')),
            ];

            final dataRows = _sortedRows.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              final statusChip = _statusChip(r.status, context);
              final isEven = index.isEven;
              return DataRow(
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);
                  }
                  if (isEven) {
                    return Theme.of(context).colorScheme.surface;
                  }
                  return Theme.of(context).colorScheme.surface.withValues(alpha: 0.96);
                }),
                cells: [
                  DataCell(Text(r.tradeId)),
                  DataCell(Text(r.amountFileA?.toStringAsFixed(2) ?? '')),
                  DataCell(Text(r.amountFileB?.toStringAsFixed(2) ?? '')),
                  DataCell(statusChip),
                ],
              );
            }).toList();

            final table = DataTable(
              columns: columns,
              rows: dataRows.toList(),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor:
                  WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
              headingTextStyle: Theme.of(context).textTheme.labelLarge,
              dataTextStyle: Theme.of(context).textTheme.bodyMedium,
              columnSpacing: isWide ? 32 : 16,
            );

            return Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: table,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(ReconciliationStatus status, BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case ReconciliationStatus.matched:
        color = Colors.green;
        label = 'Matched';
        break;
      case ReconciliationStatus.missingInA:
        color = Colors.orange;
        label = 'Missing in File A';
        break;
      case ReconciliationStatus.missingInB:
        color = Colors.orange;
        label = 'Missing in File B';
        break;
      case ReconciliationStatus.amountMismatch:
        color = Colors.red;
        label = 'Amount mismatch';
        break;
    }
    final backgroundColor = color.withValues(alpha: 0.1);
    final borderColor = color.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

