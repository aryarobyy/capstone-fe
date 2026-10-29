import 'package:flutter/material.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../models/sensor_model.dart';

/// Reusable card component for displaying sensor details in the grid.
class SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Readable area name. Falls back to `Area <id>` when null.
  final String? areaName;

  const SensorCard({
    super.key,
    required this.sensor,
    this.onEdit,
    this.onDelete,
    this.areaName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCanvas, // Light gray neutral
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(Icons.memory, size: 48, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 8),
            // Sensor Title
            Text(
              sensor.name.isNotEmpty ? sensor.name : "Sensor ${sensor.id}",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle with Area Tag
            Row(
              children: [
                const Icon(Icons.eco_outlined, size: 12, color: AppColors.areaAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    areaName ?? "Area ${sensor.areaId}",
                    style: const TextStyle(
                      color: AppColors.areaAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action Buttons (Edit & Delete)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: "Edit",
                    onPressed: onEdit ?? () {},
                    backgroundColor: AppColors.actionEdit,
                    textColor: AppColors.textPrimary,
                    borderRadius: 16.0,
                    elevation: 0,
                    height: 28.0,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: "Delete",
                    onPressed: onDelete ?? () {},
                    backgroundColor: AppColors.actionDelete,
                    textColor: Colors.white,
                    borderRadius: 16.0,
                    elevation: 0,
                    height: 28.0,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
