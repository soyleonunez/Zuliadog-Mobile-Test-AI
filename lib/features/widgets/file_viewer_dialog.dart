// lib/features/widgets/file_viewer_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/theme.dart';
import '../data/file_service.dart';

class FileViewerDialog extends StatefulWidget {
  final String fileName;
  final String fileUrl;
  final String fileType;

  const FileViewerDialog({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _localFilePath;
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Descargar archivo temporalmente
      final fileService = FileService();
      _localFilePath =
          await fileService.downloadToTemp(widget.fileUrl, widget.fileName);

      // Si es PDF, crear controlador
      if (widget.fileType.toLowerCase() == 'pdf') {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(_localFilePath!),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.neutral200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(),
                    color: _getFileColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.fileType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: _buildContent(),
            ),
            // Footer con acciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.neutral200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _downloadToDownloads,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Descargar a Descargas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cerrar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando archivo...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error cargando archivo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Mostrar contenido según el tipo de archivo
    switch (widget.fileType.toLowerCase()) {
      case 'pdf':
        return _buildPdfViewer();
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return _buildImageViewer();
      default:
        return _buildGenericViewer();
    }
  }

  Widget _buildPdfViewer() {
    if (_pdfController == null) {
      return const Center(
        child: Text('Error cargando PDF'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: PdfViewPinch(
        controller: _pdfController!,
        onDocumentLoaded: (doc) {
          print('PDF cargado: ${doc.pagesCount} páginas');
        },
        onPageChanged: (page) {
          print('Página actual: $page');
        },
      ),
    );
  }

  Widget _buildImageViewer() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Image.file(
          File(_localFilePath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error cargando imagen'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenericViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(),
            size: 64,
            color: _getFileColor(),
          ),
          const SizedBox(height: 16),
          Text(
            widget.fileName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.fileType.toUpperCase()} • Archivo no previsualizable',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadToDownloads() async {
    try {
      final fileService = FileService();
      await fileService.downloadToDownloads(widget.fileUrl, widget.fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo descargado a Descargas: ${widget.fileName}'),
            backgroundColor: AppTheme.success500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error descargando: $e'),
            backgroundColor: AppTheme.danger500,
          ),
        );
      }
    }
  }

  IconData _getFileIcon() {
    switch (widget.fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (widget.fileType.toLowerCase()) {
      case 'pdf':
        return AppTheme.danger500;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return AppTheme.warning500;
      case 'doc':
      case 'docx':
        return const Color(0xFF3B82F6);
      case 'xls':
      case 'xlsx':
        return AppTheme.success500;
      default:
        return AppTheme.neutral500;
    }
  }
}
