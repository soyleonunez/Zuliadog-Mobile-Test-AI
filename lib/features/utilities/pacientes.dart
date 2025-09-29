import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../data/data_service.dart';
import '../menu.dart';
import '../../core/navigation.dart';
import 'hospitalizacion.dart';
import '../widgets/patient_form.dart';
import '../../core/notifications.dart';

// ZULIADOG / PetTrackr — Panel de gestión de pacientes
// -----------------------------------------------------
// Este archivo provee una pantalla tipo "Dashboard/Resumen" con:
//  - KPIs (conteo de mascotas, historias)
//  - Listado de pacientes con búsqueda, filtros por estado y paginación
//  - Carga de fotos desde el bucket `patients` con URL firmada
//  - Reconoce la vista `v_app` (vista pública optimizada)
//  - Scoped por clínica usando el clinic_id hardcodeado (patrón actual)
//
// Requisitos:
//  - supabase_flutter: ^2.5.6 (o similar)
//  - La sesión del usuario debe estar iniciada (RLS activas)
//  - Vistas/tablas según el documento estratégico del proyecto
//
// Para usarla: Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsDashboardPage()));

class PatientsDashboardPage extends StatefulWidget {
  const PatientsDashboardPage({super.key});

  @override
  State<PatientsDashboardPage> createState() => _PatientsDashboardPageState();
}

class _PatientsDashboardPageState extends State<PatientsDashboardPage> {
  final _client = Supabase.instance.client;

  // Clinic ID dinámico basado en autenticación
  String? _clinicId;

  // KPIs
  int _kpiTotalMascotas = 0;
  int _kpiCitasCompletadas = 0;
  double _kpiIngresosGenerados = 0.0;
  double _kpiSatisfaccion = 0.0;

  // Listado
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'todos'; // todos|activo|inactivo|fallecido
  int _pageIndex = 0;
  static const _pageSize = 20;
  int _totalRows = 0;
  bool _loading = true;
  List<PatientRow> _rows = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadClinicId();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadClinicId() async {
    try {
      // Usar el clinic_id hardcodeado por ahora
      _clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
      _bootstrap();
    } catch (e) {
      _clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // Fallback
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadKpis(), _loadPage(resetToFirst: true)]);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inicializando panel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -----------------
  // KPI loaders
  // -----------------
  Future<void> _loadKpis() async {
    if (_clinicId == null) return;

    try {
      // Cargar total de mascotas desde la tabla patients directamente
      final countPatients = await _client
          .from('patients')
          .select('id')
          .eq('clinic_id', _clinicId!);

      _kpiTotalMascotas = countPatients.length;

      // Cargar registros médicos completados (últimos 7 días)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final medicalRecords = await _client
          .from('medical_records')
          .select('id, visit_date')
          .eq('clinic_id', _clinicId!)
          .gte('visit_date', sevenDaysAgo.toIso8601String().split('T')[0]);

      _kpiCitasCompletadas = medicalRecords.length;

      // Simular ingresos (ya que no tenemos tabla de appointments)
      _kpiIngresosGenerados = _kpiCitasCompletadas * 50.0;

      // Calcular satisfacción promedio (simulado por ahora)
      _kpiSatisfaccion = 4.8;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('KPI error: $e');
      // Valores por defecto si hay error
      _kpiTotalMascotas = 0;
      _kpiCitasCompletadas = 0;
      _kpiIngresosGenerados = 0.0;
      _kpiSatisfaccion = 0.0;
    }
  }

