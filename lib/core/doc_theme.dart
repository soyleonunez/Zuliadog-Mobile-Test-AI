import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'theme.dart'; // <-- tu archivo existente para reusar tokens

/// Tipos de archivo soportados
enum DocKind { pdf, word, sheets, image, slides, text, other }

/// Paleta por tipo (reusa tokens de AppTheme donde tiene sentido)
class DocColors {
  static const pdf = Color(0xFFE11D48); // rojo (rose-600)
  static const word = Color(0xFF2563EB); // azul (blue-600)
  static const sheets = AppTheme.success500; // verde
  static const image = AppTheme.warning500; // amarillo
  static const slides = Color(0xFFF97316); // naranja (orange-500)
  static const text = AppTheme.neutral500; // gris
  static const other = Color(0xFF7C3AED); // violeta (violet-600)
}

/// Detección por extensión
DocKind kindFromName(String name) {
  final ext = name.toLowerCase().split('.').last;
  if (ext == 'pdf') return DocKind.pdf;
  if (['doc', 'docx', 'rtf', 'odt', 'pages'].contains(ext)) return DocKind.word;
  if (['xls', 'xlsx', 'csv', 'ods', 'tsv', 'numbers'].contains(ext)) {
    return DocKind.sheets;
  }
  if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'tiff', 'svg', 'heic']
      .contains(ext)) {
    return DocKind.image;
  }
  if (['ppt', 'pptx', 'odp', 'key'].contains(ext)) return DocKind.slides;
  if (['txt', 'md', 'log'].contains(ext)) return DocKind.text;
  return DocKind.other;
}

/// Color por tipo
Color colorForKind(DocKind k) {
  switch (k) {
    case DocKind.pdf:
      return DocColors.pdf;
    case DocKind.word:
      return DocColors.word;
    case DocKind.sheets:
      return DocColors.sheets;
    case DocKind.image:
      return DocColors.image;
    case DocKind.slides:
      return DocColors.slides;
    case DocKind.text:
      return DocColors.text;
    case DocKind.other:
      return DocColors.other;
  }
}

/// Icono Iconsax por tipo
IconData iconForKind(DocKind k) {
  switch (k) {
    case DocKind.pdf:
      return Iconsax.document_code; // “PDF”
    case DocKind.word:
      return Iconsax.document_text; // “Word”
    case DocKind.sheets:
      return Iconsax.document; // “Hojas”
    case DocKind.image:
      return Iconsax.image; // “Imagen”
    case DocKind.slides:
      return Iconsax.presention_chart; // “Slides”
    case DocKind.text:
      return Iconsax.note_2; // “TXT”
    case DocKind.other:
      return Iconsax.document; // genérico
  }
}

/// Ícono coloreado reutilizable
Widget docLeadingIcon(String fileName, {double size = 20}) {
  final k = kindFromName(fileName);
  return Icon(iconForKind(k), size: size, color: colorForKind(k));
}

/// Badge reutilizable (mismo color del tipo)
class DocBadge extends StatelessWidget {
  final String fileName;
  const DocBadge(this.fileName, {super.key});

  @override
  Widget build(BuildContext context) {
    final k = kindFromName(fileName);
    final c = colorForKind(k);
    final label = switch (k) {
      DocKind.pdf => 'PDF',
      DocKind.word => 'Word',
      DocKind.sheets => 'Tabla',
      DocKind.image => 'Imagen',
      DocKind.slides => 'Presentación',
      DocKind.text => 'Texto',
      DocKind.other => 'Otro',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8, vertical: AppTheme.space4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        border: Border.all(color: c.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
