import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:printing/printing.dart';

/// A service to generate PDF documents for the application.
class PdfService {
  
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
    final currencyFormat = intl.NumberFormat.currency(symbol: '₪', decimalDigits: 2);

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
}

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
