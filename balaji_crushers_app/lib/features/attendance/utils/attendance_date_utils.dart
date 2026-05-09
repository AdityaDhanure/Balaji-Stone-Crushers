DateTime attendanceNowIst() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

DateTime attendanceTodayIstDate() {
  final now = attendanceNowIst();
  return DateTime(now.year, now.month, now.day);
}

String attendanceDateParam(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime attendanceParseDate(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return attendanceTodayIstDate();

  final hasExplicitTimezone =
      RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
  if (raw.contains('T') && hasExplicitTimezone) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateTime(ist.year, ist.month, ist.day);
    }
  }

  final datePart = raw.split('T').first;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return attendanceTodayIstDate();
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String attendanceDateString(dynamic value) =>
    attendanceDateParam(attendanceParseDate(value));
