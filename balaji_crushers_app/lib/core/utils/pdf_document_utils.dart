import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AppPdfKit {
  final pw.ThemeData? theme;
  final String currencyPrefix;

  const AppPdfKit._({required this.theme, required this.currencyPrefix});

  static final NumberFormat _rupee = NumberFormat('#,##,##0.00', 'en_IN');

  static Future<AppPdfKit> load() async {
    try {
      final regular = await PdfGoogleFonts.notoSansRegular().timeout(
        const Duration(seconds: 5),
      );
      final bold = await PdfGoogleFonts.notoSansBold().timeout(
        const Duration(seconds: 5),
      );
      return AppPdfKit._(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        currencyPrefix: '₹',
      );
    } catch (_) {
      return const AppPdfKit._(theme: null, currencyPrefix: 'Rs. ');
    }
  }

  String currency(num value) => '$currencyPrefix${_rupee.format(value)}';

  static String safeDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(start)} to ${fmt.format(end)}';
  }
}
