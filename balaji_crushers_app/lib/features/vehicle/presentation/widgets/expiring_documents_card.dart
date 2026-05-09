import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ExpiringDocumentsCard extends StatelessWidget {
  final List<dynamic> expiringDocuments;
  final Function(int) onDocumentTap;

  const ExpiringDocumentsCard({super.key, required this.expiringDocuments, required this.onDocumentTap});

  @override
  Widget build(BuildContext context) {
    if (expiringDocuments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 16)),
          const SizedBox(width: 10),
          const Expanded(child: Text('All vehicle documents are up to date', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500))),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16)),
            const SizedBox(width: 10),
            const Expanded(child: Text('Document Expiry Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
              child: Text('${expiringDocuments.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: expiringDocuments.length > 6 ? 6 : expiringDocuments.length,
              itemBuilder: (_, i) {
                final v = expiringDocuments[i];
                return GestureDetector(
                  onTap: () => onDocumentTap(v['id'] as int),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_rounded, color: AppColors.warning, size: 13),
                      const SizedBox(width: 5),
                      Text(v['vehicle_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}