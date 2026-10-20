import 'package:flutter/material.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../models/area_model.dart';

/// Reusable card component for displaying individual area information.
class AreaCard extends StatelessWidget {
  final AreaModel area;
  final VoidCallback? onDetailTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Sensor count to display. Falls back to `area.sensorsCount` when null.
  final int? sensorsCount;

  const AreaCard({
    super.key,
    required this.area,
    this.onDetailTap,
    this.onEdit,
    this.onDelete,
    this.sensorsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Title and check icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                area.name.isNotEmpty ? area.name : "Area ${area.id}",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppColors.accentGreen,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                Icons.sensors,
                "Total Sensor",
                "${sensorsCount ?? area.sensorsCount}",
              ),
              AppButton(
                text: "Detail",
                onPressed: onDetailTap ?? () {},
                backgroundColor: AppColors.areaAccent,
                textColor: Colors.white,
                borderRadius: 20.0,
                elevation: 0,
                height: 32.0,
                isFullWidth: false,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ],
          ),
          // Action Buttons (Edit & Delete), same treatment as SensorCard.
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: AppButton(
                      text: "Edit",
                      onPressed: onEdit!,
                      backgroundColor: AppColors.actionEdit,
                      textColor: AppColors.textPrimary,
                      borderRadius: 16.0,
                      elevation: 0,
                      height: 32.0,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 8),
                if (onDelete != null)
                  Expanded(
                    child: AppButton(
                      text: "Delete",
                      onPressed: onDelete!,
                      backgroundColor: AppColors.actionDelete,
                      textColor: Colors.white,
                      borderRadius: 16.0,
                      elevation: 0,
                      height: 32.0,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
