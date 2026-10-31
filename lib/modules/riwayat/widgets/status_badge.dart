import 'package:flutter/material.dart';
import '../../../utils/colorScheme.dart';

/// Coloured pill for an alert status string coming from the history API.
///
/// Backend sends uppercase values (`FATAL`, `CRITICAL`, `WARNING`,
/// `NORMAL`/`RESOLVED`); matching is case-insensitive so a casing change
/// server-side degrades to the neutral style instead of throwing.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final label = status.isEmpty ? '-' : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  static Color _colorFor(String status) {
    switch (status.toUpperCase()) {
      case 'FATAL':
      case 'CRITICAL':
        return AppColors.error;
      case 'WARNING':
        return AppColors.warning;
      case 'NORMAL':
      case 'RESOLVED':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
