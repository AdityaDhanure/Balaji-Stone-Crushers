import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';

/// Bottom sheet that displays every day of the salary period with its
/// attendance status (or "No Record" for days not yet marked).
class SlipAttendanceSheet extends ConsumerWidget {
  final SalarySlip slip;

  const SlipAttendanceSheet({super.key, required this.slip});

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _dateKeyIST(String rawDate) {
    if (!rawDate.contains('T')) return rawDate;
    final hasTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawDate);
    if (!hasTimeZone) return rawDate.split('T')[0];

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate.split('T')[0];

    final istDate = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    return _formatDate(istDate);
  }

  static List<DateTime> _monthDays(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(
      lastDay,
      (index) => DateTime(year, month, index + 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodAsync  = ref.watch(periodByIdProvider(slip.periodId));
    final attParams    = (employeeId: slip.employeeId, periodId: slip.periodId);
    final recordsAsync = ref.watch(employeeAttendanceByPeriodProvider(attParams));

    // Determine overall loading/error state from both providers
    final isLoading = periodAsync.isLoading || recordsAsync.isLoading;
    final error     = periodAsync.error ?? recordsAsync.error;
    final period    = periodAsync.valueOrNull;
    final records   = recordsAsync.valueOrNull ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slip.employeeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      isLoading
                          ? Text('Loading…',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400))
                          : Text(
                              period?.monthName ?? 'Attendance Detail',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // ── Summary strip ────────────────────────────────
          if (isLoading)
            const _SummaryStripLoading()
          else if (error == null)
            _SummaryStrip(records: records),

          const SizedBox(height: 8),

          // ── Full-month day list ───────────────────────────
          Flexible(
            child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : error != null
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 40, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(error.toString().replaceAll('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error)),
                      ],
                    ),
                  )
                : Builder(builder: (context) {
                    // Build lookup using IST calendar dates. Postgres DATE can
                    // arrive as UTC JSON, e.g. Feb 1 -> Jan 31 18:30Z.
                    final Map<String, AttendanceRecord> lookup = {
                      for (final r in records)
                        _dateKeyIST(r.date): r,
                    };

                    // Salary attendance is always the full selected salary month:
                    // 1st day through month end, independent of serialized dates.
                    final days = period == null
                        ? <DateTime>[]
                        : _monthDays(period.year, period.month);

                    if (days.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 40, color: AppColors.textSecondary),
                            SizedBox(height: 8),
                            Text('No period dates found',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      shrinkWrap: true,
                      itemCount: days.length,
                      itemBuilder: (_, i) {
                        final day = days[i];
                        final key = DateFormat('yyyy-MM-dd').format(day);
                        return _DayTile(day: day, record: lookup[key]);
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

// ── Summary stats strip ────────────────────────────────────────────────────

class _SummaryStripLoading extends StatelessWidget {
  const _SummaryStripLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: LinearProgressIndicator(minHeight: 2),
      );
}

class _SummaryStrip extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _SummaryStrip({required this.records});

  @override
  Widget build(BuildContext context) {
    int present = 0, halfDay = 0, onLeave = 0, absent = 0;
    double overtime = 0;

    for (final r in records) {
      switch (r.status) {
        case 'present':  present++;  break;
        case 'half_day': halfDay++;  break;
        case 'leave':    onLeave++;  break;
        case 'absent':   absent++;   break;
      }
      overtime += r.overtimeHours;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatChip('Present',  '$present',                  AppColors.success),
          const SizedBox(width: 6),
          _StatChip('Half Day', '$halfDay',                  AppColors.warning),
          const SizedBox(width: 6),
          _StatChip('Leave',    '$onLeave',                  AppColors.info),
          const SizedBox(width: 6),
          _StatChip('Absent',   '$absent',                   AppColors.error),
          const SizedBox(width: 6),
          _StatChip('OT Hrs',   overtime.toStringAsFixed(1), Colors.deepOrange),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 8.5,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Per-day tile ────────────────────────────────────────────────────────────

/// Shows one row per calendar day. [record] is null if no attendance was marked.
class _DayTile extends StatelessWidget {
  final DateTime day;
  final AttendanceRecord? record;

  const _DayTile({required this.day, this.record});

  bool get _isSunday => day.weekday == DateTime.sunday;

  Color get _statusColor {
    if (record == null) return Colors.grey.shade400;
    switch (record!.status) {
      case 'present':  return AppColors.success;
      case 'absent':   return AppColors.error;
      case 'half_day': return AppColors.warning;
      case 'leave':    return AppColors.info;
      case 'holiday':  return AppColors.accent;
      default:         return AppColors.textSecondary;
    }
  }

  String get _statusDisplay {
    if (record == null) return _isSunday ? 'Sunday Off' : 'No Record';
    return record!.statusDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final color       = _statusColor;
    final dayLabel    = DateFormat('EEE').format(day);
    final dateLabel   = DateFormat('dd MMM').format(day);
    final noRecord    = record == null;
    final bgColor     = _isSunday
        ? AppColors.info.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: noRecord
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // ── Date column ──────────────────────────────
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(11)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dateLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: noRecord ? Colors.grey.shade400 : color)),
                Text(dayLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: _isSunday
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: _isSunday
                            ? AppColors.info
                            : Colors.grey.shade500)),
              ],
            ),
          ),

          // ── Status bar ───────────────────────────────
          Container(
            width: 3,
            height: 46,
            color: noRecord ? Colors.grey.shade200 : color,
          ),

          const SizedBox(width: 12),

          // ── Main content ─────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge + Sunday tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: noRecord
                              ? Colors.grey.shade100
                              : color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusDisplay,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: noRecord
                                  ? Colors.grey.shade400
                                  : color),
                        ),
                      ),
                      if (_isSunday) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Sunday',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),

                  // Check-in → Check-out
                  if (record?.checkIn != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.login_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          AttendanceRecord.to12Hour(record!.checkIn),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        if (record?.checkOut != null) ...[
                          Text('  ›  ',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11)),
                          Icon(Icons.logout_rounded,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            AttendanceRecord.to12Hour(record!.checkOut),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Right badges ────────────────────────────
          if ((record?.overtimeHours ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 12, color: Colors.deepOrange.shade400),
                  Text(
                    '+${record!.overtimeHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange.shade400),
                  ),
                ],
              ),
            ),

          if ((record?.lateHours ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.watch_later_outlined,
                      size: 12, color: AppColors.warning),
                  const Text('late',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
