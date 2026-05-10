import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/pdf_document_utils.dart';
import '../providers/billing_provider.dart';
import '../../utils/billing_date_utils.dart';
import 'record_payment_dialog.dart';
import 'status_badge.dart';

class InvoiceDetailSheet extends ConsumerStatefulWidget {
  final Invoice invoice;
  final Function(double, String, String?, DateTime) onRecordPayment;
  final Function(String) onStatusChange;
  final VoidCallback? onEdit;

  const InvoiceDetailSheet({
    super.key,
    required this.invoice,
    required this.onRecordPayment,
    required this.onStatusChange,
    this.onEdit,
  });

  @override
  ConsumerState<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends ConsumerState<InvoiceDetailSheet> {
  List<InvoicePayment> _payments = [];
  List<InvoiceItem> _items = [];
  bool _loadingPayments = true;
  bool _loadingItems = true;
  final _fmt = NumberFormat('#,##,###');

  Invoice get inv => widget.invoice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadItems(), _loadPayments()]);
  }

  Future<void> _loadItems() async {
    try {
      final data = await ref
          .read(billingRepositoryProvider)
          .getItemsByInvoice(inv.id);
      if (mounted) {
        setState(() {
          _items = data
              .map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
              .toList();
          _loadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _loadPayments() async {
    try {
      final data = await ref
          .read(billingRepositoryProvider)
          .getPaymentHistory(inv.id);
      if (mounted) {
        setState(() {
          _payments = data
              .map((h) => InvoicePayment.fromJson(h as Map<String, dynamic>))
              .toList();
          _loadingPayments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPayments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialSummary(),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Items Purchased', _loadingItems),
                  const SizedBox(height: 8),
                  _buildItems(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Payment History', _loadingPayments),
                  const SizedBox(height: 8),
                  _buildPayments(),
                  if (inv.notes != null && inv.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (inv.billNo != null && inv.billNo!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bill# ${inv.billNo}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  inv.customerName ?? 'Unknown Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (inv.customerPhone != null)
                  Text(
                    inv.customerPhone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          BillingStatusBadge(status: inv.status),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow('Invoice Date', _fmtDate(inv.invoiceDate)),
          if (inv.dueDate != null) _infoRow('Due Date', _fmtDate(inv.dueDate!)),
          if (inv.customerGst != null && inv.customerGst!.isNotEmpty)
            _infoRow('GST No.', inv.customerGst!),
          if (inv.taxAmount > 0)
            _infoRow('Tax Amount', '₹${_fmt.format(inv.taxAmount)}'),
          const Divider(height: 20, color: AppColors.border),
          _infoRow(
            'Total Amount',
            '₹${_fmt.format(inv.totalAmount)}',
            isHighlighted: true,
          ),
          const SizedBox(height: 6),
          _infoRow(
            'Amount Paid',
            '₹${_fmt.format(inv.amountPaid)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 4),
          _infoRow(
            'Balance Due',
            '₹${_fmt.format(inv.balanceDue)}',
            valueColor: inv.balanceDue > 0
                ? AppColors.warning
                : AppColors.success,
          ),
          if (inv.totalAmount > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (inv.amountPaid / inv.totalAmount).clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.success,
                ),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${((inv.amountPaid / inv.totalAmount) * 100).clamp(0, 100).toStringAsFixed(0)}% paid',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (inv.status != 'paid' && inv.status != 'cancelled')
            _ActionBtn(
              label: 'Record Payment',
              icon: Icons.payment_rounded,
              color: AppColors.success,
              onTap: () => _showPaymentDialog(context),
            ),
          const SizedBox(width: 8),
          _ActionBtn(
            label: 'Edit',
            icon: Icons.edit_rounded,
            color: AppColors.primary,
            outlined: true,
            onTap: () {
              Navigator.pop(context);
              widget.onEdit?.call();
            },
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            label: 'Print',
            icon: Icons.print_rounded,
            color: AppColors.primary,
            outlined: true,
            onTap: () => _printInvoice(context),
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            label: 'Share',
            icon: Icons.share_rounded,
            color: AppColors.info,
            outlined: true,
            onTap: () => _shareInvoice(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, bool loading) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        if (loading) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _buildItems() {
    if (_loadingItems) return const SizedBox.shrink();
    if (_items.isEmpty) return _emptyBox('No items');
    return Column(
      children: _items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName ?? item.description ?? 'Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.quantity.toStringAsFixed(1)} brass × ₹${item.sellingRatePerUnit.toStringAsFixed(0)}/brass',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${_fmt.format(item.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPayments() {
    if (_loadingPayments) return const SizedBox.shrink();
    if (_payments.isEmpty) return _emptyBox('No payments recorded yet');
    return Column(
      children: _payments.map((p) {
        final d = billingParseDate(p.paymentDate);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.paymentModeDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(d),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (p.referenceNumber != null &&
                        p.referenceNumber!.isNotEmpty)
                      Text(
                        'Ref: ${p.referenceNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${_fmt.format(p.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(inv.notes!, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyBox(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      msg,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
  );

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlighted = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
            fontSize: isHighlighted ? 17 : 13,
          ),
        ),
      ],
    ),
  );

  String _fmtDate(String raw) {
    try {
      final d = billingParseDate(raw);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return raw;
    }
  }

  void _showPaymentDialog(BuildContext context) => showDialog(
    context: context,
    builder: (_) => RecordPaymentDialog(
      invoice: inv,
      onPay: (amount, mode, ref, paymentDate) async {
        await widget.onRecordPayment(amount, mode, ref, paymentDate);
        _loadPayments();
      },
    ),
  );

  String get _invoicePdfFileName {
    final safeInvoiceNumber = inv.invoiceNumber.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    return 'invoice_$safeInvoiceNumber.pdf';
  }

  Future<void> _ensureInvoiceDataLoaded() async {
    if (_loadingItems || _loadingPayments) {
      await _load();
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      await _ensureInvoiceDataLoaded();
      if (!context.mounted) return;

      await Printing.layoutPdf(
        name: _invoicePdfFileName,
        onLayout: _buildInvoicePdf,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open invoice PDF: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<Uint8List> _buildInvoicePdf(PdfPageFormat format) async {
    final kit = await AppPdfKit.load();
    final doc = pw.Document(theme: kit.theme);
    final invoiceDate = DateFormat(
      'dd MMM yyyy',
    ).format(billingParseDate(inv.invoiceDate));
    final dueDate = inv.dueDate == null
        ? null
        : DateFormat('dd MMM yyyy').format(billingParseDate(inv.dueDate!));

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated (IST): ${DateFormat('dd MMM yyyy HH:mm').format(billingNowIst())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
        build: (_) => [
          _pdfHeader(),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _pdfPanel('Bill To', [
                  inv.customerName ?? 'Unknown Customer',
                  if (inv.customerPhone != null &&
                      inv.customerPhone!.isNotEmpty)
                    inv.customerPhone!,
                  if (inv.customerCity != null && inv.customerCity!.isNotEmpty)
                    inv.customerCity!,
                  if (inv.customerGst != null && inv.customerGst!.isNotEmpty)
                    'GST: ${inv.customerGst}',
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _pdfPanel('Invoice Details', [
                  'Invoice No: ${inv.invoiceNumber}',
                  if (inv.billNo != null && inv.billNo!.isNotEmpty)
                    'Bill No: ${inv.billNo}',
                  'Invoice Date: $invoiceDate',
                  if (dueDate != null) 'Due Date: $dueDate',
                  'Status: ${inv.statusDisplay.toUpperCase()}',
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _pdfSection('Items'),
          _pdfItemsTable(kit),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(width: 230, child: _pdfTotals(kit)),
          ),
          pw.SizedBox(height: 18),
          _pdfSection('Payments'),
          _pdfPaymentsTable(kit),
          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _pdfSection('Notes'),
            pw.Text(inv.notes!, style: const pw.TextStyle(fontSize: 9)),
          ],
          if (inv.terms != null && inv.terms!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _pdfSection('Terms'),
            pw.Text(inv.terms!, style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Balaji Crushers',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Text(
              inv.invoiceNumber,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Divider(height: 16, color: PdfColors.grey600),
      ],
    );
  }

  pw.Widget _pdfPanel(String title, List<String> lines) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey700,
            ),
          ),
          pw.SizedBox(height: 6),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title) {
    return pw.Padding(
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
  }

  pw.Widget _pdfItemsTable(AppPdfKit kit) {
    final data = _items.isEmpty
        ? [
            ['No items', '', '', '', ''],
          ]
        : _items.map((item) {
            return [
              item.productName ?? item.description ?? 'Item',
              item.quantity.toStringAsFixed(2),
              item.unit,
              kit.currency(item.sellingRatePerUnit),
              kit.currency(item.amount),
            ];
          }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Item', 'Qty', 'Unit', 'Rate', 'Amount'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2.6),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(1.2),
      },
    );
  }

  pw.Widget _pdfTotals(AppPdfKit kit) {
    final rows = <List<String>>[
      ['Subtotal', kit.currency(inv.subtotal)],
      if (inv.taxAmount > 0) ['Tax', kit.currency(inv.taxAmount)],
      if (inv.discountAmount > 0)
        ['Discount', '-${kit.currency(inv.discountAmount)}'],
      ['Total', kit.currency(inv.totalAmount)],
      ['Paid', kit.currency(inv.amountPaid)],
      ['Balance Due', kit.currency(inv.balanceDue)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1.4),
      },
      children: rows.map((row) {
        final highlight = row[0] == 'Total' || row[0] == 'Balance Due';
        return pw.TableRow(
          decoration: highlight
              ? const pw.BoxDecoration(color: PdfColors.blueGrey50)
              : null,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: highlight
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                row[1],
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: highlight
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _pdfPaymentsTable(AppPdfKit kit) {
    if (_payments.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Text(
          'No payments recorded yet',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Mode', 'Reference', 'Amount'],
      data: _payments.map((payment) {
        return [
          DateFormat(
            'dd MMM yyyy',
          ).format(billingParseDate(payment.paymentDate)),
          _paymentModeLabel(payment.paymentMode),
          payment.referenceNumber ?? '',
          kit.currency(payment.amount),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }

  String _paymentModeLabel(String mode) {
    switch (mode) {
      case 'cash':
        return 'Cash';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'rtgs':
        return 'RTGS/NEFT';
      case 'upi':
        return 'UPI';
      default:
        return mode;
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    try {
      await _ensureInvoiceDataLoaded();
      if (!context.mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final shareOrigin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;
      final pdfBytes = await _buildInvoicePdf(PdfPageFormat.a4);

      await Share.shareXFiles(
        [
          XFile.fromData(
            pdfBytes,
            mimeType: 'application/pdf',
            name: _invoicePdfFileName,
          ),
        ],
        subject: 'Invoice ${inv.invoiceNumber}',
        text:
            'Invoice ${inv.invoiceNumber} for ${inv.customerName ?? 'Customer'}\n'
            'Total: ₹${_fmt.format(inv.totalAmount)} | Balance: ₹${_fmt.format(inv.balanceDue)}',
        fileNameOverrides: [_invoicePdfFileName],
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to share invoice PDF: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
