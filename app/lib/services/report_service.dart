import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_record.dart';

class ReportService {
  static Future<String> _getExportDirectory() async {
    try {
      Directory directory;
      
      if (Platform.isAndroid) {
        // For Android, use external storage
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final exportDir = Directory('${directory.path}/RESP-AI_Reports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      debugPrint('Export directory: ${exportDir.path}');
      return exportDir.path;
    } catch (e) {
      debugPrint('Error getting export directory: $e');
      // Fallback to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  static Future<pw.Document> _buildReportDocument(HistoryRecord record) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final riskLevel = record.riskScore >= 7 ? 'HIGH RISK' : (record.riskScore >= 4 ? 'MODERATE RISK' : 'LOW RISK');
          final riskColor = record.riskScore >= 7 ? PdfColors.red : (record.riskScore >= 4 ? PdfColors.orange : PdfColors.green);
          
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RESP-AI CLINICAL REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          DateFormat('MMM d, yyyy').format(record.timestamp),
                          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
                        ),
                        pw.Text(
                          DateFormat('h:mm a').format(record.timestamp),
                          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 20),
                
                // Risk Score Badge
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: riskColor.shade(50),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Risk Score: ',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${record.riskScore.toStringAsFixed(1)} / 10.0',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: riskColor),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: riskColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          riskLevel,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),
                
                _buildSectionTitle('ANALYSIS SUMMARY'),
                pw.SizedBox(height: 12),
                _buildInfoRow('Classification:', record.classification),
                _buildInfoRow('Associated Condition:', record.condition),
                _buildInfoRow('Confidence Level:', '${(record.confidence * 100).toStringAsFixed(1)}%'),
                
                pw.SizedBox(height: 25),
                _buildSectionTitle('SYMPTOMS & OBSERVATIONS'),
                pw.SizedBox(height: 12),
                if (record.symptoms.isNotEmpty)
                  pw.Text(record.symptoms.join(', '), style: const pw.TextStyle(fontSize: 11))
                else
                  pw.Text('No specific symptoms recorded.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11)),
                
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('Additional Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(record.notes!, style: const pw.TextStyle(fontSize: 11)),
                ],

                pw.SizedBox(height: 25),
                _buildSectionTitle('RECOMMENDED NEXT STEPS'),
                pw.SizedBox(height: 12),
                if (record.riskScore >= 7)
                  pw.Text('• Consult a healthcare professional immediately\n• Do not delay seeking medical attention\n• Bring this report to your appointment', style: const pw.TextStyle(fontSize: 11))
                else if (record.riskScore >= 4)
                  pw.Text('• Schedule an appointment with your doctor\n• Monitor symptoms for any changes\n• Consider a follow-up assessment in 1-2 weeks', style: const pw.TextStyle(fontSize: 11))
                else
                  pw.Text('• Continue regular health monitoring\n• Maintain healthy respiratory habits\n• Schedule routine check-ups as recommended', style: const pw.TextStyle(fontSize: 11)),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DISCLAIMER: This report is generated by an AI screening tool and is NOT a medical diagnosis. '
                  'Always consult with a qualified medical professional for diagnosis and treatment.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static Future<void> generateAndShareReport(HistoryRecord record) async {
    try {
      final pdf = await _buildReportDocument(record);
      final filename = 'resp-ai-report-${record.id.substring(0, 8)}.pdf';
      
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: filename,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: filename,
        );
      }
    } catch (e) {
      debugPrint('Error sharing report: $e');
      rethrow;
    }
  }

  static Future<String> exportReportToFile(HistoryRecord record) async {
    try {
      final pdf = await _buildReportDocument(record);
      final exportPath = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(record.timestamp);
      final filename = 'resp-ai-report-$timestamp.pdf';
      final filePath = '$exportPath/$filename';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('Report exported to: $filePath');
      
      // Also share the file after saving
      try {
        await Share.shareXFiles([XFile(filePath)], text: 'RESP-AI Clinical Report');
      } catch (e) {
        debugPrint('Share after export failed (non-critical): $e');
      }
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting report: $e');
      rethrow;
    }
  }

  static Future<void> viewPdfFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // Try to regenerate the PDF
        debugPrint('PDF file not found, regenerating...');
        throw Exception('PDF file not found');
      }
      
      final bytes = await file.readAsBytes();
      final filename = filePath.split('/').last;
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: filename,
      );
    } catch (e) {
      debugPrint('Error viewing PDF: $e');
      rethrow;
    }
  }

  static Future<void> generateAndShareHistoryReport(List<HistoryRecord> records) async {
    try {
      final pdf = pw.Document();
      final filename = 'resp-ai-history-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RESP-AI HISTORY REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This report contains a summary of respiratory risk assessments over the selected period.',
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Risk', 'Condition', 'Symptoms'],
                  ...records.map((r) => [
                    DateFormat('MMM d, HH:mm').format(r.timestamp),
                    r.riskScore.toStringAsFixed(1),
                    r.condition,
                    r.symptoms.take(2).join(', ') + (r.symptoms.length > 2 ? '...' : ''),
                  ]),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 40),
                child: pw.Text(
                  'DISCLAIMER: This report is for screening purposes only. '
                  'It is NOT a medical diagnosis. Consult a doctor for clinical advice.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: filename,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: filename,
        );
      }
    } catch (e) {
      debugPrint('Error generating history report: $e');
      rethrow;
    }
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      width: double.infinity,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
          fontSize: 14,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Text(value),
        ],
      ),
    );
  }
}
