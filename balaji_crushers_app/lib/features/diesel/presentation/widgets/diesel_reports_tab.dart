import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/diesel_provider.dart';

class DieselReportsTab extends StatelessWidget {
  final List<PumpWisePayment> pumpPayments;

  const DieselReportsTab({super.key, required this.pumpPayments});

  @override
  Widget build(BuildContext context) {
    if (pumpPayments.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
            child: Icon(Icons.pie_chart_outline_rounded, size: 44, color: AppColors.primary.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        const Text('No report data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Pump-wise payments will appear here', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]));
    }

    final totalAmount = pumpPayments.fold<double>(0, (s, p) => s + p.totalAmount);
    final fmt = NumberFormat('#,##,###');

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pump-wise Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
              Text('${pumpPayments.length} pumps · ₹${fmt.format(totalAmount)} total', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
          ]),
        ),
        ...pumpPayments.map((pump) {
          final share = totalAmount > 0 ? pump.totalAmount / totalAmount : 0.0;
          final colors = [AppColors.primary, AppColors.info, AppColors.success, const Color(0xFF8E44AD), const Color(0xFFE67E22)];
          final color = colors[pump.pumpName.hashCode.abs() % colors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 3, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.local_gas_station_rounded, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pump.pumpName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${pump.purchases} purchases · ${pump.totalQuantity.toStringAsFixed(1)} L', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${fmt.format(pump.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                    Text('${(share * 100).toStringAsFixed(1)}% share', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}