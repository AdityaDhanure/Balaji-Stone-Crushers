import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/diesel_provider.dart';


class DieselStockCard extends StatelessWidget {
  final DieselStockOverview stock;

  const DieselStockCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    final fmt = NumberFormat('#,##,###');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF1E6B3C), Color(0xFF145A32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF1E6B3C).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(top: -30, right: -20, child: _circle(120, 0.07)),
          Positioned(bottom: -40, right: 60, child: _circle(100, 0.05)),
          Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Diesel Management', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('${stock.currentStock.toStringAsFixed(1)} L in stock', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ]),
                ]),
                SizedBox(height: isSmall ? 14 : 18),
                isSmall
                    ? Column(children: [
                        Row(children: [
                          Expanded(child: _Chip(label: 'Stock', value: '${stock.currentStock.toStringAsFixed(1)} L', icon: Icons.inventory_2_rounded, isHighlight: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _Chip(label: 'Purchased', value: '${stock.totalPurchased.toStringAsFixed(1)} L', icon: Icons.local_shipping_rounded)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _Chip(label: 'Consumed', value: '${stock.totalConsumed.toStringAsFixed(1)} L', icon: Icons.speed_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _Chip(label: 'Pending', value: '₹${fmt.format(stock.pendingPayments)}', icon: Icons.pending_actions_rounded, isDanger: true)),
                        ]),
                      ])
                    : Row(children: [
                        Expanded(child: _Chip(label: 'Stock', value: '${stock.currentStock.toStringAsFixed(1)} L', icon: Icons.inventory_2_rounded, isHighlight: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Chip(label: 'Purchased', value: '${stock.totalPurchased.toStringAsFixed(1)} L', icon: Icons.local_shipping_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _Chip(label: 'Consumed', value: '${stock.totalConsumed.toStringAsFixed(1)} L', icon: Icons.speed_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _Chip(label: 'Pending', value: '₹${fmt.format(stock.pendingPayments)}', icon: Icons.pending_actions_rounded, isDanger: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Chip(label: 'Paid', value: '₹${fmt.format(stock.totalPaid)}', icon: Icons.check_circle_rounded)),
                      ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;
  final bool isDanger;
  const _Chip({required this.label, required this.value, required this.icon, this.isHighlight = false, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final accent = isHighlight ? const Color(0xFF2ECC71) : isDanger ? const Color(0xFFE74C3C) : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: accent != null ? accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent != null ? accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: accent ?? Colors.white70, size: 16),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: accent ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
        ])),
      ]),
    );
  }
}