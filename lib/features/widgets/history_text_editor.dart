import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/history_service.dart';

/// Widget para editar el contenido de texto de una historia médica
class HistoryTextEditor extends StatefulWidget {
  final Map<String, dynamic> record;
  final HistoryService historyService;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const HistoryTextEditor({
    super.key,
    required this.record,
    required this.historyService,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<HistoryTextEditor> createState() => _HistoryTextEditorState();
}

class _HistoryTextEditorState extends State<HistoryTextEditor> {
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _isSaving = false;
  String _originalText = '';

  @override
  void initState() {
    super.initState();
    _originalText = widget.record['content_delta'] ?? '';
    _textController = TextEditingController(text: _originalText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _textController.text = _originalText;
    });
  }

  Future<void> _saveChanges() async {
    if (_textController.text.trim() == _originalText) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final recordId = widget.record['id'] as String;
      final clinicId = widget.record['clinic_id'] as String;

      await widget.historyService.updateBlockContent(
        recordId,
        _textController.text.trim(),
        clinicId: clinicId,
      );

      setState(() {
        _originalText = _textController.text.trim();
        _isEditing = false;
      });

      if (widget.onSaved != null) {
        widget.onSaved!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y controles
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record['title'] ?? 'Historia médica',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!_isEditing) ...[
                  IconButton(
                    onPressed: _startEditing,
                    icon: const Icon(Iconsax.edit_2, size: 20),
                    tooltip: 'Editar texto',
                  ),
                ] else ...[
                  if (_isSaving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    IconButton(
                      onPressed: _saveChanges,
                      icon: const Icon(Iconsax.tick_circle, size: 20),
                      tooltip: 'Guardar cambios',
                      color: Colors.green,
                    ),
                    IconButton(
                      onPressed: _cancelEditing,
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      tooltip: 'Cancelar',
                      color: Colors.red,
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Fecha y departamento
            Row(
              children: [
                Icon(Iconsax.calendar_1, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  widget.record['date'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.building, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  widget.record['department_code'] ?? 'MED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Área de texto editable
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.blue[50] : Colors.grey[50],
                border: Border.all(
                  color: _isEditing ? Colors.blue[300]! : Colors.grey[300]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isEditing
                  ? TextField(
                      controller: _textController,
                      maxLines: null,
                      minLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Escribe el contenido de la historia médica...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Text(
                      _textController.text.isEmpty
                          ? 'Sin contenido'
                          : _textController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _textController.text.isEmpty
                                ? Colors.grey[500]
                                : null,
                          ),
                    ),
            ),

            // Información adicional
            if (!_isEditing) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.user, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado por: ${widget.record['created_by'] ?? 'Desconocido'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const Spacer(),
                  if (widget.record['locked'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.lock, size: 12, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Bloqueado',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.edit,
                              size: 12, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Editable',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
