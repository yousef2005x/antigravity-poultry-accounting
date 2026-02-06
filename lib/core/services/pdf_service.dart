import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultry_accounting/domain/entities/payment.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

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
            pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('هاتف: $phone', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              payment.type == 'receipt' ? 'سند قبض' : 'سند صرف',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: payment.type == 'receipt' ? PdfColors.green : PdfColors.red),
            ),
            pw.Text('رقم السند: ${payment.paymentNumber}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('التاريخ: ${dateFormat.format(payment.paymentDate)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptBody(Payment payment, intl.NumberFormat currency) {
    final partyName = payment.customer?.name ?? payment.supplier?.name ?? 'جهة غير معروفة';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(payment.type == 'receipt' ? 'وصلنا من السيد/ة: ' : 'صرفنا للسيد/ة: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(partyName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('مبلغ وقدره: ', style: pw.TextStyle(fontSize: 14)),
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
            pw.Text('وذلك عن: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.notes ?? 'تسديد حساب', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('طريقة الدفع: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.methodDisplayName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (payment.referenceNumber != null) ...[
              pw.SizedBox(width: 20),
              pw.Text('رقم المرجع: ', style: pw.TextStyle(fontSize: 14)),
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
            pw.Text('توقيع المستلم', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('_________________'),
          ],
        ),
        pw.Column(
          children: [
            pw.Text('توقيع المحاسب', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

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
            pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('هاتف: $phone'),
            if (address != null) pw.Text('العنوان: $address'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('فاتورة مبيعات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('رقم الفاتورة: #${invoice.id}'),
            pw.Text('التاريخ: ${dateFormat.format(invoice.invoiceDate)}'),
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

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
                      pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      if (companyPhone != null) pw.Text('هاتف: $companyPhone'),
                    ],
                  ),
                  pw.Text('كشف حساب مورد', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('المورد: $supplierName', style: pw.TextStyle(fontSize: 16)),
              if (fromDate != null || toDate != null)
                pw.Text(
                  'الفترة: ${fromDate != null ? dateFormat.format(fromDate) : '...'} - ${toDate != null ? dateFormat.format(toDate) : '...'}',
                ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox('إجمالي المشتريات', currencyFormat.format(totalPurchases), PdfColors.blue),
              _buildSummaryBox('إجمالي المدفوع', currencyFormat.format(totalPaid), PdfColors.green),
              _buildSummaryBox('الرصيد المتبقي', currencyFormat.format(remainingBalance), PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['التاريخ', 'البيان', 'علينا', 'دفعنا', 'الرصيد', 'الحالة'],
            data: entries.map((e) => [
              dateFormat.format(e.date),
              e.description,
              e.credit > 0 ? currencyFormat.format(e.credit) : '-',
              e.debit > 0 ? currencyFormat.format(e.debit) : '-',
              currencyFormat.format(e.balance),
              e.type == 'purchase' ? (e.isPaid ? 'مدفوعة' : 'غير مدفوعة') : '-',
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
                pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (phone != null) pw.Text('هاتف: $phone'),
              ],
            ),
            pw.Text('كشف حساب عميل', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('العميل: ${customer.name}', style: pw.TextStyle(fontSize: 16)),
        if (from != null || to != null)
          pw.Text(
            'الفترة: ${from != null ? intl.DateFormat('yyyy/MM/dd').format(from) : '...'} - ${to != null ? intl.DateFormat('yyyy/MM/dd').format(to) : '...'}',
          ),
      ],
    );
  }

  pw.Widget _buildStatementTable(List<CustomerStatementEntry> entries, intl.NumberFormat currency, intl.DateFormat dateFormat) {
    return pw.TableHelper.fromTextArray(
      headers: ['التاريخ', 'البيان', 'المرجع', 'مدين (له)', 'دائن (عليه)', 'الرصيد'],
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
              pw.Text('الرصيد النهائي المستحق:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
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
          pw.Text('السيد / السادة: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(customer.name, style: const pw.TextStyle(fontSize: 16)),
          pw.Spacer(),
          if (customer.phone != null) pw.Text('جوال: ${customer.phone}'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceTable(List<InvoiceItem> items, intl.NumberFormat currency) {
    return pw.TableHelper.fromTextArray(
      headers: ['م', 'الصنف', 'الكمية', 'السعر الإفرادي', 'الإجمالي'],
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
              _buildTotalRow('المبيعات', currency.format(invoice.subtotal)),
              if (invoice.discount > 0)
                _buildTotalRow('الخصم', currency.format(invoice.discount), color: PdfColors.red),
              pw.Divider(),
              _buildTotalRow('الصافي المطلوب', currency.format(invoice.total), isBold: true, fontSize: 16),
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
        pw.Text('شكراً لتعاملكم معنا', style: const pw.TextStyle(fontSize: 14)),
        pw.Text('حررت هذه الفاتورة إلكترونياً ولا تحتاج إلى توقيع', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
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
                    pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (companyPhone != null) pw.Text('هاتف: $companyPhone'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('تقرير الأرباح والخسائر', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.Text('تاريخ الطباعة: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            // Report Items
            _buildReportRow('إجمالي الإيرادات', currencyFormat.format(report.revenue), PdfColors.green),
            pw.SizedBox(height: 10),
            _buildReportRow('تكلفة البضاعة المباعة', currencyFormat.format(report.cost), PdfColors.orange),
            pw.SizedBox(height: 10),
            _buildReportRow('المصروفات التشغيلية', currencyFormat.format(report.expenses), PdfColors.red),
            pw.Divider(),
            _buildReportRow('الربح التشغيلي', currencyFormat.format(report.profit), PdfColors.blue, isBold: true),
            pw.SizedBox(height: 20),
            _buildReportRow('الرواتب والأجور', currencyFormat.format(report.salaries), PdfColors.teal),
            pw.SizedBox(height: 10),
            _buildReportRow('الجرد السنوي / تسوية', currencyFormat.format(report.annualInventories), PdfColors.indigo),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            _buildReportRow(
              'صافي الربح النهائي', 
              currencyFormat.format(report.netProfit), 
              report.netProfit >= 0 ? PdfColors.green : PdfColors.red, 
              isBold: true,
              fontSize: 16,
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'هامش الربح النهائي: ${report.profitMargin.toStringAsFixed(1)}%',
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
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
              pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('تقرير مبيعات الأصناف', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.purple)),
                  pw.Text('تاريخ الطباعة: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['الصنف', 'الكمية المباعة', 'الإيرادات', 'الأرباح'],
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
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
              pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('تقرير أعمار ذمم العملاء', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
                  pw.Text('تاريخ الطباعة: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['العميل', 'حالياً (0-30)', '30-60 يوم', '60-90 يوم', '>90 يوم', 'الإجمالي'],
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');
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
              pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('تقرير حركة الصندوق', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                  pw.Text('تاريخ الطباعة: ${printDateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['التاريخ', 'البيان', 'النوع', 'المبلغ', 'الرصيد'],
            data: entries.map((e) {
              final isIn = e.type == 'in' || e.type == 'receipt';
              return [
                dateFormat.format(e.date),
                e.description,
                e.type == 'opening' ? 'رصيد افتتاحي' : (isIn ? 'وارد' : 'صادر'),
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
                    'الرصيد النهائي: ${currencyFormat.format(entries.last.balance)}',
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
    final currencyFormat = intl.NumberFormat.currency(symbol: 'شيكل', decimalDigits: 2, customPattern: '#,##0.00 \u00A4');

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
                   pw.Text(companyName ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                   if (companyPhone != null) pw.Text('هاتف: $companyPhone'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                   pw.Text('كشف رواتب الموظفين', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                   pw.Text('عن شهر: ${month.month}/${month.year}', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['الموظف', 'الراتب الثابت', 'المدفوع', 'المتبقي', 'التوقيع'],
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
