import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/trade_record.dart';
import '../services/csv_parser_service.dart';
import '../services/reconciliation_service.dart';
import '../services/export_service.dart';
import '../widgets/results_table.dart';
import '../widgets/summary_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _fileABytes;
  Uint8List? _fileBBytes;
  String? _fileAName;
  String? _fileBName;

  ReconciliationResult? _result;
  bool _isProcessing = false;
  String? _error;
  _ReconciliationFilter _filter = _ReconciliationFilter.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trade Reconciliation System',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'Settlement Utility Tool',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControls(isWide),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ),
                    if (_result != null) ...[
                      SummaryPanel(
                        summary: _result!.summary,
                        fileAName: _fileAName,
                        fileBName: _fileBName,
                      ),
                      const SizedBox(height: 12),
                      _buildFiltersAndSearch(isWide),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ResultsTable(rows: _filteredRows),
                      ),
                    ] else
                      Expanded(
                        child: Center(
                          child: Text(
                            'Upload File A and File B to begin reconciliation.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '© 2026 Settlement Utility Tool by Brahmakshatriya',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildControls(bool isWide) {
    final buttons = [
      _buildUploadButton(label: 'Upload File A', onTap: () => _pickFile(isFileA: true), fileName: _fileAName),
      _buildUploadButton(label: 'Upload File B', onTap: () => _pickFile(isFileA: false), fileName: _fileBName),
      FilledButton.icon(
        onPressed: _canReconcile && !_isProcessing ? _runReconciliation : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Reconciliation'),
      ),
      OutlinedButton.icon(
        onPressed: _result?.rows.isNotEmpty == true ? _exportResults : null,
        icon: const Icon(Icons.download),
        label: const Text('Export Report'),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (final b in buttons) ...[
            b,
            const SizedBox(width: 12),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buttons) ...[
          b,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildUploadButton({required String label, required VoidCallback onTap, String? fileName}) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : onTap,
      icon: const Icon(Icons.upload_file),
      label: Text(fileName == null ? label : '$label: $fileName'),
    );
  }

  bool get _canReconcile => _fileABytes != null && _fileBBytes != null;

  List<ReconciliationRow> get _filteredRows {
    if (_result == null) {
      return [];
    }
    Iterable<ReconciliationRow> rows = _result!.rows;
    switch (_filter) {
      case _ReconciliationFilter.matched:
        rows = rows.where((r) => r.status == ReconciliationStatus.matched);
        break;
      case _ReconciliationFilter.mismatched:
        rows = rows.where((r) => r.status == ReconciliationStatus.amountMismatch);
        break;
      case _ReconciliationFilter.missing:
        rows = rows.where((r) =>
            r.status == ReconciliationStatus.missingInA ||
            r.status == ReconciliationStatus.missingInB);
        break;
      case _ReconciliationFilter.all:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      rows = rows.where((r) => r.tradeId.toLowerCase().contains(q));
    }
    return rows.toList();
  }

  Future<void> _pickFile({required bool isFileA}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        setState(() => _error = 'Selected file has no readable data. Please choose a different CSV.');
        return;
      }
      setState(() {
        _error = null;
        if (isFileA) {
          _fileABytes = file.bytes;
          _fileAName = file.name;
        } else {
          _fileBBytes = file.bytes;
          _fileBName = file.name;
        }
        _result = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick file: $e');
    }
  }

  Future<void> _runReconciliation() async {
    if (!_canReconcile) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final recordsA = await CsvParserService.parseCsvBytes(_fileABytes!);
      final recordsB = await CsvParserService.parseCsvBytes(_fileBBytes!);
      final result = ReconciliationService.reconcile(fileA: recordsA, fileB: recordsB);
      setState(() {
        _result = result;
      });
    } catch (e) {
      String message;
      if (e is FormatException &&
          e.message.contains('Missing required headers')) {
        message =
            'The selected files must include the columns Trade_ID and Amount.';
      } else {
        message =
            'Reconciliation failed. Please verify that both files are valid CSVs with Trade_ID and Amount columns.';
      }
      setState(() => _error = message);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reconciliation Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildFiltersAndSearch(bool isWide) {
    final filterButtons = [
      _buildFilterChip('Show All', _ReconciliationFilter.all),
      _buildFilterChip('Show Matched', _ReconciliationFilter.matched),
      _buildFilterChip('Show Mismatched', _ReconciliationFilter.mismatched),
      _buildFilterChip('Show Missing', _ReconciliationFilter.missing),
    ];

    final searchField = Expanded(
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search by Trade_ID',
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Wrap(
            spacing: 8,
            children: filterButtons,
          ),
          const SizedBox(width: 16),
          searchField,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filterButtons,
        ),
        const SizedBox(height: 8),
        searchField,
      ],
    );
  }

  Widget _buildFilterChip(String label, _ReconciliationFilter value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing reconciliation...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportResults() async {
    if (_result == null) return;
    try {
      final format = await showDialog<_ExportFormat>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Export Reconciliation Report'),
            content: const Text(
              'Are you sure you want to export the reconciliation report?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_ExportFormat.csv),
                child: const Text('Export as CSV'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_ExportFormat.excel),
                child: const Text('Export as Excel (.xlsx)'),
              ),
            ],
          );
        },
      );
      if (format == null) return;

      if (format == _ExportFormat.csv) {
        await ExportService.saveCsv(_result!.rows);
      } else {
        await ExportService.saveExcel(_result!.rows);
      }
    } catch (e) {
      setState(() => _error = 'Failed to export results: $e');
    }
  }
}

enum _ReconciliationFilter {
  all,
  matched,
  mismatched,
  missing,
}

enum _ExportFormat {
  csv,
  excel,
}
