import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/format_utils.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/report_period_selector.dart';

/// Generates and prints/downloads PDF for each report tab.
class ReportPdfService {
  static final _rupee = NumberFormat('#,##,##0.00', 'en_IN');
  static String _cur(double v) => '₹${_rupee.format(v)}';
  static String _range(DateTime s, DateTime e) =>
      '${DateFormat('dd MMM yyyy').format(s)} – ${DateFormat('dd MMM yyyy').format(e)}';
  static DateTime _nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  static DateTime _reportDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return _nowIst();

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
    if (parsed == null) return _nowIst();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Common helpers
  // ────────────────────────────────────────────────────────────────────────────

  static pw.Document _baseDoc(String title, String subtitle) {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Balaji Crushers',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 2),
          pw.Text(title,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(height: 12),
        ],
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated (IST): ${DateFormat('dd MMM yyyy HH:mm').format(_nowIst())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
      build: (_) => [], // filled by each specific method
    ));
    return doc;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 1. Overview PDF
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> printOverview(
    Map<String, dynamic> data,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final n = _num;
    final res = data['resources'] as Map<String, dynamic>? ?? {};

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Overview Report', _range(startDate, endDate)),
          pw.SizedBox(height: 12),
          _section('Financial Summary'),
          _kpiTable([
            ['Total Revenue',    _cur(n(data['totalSales']))],
            ['Collected',        _cur(n(data['collected']))],
            ['Pending Payments', _cur(n(data['pendingPayments']))],
            ['Total Expenses',   _cur(n(data['totalExpenses']))],
            ['Net Profit/Loss',  _cur(n(data['netProfit']))],
          ]),
          pw.SizedBox(height: 16),
          _section('Resource Status'),
          _kpiTable([
            ['Active Vehicles',       '${res['activeVehicles'] ?? 0}'],
            ['Active Employees',      '${res['activeEmployees'] ?? 0}'],
            ['Diesel Stock',          '${FormatUtils.formatNumber(n(res['dieselStockLitres']))} L'],
            ['Equipment Maintenance', '${res['equipmentMaintenance'] ?? 0} items'],
          ]),
        ],
      ));
      return doc.save();
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 2. Sales PDF
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> printSales(
    List<dynamic> rows,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final n = _num;
    double totalSales =
        rows.fold<double>(0, (s, r) => s + n(r['total_amount']));
    double totalPaid =
        rows.fold<double>(0, (s, r) => s + n(r['amount_paid']));

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Sales Report', _range(startDate, endDate)),
          pw.SizedBox(height: 8),
          _kpiTable([
            ['Total Invoices', '${rows.length}'],
            ['Total Sales',    _cur(totalSales)],
            ['Total Collected',_cur(totalPaid)],
            ['Pending',        _cur(totalSales - totalPaid)],
          ]),
          pw.SizedBox(height: 12),
          _section('Invoice List'),
          pw.Table.fromTextArray(
            headers: ['Invoice #', 'Customer', 'Date', 'Amount', 'Paid', 'Balance', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            data: rows.map((r) {
              final date = _reportDate(r['invoice_date']);
              return [
                r['invoice_number'] ?? '',
                r['customer_name'] ?? '',
                DateFormat('dd/MM/yy').format(date),
                _cur(n(r['total_amount'])),
                _cur(n(r['amount_paid'])),
                _cur(n(r['balance'])),
                (r['status'] as String? ?? '').toUpperCase(),
              ];
            }).toList(),
          ),
        ],
      ));
      return doc.save();
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 3. Expenses PDF
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> printExpenses(
    Map<String, dynamic> data,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final n = _num;

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Expense Summary Report', _range(startDate, endDate)),
          pw.SizedBox(height: 8),
          pw.Text('Total: ${_cur(n(data["total"]))}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 12),
          _section('Breakdown by Source'),
          _kpiTable([
            ['Manual Expenses',    _cur(n(data['manual']))],
            ['Diesel (Paid)',      _cur(n(data['diesel_paid']))],
            ['Diesel (Pending)',   _cur(n(data['diesel_pending']))],
            ['Blast / Drilling',   _cur(n(data['blast']))],
            ['Royalty',            _cur(n(data['royalty']))],
            ['Maintenance',        _cur(n(data['maintenance']))],
            ['Salaries (Paid)',    _cur(n(data['salaries_paid']))],
            ['Salaries (Pending)', _cur(n(data['salaries_pending']))],
            ['Salary Advances',    _cur(n(data['advances']))],
            ['Production Cost',    _cur(n(data['production_cost']))],
          ]),
        ],
      ));
      return doc.save();
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 4. Profit/Loss PDF
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> printProfitLoss(
    Map<String, dynamic> data,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final n = _num;
    final costItems = (data['costBreakdown'] as List<dynamic>?) ?? [];

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Profit & Loss Report', _range(startDate, endDate)),
          pw.SizedBox(height: 12),
          _section('Summary'),
          _kpiTable([
            ['Total Sales',       _cur(n(data['totalSales']))],
            ['Collected',         _cur(n(data['collected']))],
            ['Pending Revenue',   _cur(n(data['pendingRevenue']))],
            ['Total Expenses',    _cur(n(data['totalExpenses']))],
            ['Net Profit/Loss',   _cur(n(data['netProfit']))],
            ['Profit Margin',     '${n(data['profitMargin']).toStringAsFixed(1)}%'],
          ]),
          pw.SizedBox(height: 16),
          _section('Cost Breakdown'),
          _kpiTable(costItems.map<List<String>>((e) {
            final m = e as Map<String, dynamic>;
            return [m['label'] as String? ?? '', _cur(n(m['amount']))];
          }).toList()),
        ],
      ));
      return doc.save();
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 5. Yearly Trend PDF
  // ────────────────────────────────────────────────────────────────────────────

  static const _monthsFull = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  static Future<void> printYearlyTrend(List<dynamic> rows, int year) async {
    final n = _num;
    double totalSales = 0, totalExp = 0;
    for (final r in rows) { totalSales += n(r['total_sales']); totalExp += n(r['total_expenses']); }

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Yearly Trend – $year', 'January $year – December $year'),
          pw.SizedBox(height: 8),
          _kpiTable([
            ['Year Revenue',  _cur(totalSales)],
            ['Year Expenses', _cur(totalExp)],
            ['Net Profit',    _cur(totalSales - totalExp)],
          ]),
          pw.SizedBox(height: 12),
          _section('Monthly Breakdown'),
          pw.Table.fromTextArray(
            headers: ['Month', 'Revenue', 'Expenses', 'Profit / Loss'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: [
              ...rows.map((r) {
                final month = r['month'];
                final monthNumber = month is num
                    ? month.toInt()
                    : int.tryParse(month?.toString() ?? '') ?? 1;
                final m = monthNumber - 1;
                final pl = n(r['net_profit']);
                return [
                  _monthsFull[m.clamp(0, 11)],
                  _cur(n(r['total_sales'])),
                  _cur(n(r['total_expenses'])),
                  '${pl >= 0 ? '+' : '-'}${_cur(pl.abs())}',
                ];
              }),
              ['TOTAL', _cur(totalSales), _cur(totalExp), '${totalSales >= totalExp ? '+' : '-'}${_cur((totalSales - totalExp).abs())}'],
            ],
          ),
        ],
      ));
      return doc.save();
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Layout helpers
  // ────────────────────────────────────────────────────────────────────────────

  static pw.Widget _header(String title, String sub) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Balaji Crushers',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
      pw.SizedBox(height: 2),
      pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.Text(sub, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      pw.Divider(height: 12),
    ],
  );

  static pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
  );

  static pw.Widget _kpiTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((r) => pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(r[0], style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(r[1],
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ),
      ])).toList(),
    );
  }
}
