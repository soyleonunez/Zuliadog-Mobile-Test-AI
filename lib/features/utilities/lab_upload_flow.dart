import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../home.dart' as home;
import '../services/lab_service.dart';

/// Modal para subir resultados de laboratorio por paciente
class LabUploadFlow extends StatefulWidget {
  const LabUploadFlow({super.key});

  @override
  State<LabUploadFlow> createState() => _LabUploadFlowState();
}

class _LabUploadFlowState extends State<LabUploadFlow> {
  final LabService _labService = LabService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  List<String> _suggestedTests = [];
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedTests() async {
    try {
      final tests = await _labService.getSuggestedTests('veterinaria-zuliadog');
      setState(() {
        _suggestedTests = tests;
      });
    } catch (e) {
      print('Error cargando pruebas sugeridas: $e');
      // Fallback a pruebas básicas
      setState(() {
        _suggestedTests = [
          'Hemograma completo',
          'Perfil bioquímico',
          'Uroanálisis',
        ];
      });
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _labService.searchPatients(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error buscando pacientes: $e');
      // No mostrar error al usuario, solo usar datos mock
      final mockResults = await _labService.searchPatients(query);
      setState(() {
        _searchResults = mockResults;
      });
    }
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _searchResults = [];
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        _showSuccess('${result.files.length} archivo(s) seleccionado(s)');
      }
    } catch (e) {
      _showError('Error seleccionando archivos: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedPatient == null || _selectedFiles.isEmpty) {
      _showError('Selecciona un paciente y al menos un archivo');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      for (final file in _selectedFiles) {
        print('📤 Subiendo archivo: ${file.name}');

        await _labService.uploadResultForPatient(
          patient: _selectedPatient!,
          title:
              'Resultado de laboratorio - ${_selectedPatient!['name']} - ${file.name}',
          fileName: file.name,
          filePath: file.path!,
          fileType: file.extension ?? 'pdf',
          fileSize: file.size,
          testsRequested: _suggestedTests.take(3).join(', '),
          responsibleVet: 'Dr. Veterinario',
        );
      }

      _showSuccess(
          '${_selectedFiles.length} archivo(s) subido(s) correctamente');
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ Error subiendo archivos: $e');
      _showError('Error subiendo archivos: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: home.AppColors.success500,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: home.AppColors.danger500,
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Iconsax.document_text;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Iconsax.image;
      case 'doc':
      case 'docx':
        return Iconsax.document;
      case 'txt':
        return Iconsax.document_text;
      default:
        return Iconsax.document;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: home.AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: home.AppColors.primary500,
              secondary: home.AppColors.primary600,
              surface: Colors.white,
              onSurface: home.AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: home.AppColors.neutral50,
        appBar: AppBar(
          title: const Text('Subir Resultados por Paciente'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  if (_selectedPatient != null) ...[
                    const SizedBox(height: 24),
                    _buildPatientInfoCard(),
                    const SizedBox(height: 24),
                    _buildFileUploadCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: home.AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buscar Paciente',
              style: home.AppText.titleL.copyWith(
                color: home.AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _searchPatients,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o número de historia',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: home.AppColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: home.AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: home.AppColors.primary500, width: 2),
                ),
                filled: true,
                fillColor: home.AppColors.neutral50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Resultados de búsqueda
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: home.AppColors.neutral200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final patient = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: home.AppColors.primary100,
                        child: Icon(
                          Iconsax.pet,
                          color: home.AppColors.primary600,
                        ),
                      ),
                      title: Text(
                        patient['name'] ?? 'Sin nombre',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historia: ${patient['history_number']}',
                            style: home.AppText.bodyS.copyWith(
                              color: home.AppColors.neutral600,
                            ),
                          ),
                          Text(
                            '${patient['species_code']} • ${patient['breed'] ?? 'Sin raza'}',
                            style: home.AppText.bodyS.copyWith(
                              color: home.AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _selectPatient(patient),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: home.AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Paciente',
              style: home.AppText.titleL.copyWith(
                color: home.AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: home.AppColors.primary100,
                  child: Icon(
                    Iconsax.pet,
                    size: 32,
                    color: home.AppColors.primary600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!['name'] ?? 'Sin nombre',
                        style: home.AppText.titleM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Historia: ${_selectedPatient!['history_number']}',
                        style: home.AppText.bodyM.copyWith(
                          color: home.AppColors.primary600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedPatient!['species_code']} • ${_selectedPatient!['breed'] ?? 'Sin raza'}',
                        style: home.AppText.bodyS.copyWith(
                          color: home.AppColors.neutral600,
                        ),
                      ),
                      if (_selectedPatient!['owner_name'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dueño: ${_selectedPatient!['owner_name']}',
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Pruebas Sugeridas',
              style: home.AppText.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: home.AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedTests.take(3).map((test) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: home.AppColors.primary100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    test,
                    style: home.AppText.bodyS.copyWith(
                      color: home.AppColors.primary700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: home.AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archivos a Subir',
              style: home.AppText.titleL.copyWith(
                color: home.AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Zona de drag & drop
            InkWell(
              onTap: _pickFiles,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: home.AppColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: home.AppColors.neutral200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.cloud_add,
                      size: 48,
                      color: home.AppColors.neutral400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Arrastra y suelta archivos aquí',
                      style: home.AppText.bodyM.copyWith(
                        color: home.AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'o haz clic para seleccionar',
                      style: home.AppText.bodyM.copyWith(
                        color: home.AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: home.AppColors.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PDF, JPG, PNG, DOC, DOCX, TXT',
                        style: home.AppText.bodyS.copyWith(
                          color: home.AppColors.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de archivos seleccionados
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Archivos Seleccionados (${_selectedFiles.length})',
                style: home.AppText.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: home.AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: home.AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(file.extension),
                            size: 20,
                            color: home.AppColors.primary500,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: home.AppText.bodyM.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(file.size),
                                  style: home.AppText.bodyS.copyWith(
                                    color: home.AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFile(index),
                            icon: const Icon(Icons.close),
                            color: home.AppColors.danger500,
                            iconSize: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: home.AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subir Archivos',
              style: home.AppText.titleL.copyWith(
                color: home.AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFiles,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Iconsax.cloud_add, size: 24),
                label: Text(
                  _isUploading ? 'Subiendo archivos...' : 'Subir Archivos',
                  style: home.AppText.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: home.AppColors.primary500,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Se subirán ${_selectedFiles.length} archivo(s) para ${_selectedPatient!['name']}',
                style: home.AppText.bodyM.copyWith(
                  color: home.AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
