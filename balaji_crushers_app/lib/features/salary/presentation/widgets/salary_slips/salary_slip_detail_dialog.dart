import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/common/detail_row.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/salary_slips/slip_attendance_sheet.dart';

class _AttendanceTotals {
  final int present;
  final int half;
  final int absent;
  final int leave;
  final int sundays;
  final int total;
  final double extra;
  final double overtime;
  final double workedDays;

  const _AttendanceTotals({
    required this.present,
    required this.half,
    required this.absent,
    required this.leave,
    required this.sundays,
    required this.total,
    required this.extra,
    required this.overtime,
    required this.workedDays,
  });

  factory _AttendanceTotals.fromSlip(SalarySlip slip) {
    final present = slip.presentDays ?? 0;
    final half = slip.halfDays ?? 0;
    final leave = slip.leaveDays ?? 0;
    final sundays = slip.sundays ?? 0;
    final extra = slip.extraDays ?? 0;

    return _AttendanceTotals(
      present: present,
      half: half,
      absent: slip.absentDays ?? 0,
      leave: leave,
      sundays: sundays,
      total: slip.totalDays ?? 31,
      extra: extra,
      overtime: slip.overtimeAmount > 0 ? slip.overtimeAmount / 50 : 0,
      workedDays: slip.workedDays ??
          (present + (half * 0.5) + leave + sundays + extra).toDouble(),
    );
  }

  factory _AttendanceTotals.fromRecords(
    List<AttendanceRecord> records,
    SalarySlip slip,
  ) {
    var present = 0;
    var half = 0;
    var absent = 0;
    var leave = 0;
    var extra = 0.0;
    var overtime = 0.0;

    for (final record in records) {
      final date = _attendanceRecordDate(record.date);
      final isSunday = date?.weekday == DateTime.sunday;

      if (isSunday) {
        if (record.status == 'present') extra += 1;
        if (record.status == 'half_day') extra += 0.5;
      } else {
        switch (record.status) {
          case 'present':
            present++;
            break;
          case 'half_day':
            half++;
            break;
          case 'absent':
            absent++;
            break;
          case 'leave':
            leave++;
            break;
        }
      }

      overtime += record.overtimeHours;
    }

    final sundays = slip.sundays ?? 0;
    final workedDays = present + (half * 0.5) + leave + sundays + extra;

    return _AttendanceTotals(
      present: present,
      half: half,
      absent: absent,
      leave: leave,
      sundays: sundays,
      total: slip.totalDays ?? 31,
      extra: extra,
      overtime: overtime,
      workedDays: workedDays.toDouble(),
    );
  }
}

DateTime? _attendanceRecordDate(String rawDate) {
  if (!rawDate.contains('T')) {
    final parts = rawDate.split('-');
    if (parts.length < 3) return DateTime.tryParse(rawDate);
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return DateTime.tryParse(rawDate);
    }
    return DateTime(
      year,
      month,
      day,
    );
  }

  final hasTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawDate);
  if (!hasTimeZone) {
    return DateTime.tryParse(rawDate.split('T')[0]);
  }

  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return null;
  return parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
}

class SalarySlipDetailDialog extends ConsumerWidget {
  final SalarySlip slip;

