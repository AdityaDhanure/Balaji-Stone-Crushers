import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';

class SalarySlipEditDialog extends ConsumerStatefulWidget {
  final SalarySlip slip;

  const SalarySlipEditDialog({super.key, required this.slip});

  @override
  ConsumerState<SalarySlipEditDialog> createState() => _SalarySlipEditDialogState();
}

class _SalarySlipEditDialogState extends ConsumerState<SalarySlipEditDialog> {
  late TextEditingController _basic;
  late TextEditingController _hra;
  late TextEditingController _allowances;
  late TextEditingController _overtime;
  late TextEditingController _bonus;
  late TextEditingController _pf;
  late TextEditingController _tds;
  late TextEditingController _other;
  late TextEditingController _notes;
  bool _isLoading = false;

  double get _totalDeductions => _val(_pf) + _val(_tds) + _val(_other);

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  double _workedDaysFromSlip() {
    final present = widget.slip.presentDays ?? 0;
    final half = widget.slip.halfDays ?? 0;
    final leave = widget.slip.leaveDays ?? 0;
    final sundays = widget.slip.sundays ?? 0;
    final extra = widget.slip.extraDays ?? 0;

    return widget.slip.workedDays ??
        (present + (half * 0.5) + leave + sundays + extra).toDouble();
  }

  double _workedDaysFromRecords(List<AttendanceRecord> records) {
    var regularPaidDays = 0.0;
    var extraDays = 0.0;

    for (final record in records) {
      final date = _attendanceRecordDate(record.date);
      final isSunday = date?.weekday == DateTime.sunday;

      if (isSunday) {
        if (record.status == 'present') extraDays += 1;
        if (record.status == 'half_day') extraDays += 0.5;
      } else {
        switch (record.status) {
          case 'present':
          case 'leave':
            regularPaidDays += 1;
            break;
          case 'half_day':
            regularPaidDays += 0.5;
            break;
        }
      }
    }

    return regularPaidDays + (widget.slip.sundays ?? 0) + extraDays;
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
      return DateTime(year, month, day);
    }

    final hasTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawDate);
    if (!hasTimeZone) return DateTime.tryParse(rawDate.split('T')[0]);

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;
    return parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  double _workedDays(List<AttendanceRecord>? records) {
    if (records == null) return _workedDaysFromSlip();
    return _workedDaysFromRecords(records);
  }

  double _attendanceFactor(List<AttendanceRecord>? records) {
    final totalDays = (widget.slip.totalDays ?? 30).toDouble();
    if (totalDays <= 0) return 1;
    return _workedDays(records) / totalDays;
  }

  double _proRatedBasic(List<AttendanceRecord>? records) =>
      _val(_basic) * _attendanceFactor(records);

  double _totalEarnings(List<AttendanceRecord>? records) =>
      _proRatedBasic(records) +
      _val(_hra) +
      _val(_allowances) +
      _val(_overtime) +
      _val(_bonus);

  double _netSalary(List<AttendanceRecord>? records) =>
      _totalEarnings(records) - _totalDeductions;

  @override
  void initState() {
    super.initState();
    final s = widget.slip;
    _basic      = TextEditingController(text: s.basicSalary.toStringAsFixed(2));
    _hra        = TextEditingController(text: s.hra.toStringAsFixed(2));
    _allowances = TextEditingController(text: s.allowances.toStringAsFixed(2));
    _overtime   = TextEditingController(text: s.overtimeAmount.toStringAsFixed(2));
    _bonus      = TextEditingController(text: s.bonus.toStringAsFixed(2));
    _pf         = TextEditingController(text: s.pfDeduction.toStringAsFixed(2));
    _tds        = TextEditingController(text: s.tdsDeduction.toStringAsFixed(2));
    _other      = TextEditingController(text: s.otherDeductions.toStringAsFixed(2));
    _notes      = TextEditingController(text: s.notes ?? '');

    // Recalculate on every change
    for (final c in [_basic, _hra, _allowances, _overtime, _bonus, _pf, _tds, _other]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_basic, _hra, _allowances, _overtime, _bonus, _pf, _tds, _other, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(employeeAttendanceByPeriodProvider((
      employeeId: widget.slip.employeeId,
      periodId: widget.slip.periodId,
    )));
    final attendanceRecords = attendanceAsync.valueOrNull;
    final isAttendanceLoading = attendanceAsync.isLoading && attendanceRecords == null;
    final totalDays = (widget.slip.totalDays ?? 30).toDouble();
    final workedDays = _workedDays(attendanceRecords);
    final factor = _attendanceFactor(attendanceRecords);
    final proRatedBasic = _proRatedBasic(attendanceRecords);
    final totalEarnings = _totalEarnings(attendanceRecords);
    final netSalary = _netSalary(attendanceRecords);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
        child: Column(
          children: [
            // Header
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_document, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Salary Slip',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(widget.slip.employeeName,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left — Earnings
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.trending_up_rounded,
                            title: 'Earnings',
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 10),
                          _EditField('Monthly Basic', _basic, AppColors.success),
                          if ((factor - 1.0).abs() > 0.001) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pro-rated (${workedDays.toStringAsFixed(1)}/${totalDays.toStringAsFixed(0)} days)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Text(
                                    '₹${proRatedBasic.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _EditField('HRA', _hra, AppColors.success),
                          _EditField('Allowances', _allowances, AppColors.success),
                          _EditField('Overtime', _overtime, AppColors.success),
                          _EditField('Bonus', _bonus, AppColors.success),

                          const SizedBox(height: 8),
                          _TotalBox(
                            label: 'Total Earnings',
                            value: totalEarnings,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right — Deductions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.trending_down_rounded,
                            title: 'Deductions',
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 10),
                          _EditField('PF Deduction', _pf, AppColors.error),
                          _EditField('TDS', _tds, AppColors.error),
                          _EditField('Other Deductions', _other, AppColors.error),

                          const SizedBox(height: 8),
                          _TotalBox(
                            label: 'Total Deductions',
                            value: _totalDeductions,
                            color: AppColors.error,
                          ),

                          const SizedBox(height: 16),

                          // Net salary live preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NET SALARY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${netSalary.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Synced with view calculation',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notes + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Notes (optional)',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.notes_outlined, size: 18, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || isAttendanceLoading ? null : _save,
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: _isLoading || isAttendanceLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final records = ref
          .read(employeeAttendanceByPeriodProvider((
            employeeId: widget.slip.employeeId,
            periodId: widget.slip.periodId,
          )))
          .valueOrNull;
      final workedDays = _workedDays(records);
      final totalEarnings = _totalEarnings(records);
      final netSalary = _netSalary(records);

      await ref.read(salaryNotifierProvider.notifier).updateSlip(widget.slip.id!, {
        'basic_salary':      _val(_basic).toString(),
        'hra':               _val(_hra).toString(),
        'allowances':        _val(_allowances).toString(),
        'overtime_amount':   _val(_overtime).toString(),
        'bonus':             _val(_bonus).toString(),
        'total_earnings':    totalEarnings.toString(),
        'pf_deduction':      _val(_pf).toString(),
        'tds_deduction':     _val(_tds).toString(),
        'other_deductions':  _val(_other).toString(),
        'total_deductions':  _totalDeductions.toString(),
        'net_salary':        netSalary.toString(),
        'worked_days':       workedDays.toString(),
        'notes':             _notes.text,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary slip updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
    ],
  );
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color accentColor;

  const _EditField(this.label, this.controller, this.accentColor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixText: '₹ ',
        prefixStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    ),
  );
}

class _TotalBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TotalBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    ),
  );
}
