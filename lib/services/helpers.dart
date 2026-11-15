import 'package:intl/intl.dart';

int asInt(dynamic v) => int.tryParse('$v') ?? 0;
double asDouble(dynamic v) => double.tryParse('$v') ?? 0;

String peso(dynamic v) => NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(asDouble(v));

/// in / low / out
String stockStatus(Map p) {
  final q = asInt(p['stock_quantity']);
  final t = asInt(p['low_stock_threshold']);
  if (q <= 0) return 'out';
  return q <= t ? 'low' : 'in';
}

DateTime? lastUpdated(Map p) {
  final a = DateTime.tryParse('${p['price_updated_at']}');
  final b = DateTime.tryParse('${p['stock_updated_at']}');
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}

String whenText(DateTime? d) => d == null ? '-' : DateFormat('MMM d, h:mm a').format(d);
