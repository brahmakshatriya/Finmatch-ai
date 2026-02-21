import 'package:flutter/material.dart';

import '../models/trade_record.dart';

class SummaryPanel extends StatelessWidget {
  final ReconciliationSummary summary;
  final String? fileAName;
  final String? fileBName;

  const SummaryPanel({
    super.key,
    required this.summary,
    this.fileAName,
    this.fileBName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tiles = [
              _metricTile('Total in File A', summary.totalA.toString(), Icons.upload_file, colorScheme.primary),
              _metricTile('Total in File B', summary.totalB.toString(), Icons.upload_file, colorScheme.primary),
              _metricTile('Matched', summary.totalMatched.toString(), Icons.check_circle, Colors.green),
              _metricTile('Mismatched', summary.totalMismatched.toString(), Icons.error_outline, Colors.red),
              _metricTile('Missing', summary.totalMissing.toString(), Icons.warning_amber, Colors.orange),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fileAName != null || fileBName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'File A: ${fileAName ?? '-'}   |   File B: ${fileBName ?? '-'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: tiles,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color) {
    final backgroundColor = color.withValues(alpha: 0.06);
    final borderColor = color.withValues(alpha: 0.2);
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
