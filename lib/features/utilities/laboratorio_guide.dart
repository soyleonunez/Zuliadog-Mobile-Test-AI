// =======================
// Diálogo de guía para subir documentos
// =======================

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../home.dart' as home;
import 'lab_upload_flow.dart';

class UploadDocumentGuideDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Iconsax.document_upload,
                    color: home.AppColors.primary500, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Guía de Subida de Documentos',
                  style: home.AppText.titleM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: home.AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección 1: Cómo subir documentos
                    _buildSection(
                      '📤 Cómo Subir Documentos',
                      'Sigue estos pasos para subir documentos médicos:',
                      [
                        '1. Haz clic en "Subir Documento" en la sección de Acciones Rápidas',
                        '2. Busca al paciente por nombre o número de historia',
                        '3. Arrastra y suelta el archivo en el área designada',
                        '4. Selecciona el tipo de documento (Resultado de laboratorio, Rayos X, etc.)',
                        '5. Agrega notas adicionales si es necesario',
                        '6. Haz clic en "Subir" para completar el proceso',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección 2: Tipos de archivos soportados
                    _buildSection(
                      '📁 Tipos de Archivos Soportados',
                      'Puedes subir los siguientes tipos de archivos:',
                      [
                        '• PDF - Documentos de texto y reportes',
                        '• JPG/JPEG - Imágenes médicas y fotos',
                        '• PNG - Imágenes con transparencia',
                        '• DOC/DOCX - Documentos de Word',
                        '• Tamaño máximo: 10MB por archivo',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección 3: Cómo descargar documentos
                    _buildSection(
                      '📥 Cómo Descargar Documentos',
                      'Para descargar documentos existentes:',
                      [
                        '1. Ve a la sección "Buscar Documento"',
                        '2. Busca por nombre del paciente o número de historia',
                        '3. Haz clic en "Descargar" junto al documento deseado',
                        '4. El archivo se guardará en tu carpeta de Descargas',
                        '5. También puedes ver detalles del documento antes de descargar',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección 4: Crear órdenes de laboratorio
                    _buildSection(
                      '🧪 Crear Órdenes de Laboratorio',
                      'Para crear nuevas órdenes de laboratorio:',
                      [
                        '1. Haz clic en "Crear Orden" en las Acciones Rápidas',
                        '2. Busca y selecciona al paciente',
                        '3. Especifica las pruebas solicitadas',
                        '4. Asigna un veterinario responsable',
                        '5. Agrega notas adicionales si es necesario',
                        '6. Guarda la orden para que aparezca en el sistema',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección 5: Consejos útiles
                    _buildSection(
                      '💡 Consejos Útiles',
                      'Para un mejor uso del sistema:',
                      [
                        '• Usa nombres descriptivos para los archivos',
                        '• Organiza los documentos por fecha y tipo',
                        '• Revisa el estado de las órdenes regularmente',
                        '• Mantén actualizada la información del paciente',
                        '• Usa las notas para agregar contexto importante',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cerrar',
                      style: home.AppText.bodyM.copyWith(
                        color: home.AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Abrir el flujo de subida real
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LabUploadFlow(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: home.AppColors.primary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Subir Documento Ahora',
                      style: home.AppText.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: home.AppText.titleS.copyWith(
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: home.AppText.bodyM.copyWith(
              color: home.AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: home.AppColors.primary500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: home.AppText.bodyS.copyWith(
                          color: home.AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
