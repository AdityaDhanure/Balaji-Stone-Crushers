import 'package:flutter/material.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool highlight;
  final Color? valueColor;

  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? AppColors.success
                  : valueColor ?? Colors.black87,
              fontSize: highlight ? 18 : bold ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
}