  const SalarySlipDetailDialog({super.key, required this.slip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(employeeAttendanceByPeriodProvider((
      employeeId: slip.employeeId,
      periodId: slip.periodId,
    )));
    final attendanceTotals = attendanceAsync.valueOrNull == null
        ? _AttendanceTotals.fromSlip(slip)
        : _AttendanceTotals.fromRecords(attendanceAsync.valueOrNull!, slip);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(
          children: [
            // ── Header ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        slip.employeeName.isNotEmpty
                            ? slip.employeeName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slip.employeeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${slip.employeeCode ?? ''} • ${slip.departmentName ?? ''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Net salary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'NET SALARY',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 0.8),
                      ),
                      Text(
                        '₹${(slip.netSalary ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Attendance section ─ tappable ────────────────────
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.75,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            builder: (_, scrollController) =>
                                SlipAttendanceSheet(slip: slip),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header row with chevron hint
                            Row(
                              children: [
                                const _SectionHeader(
                                  icon: Icons.today_rounded,
                                  title: 'Attendance',
                                  color: AppColors.info,
                                ),
                                const Spacer(),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.info.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16,
                                    color: AppColors.info.withValues(alpha: 0.7)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _AttendanceGrid(
                              present: attendanceTotals.present,  half: attendanceTotals.half,
                              absent: attendanceTotals.absent,    leave: attendanceTotals.leave,
                              sundays: attendanceTotals.sundays,  extra: attendanceTotals.extra,
                              total: attendanceTotals.total,      overtime: attendanceTotals.overtime,
                              workedDays: attendanceTotals.workedDays,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Earnings section
                    _SectionHeader(icon: Icons.trending_up_rounded, title: 'Earnings', color: AppColors.success),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
                      ),
                      child: Builder(builder: (ctx) {
                        final earningsAsync = ref.watch(activeEarningsProvider);
                        // Pro-rate factor from actual worked days
                        final totalDays  = (slip.totalDays  ?? 30).toDouble();
                        final workedDays = attendanceTotals.workedDays;
                        final factor     = totalDays > 0 ? workedDays / totalDays : 1.0;
                        final proRatedBasic = slip.basicSalary * factor;
                        return Column(
                          children: [
                            // Full monthly salary from employee record
                            if (slip.basicSalary > 0) ...[               
                              DetailRow('Monthly Basic', '₹${slip.basicSalary.toStringAsFixed(2)}'),
                              if ((factor - 1.0).abs() > 0.001)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Pro-rated (${workedDays.toStringAsFixed(1)}/${totalDays.toStringAsFixed(0)} days)',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                      ),
                                      Text(
                                        '₹${proRatedBasic.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            // Dynamic earning components from DB (pro-rated)
                            earningsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (earnings) => Column(
                                children: earnings.map((e) {
                                  final amt = e.calculationType == 'percentage'
                                      ? proRatedBasic * e.value / 100
                                      : e.value * factor;
                                  return amt > 0
                                      ? DetailRow(e.name, '₹${amt.toStringAsFixed(2)}')
                                      : const SizedBox.shrink();
                                }).toList(),
                              ),
                            ),
                            if (slip.overtimeAmount > 0)
                              DetailRow('Overtime', '₹${slip.overtimeAmount.toStringAsFixed(2)}'),
                            if (slip.bonus > 0)
                              DetailRow('Bonus', '₹${slip.bonus.toStringAsFixed(2)}'),
                            Divider(color: AppColors.success.withValues(alpha: 0.2), height: 16),
                            DetailRow(
                              'Total Earnings',
                              '₹${slip.totalEarnings.toStringAsFixed(2)}',
                              bold: true,
                              valueColor: AppColors.success,
                            ),
                          ],
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Deductions section
                    _SectionHeader(icon: Icons.trending_down_rounded, title: 'Deductions', color: AppColors.error),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                      ),
                      child: Builder(builder: (ctx) {
                        final deductionsAsync = ref.watch(activeDeductionsProvider);
                        return Column(
                          children: [
                            // Show stored slip values matched to DB deduction names by type
                            // Ensures line items always sum to stored totalDeductions exactly
                            deductionsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                              error: (_, __) => Column(children: [
                                if (slip.pfDeduction > 0)
                                  DetailRow('PF Deduction', '₹${slip.pfDeduction.toStringAsFixed(2)}'),
                                if (slip.tdsDeduction > 0)
                                  DetailRow('TDS Deduction', '₹${slip.tdsDeduction.toStringAsFixed(2)}'),
                                if (slip.otherDeductions > 0)
                                  DetailRow('Other Deductions', '₹${slip.otherDeductions.toStringAsFixed(2)}'),
                              ]),
                              data: (deductions) {
                                // Match stored amounts to DB names by deduction type
                                final pfName = deductions
                                    .where((d) => d.type == 'pf')
                                    .map((d) => d.name)
                                    .firstOrNull ?? 'PF Deduction';
                                final tdsName = deductions
                                    .where((d) => d.type == 'tds')
                                    .map((d) => d.name)
                                    .firstOrNull ?? 'TDS Deduction';
                                final taxName = deductions
                                    .where((d) => d.type == 'tax')
                                    .map((d) => d.name)
                                    .firstOrNull ?? 'Professional Tax';
                                return Column(children: [
                                  if (slip.pfDeduction > 0)
                                    DetailRow(pfName, '₹${slip.pfDeduction.toStringAsFixed(2)}'),
                                  if (slip.tdsDeduction > 0)
                                    DetailRow(tdsName, '₹${slip.tdsDeduction.toStringAsFixed(2)}'),
                                  if (slip.otherDeductions > 0)
                                    DetailRow(taxName, '₹${slip.otherDeductions.toStringAsFixed(2)}'),
                                ]);
                              },
                            ),
                            Divider(color: AppColors.error.withValues(alpha: 0.2), height: 16),
                            DetailRow(
                              'Total Deductions',
                              '₹${slip.totalDeductions.toStringAsFixed(2)}',
                              bold: true,
                              valueColor: AppColors.error,
                            ),
                          ],
                        );
                      }),
                    ),

                    // Net salary section
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Salary Payable',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₹${(slip.netSalary ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bank details
                    if (slip.bankAccount != null) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(icon: Icons.account_balance_outlined, title: 'Bank Details', color: AppColors.primaryLight),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            DetailRow('Account No.', slip.bankAccount ?? ''),
                            DetailRow('Bank', slip.bankName ?? ''),
                            DetailRow('IFSC', slip.ifscCode ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _AttendanceGrid extends StatelessWidget {
  final int present, half, absent, leave, sundays, total;
  final double extra;       // Sundays with attendance (extra worked days)
  final double overtime;    // Overtime hours
  final double workedDays;  // Stored paid days total

  const _AttendanceGrid({
    required this.present,  required this.half,
    required this.absent,   required this.leave,
    required this.sundays,  required this.total,
    this.extra = 0,
    this.overtime = 0,
    this.workedDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Row 1: Total Days | Present | Sundays | Extra Days
          Row(
            children: [
              _AttCell('Total Days',  '$total',                        Colors.grey),
              _AttCell('Present',     '$present',                      AppColors.success),
              _AttCell('Sundays',     '$sundays',                      AppColors.info),
              _AttCell('Extra Days',  extra.toStringAsFixed(extra % 1 == 0 ? 0 : 1), AppColors.accent),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Half Days | Leave | Absent | Overtime Hrs
          Row(
            children: [
              _AttCell('Half Days',    '$half',                          AppColors.warning),
              _AttCell('Leave',        '$leave',                         AppColors.primaryLight),
              _AttCell('Absent',       '$absent',                        AppColors.error),
              _AttCell('Overtime Hrs', overtime.toStringAsFixed(overtime % 1 == 0 ? 0 : 1), Colors.deepOrange),
            ],
          ),
          Divider(color: AppColors.info.withValues(alpha: 0.2), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paid Days for Salary',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                workedDays.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
            Text(label,
              style: TextStyle(fontSize: 8.5, color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
