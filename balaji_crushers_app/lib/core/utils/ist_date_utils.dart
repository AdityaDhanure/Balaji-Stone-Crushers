import 'package:intl/intl.dart';

DateTime appNowIst() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

DateTime appTodayIstDate() {
  final now = appNowIst();
  return DateTime(now.year, now.month, now.day);
}

String appDateParam(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

DateTime? appParseIstDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return DateTime(value.year, value.month, value.day);

  final raw = value.toString();
  if (raw.isEmpty) return null;

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
  if (parsed == null) return null;
  final ist = parsed.isUtc
      ? parsed.toUtc().add(const Duration(hours: 5, minutes: 30))
      : parsed;
  return DateTime(ist.year, ist.month, ist.day);
}

DateTime? appParseIstDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  final raw = value.toString();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  return hasZone
      ? parsed.toUtc().add(const Duration(hours: 5, minutes: 30))
      : parsed;
}
