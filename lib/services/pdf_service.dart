import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/appointment.dart';
import 'dart:math';

class PdfService {
  // Singleton pattern
  static final PdfService _instance = PdfService._internal();

  factory PdfService() {
    return _instance;
  }

  PdfService._internal();

  // Generate a random confirmation ID
  String generateConfirmationId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final random = Random();
    final confirmationId = String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return confirmationId;
  }

  // Generate PDF for appointment confirmation
  Future<Uint8List> generateAppointmentConfirmation(
      Appointment appointment) async {
    final pdf = pw.Document();

    // Load a font from assets (if you have a custom font)
    // final font = await PdfGoogleFonts.nunitoRegular();
    // final fontBold = await PdfGoogleFonts.nunitoBold();

    // Add clinic logo
    final PdfColor primaryColor = PdfColor.fromHex('#0D47A1'); // Deep Blue
    final PdfColor accentColor = PdfColor.fromHex('#2196F3'); // Light Blue

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: accentColor,
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Pet Clinic',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(
                            'APPOINTMENT CONFIRMATION',
                            style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Your pet health care partner',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Confirmation ID
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: accentColor,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Confirmation ID: ${appointment.confirmationId}',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Status: ${appointment.status.toUpperCase()}',
                      style: pw.TextStyle(
                        color: PdfColors.green,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Client Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENT INFORMATION',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Divider(color: accentColor),
                    _buildInfoRow('Owner Name', appointment.ownerName),
                    _buildInfoRow('Phone', appointment.contactPhone),
                    _buildInfoRow('Email', appointment.contactEmail),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Pet Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PET INFORMATION',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Divider(color: accentColor),
                    _buildInfoRow('Pet Name', appointment.petName),
                    _buildInfoRow('Pet Type', appointment.petType),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Appointment Details
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'APPOINTMENT DETAILS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Divider(color: accentColor),
                    _buildInfoRow('Service Type', appointment.serviceType),
                    _buildInfoRow('Date',
                        '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}'),
                    _buildInfoRow('Time', appointment.time),
                    if (appointment.notes.isNotEmpty)
                      _buildInfoRow('Notes', appointment.notes),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Thank you for choosing our Pet Clinic',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Please arrive 10 minutes before your scheduled appointment time.',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'If you need to reschedule or cancel, please contact us at (123) 456-7890',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Bottom disclaimer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'This is a digital confirmation of your appointment. No signature required.',
                  style: pw.TextStyle(
                    color: PdfColors.grey,
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper function to build info rows
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  // Print the PDF
  Future<void> printAppointmentConfirmation(Appointment appointment) async {
    final pdf = await generateAppointmentConfirmation(appointment);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf,
    );
  }

  // Save the PDF
  Future<Uint8List> savePdfToBytes(Appointment appointment) async {
    return await generateAppointmentConfirmation(appointment);
  }
}