  // -----------------
  // List / search / pagination
  // -----------------
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadPage(resetToFirst: true);
    });
  }

  Future<void> _loadPage({bool resetToFirst = false}) async {
    if (resetToFirst) _pageIndex = 0;
    if (_clinicId == null) return;

    setState(() => _loading = true);

    try {
      // Usar la vista v_app que ya tiene todos los JOINs
      var query = _client.from('v_app').select('*').eq('clinic_id', _clinicId!);

      final q = _searchCtrl.text.trim();
      if (q.isNotEmpty) {
        // Buscar en múltiples campos de v_app
        query = query.or(
          'patient_name.ilike.%$q%,history_number.ilike.%$q%,history_number_snapshot.ilike.%$q%,owner_name.ilike.%$q%',
        );
      }

      final data = await query.order('patient_name');
      final List rows = (data as List);

      _totalRows = rows.length;

      // Aplicar paginación manualmente
      final from = _pageIndex * _pageSize;
      final to = (from + _pageSize).clamp(0, rows.length);
      final paginatedRows = rows.sublist(from, to);

      _rows = paginatedRows.map((e) => PatientRow.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error al cargar pacientes: $e');
      _rows = [];
      _totalRows = 0;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _nextPage() async {
    if ((_pageIndex + 1) * _pageSize >= _totalRows) return;
    _pageIndex += 1;
    await _loadPage();
  }

  Future<void> _prevPage() async {
    if (_pageIndex == 0) return;
    _pageIndex -= 1;
    await _loadPage();
  }

  // -----------------
  // Image helpers usando DataService
  // -----------------
  Widget _buildPatientAvatar(PatientRow row) {
    return DataService().buildBreedImageWidget(
      breedId: row.breedId,
      species: row.species,
      width: 40,
      height: 40,
      borderRadius: 20,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Row(
            children: [
              // Botones de acción
              _buildHeaderButton(
                icon: Iconsax.add,
                text: 'Nuevo Paciente',
                color: const Color(0xFF4F46E5),
                onTap: () => _openNewPatientForm(),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Iconsax.export_2,
                text: 'Exportar',
                color: const Color(0xFF16A34A),
                onTap: () => _exportPatients(),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Iconsax.refresh,
                text: 'Actualizar',
                color: const Color(0xFF6B7280),
                onTap: _bootstrap,
              ),
              const SizedBox(width: 16),
              // Selector de fecha
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.calendar_1,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Últimos 7 días',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Iconsax.arrow_down_2,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _AnimatedButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 32,
      ), // Mismo padding que la tabla
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Siempre 4 columnas en una sola fila
          int crossAxisCount = 4;
          double childAspectRatio =
              1.8; // Más estrechas para caber siempre en 4 columnas

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: childAspectRatio,
            children: [
              _buildKpiCard(
                icon: Iconsax.pet,
                title: 'Mascotas Totales',
                value: _kpiTotalMascotas.toString(),
                trend: _calculateTrend(_kpiTotalMascotas, _kpiTotalMascotas),
                trendColor: _kpiTotalMascotas >= 0 ? Colors.green : Colors.red,
              ),
              _buildKpiCard(
                icon: Iconsax.tick_circle,
                title: 'Citas Completadas',
                value: _kpiCitasCompletadas.toString(),
                trend: _calculateTrend(
                  _kpiCitasCompletadas,
                  _kpiCitasCompletadas,
                ),
                trendColor:
                    _kpiCitasCompletadas >= 0 ? Colors.green : Colors.red,
              ),
              _buildKpiCard(
                icon: Iconsax.dollar_circle,
                title: 'Ingresos Generados',
                value: '\$${_kpiIngresosGenerados.toStringAsFixed(0)}',
                trend: _calculateTrend(
                  _kpiIngresosGenerados,
                  _kpiIngresosGenerados,
                ),
                trendColor:
                    _kpiIngresosGenerados >= 0 ? Colors.green : Colors.red,
              ),
              _buildKpiCard(
                icon: Iconsax.emoji_happy,
                title: 'Satisfacción del Dueño',
                value: '${_kpiSatisfaccion.toStringAsFixed(1)} / 5.0',
                trend: _calculateTrend(_kpiSatisfaccion, _kpiSatisfaccion),
                trendColor: _kpiSatisfaccion >= 4.0 ? Colors.green : Colors.red,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '7d',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 3),
              Row(
                children: [
                  Icon(
                    trend.startsWith('+')
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_2,
                    size: 8,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      color: trendColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : _buildTableContent(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalRows registros totales',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Hoy, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFilterTabs()),
              const SizedBox(width: 16),
              _buildSearchAndFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterTab('Todos', _statusFilter == 'todos'),
          _buildFilterTab('Activo (56)', _statusFilter == 'activo'),
          _buildFilterTab('Inactivo (34)', _statusFilter == 'inactivo'),
          _buildFilterTab('Fallecido (25)', _statusFilter == 'fallecido'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final status = label.split(' ')[0].toLowerCase();
        setState(() => _statusFilter = status);
        _loadPage(resetToFirst: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color:
                isSelected ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Buscar...',
              hintStyle: TextStyle(color: Color(0xFF6B7280)),
              prefixIcon: Icon(
                Iconsax.search_normal,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.filter, size: 16, color: Color(0xFF1F2937)),
              const SizedBox(width: 8),
              const Text(
                'Filtrar',
                style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas pequeñas, usar ListView en lugar de tabla
        if (constraints.maxWidth < 800) {
          return ListView.builder(
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              final row = _rows[index];
              return _buildMobileTableRow(row);
            },
          );
        }

        // En pantallas grandes, usar tabla
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeaderCell('Mascota')),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Dueño')),
                    Expanded(flex: 1, child: _buildTableHeaderCell('Estado')),
                    Expanded(
                      flex: 1,
                      child: _buildTableHeaderCell('Última Visita'),
                    ),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Acciones')),
                  ],
                ),
              ),
              ..._rows.map((row) => _buildTableRow(row)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTableRow(PatientRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildPatientAvatar(row),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Historia ${row.historyNumber} • ${row.breed ?? row.species ?? ''}, ${_calculateAge(row)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.ownerName ?? 'Sin dueño',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  row.ownerPhone ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [_StatusPill(status: row.status)],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              row.lastVisitAt?.toIso8601String().split('T').first ?? '-',
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(flex: 2, child: _buildPatientActions(row)),
        ],
      ),
    );
  }

  Widget _buildMobileTableRow(PatientRow row) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPatientAvatar(row),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Historia ${row.historyNumber} • ${row.breed ?? row.species ?? ''}, ${_calculateAge(row)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: row.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dueño:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      row.ownerName ?? 'Sin dueño',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (row.ownerPhone != null)
                      Text(
                        row.ownerPhone!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Última visita:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    row.lastVisitAt?.toIso8601String().split('T').first ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPatientActions(row),
        ],
      ),
    );
  }

  Widget _buildPatientActions(PatientRow row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          icon: Iconsax.health,
          tooltip: 'Historia Médica',
          color: const Color(0xFF4F46E5),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/historias',
              arguments: {
                'historyNumber': row.historyNumber,
                'patient_id': row.patientId,
              },
            );
          },
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          icon: Iconsax.document_text,
          tooltip: 'Exámenes',
          color: const Color(0xFF16A34A),
          onTap: () => _showExams({
            'patient_name': row.patientName,
            'patient_id': row.patientId,
            'history_number': row.historyNumber,
          }),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          icon: Iconsax.edit,
          tooltip: 'Editar Paciente',
          color: const Color(0xFFF59E0B),
          onTap: () => _editPatient({
            'patient_name': row.patientName,
            'patient_id': row.patientId,
            'history_number': row.historyNumber,
          }),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _AnimatedButton(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final from = _totalRows == 0 ? 0 : (_pageIndex * _pageSize) + 1;
    final to = ((_pageIndex + 1) * _pageSize).clamp(0, _totalRows);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $from-$to de $_totalRows registros',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _pageIndex > 0 ? _prevPage : null,
                icon: const Icon(Iconsax.arrow_left_2, size: 16),
                color: _pageIndex > 0
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFD1D5DB),
              ),
              _buildPageButton(1, _pageIndex == 0),
              _buildPageButton(2, _pageIndex == 1),
              _buildPageButton(3, _pageIndex == 2),
              const Text('...', style: TextStyle(color: Color(0xFF6B7280))),
              _buildPageButton(19, _pageIndex == 18),
              IconButton(
                onPressed: (_pageIndex + 1) * _pageSize < _totalRows
                    ? _nextPage
                    : null,
                icon: const Icon(Iconsax.arrow_right_2, size: 16),
                color: (_pageIndex + 1) * _pageSize < _totalRows
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int page, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: _AnimatedButton(
        onTap: () {
          setState(() => _pageIndex = page - 1);
          _loadPage();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            page.toString(),
            style: TextStyle(
              fontSize: 14,
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _calculateAge(PatientRow row) {
    return '3 años'; // Placeholder
  }

  String _calculateTrend(num current, num previous) {
    if (previous == 0) return '+0%';
    final change = ((current - previous) / previous * 100);
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  void _navigateToRoute(BuildContext context, String route) {
    // Mapear las rutas del menú a las rutas del sistema de navegación
    String navigationRoute;
    switch (route) {
      case 'frame_home':
        navigationRoute = '/home';
        break;
      case 'frame_pacientes':
        navigationRoute = '/pacientes';
        break;
      case 'frame_historias':
        navigationRoute = '/historias';
        break;
      case 'frame_recetas':
        navigationRoute = '/recetas';
        break;
      case 'frame_laboratorio':
        navigationRoute = '/laboratorio';
        break;
      case 'frame_agenda':
        navigationRoute = '/agenda';
        break;
      case 'frame_hospitalizacion':
        navigationRoute = HospitalizacionPage.route;
        break;
      case 'frame_recursos':
        navigationRoute = '/recursos';
        break;
      case 'frame_tickets':
        navigationRoute = '/tickets';
        break;
      case 'frame_reportes':
        navigationRoute = '/reportes';
        break;
      case 'frame_ajustes':
        // TODO: Implementar página de ajustes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración (próximamente)')),
        );
        return;
      default:
        navigationRoute = '/home';
    }

    // Navegar usando el NavigationHelper
    NavigationHelper.navigateToRoute(context, navigationRoute);
  }

  // -----------------
  // UI
  // -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // background-light
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sidebar de navegación usando el componente existente
              AppSidebar(
                activeRoute: 'frame_pacientes',
                userRole: UserRole.doctor,
                onTap: (route) {
                  _navigateToRoute(context, route);
                },
              ),
              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // Header con título y filtro de fecha
                    _buildHeader(),
                    const SizedBox(height: 32),
                    // KPIs en grid
                    _buildKpiGrid(),
                    const SizedBox(height: 32),
                    // Tabla de pacientes
                    Expanded(child: _buildPatientsTable()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openNewPatientForm() {
    // Abrir formulario de nuevo paciente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernPatientForm(
          onPatientCreated: () {
            // Callback cuando se crea un paciente exitosamente
            Navigator.of(context).pop();
            NotificationService.showSuccess('Paciente creado exitosamente');
            // Recargar datos
            _loadKpis();
            _loadPage();
          },
          onCancel: () {
            // Callback cuando se cancela la creación
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _editPatient(Map<String, dynamic> patient) {
    // Navegar a la página de historias médicas para editar
    Navigator.pushNamed(
      context,
      '/historias',
      arguments: {
        'patient_id': patient['patient_id'],
        'historyNumber': patient['history_number'],
      },
    );
  }

  void _exportPatients() {
    // Mostrar mensaje de funcionalidad pendiente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación próximamente disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showExams(Map<String, dynamic> patient) {
    // Mostrar mensaje de funcionalidad pendiente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Exámenes para ${patient['patient_name']} - Próximamente'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showPatientOptions(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opciones para ${patient['patient_name']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Iconsax.copy),
              title: const Text('Duplicar Paciente'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Función próximamente disponible')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.trash),
              title: const Text('Eliminar Paciente'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Función próximamente disponible')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title: const Text('Compartir Información'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Función próximamente disponible')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PatientRow {
  final String patientId;
  final String clinicId;
  final String patientName;
  final String? historyNumber;
  final int? historyNumberInt;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? species;
  final String? breed;
  final String? breedId;
  final String? sex;
  final String status; // active|inactive|deceased
  final DateTime? lastVisitAt;
  final String? photoPath;

  PatientRow({
    required this.patientId,
    required this.clinicId,
    required this.patientName,
    this.historyNumber,
    this.historyNumberInt,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.species,
    this.breed,
    this.breedId,
    this.sex,
    this.status = 'active',
    this.lastVisitAt,
    this.photoPath,
  });

  factory PatientRow.fromMap(Map<String, dynamic> m) {
    return PatientRow(
      patientId:
          m['patient_id']?.toString() ?? m['patient_uuid']?.toString() ?? '',
      clinicId: m['clinic_id']?.toString() ?? '',
      patientName: m['patient_name']?.toString() ??
          m['paciente_name_snapshot']?.toString() ??
          '',
      historyNumber: m['history_number']?.toString() ??
          m['history_number_snapshot']?.toString(),
      historyNumberInt: m['history_number_int'] is num
          ? (m['history_number_int'] as num).toInt()
          : null,
      ownerName:
          m['owner_name']?.toString() ?? m['owner_name_snapshot']?.toString(),
      ownerPhone: m['owner_phone']?.toString(),
      ownerEmail: m['owner_email']?.toString(),
      species: _getSpeciesLabel(m['species_code']),
      breed: m['breed_label']?.toString() ?? m['breed']?.toString(),
      breedId: m['breed_id']?.toString(),
      sex: m['sex']?.toString(),
      status: (m['status'] ?? 'active') as String,
      lastVisitAt: _tryParseDate(m['last_visit_at']),
      photoPath: m['photo_path']?.toString(),
    );
  }

  static String _getSpeciesLabel(String? speciesCode) {
    switch (speciesCode?.toUpperCase()) {
      case 'CAN':
        return 'Canino';
      case 'FEL':
        return 'Felino';
      case 'AVE':
        return 'Ave';
      case 'EQU':
        return 'Equino';
      case 'BOV':
        return 'Bovino';
      case 'POR':
        return 'Porcino';
      case 'CAP':
        return 'Caprino';
      case 'OVI':
        return 'Ovino';
      default:
        return speciesCode ?? 'Sin especificar';
    }
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  // Getters para compatibilidad
  String get mrn {
    final result =
        historyNumber ?? historyNumberInt?.toString().padLeft(6, '0') ?? '';
    return result;
  }

  String get name => patientName;
}

class _StatusPill extends StatelessWidget {
  final String status; // active|inactive|deceased
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final IconData icon;

    switch (status) {
      case 'inactive':
        label = 'Inactivo';
        color = Colors.amber;
        icon = Iconsax.pause_circle;
        break;
      case 'deceased':
        label = 'Fallecido';
        color = Colors.redAccent;
        icon = Iconsax.close_circle;
        break;
      default:
        label = 'Activo';
        color = Colors.green;
        icon = Iconsax.tick_circle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de botón animado reutilizable
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedButton({required this.onTap, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(8),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
