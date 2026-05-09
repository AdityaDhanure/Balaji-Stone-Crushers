double toDouble(dynamic v) {
  if (v == null) return 0;

  if (v is double) return v;
  if (v is int) return v.toDouble();

  return double.tryParse(v.toString()) ?? 0;
}

int? toInt(dynamic v) {
  if (v == null) return null;

  if (v is int) return v;

  return int.tryParse(v.toString());
}