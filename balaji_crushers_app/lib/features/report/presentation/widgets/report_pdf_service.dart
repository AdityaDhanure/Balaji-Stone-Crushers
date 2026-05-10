import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/utils/pdf_document_utils.dart';
import 'package:balaji_crushers_app/features/report/presentation/widgets/common/format_utils.dart';

/// Generates and prints/downloads PDF for each report tab.
class ReportPdfService {
  static String _range(DateTime s, DateTime e) => AppPdfKit.safeDateRange(s, e);
  static DateTime _nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  static DateTime _reportDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return _nowIst();

    final hasExplicitTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
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

    await Printing.layoutPdf(
      onLayout: (_) async {
        final kit = await AppPdfKit.load();
        final doc = pw.Document(theme: kit.theme);
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              _header('Overview Report', _range(startDate, endDate)),
              pw.SizedBox(height: 12),
              _section('Financial Summary'),
              _kpiTable([
                ['Total Revenue', kit.currency(n(data['totalSales']))],
                ['Collected', kit.currency(n(data['collected']))],
                ['Pending Payments', kit.currency(n(data['pendingPayments']))],
                ['Total Expenses', kit.currency(n(data['totalExpenses']))],
                ['Net Profit/Loss', kit.currency(n(data['netProfit']))],
              ]),
              pw.SizedBox(height: 16),
              _section('Resource Status'),
              _kpiTable([
                ['Active Vehicles', '${res['activeVehicles'] ?? 0}'],
                ['Active Employees', '${res['activeEmployees'] ?? 0}'],
                [
                  'Diesel Stock',
                  '${FormatUtils.formatNumber(n(res['dieselStockLitres']))} L',
                ],
                [
                  'Equipment Maintenance',
                  '${res['equipmentMaintenance'] ?? 0} items',
                ],
              ]),
            ],
          ),
        );
        return doc.save();
      },
    );
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
    double totalSales = rows.fold<double>(
      0,
      (s, r) => s + n(r['total_amount']),
    );
    double totalPaid = rows.fold<double>(0, (s, r) => s + n(r['amount_paid']));

    await Printing.layoutPdf(
      onLayout: (_) async {
        final kit = await AppPdfKit.load();
        final doc = pw.Document(theme: kit.theme);
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              _header('Sales Report', _range(startDate, endDate)),
              pw.SizedBox(height: 8),
              _kpiTable([
                ['Total Invoices', '${rows.length}'],
                ['Total Sales', kit.currency(totalSales)],
                ['Total Collected', kit.currency(totalPaid)],
                ['Pending', kit.currency(totalSales - totalPaid)],
              ]),
              pw.SizedBox(height: 12),
              _section('Invoice List'),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Invoice #',
                  'Customer',
                  'Date',
                  'Amount',
                  'Paid',
                  'Balance',
                  'Status',
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                data: rows.map((r) {
                  final date = _reportDate(r['invoice_date']);
                  return [
                    r['invoice_number'] ?? '',
                    r['customer_name'] ?? '',
                    DateFormat('dd/MM/yy').format(date),
                    kit.currency(n(r['total_amount'])),
                    kit.currency(n(r['amount_paid'])),
                    kit.currency(n(r['balance'])),
                    (r['status'] as String? ?? '').toUpperCase(),
                  ];
                }).toList(),
              ),
            ],
          ),
        );
        return doc.save();
      },
    );
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

    await Printing.layoutPdf(
      onLayout: (_) async {
        final kit = await AppPdfKit.load();
        final doc = pw.Document(theme: kit.theme);
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              _header('Expense Summary Report', _range(startDate, endDate)),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total: ${kit.currency(n(data["total"]))}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 12),
              _section('Breakdown by Source'),
              _kpiTable([
                ['Manual Expenses', kit.currency(n(data['manual']))],
                ['Diesel (Paid)', kit.currency(n(data['diesel_paid']))],
                ['Diesel (Pending)', kit.currency(n(data['diesel_pending']))],
                ['Blast / Drilling', kit.currency(n(data['blast']))],
                ['Royalty', kit.currency(n(data['royalty']))],
                ['Maintenance', kit.currency(n(data['maintenance']))],
                ['Salaries (Paid)', kit.currency(n(data['salaries_paid']))],
                [
                  'Salaries (Pending)',
                  kit.currency(n(data['salaries_pending'])),
                ],
                ['Salary Advances', kit.currency(n(data['advances']))],
                ['Production Cost', kit.currency(n(data['production_cost']))],
              ]),
            ],
          ),
        );
        return doc.save();
      },
    );
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

    await Printing.layoutPdf(
      onLayout: (_) async {
        final kit = await AppPdfKit.load();
        final doc = pw.Document(theme: kit.theme);
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              _header('Profit & Loss Report', _range(startDate, endDate)),
              pw.SizedBox(height: 12),
              _section('Summary'),
              _kpiTable([
                ['Total Sales', kit.currency(n(data['totalSales']))],
                ['Collected', kit.currency(n(data['collected']))],
                ['Pending Revenue', kit.currency(n(data['pendingRevenue']))],
                ['Total Expenses', kit.currency(n(data['totalExpenses']))],
                ['Net Profit/Loss', kit.currency(n(data['netProfit']))],
                [
                  'Profit Margin',
                  '${n(data['profitMargin']).toStringAsFixed(1)}%',
                ],
              ]),
              pw.SizedBox(height: 16),
              _section('Cost Breakdown'),
              _kpiTable(
                costItems.map<List<String>>((e) {
                  final m = e as Map<String, dynamic>;
                  return [
                    m['label'] as String? ?? '',
                    kit.currency(n(m['amount'])),
                  ];
                }).toList(),
              ),
            ],
          ),
        );
        return doc.save();
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 5. Yearly Trend PDF
  // ────────────────────────────────────────────────────────────────────────────

  static const _monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static Future<void> printYearlyTrend(List<dynamic> rows, int year) async {
    final n = _num;
    double totalSales = 0, totalExp = 0;
    for (final r in rows) {
      totalSales += n(r['total_sales']);
      totalExp += n(r['total_expenses']);
    }

    await Printing.layoutPdf(
      onLayout: (_) async {
        final kit = await AppPdfKit.load();
        final doc = pw.Document(theme: kit.theme);
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              _header(
                'Yearly Trend - $year',
                'January $year to December $year',
              ),
              pw.SizedBox(height: 8),
              _kpiTable([
                ['Year Revenue', kit.currency(totalSales)],
                ['Year Expenses', kit.currency(totalExp)],
                ['Net Profit', kit.currency(totalSales - totalExp)],
              ]),
              pw.SizedBox(height: 12),
              _section('Monthly Breakdown'),
              pw.TableHelper.fromTextArray(
                headers: ['Month', 'Revenue', 'Expenses', 'Profit / Loss'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
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
                      kit.currency(n(r['total_sales'])),
                      kit.currency(n(r['total_expenses'])),
                      '${pl >= 0 ? '+' : '-'}${kit.currency(pl.abs())}',
                    ];
                  }),
                  [
                    'TOTAL',
                    kit.currency(totalSales),
                    kit.currency(totalExp),
                    '${totalSales >= totalExp ? '+' : '-'}${kit.currency((totalSales - totalExp).abs())}',
                  ],
                ],
              ),
            ],
          ),
        );
        return doc.save();
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Layout helpers
  // ────────────────────────────────────────────────────────────────────────────

  static pw.Widget _header(String title, String sub) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Balaji Crushers',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        sub,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
      pw.Divider(height: 12),
    ],
  );

  static pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey700,
      ),
    ),
  );

  static pw.Widget _kpiTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows
          .map(
            (r) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(r[0], style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    r[1],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
