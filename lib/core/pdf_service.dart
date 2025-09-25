import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PDFService {
  static Future<void> exportMedicalHistory({
    required Map<String, dynamic> patient,
    required List<Map<String, dynamic>> medicalRecords,
    required String clinicName,
    required String clinicAddress,
    required String clinicPhone,
  }) async {
    final pdf = pw.Document();

    // Cargar logo
    final logoBytes = await _loadAsset('Assets/Images/logo.png');
    pw.ImageProvider? logoProvider;
    if (logoBytes != null) {
      logoProvider = pw.MemoryImage(logoBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildHeader(
                logoProvider,
                clinicName,
                medicalRecords.isNotEmpty
                    ? medicalRecords.first['mrn'] ?? 'N/A'
                    : 'N/A'),
            pw.SizedBox(height: 20),
            _buildOwnerSection(patient),
            pw.SizedBox(height: 15),
            _buildPatientSection(patient),
            pw.SizedBox(height: 20),
            _buildMedicalHistorySection(medicalRecords),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    // Mostrar diálogo de impresión/exportación
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Historia_Clinica_${patient['name'] ?? 'Paciente'}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader(
      pw.ImageProvider? logo, String clinicName, String historyNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) pw.Image(logo, width: 120, height: 40),
            pw.SizedBox(height: 5),
            pw.Text(
              clinicName,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'N° Historia: $historyNumber',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOwnerSection(Map<String, dynamic> patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '👤 ',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.green,
                ),
              ),
              pw.Text(
                'Datos del propietario:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('Nombres:', patient['owner_name'] ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child:
                    _buildField('Apellidos:', patient['owner_lastname'] ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child:
                    _buildField('Dirección:', patient['owner_address'] ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField('Teléfono:', patient['owner_phone'] ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('C.I.:', patient['owner_id'] ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField('E-mail:', patient['owner_email'] ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildField('Profesión:', patient['owner_profession'] ?? ''),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientSection(Map<String, dynamic> patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '🐾 ',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.green,
                ),
              ),
              pw.Text(
                'Datos del paciente:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('Fecha de admisión:',
                    DateFormat('dd/MM/yyyy').format(DateTime.now())),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child:
                    _buildField('Nombre del paciente:', patient['name'] ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('Especie:', patient['species'] ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField('Raza:', patient['breed'] ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('Sexo:', patient['sex'] ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField(
                    'Edad:', _safeToString(patient['age_years']) ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField('Fecha de nacimiento:',
                    _safeToString(patient['birth_date']) ?? ''),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField('Temperatura:',
                    _safeToString(patient['temperature']) ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField(
                    'Peso:', '${_safeToString(patient['weight']) ?? ''} Kg'),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField('Respiración:',
                    _safeToString(patient['respiration']) ?? ''),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildField(
                    'Pulso:', '${_safeToString(patient['pulse']) ?? ''} /min'),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildField(
                    'Hidratación:', _safeToString(patient['hydration']) ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMedicalHistorySection(
      List<Map<String, dynamic>> medicalRecords) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Historial Médico:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...medicalRecords.map((record) => _buildMedicalRecord(record)).toList(),
      ],
    );
  }

  static pw.Widget _buildMedicalRecord(Map<String, dynamic> record) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                record['record_title'] ?? 'Sin título',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(
                    DateTime.tryParse(record['record_date'] ?? '') ??
                        DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (record['record_summary'] != null)
            pw.Text(
              'Motivo de consulta:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          if (record['record_summary'] != null)
            pw.Text(
              record['record_summary'],
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          pw.SizedBox(height: 8),
          if (record['content_delta'] != null)
            pw.Text(
              'Hallazgos y tratamiento:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          if (record['content_delta'] != null)
            pw.Text(
              _extractTextFromDelta(record['content_delta']),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dr/Dra. ${record['doctor'] ?? 'No especificado'}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Departamento: ${record['department_code'] ?? 'MED'}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'QUEDA CONSTANCIA QUE EL MÉDICO TRATANTE ME HA EXPLICADO TODOS LOS EXÁMENES REFERENTES A MI MASCOTA Y HE ENTENDIDO EL DIAGNÓSTICO, PRONÓSTICO, RECOMENDACIONES Y EL TRATAMIENTO, QUEDA A MI TOTAL CONFORMIDAD Y ME HAGO RESPONSABLE DE SU CONDICIÓN.',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Firma del propietario / tutor:',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Firma/sello del médico tratante:',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          height: 1,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '_________________________________',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey400,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '_________________________________',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey400,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ),
      ],
    );
  }

  static String _extractTextFromDelta(dynamic delta) {
    if (delta == null) return '';

    try {
      if (delta is String) {
        final parsed = Uri.decodeComponent(delta);
        return parsed
            .replaceAll(RegExp(r'[\[\]{}"]'), '')
            .replaceAll(',', ' ')
            .trim();
      }
      return delta.toString();
    } catch (e) {
      return delta.toString();
    }
  }

  static String? _safeToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is DateTime) return DateFormat('dd/MM/yyyy').format(value);
    return value.toString();
  }

  static Future<Uint8List?> _loadAsset(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
