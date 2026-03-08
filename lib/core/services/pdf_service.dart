import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultry_accounting/backend/domain/entities/payment.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/repositories/report_repository.dart';
import 'package:printing/printing.dart';

/// A service to generate PDF documents for the application.
class PdfService {
  
  /// Generates a PDF for a payment receipt or payment voucher.
  Future<Uint8List> generatePaymentReceiptPdf({
    required Payment payment,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a5.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildReceiptHeader(companyName, companyPhone, companyAddress, payment, dateFormat),
              pw.SizedBox(height: 20),
              _buildReceiptBody(payment, currencyFormat),
              pw.Spacer(),
              _buildReceiptSignatures(),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReceiptHeader(String? name, String? phone, String? address, Payment payment, intl.DateFormat dateFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('ظ‡ط§طھظپ: $phone', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              payment.type == 'receipt' ? 'ط³ظ†ط¯ ظ‚ط¨ط¶' : 'ط³ظ†ط¯ طµط±ظپ',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: payment.type == 'receipt' ? PdfColors.green : PdfColors.red),
            ),
            pw.Text('ط±ظ‚ظ… ط§ظ„ط³ظ†ط¯: ${payment.paymentNumber}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ط§ظ„طھط§ط±ظٹط®: ${dateFormat.format(payment.paymentDate)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptBody(Payment payment, intl.NumberFormat currency) {
    final partyName = payment.customer?.name ?? payment.supplier?.name ?? 'ط¬ظ‡ط© ط؛ظٹط± ظ…ط¹ط±ظˆظپط©';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(payment.type == 'receipt' ? 'ظˆطµظ„ظ†ط§ ظ…ظ† ط§ظ„ط³ظٹط¯/ط©: ' : 'طµط±ظپظ†ط§ ظ„ظ„ط³ظٹط¯/ط©: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(partyName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('ظ…ط¨ظ„ط؛ ظˆظ‚ط¯ط±ظ‡: ', style: pw.TextStyle(fontSize: 14)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text(currency.format(payment.amount), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('ظˆط°ظ„ظƒ ط¹ظ†: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.notes ?? 'طھط³ط¯ظٹط¯ ط­ط³ط§ط¨', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('ط·ط±ظٹظ‚ط© ط§ظ„ط¯ظپط¹: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.methodDisplayName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (payment.referenceNumber != null) ...[
              pw.SizedBox(width: 20),
              pw.Text('ط±ظ‚ظ… ط§ظ„ظ…ط±ط¬ط¹: ', style: pw.TextStyle(fontSize: 14)),
              pw.Text(payment.referenceNumber!, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Text('طھظˆظ‚ظٹط¹ ط§ظ„ظ…ط³طھظ„ظ…', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('_________________'),
          ],
        ),
        pw.Column(
          children: [
            pw.Text('طھظˆظ‚ظٹط¹ ط§ظ„ظ…ط­ط§ط³ط¨', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('_________________'),
          ],
        ),
      ],
    );
  }

  /// Generates a PDF for a specific Sales Invoice.
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Customer customer,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();

    // Load Arabic Font (Cairo)
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );
    
    // Date Formatter
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl, // RT support for Arabic
        build: (context) => [
          _buildHeader(companyName, companyPhone, companyAddress, invoice, dateFormat),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(customer),
          pw.SizedBox(height: 20),
          _buildInvoiceTable(invoice.items, currencyFormat),
          pw.SizedBox(height: 20),
          _buildTotals(invoice, currencyFormat),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    String? name, 
    String? phone, 
    String? address, 
    Invoice invoice, 
    intl.DateFormat dateFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('ظ‡ط§طھظپ: $phone'),
            if (address != null) pw.Text('ط§ظ„ط¹ظ†ظˆط§ظ†: $address'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ظپط§طھظˆط±ط© ظ…ط¨ظٹط¹ط§طھ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('ط±ظ‚ظ… ط§ظ„ظپط§طھظˆط±ط©: #${invoice.id}'),
            pw.Text('ط§ظ„طھط§ط±ظٹط®: ${dateFormat.format(invoice.invoiceDate)}'),
          ],
        ),
      ],
    );
  }

  Future<Uint8List> generateStatementPdf({
    required Customer customer,
    required List<CustomerStatementEntry> entries,
    DateTime? fromDate,
    DateTime? toDate,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          _buildStatementHeader(companyName, companyPhone, companyAddress, customer, fromDate, toDate),
          pw.SizedBox(height: 20),
          _buildStatementTable(entries, currencyFormat, dateFormat),
          pw.SizedBox(height: 20),
          _buildStatementSummary(entries, currencyFormat),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF for a supplier account statement
  Future<Uint8List> generateSupplierStatementPdf({
    required String supplierName,
    required List<SupplierStatementEntry> entries,
    required double totalPurchases,
    required double totalPaid,
    required double remainingBalance,
    DateTime? fromDate,
    DateTime? toDate,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      if (companyPhone != null) pw.Text('ظ‡ط§طھظپ: $companyPhone'),
                    ],
                  ),
                  pw.Text('ظƒط´ظپ ط­ط³ط§ط¨ ظ…ظˆط±ط¯', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('ط§ظ„ظ…ظˆط±ط¯: $supplierName', style: pw.TextStyle(fontSize: 16)),
              if (fromDate != null || toDate != null)
                pw.Text(
                  'ط§ظ„ظپطھط±ط©: ${fromDate != null ? dateFormat.format(fromDate) : '...'} - ${toDate != null ? dateFormat.format(toDate) : '...'}',
                ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ…ط´طھط±ظٹط§طھ', currencyFormat.format(totalPurchases), PdfColors.blue),
              _buildSummaryBox('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ…ط¯ظپظˆط¹', currencyFormat.format(totalPaid), PdfColors.green),
              _buildSummaryBox('ط§ظ„ط±طµظٹط¯ ط§ظ„ظ…طھط¨ظ‚ظٹ', currencyFormat.format(remainingBalance), PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['ط§ظ„طھط§ط±ظٹط®', 'ط§ظ„ط¨ظٹط§ظ†', 'ط¹ظ„ظٹظ†ط§', 'ط¯ظپط¹ظ†ط§', 'ط§ظ„ط±طµظٹط¯', 'ط§ظ„ط­ط§ظ„ط©'],
            data: entries.map((e) => [
              dateFormat.format(e.date),
              e.description,
              e.credit > 0 ? currencyFormat.format(e.credit) : '-',
              e.debit > 0 ? currencyFormat.format(e.debit) : '-',
              currencyFormat.format(e.balance),
              e.type == 'purchase' ? (e.isPaid ? 'ظ…ط¯ظپظˆط¹ط©' : 'ط؛ظٹط± ظ…ط¯ظپظˆط¹ط©') : '-',
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryBox(String title, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }


  pw.Widget _buildStatementHeader(
    String? name,
    String? phone,
    String? address,
    Customer customer,
    DateTime? from,
    DateTime? to,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (phone != null) pw.Text('ظ‡ط§طھظپ: $phone'),
              ],
            ),
            pw.Text('ظƒط´ظپ ط­ط³ط§ط¨ ط¹ظ…ظٹظ„', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('ط§ظ„ط¹ظ…ظٹظ„: ${customer.name}', style: pw.TextStyle(fontSize: 16)),
        if (from != null || to != null)
          pw.Text(
            'ط§ظ„ظپطھط±ط©: ${from != null ? intl.DateFormat('yyyy/MM/dd').format(from) : '...'} - ${to != null ? intl.DateFormat('yyyy/MM/dd').format(to) : '...'}',
          ),
      ],
    );
  }

  pw.Widget _buildStatementTable(List<CustomerStatementEntry> entries, intl.NumberFormat currency, intl.DateFormat dateFormat) {
    return pw.TableHelper.fromTextArray(
      headers: ['ط§ظ„طھط§ط±ظٹط®', 'ط§ظ„ط¨ظٹط§ظ†', 'ط§ظ„ظ…ط±ط¬ط¹', 'ظ…ط¯ظٹظ† (ظ„ظ‡)', 'ط¯ط§ط¦ظ† (ط¹ظ„ظٹظ‡)', 'ط§ظ„ط±طµظٹط¯'],
      data: entries.map((e) => [
        dateFormat.format(e.date),
        e.description,
        e.reference,
        if (e.debit > 0) currency.format(e.debit) else '-',
        if (e.credit > 0) currency.format(e.credit) else '-',
        currency.format(e.balance),
      ]).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Widget _buildStatementSummary(List<CustomerStatementEntry> entries, intl.NumberFormat currency) {
    final lastBalance = entries.isNotEmpty ? entries.last.balance : 0.0;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ط§ظ„ط±طµظٹط¯ ط§ظ„ظ†ظ‡ط§ط¦ظٹ ط§ظ„ظ…ط³طھط­ظ‚:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text(currency.format(lastBalance), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: lastBalance > 0 ? PdfColors.red : PdfColors.green)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text('ط§ظ„ط³ظٹط¯ / ط§ظ„ط³ط§ط¯ط©: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(customer.name, style: const pw.TextStyle(fontSize: 16)),
          pw.Spacer(),
          if (customer.phone != null) pw.Text('ط¬ظˆط§ظ„: ${customer.phone}'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceTable(List<InvoiceItem> items, intl.NumberFormat currency) {
    return pw.TableHelper.fromTextArray(
      headers: ['ظ…', 'ط§ظ„طµظ†ظپ', 'ط§ظ„ظƒظ…ظٹط©', 'ط§ظ„ط³ط¹ط± ط§ظ„ط¥ظپط±ط§ط¯ظٹ', 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ'],
      data: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return [
          index.toString(),
          item.productName,
          item.quantity.toStringAsFixed(2),
          currency.format(item.unitPrice),
          currency.format(item.total),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        1: pw.Alignment.centerRight, // Product name alignment
      },
    );
  }

  pw.Widget _buildTotals(Invoice invoice, intl.NumberFormat currency) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _buildTotalRow('ط§ظ„ظ…ط¨ظٹط¹ط§طھ', currency.format(invoice.subtotal)),
              if (invoice.discount > 0)
                _buildTotalRow('ط§ظ„ط®طµظ…', currency.format(invoice.discount), color: PdfColors.red),
              pw.Divider(),
              _buildTotalRow('ط§ظ„طµط§ظپظٹ ط§ظ„ظ…ط·ظ„ظˆط¨', currency.format(invoice.total), isBold: true, fontSize: 16),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {PdfColor? color, bool isBold = false, double fontSize = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(color: color, fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Text('ط´ظƒط±ط§ظ‹ ظ„طھط¹ط§ظ…ظ„ظƒظ… ظ…ط¹ظ†ط§', style: const pw.TextStyle(fontSize: 14)),
        pw.Text('ط­ط±ط±طھ ظ‡ط°ظ‡ ط§ظ„ظپط§طھظˆط±ط© ط¥ظ„ظƒطھط±ظˆظ†ظٹط§ظ‹ ظˆظ„ط§ طھط­طھط§ط¬ ط¥ظ„ظ‰ طھظˆظ‚ظٹط¹', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    );
  }

  /// Generates a PDF for Profit/Loss Report
  Future<Uint8List> generateProfitLossPdf({
    required ProfitLossReport report,
    String? companyName,
    String? companyPhone,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (companyPhone != null) pw.Text('ظ‡ط§طھظپ: $companyPhone'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('طھظ‚ط±ظٹط± ط§ظ„ط£ط±ط¨ط§ط­ ظˆط§ظ„ط®ط³ط§ط¦ط±', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.Text('طھط§ط±ظٹط® ط§ظ„ط·ط¨ط§ط¹ط©: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            // Report Items
            _buildReportRow('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط¥ظٹط±ط§ط¯ط§طھ', currencyFormat.format(report.revenue), PdfColors.green),
            pw.SizedBox(height: 10),
            _buildReportRow('طھظƒظ„ظپط© ط§ظ„ط¨ط¶ط§ط¹ط© ط§ظ„ظ…ط¨ط§ط¹ط©', currencyFormat.format(report.cost), PdfColors.orange),
            pw.SizedBox(height: 10),
            _buildReportRow('ط§ظ„ظ…طµط±ظˆظپط§طھ ط§ظ„طھط´ط؛ظٹظ„ظٹط©', currencyFormat.format(report.expenses), PdfColors.red),
            pw.Divider(),
            _buildReportRow('ط§ظ„ط±ط¨ط­ ط§ظ„طھط´ط؛ظٹظ„ظٹ', currencyFormat.format(report.profit), PdfColors.blue, isBold: true),
            pw.SizedBox(height: 20),
            _buildReportRow('ط§ظ„ط±ظˆط§طھط¨ ظˆط§ظ„ط£ط¬ظˆط±', currencyFormat.format(report.salaries), PdfColors.teal),
            pw.SizedBox(height: 10),
            _buildReportRow('ط§ظ„ط¬ط±ط¯ ط§ظ„ط³ظ†ظˆظٹ / طھط³ظˆظٹط©', currencyFormat.format(report.annualInventories), PdfColors.indigo),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            _buildReportRow(
              'طµط§ظپظٹ ط§ظ„ط±ط¨ط­ ط§ظ„ظ†ظ‡ط§ط¦ظٹ', 
              currencyFormat.format(report.netProfit), 
              report.netProfit >= 0 ? PdfColors.green : PdfColors.red, 
              isBold: true,
              fontSize: 16,
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'ظ‡ط§ظ…ط´ ط§ظ„ط±ط¨ط­ ط§ظ„ظ†ظ‡ط§ط¦ظٹ: ${report.profitMargin.toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 14, color: report.netProfit >= 0 ? PdfColors.green : PdfColors.red),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReportRow(String label, String value, PdfColor color, {bool isBold = false, double fontSize = 14}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// Generates a PDF for Product Sales Report
  Future<Uint8List> generateProductSalesPdf({
    required List<Map<String, dynamic>> salesData,
    String? companyName,
    String? companyPhone,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('طھظ‚ط±ظٹط± ظ…ط¨ظٹط¹ط§طھ ط§ظ„ط£طµظ†ط§ظپ', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.purple)),
                  pw.Text('طھط§ط±ظٹط® ط§ظ„ط·ط¨ط§ط¹ط©: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['ط§ظ„طµظ†ظپ', 'ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط¨ط§ط¹ط©', 'ط§ظ„ط¥ظٹط±ط§ط¯ط§طھ', 'ط§ظ„ط£ط±ط¨ط§ط­'],
            data: salesData.map((row) => [
              row['productName'] ?? '',
              (row['totalQuantity'] as double).toStringAsFixed(1),
              currencyFormat.format(row['totalRevenue']),
              currencyFormat.format(row['profit']),
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF for Aging Report
  Future<Uint8List> generateAgingReportPdf({
    required List<AgingReportEntry> entries,
    String? companyName,
    String? companyPhone,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('طھظ‚ط±ظٹط± ط£ط¹ظ…ط§ط± ط°ظ…ظ… ط§ظ„ط¹ظ…ظ„ط§ط،', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
                  pw.Text('طھط§ط±ظٹط® ط§ظ„ط·ط¨ط§ط¹ط©: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['ط§ظ„ط¹ظ…ظٹظ„', 'ط­ط§ظ„ظٹط§ظ‹ (0-30)', '30-60 ظٹظˆظ…', '60-90 ظٹظˆظ…', '>90 ظٹظˆظ…', 'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ'],
            data: entries.map((e) => [
              e.customerName,
              e.current > 0 ? currencyFormat.format(e.current) : '-',
              e.days30 > 0 ? currencyFormat.format(e.days30) : '-',
              e.days60 > 0 ? currencyFormat.format(e.days60) : '-',
              (e.days90 + e.over90) > 0 ? currencyFormat.format(e.days90 + e.over90) : '-',
              currencyFormat.format(e.total),
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.amber),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF for Cash Flow Report
  Future<Uint8List> generateCashFlowPdf({
    required List<CashFlowEntry> entries,
    String? companyName,
    String? companyPhone,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    final printDateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('طھظ‚ط±ظٹط± ط­ط±ظƒط© ط§ظ„طµظ†ط¯ظˆظ‚', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                  pw.Text('طھط§ط±ظٹط® ط§ظ„ط·ط¨ط§ط¹ط©: ${printDateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['ط§ظ„طھط§ط±ظٹط®', 'ط§ظ„ط¨ظٹط§ظ†', 'ط§ظ„ظ†ظˆط¹', 'ط§ظ„ظ…ط¨ظ„ط؛', 'ط§ظ„ط±طµظٹط¯'],
            data: entries.map((e) {
              final isIn = e.type == 'in' || e.type == 'receipt';
              return [
                dateFormat.format(e.date),
                e.description,
                e.type == 'opening' ? 'ط±طµظٹط¯ ط§ظپطھطھط§ط­ظٹ' : (isIn ? 'ظˆط§ط±ط¯' : 'طµط§ط¯ط±'),
                e.type == 'opening' ? '-' : '${isIn ? "+" : "-"}${currencyFormat.format(e.amount)}',
                currencyFormat.format(e.balance),
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          // Final Balance
          if (entries.isNotEmpty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.teal),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    'ط§ظ„ط±طµظٹط¯ ط§ظ„ظ†ظ‡ط§ط¦ظٹ: ${currencyFormat.format(entries.last.balance)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return pdf.save();
  }
  /// Generates a PDF for Salary Account Statement (Consolidated)
  Future<Uint8List> generateSalaryStatementPdf({
    required DateTime month,
    required List<Map<String, dynamic>> salaryData,
    String? companyName,
    String? companyPhone,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final currencyFormat = intl.NumberFormat.currency(symbol: 'ط´ظٹظƒظ„', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Text(companyName ?? 'ط§ط³ظ… ط§ظ„ظ…ظ†ط´ط£ط©', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                   if (companyPhone != null) pw.Text('ظ‡ط§طھظپ: $companyPhone'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                   pw.Text('ظƒط´ظپ ط±ظˆط§طھط¨ ط§ظ„ظ…ظˆط¸ظپظٹظ†', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                   pw.Text('ط¹ظ† ط´ظ‡ط±: ${month.month}/${month.year}', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['ط§ظ„ظ…ظˆط¸ظپ', 'ط§ظ„ط±ط§طھط¨ ط§ظ„ط«ط§ط¨طھ', 'ط§ظ„ظ…ط¯ظپظˆط¹', 'ط§ظ„ظ…طھط¨ظ‚ظٹ', 'ط§ظ„طھظˆظ‚ظٹط¹'],
            data: salaryData.map((e) => [
              e['name'],
              currencyFormat.format(e['fixed']),
              currencyFormat.format(e['paid']),
              currencyFormat.format(e['remaining']),
              '',
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            cellAlignment: pw.Alignment.center,
             cellAlignments: {
              0: pw.Alignment.centerRight,
            },
          ),
          
          pw.SizedBox(height: 20),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
