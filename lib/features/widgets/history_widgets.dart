import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import 'search_widgets.dart';

/// Widget para mostrar un bloque de historia médica
class HistoryBlockCard extends StatelessWidget {
  final HistoryBlock block;
  final String dateFmt;
  final Function(String, bool) onToggleLock;
  final Function(String, String) onSaveDelta;

  const HistoryBlockCard({
    super.key,
    required this.block,
    required this.dateFmt,
    required this.onToggleLock,
    required this.onSaveDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del bloque
            Row(
              children: [
                Icon(
                  block.locked ? Iconsax.lock : Iconsax.unlock,
                  size: 20,
                  color: block.locked ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.title ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onToggleLock(block.id, !block.locked),
                  icon: Icon(
                    block.locked ? Iconsax.unlock : Iconsax.lock,
                    size: 18,
                  ),
                  tooltip: block.locked ? 'Desbloquear' : 'Bloquear',
                ),
              ],
            ),

            // Contenido del bloque
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _extractTextFromDelta(block.deltaJson),
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // Footer con fecha y autor
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.calendar, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat(dateFmt).format(block.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.user, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  block.author,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _extractTextFromDelta(String deltaJson) {
    try {
      // Extraer texto simple del JSON delta
      final regex = RegExp(r'"insert":"([^"]*)"');
      final match = regex.firstMatch(deltaJson);
      return match?.group(1) ?? 'Contenido no disponible';
    } catch (e) {
      return 'Error al leer contenido';
    }
  }
}

/// Widget para mostrar el estado vacío cuando no hay historias
class EmptyHistoryState extends StatelessWidget {
  final VoidCallback? onCreateHistory;

  const EmptyHistoryState({this.onCreateHistory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.health,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historias médicas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un paciente para ver su historial médico',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (onCreateHistory != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateHistory,
              icon: const Icon(Iconsax.add),
              label: const Text('Crear Primera Historia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para mostrar el estado de carga
class LoadingHistoryState extends StatelessWidget {
  const LoadingHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando historias médicas...'),
        ],
      ),
    );
  }
}

/// Widget para mostrar cuando no hay paciente seleccionado
class NoPatientSelectedView extends StatefulWidget {
  final Function(String) onPatientSelected;

  const NoPatientSelectedView({required this.onPatientSelected});

  @override
  State<NoPatientSelectedView> createState() => _NoPatientSelectedViewState();
}

class _NoPatientSelectedViewState extends State<NoPatientSelectedView> {
  final _searchController = TextEditingController();
  final _historyService = HistoryService();
  List<PatientSearchRow> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _historyService.searchPatients(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      print('Error en búsqueda: $e');
    }
  }

  Future<void> _runDiagnostic() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Ejecutando diagnóstico...'),
            ],
          ),
        ),
      );

      // Ejecutar diagnóstico
      final result = await _historyService.diagnoseConnection();

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar resultados
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diagnóstico de Conexión'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Estado de conexión: ${result['connection'] ? '✅ Conectado' : '❌ Error'}'),
                const SizedBox(height: 16),
                if (result['tables'] != null) ...[
                  const Text('Tablas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result['tables'].entries.map((entry) =>
                      Text('  ${entry.value ? '✅' : '❌'} ${entry.key}')),
                  const SizedBox(height: 16),
                ],
                if (result['views'] != null) ...[
                  const Text('Vistas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result['views'].entries.map((entry) =>
                      Text('  ${entry.value ? '✅' : '❌'} ${entry.key}')),
                  const SizedBox(height: 16),
                ],
                if (result['error'] != null) ...[
                  const Text('Error:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(result['error'],
                      style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en diagnóstico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un Paciente',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          PatientSearchField(
            searchController: _searchController,
            searchResults: _searchResults,
            isSearching: _isSearching,
            onSearchChanged: _searchPatients,
            onPatientSelected: (patient) {
              // Debug: mostrar qué datos se están recibiendo
              print('🔍 Paciente seleccionado desde NoPatientSelectedView:');
              print('  - patientId: ${patient.patientId}');
              print('  - historyNumber: ${patient.historyNumber}');
              print('  - patientName: ${patient.patientName}');

              // Usar el número de historia en lugar del UUID
              final mrnToUse = patient.historyNumber ?? patient.patientId;
              print('🔍 MRN a usar desde NoPatientSelectedView: $mrnToUse');
              widget.onPatientSelected(mrnToUse);
            },
          ),
          const SizedBox(height: 24),

          // Acciones rápidas
          _buildQuickActionsRow(),
          const SizedBox(height: 16),

          // Botón de diagnóstico
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _runDiagnostic();
              },
              icon: const Icon(Iconsax.setting_2),
              label: const Text('Diagnóstico de Conexión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Área de resultados de búsqueda
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(
                        child: Text('No se encontraron pacientes'),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                                'Ingresa un término de búsqueda para comenzar'),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final patient = _searchResults[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF4F46E5),
                                    child: Icon(
                                      Iconsax.pet,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(patient.patientName),
                                  subtitle: Text(
                                      'MRN: ${patient.historyNumber ?? 'N/A'}'),
                                  onTap: () {
                                    // Debug: mostrar qué datos se están recibiendo
                                    print(
                                        '🔍 Paciente seleccionado desde ListTile:');
                                    print(
                                        '  - patientId: ${patient.patientId}');
                                    print(
                                        '  - historyNumber: ${patient.historyNumber}');
                                    print(
                                        '  - patientName: ${patient.patientName}');

                                    // Usar el número de historia en lugar del UUID
                                    final mrnToUse = patient.historyNumber ??
                                        patient.patientId;
                                    print(
                                        '🔍 MRN a usar desde ListTile: $mrnToUse');
                                    widget.onPatientSelected(mrnToUse);
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar nueva historia
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nueva Historia (pendiente)')),
              );
            },
            icon: const Icon(Iconsax.add_circle, size: 18),
            label: const Text('Nueva Historia', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              foregroundColor: const Color(0xFF4F46E5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar crear camada
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Crear Camada (pendiente)')),
              );
            },
            icon: const Icon(Iconsax.pet, size: 18),
            label: const Text('Crear Camada', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.1),
              foregroundColor: Colors.orange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar editar paciente
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar Paciente (pendiente)')),
              );
            },
            icon: const Icon(Iconsax.edit, size: 18),
            label:
                const Text('Editar Paciente', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              foregroundColor: Colors.blue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget para el timeline de eventos
class TimelineItem extends StatelessWidget {
  final TimelineEvent event;

  const TimelineItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Punto del timeline
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido del evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM y, h:mm a').format(event.at),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog para crear historias médicas
class HistoryEditorDialog extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onSave;

  const HistoryEditorDialog({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Iconsax.document_text, color: Color(0xFF4F46E5)),
                const SizedBox(width: 12),
                const Text(
                  'Editor de Historia Médica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Iconsax.close_circle),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Formulario
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Número de Historia',
                      hintText: 'Ingresa el número de historia',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: contentController,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: 'Describe la consulta o tratamiento',
                        hintText: 'Escribe aquí la historia médica...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botones
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
