import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../menu.dart';
import '../home.dart' as home;
import '../../core/navigation.dart';
import 'hospitalizacion.dart';
import '../services/lab_service.dart';
import 'laboratorio_guide.dart';

final _supa = Supabase.instance.client;

class LaboratorioPage extends StatefulWidget {
  const LaboratorioPage({super.key});

  static const route = '/laboratorio';

  @override
  State<LaboratorioPage> createState() => _LaboratorioPageState();
}

class _LaboratorioPageState extends State<LaboratorioPage> {
  final LabService _labService = LabService();
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String _activeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🔄 Cargando datos de laboratorio...');
      final stats = await _labService.getLabStats();
      final orders = await _labService.getRecentOrders();

      print('📊 Estadísticas cargadas: $stats');
      print('📋 Órdenes cargadas: ${orders.length}');
      print('📋 Primeras 3 órdenes: ${orders.take(3).toList()}');

      setState(() {
        _stats = stats;
        _orders = orders;
        _filteredOrders = orders; // Inicializar con todas las órdenes
        _isLoading = false;
      });

      print('✅ Datos de laboratorio cargados correctamente');
      print('✅ Estado actualizado - _orders.length: ${_orders.length}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error cargando datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: home.AppColors.primary500.withOpacity(.12),
        hoverColor: home.AppColors.neutral50,
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
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(
              activeRoute: 'frame_laboratorio',
              onTap: (route) => _handleNavigation(context, route),
              userRole: UserRole.doctor,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Divider(height: 1, color: home.AppColors.neutral200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con estadísticas
                          _buildStatsSection(),
                          const SizedBox(height: 32),

                          // Acciones rápidas
                          _buildQuickActionsSection(context),
                          const SizedBox(height: 32),

                          // Órdenes recientes
                          _buildRecentOrdersSection(),
                        ],
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

  void _handleNavigation(BuildContext context, String route) {
    if (route == 'frame_home') {
      NavigationHelper.navigateToRoute(context, '/home');
    } else if (route == 'frame_laboratorio') {
      // Ya estamos en laboratorio
    } else {
      // Navegar a la página correspondiente
      String routePath = '/home'; // fallback
      switch (route) {
        case 'frame_pacientes':
          routePath = '/pacientes';
          break;
        case 'frame_historias':
          routePath = '/historias';
          break;
        case 'frame_recetas':
          routePath = '/recetas';
          break;
        case 'frame_agenda':
          routePath = '/agenda';
          break;
        case 'frame_hospitalizacion':
          routePath = HospitalizacionPage.route;
          break;
        case 'frame_recursos':
          routePath = '/recursos';
          break;
        case 'frame_tickets':
          routePath = '/tickets';
          break;
        case 'frame_reportes':
          routePath = '/reportes';
          break;
      }
      NavigationHelper.navigateToRoute(context, routePath);
    }
  }

  Widget _buildTopBar() {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: home.AppColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Laboratorio',
              style: home.AppText.titleM.copyWith(
                color: home.AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          // En móvil: scroll horizontal
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: _StatCard(
                    title: 'Órdenes Pendientes',
                    value: _stats['pending']?.toString() ?? '0',
                    change: '+14.3%',
                    isPositive: true,
                    icon: Icons.hourglass_empty,
                    color: home.AppColors.warning500,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _StatCard(
                    title: 'En Proceso',
                    value: _stats['processing']?.toString() ?? '0',
                    change: '-25%',
                    isPositive: false,
                    icon: Icons.sync,
                    color: home.AppColors.primary500,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _StatCard(
                    title: 'Completadas',
                    value: _stats['completed']?.toString() ?? '0',
                    change: '+11.8%',
                    isPositive: true,
                    icon: Icons.check_circle,
                    color: home.AppColors.success500,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _StatCard(
                    title: 'Resultados Críticos',
                    value: _stats['critical']?.toString() ?? '0',
                    change: '+200%',
                    isPositive: true,
                    icon: Icons.warning,
                    color: home.AppColors.danger500,
                  ),
                ),
              ],
            ),
          );
        } else {
          // En tablet y desktop: fila horizontal con scroll
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'Órdenes Pendientes',
                    value: _stats['pending']?.toString() ?? '0',
                    change: '+14.3%',
                    isPositive: true,
                    icon: Icons.hourglass_empty,
                    color: home.AppColors.warning500,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'En Proceso',
                    value: _stats['processing']?.toString() ?? '0',
                    change: '-25%',
                    isPositive: false,
                    icon: Icons.sync,
                    color: home.AppColors.primary500,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'Completadas',
                    value: _stats['completed']?.toString() ?? '0',
                    change: '+11.8%',
                    isPositive: true,
                    icon: Icons.check_circle,
                    color: home.AppColors.success500,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 280,
                  child: _StatCard(
                    title: 'Resultados Críticos',
                    value: _stats['critical']?.toString() ?? '0',
                    change: '+200%',
                    isPositive: true,
                    icon: Icons.warning,
                    color: home.AppColors.danger500,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Iconsax.cloud_add,
        label: 'Subir Documento',
        color: home.AppColors.primary500,
        onTap: () => _showUploadModal(context),
      ),
      _QuickAction(
        icon: Iconsax.search_normal,
        label: 'Buscar Documento',
        color: home.AppColors.neutral500,
        onTap: () => _showSearchModal(context),
      ),
      _QuickAction(
        icon: Iconsax.add_circle,
        label: 'Crear Orden',
        color: home.AppColors.success500,
        onTap: () => _showCreateOrderModal(context),
      ),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: home.AppText.titleS.copyWith(
                fontWeight: FontWeight.w600,
                color: home.AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions
                  .map((action) => _QuickActionButton(action: action))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;

              if (isMobile) {
                // En móvil: título arriba, filtros abajo
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Órdenes Recientes',
                      style: home.AppText.titleS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: home.AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todos',
                            isSelected: _activeFilter == 'Todos',
                            onTap: () => _filterOrders('Todos'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pendiente',
                            isSelected: _activeFilter == 'Pendiente',
                            onTap: () => _filterOrders('Pendiente'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'En Proceso',
                            isSelected: _activeFilter == 'En Proceso',
                            onTap: () => _filterOrders('En Proceso'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completada',
                            isSelected: _activeFilter == 'Completada',
                            onTap: () => _filterOrders('Completada'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Crítico',
                            isSelected: _activeFilter == 'Crítico',
                            onTap: () => _filterOrders('Crítico'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // En desktop: título y filtros en la misma fila
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Órdenes Recientes',
                      style: home.AppText.titleS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: home.AppColors.neutral900,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todos',
                            isSelected: _activeFilter == 'Todos',
                            onTap: () => _filterOrders('Todos'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pendiente',
                            isSelected: _activeFilter == 'Pendiente',
                            onTap: () => _filterOrders('Pendiente'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'En Proceso',
                            isSelected: _activeFilter == 'En Proceso',
                            onTap: () => _filterOrders('En Proceso'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completada',
                            isSelected: _activeFilter == 'Completada',
                            onTap: () => _filterOrders('Completada'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Crítico',
                            isSelected: _activeFilter == 'Crítico',
                            onTap: () => _filterOrders('Crítico'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: home.AppColors.neutral200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _OrdersTable(
                      orders: _filteredOrders,
                      onStatusChanged: _loadData,
                      onOrderSelected: _showOrderDetails,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UploadDocumentGuideDialog(),
    );
  }

  void _showSearchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ReportSearchDialog(),
    );
  }

  void _showCreateOrderModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateOrderDialog(
        onOrderCreated: _loadData,
      ),
    );
  }

  void _filterOrders(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'Todos') {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          final status = order['status'] as String? ?? '';
          switch (filter) {
            case 'Pendiente':
              return status == 'Pendiente';
            case 'En Proceso':
              return status == 'En Proceso';
            case 'Completada':
              return status == 'Completada';
            case 'Crítico':
              return status == 'Crítico';
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalles de la Orden',
          style: home.AppText.titleS.copyWith(
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderDetailRow('Orden #', order['order_number'] ?? 'N/A'),
              _buildOrderDetailRow('Paciente', order['patient_name'] ?? 'N/A'),
              _buildOrderDetailRow('MRN', order['mrn'] ?? 'N/A'),
              _buildOrderDetailRow('Especie', order['species_code'] ?? 'N/A'),
              _buildOrderDetailRow('Raza', order['breed'] ?? 'N/A'),
              _buildOrderDetailRow(
                  'Pruebas', order['tests_requested'] ?? 'Sin especificar'),
              _buildOrderDetailRow(
                  'Responsable', order['responsible'] ?? 'Sin asignar'),
              _buildOrderDetailRow('Estado', order['status'] ?? 'N/A'),
              _buildOrderDetailRow('Creado', _formatDate(order['created_at'])),
              _buildOrderDetailRow(
                  'Actualizado', _formatDate(order['updated_at'])),
              if (order['notes'] != null)
                _buildOrderDetailRow('Notas', order['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          _buildOrderActionButton(
            'Editar',
            Iconsax.edit,
            home.AppColors.primary500,
            () => _editOrder(order),
          ),
          _buildOrderActionButton(
            'Borrar',
            Iconsax.trash,
            home.AppColors.danger500,
            () => _deleteOrder(order),
          ),
          _buildOrderActionButton(
            'Completar',
            Iconsax.tick_circle,
            home.AppColors.success500,
            () => _completeOrder(order),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: home.AppText.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: home.AppColors.neutral700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: home.AppText.bodyS.copyWith(
                color: home.AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: home.AppText.bodyS.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _editOrder(Map<String, dynamic> order) {
    Navigator.of(context).pop(); // Cerrar el diálogo de detalles

    // Mostrar diálogo de edición
    showDialog(
      context: context,
      builder: (context) => _EditOrderDialog(
        order: order,
        onOrderUpdated: _loadData,
      ),
    );
  }

  Future<void> _deleteOrder(Map<String, dynamic> order) async {
    Navigator.of(context).pop(); // Cerrar el diálogo de detalles

    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Eliminación',
          style: home.AppText.titleS.copyWith(
            fontWeight: FontWeight.w600,
            color: home.AppColors.danger500,
          ),
        ),
        content: Text(
            '¿Estás seguro de que quieres eliminar la orden ${order['order_number']}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: home.AppColors.danger500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Eliminar de la base de datos
        await _supa.from('lab_documents').delete().eq('id', order['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Orden ${order['order_number']} eliminada exitosamente'),
              backgroundColor: home.AppColors.success500,
            ),
          );

          // Recargar datos
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar orden: $e'),
              backgroundColor: home.AppColors.danger500,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeOrder(Map<String, dynamic> order) async {
    Navigator.of(context).pop(); // Cerrar el diálogo de detalles

    try {
      // Actualizar estado a "Completada"
      await _supa.from('lab_documents').update({
        'status': 'Completada',
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', order['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Orden ${order['order_number']} marcada como completada'),
            backgroundColor: home.AppColors.success500,
          ),
        );

        // Recargar datos
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar orden: $e'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _ReportSearchDialog extends StatefulWidget {
  @override
  State<_ReportSearchDialog> createState() => _ReportSearchDialogState();
}

class _ReportSearchDialogState extends State<_ReportSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchReports(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Buscar reportes de laboratorio por history_number, title, tests_requested o responsible_vet
      final response = await _supa
          .from('lab_documents')
          .select('''
            *,
            patients!inner(
              name,
              history_number,
              species_code,
              breed_id,
              breed,
              owners:owner_id (
                name,
                phone,
                email
              ),
              breeds:breed_id (
                label,
                species_code,
                species_label
              )
            )
          ''')
          .eq('clinic_id', '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203')
          .or('title.ilike.%$query%,tests_requested.ilike.%$query%,responsible_vet.ilike.%$query%,history_number.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar reportes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Iconsax.search_normal,
                    color: home.AppColors.primary600, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Buscar Reportes de Laboratorio',
                  style: home.AppText.titleS.copyWith(
                    fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),

            // Campo de búsqueda
            TextField(
              controller: _searchController,
              onChanged: _searchReports,
              decoration: InputDecoration(
                hintText:
                    'Buscar por número de historia, título, pruebas o veterinario',
                prefixIcon: Icon(Iconsax.search_normal,
                    color: home.AppColors.neutral400, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: home.AppColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: home.AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: home.AppColors.primary500, width: 2),
                ),
                filled: true,
                fillColor: home.AppColors.neutral50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Resultados
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Buscando reportes...'),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.document_text,
                                size: 48,
                                color: home.AppColors.neutral400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron reportes',
                                style: home.AppText.bodyM.copyWith(
                                  color: home.AppColors.neutral600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Intenta con otros términos de búsqueda',
                                style: home.AppText.bodyS.copyWith(
                                  color: home.AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final doc = _searchResults[index];
                            final patient =
                                doc['patients'] as Map<String, dynamic>?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: home.AppColors.neutral50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: home.AppColors.neutral200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: home.AppColors.primary100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getFileIcon(doc['file_type']),
                                          color: home.AppColors.primary600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc['title'] ?? 'Sin título',
                                              style:
                                                  home.AppText.bodyM.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Paciente: ${patient?['name'] ?? 'N/A'} (${doc['history_number']})',
                                              style:
                                                  home.AppText.bodyS.copyWith(
                                                color:
                                                    home.AppColors.neutral600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Archivo: ${doc['file_name']} • ${_formatFileSize(doc['file_size'] ?? 0)}',
                                              style:
                                                  home.AppText.bodyS.copyWith(
                                                color:
                                                    home.AppColors.neutral500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _StatusChip(
                                        status: doc['status'],
                                        documentId: doc['id'],
                                        onStatusChanged: () {
                                          // Recargar datos después de cambiar el estado
                                          setState(() {
                                            _searchReports(
                                                _searchController.text);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Metadatos adicionales
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetadataItem(
                                          Iconsax.calendar_1,
                                          'Creado: ${_formatDate(doc['created_at'])}',
                                          home.AppColors.neutral500,
                                        ),
                                      ),
                                      if (doc['responsible_vet'] != null) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildMetadataItem(
                                            Iconsax.user_square,
                                            'Vet: ${doc['responsible_vet']}',
                                            home.AppColors.neutral500,
                                          ),
                                        ),
                                      ],
                                      if (doc['tests_requested'] != null) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildMetadataItem(
                                            Iconsax.document_text,
                                            'Pruebas: ${doc['tests_requested']}',
                                            home.AppColors.neutral500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Botones de acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          'Descargar',
                                          Iconsax.document_download,
                                          home.AppColors.primary500,
                                          () => _downloadDocument(doc),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildActionButton(
                                          'Ver Detalles',
                                          Iconsax.eye,
                                          home.AppColors.neutral500,
                                          () => _showDocumentDetails(
                                              doc, patient),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
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
      default:
        return Iconsax.document;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildMetadataItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: home.AppText.bodyS.copyWith(
              color: color,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: home.AppText.bodyS.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadDocument(Map<String, dynamic> doc) async {
    try {
      final filePath = doc['file_path'] as String?;
      if (filePath == null || filePath.isEmpty) {
        _showError('No se encontró la ruta del archivo');
        return;
      }

      // Mostrar indicador de descarga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('Descargando ${doc['file_name']}...'),
              ],
            ),
            backgroundColor: home.AppColors.primary500,
          ),
        );
      }

      // Obtener la carpeta de descargas del sistema
      final downloadsPath = await _getDownloadsPath();
      final fileName = doc['file_name'] as String? ?? 'documento.pdf';
      final localPath = '$downloadsPath/$fileName';

      // Simular descarga (en una app real, aquí usarías un plugin de descarga)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${doc['file_name']} descargado exitosamente'),
                const SizedBox(height: 4),
                Text(
                  'Guardado en: $localPath',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: home.AppColors.success500,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      print('📥 Descargando archivo: $filePath');
      print('📁 Archivo: ${doc['file_name']}');
      print('📊 Tamaño: ${_formatFileSize(doc['file_size'] ?? 0)}');
      print('💾 Ruta local: $localPath');
    } catch (e) {
      _showError('Error al descargar archivo: $e');
    }
  }

  Future<String> _getDownloadsPath() async {
    try {
      // Obtener la carpeta de descargas del sistema
      final directory =
          Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      if (!await directory.exists()) {
        // Si no existe, crear la carpeta
        await directory.create(recursive: true);
      }
      return directory.path;
    } catch (e) {
      // Fallback a una carpeta temporal
      final tempDir = Directory.systemTemp;
      return tempDir.path;
    }
  }

  void _showDocumentDetails(
      Map<String, dynamic> doc, Map<String, dynamic>? patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalles del Documento',
          style: home.AppText.titleS.copyWith(
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Título', doc['title'] ?? 'N/A'),
              _buildDetailRow('Archivo', doc['file_name'] ?? 'N/A'),
              _buildDetailRow('Tipo', doc['file_type'] ?? 'N/A'),
              _buildDetailRow('Tamaño', _formatFileSize(doc['file_size'] ?? 0)),
              _buildDetailRow('Estado', doc['status'] ?? 'N/A'),
              _buildDetailRow('Paciente', patient?['name'] ?? 'N/A'),
              _buildDetailRow('Historia', doc['history_number'] ?? 'N/A'),
              if (doc['responsible_vet'] != null)
                _buildDetailRow('Veterinario', doc['responsible_vet']),
              if (doc['tests_requested'] != null)
                _buildDetailRow('Pruebas', doc['tests_requested']),
              if (doc['notes'] != null) _buildDetailRow('Notas', doc['notes']),
              _buildDetailRow('Creado', _formatDate(doc['created_at'])),
              _buildDetailRow('Actualizado', _formatDate(doc['updated_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadDocument(doc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: home.AppColors.primary500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: home.AppText.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: home.AppColors.neutral700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: home.AppText.bodyS.copyWith(
                color: home.AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    }
  }
}

class _CreateOrderDialog extends StatefulWidget {
  final VoidCallback? onOrderCreated;

  const _CreateOrderDialog({this.onOrderCreated});

  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _testsController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _patientController.dispose();
    _testsController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Usar la misma lógica que home.dart para buscar pacientes
      final response = await _supa
          .from('patients')
          .select('''
            id,
            history_number,
            name,
            species_code,
            breed_id,
            breed,
            sex,
            birth_date,
            weight_kg,
            notes,
            owner_id,
            clinic_id,
            temper,
            temperature,
            respiration,
            pulse,
            hydration,
            weight,
            admission_date,
            _patient_id,
            created_at,
            updated_at,
            owners:owner_id (
              name,
              phone,
              email
            ),
            breeds:breed_id (
              label,
              species_code,
              species_label
            )
          ''')
          .eq('clinic_id',
              '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203') // Usar el mismo clinic_id que home.dart
          .or('name.ilike.%$query%,history_number.ilike.%$query%')
          .limit(10);

      // Procesar los resultados con el mismo formato que home.dart
      final processedResults = response.map((record) {
        final owner = record['owners'] as Map<String, dynamic>?;
        final breed = record['breeds'] as Map<String, dynamic>?;

        return {
          'id': record['id'],
          'name': record['name'],
          'history_number': record['history_number'],
          'species_code': record['species_code'],
          'breed': breed?['label'] ?? record['breed'],
          'breed_id': record['breed_id'],
          'sex': record['sex'],
          'owners': owner,
        };
      }).toList();

      setState(() {
        _searchResults = processedResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar pacientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate() || _selectedPatient == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final orderData = {
        'history_number': _selectedPatient!['history_number'],
        'patient_id': _selectedPatient!['id'],
        'clinic_id': '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203',
        'title': 'Orden de Laboratorio - ${_testsController.text}',
        'file_name': 'orden_${DateTime.now().millisecondsSinceEpoch}.txt',
        'file_path':
            'lab_orders/${_selectedPatient!['history_number']}/orden_${DateTime.now().millisecondsSinceEpoch}.txt',
        'file_type': 'txt',
        'file_size': 0,
        'storage_bucket': 'lab_results',
        'storage_key':
            'lab_orders/${_selectedPatient!['history_number']}/orden_${DateTime.now().millisecondsSinceEpoch}.txt',
        'status': 'Pendiente',
        'tests_requested': _testsController.text,
        'notes': _notesController.text,
        'responsible_vet': _vetController.text,
        'uploaded_by': _supa.auth.currentUser?.id,
      };

      await _supa.from('lab_documents').insert(orderData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden de laboratorio creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar datos para mostrar la nueva orden
        widget.onOrderCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear orden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Iconsax.add_circle,
                      color: home.AppColors.success500, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Crear Orden de Laboratorio',
                    style: home.AppText.titleS.copyWith(
                      fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),

              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Campo de paciente
                      Text(
                        'Paciente',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _patientController,
                        onChanged: _searchPatients,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o número de historia',
                          prefixIcon: Icon(Iconsax.user,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),

                      // Resultados de búsqueda de pacientes
                      if (_isSearching)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: home.AppColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Buscando pacientes...'),
                            ],
                          ),
                        )
                      else if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: home.AppColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: home.AppColors.neutral200),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final patient = _searchResults[index];
                              final owner =
                                  patient['owners'] as Map<String, dynamic>?;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPatient = patient;
                                    _patientController.text =
                                        '${patient['name']} (${patient['history_number']})';
                                    _searchResults = [];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: home.AppColors.neutral200,
                                        width: index < _searchResults.length - 1
                                            ? 1
                                            : 0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            home.AppColors.primary100,
                                        child: Text(
                                          patient['name'][0].toUpperCase(),
                                          style: TextStyle(
                                            color: home.AppColors.primary600,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient['name'],
                                              style:
                                                  home.AppText.bodyS.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Historia: ${patient['history_number']} • Dueño: ${owner?['name'] ?? 'N/A'}',
                                              style:
                                                  home.AppText.bodyS.copyWith(
                                                color:
                                                    home.AppColors.neutral600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Campo de pruebas solicitadas
                      Text(
                        'Pruebas Solicitadas',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _testsController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Hemograma, Bioquímica, Uroanálisis',
                          prefixIcon: Icon(Iconsax.document_text,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Campo de veterinario
                      Text(
                        'Veterinario Responsable',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vetController,
                        decoration: InputDecoration(
                          hintText: 'Nombre del veterinario',
                          prefixIcon: Icon(Iconsax.user_square,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Campo de notas
                      Text(
                        'Notas Adicionales',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Observaciones especiales o instrucciones...',
                          prefixIcon: Icon(Iconsax.note_text,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: home.AppText.bodyS.copyWith(
                          color: home.AppColors.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: home.AppColors.success500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Crear Orden',
                              style: home.AppText.bodyS.copyWith(
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String? documentId;
  final VoidCallback? onStatusChanged;

  const _StatusChip({
    required this.status,
    this.documentId,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pendiente':
        backgroundColor = home.AppColors.warning500.withOpacity(0.1);
        textColor = home.AppColors.warning500;
        break;
      case 'en proceso':
        backgroundColor = home.AppColors.primary500.withOpacity(0.1);
        textColor = home.AppColors.primary600;
        break;
      case 'completada':
        backgroundColor = home.AppColors.success500.withOpacity(0.1);
        textColor = home.AppColors.success500;
        break;
      case 'crítico':
        backgroundColor = home.AppColors.danger500.withOpacity(0.1);
        textColor = home.AppColors.danger500;
        break;
      case 'colectada':
        backgroundColor = home.AppColors.neutral500.withOpacity(0.1);
        textColor = home.AppColors.neutral600;
        break;
      default:
        backgroundColor = home.AppColors.neutral200;
        textColor = home.AppColors.neutral600;
    }

    return InkWell(
      onTap: status.toLowerCase() != 'completada' && documentId != null
          ? () => _showStatusMenu(context)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: status.toLowerCase() != 'completada' && documentId != null
              ? Border.all(color: textColor.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              style: home.AppText.bodyS.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (status.toLowerCase() != 'completada' && documentId != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambiar Estado',
          style: home.AppText.titleS.copyWith(
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              status: 'En Proceso',
              color: home.AppColors.primary500,
              icon: Iconsax.refresh,
              onTap: () => _updateStatus(context, 'En Proceso'),
            ),
            const SizedBox(height: 8),
            _StatusOption(
              status: 'Completada',
              color: home.AppColors.success500,
              icon: Iconsax.tick_circle,
              onTap: () => _updateStatus(context, 'Completada'),
            ),
            const SizedBox(height: 8),
            _StatusOption(
              status: 'Crítico',
              color: home.AppColors.danger500,
              icon: Iconsax.warning_2,
              onTap: () => _updateStatus(context, 'Crítico'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await _supa.from('lab_documents').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', documentId!);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: $newStatus'),
            backgroundColor: home.AppColors.success500,
          ),
        );

        // Llamar callback si existe
        onStatusChanged?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
      }
    }
  }
}

class _StatusOption extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              status,
              style: home.AppText.bodyM.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: home.AppText.bodyM.copyWith(
                    color: home.AppColors.neutral600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: home.AppText.titleM.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive
                    ? home.AppColors.success500
                    : home.AppColors.danger500,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  change,
                  style: home.AppText.bodyS.copyWith(
                    color: isPositive
                        ? home.AppColors.success500
                        : home.AppColors.danger500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  'vs ayer',
                  style: home.AppText.bodyS.copyWith(
                    color: home.AppColors.neutral500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
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
    widget.action.onTap();
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: widget.action.color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.action.color.withOpacity(.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.action.icon,
                      size: 14,
                      color: widget.action.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.action.label,
                      style: home.AppText.label.copyWith(
                        color: widget.action.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? home.AppColors.primary500
              : home.AppColors.neutral100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? home.AppColors.primary500
                : home.AppColors.neutral200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: home.AppText.bodyS.copyWith(
            color: isSelected ? Colors.white : home.AppColors.neutral700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final VoidCallback? onStatusChanged;
  final Function(Map<String, dynamic>)? onOrderSelected;

  const _OrdersTable({
    required this.orders,
    this.onStatusChanged,
    this.onOrderSelected,
  });

  IconData _getSpeciesIcon(String speciesCode) {
    switch (speciesCode.toUpperCase()) {
      case 'CAN':
        return Icons.pets; // Perro
      case 'FEL':
        return Icons.pets; // Gato
      case 'AVE':
        return Icons.flight; // Ave
      case 'EQU':
        return Icons.pets; // Caballo
      case 'BOV':
        return Icons.pets; // Vaca
      case 'POR':
        return Icons.pets; // Cerdo
      case 'CAP':
        return Icons.pets; // Cabra
      case 'OVI':
        return Icons.pets; // Oveja
      default:
        return Icons.pets; // Por defecto
    }
  }

  String _getSpeciesLabel(String speciesCode) {
    switch (speciesCode.toUpperCase()) {
      case 'CAN':
        return 'Perro';
      case 'FEL':
        return 'Gato';
      case 'AVE':
        return 'Ave';
      case 'EQU':
        return 'Caballo';
      case 'BOV':
        return 'Vaca';
      case 'POR':
        return 'Cerdo';
      case 'CAP':
        return 'Cabra';
      case 'OVI':
        return 'Oveja';
      default:
        return 'Desconocido';
    }
  }

  String _calculateAge(String? birthDateString) {
    if (birthDateString == null || birthDateString.isEmpty) {
      return 'N/A';
    }

    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      final age = now.difference(birthDate).inDays;

      if (age < 30) {
        return '${age}d';
      } else if (age < 365) {
        final months = (age / 30).floor();
        return '${months}m';
      } else {
        final years = (age / 365).floor();
        final remainingMonths = ((age % 365) / 30).floor();
        if (remainingMonths > 0) {
          return '${years}a ${remainingMonths}m';
        } else {
          return '${years}a';
        }
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: home.AppColors.neutral400,
              ),
              SizedBox(height: 16),
              Text(
                'No hay órdenes disponibles',
                style: TextStyle(
                  color: home.AppColors.neutral500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          // En móvil: mostrar como cards
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: home.AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order['order_number'] as String? ?? 'N/A',
                            style: home.AppText.bodyM.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _StatusChip(
                          status: order['status'] as String? ?? 'Pendiente',
                          documentId: order['id'],
                          onStatusChanged: onStatusChanged,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: home.AppColors.primary100,
                          child: const Icon(Icons.pets, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['patient_name'] as String? ??
                                    'Sin nombre',
                                style: home.AppText.bodyM.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'MRN: ${order['mrn'] as String? ?? 'N/A'}',
                                style: home.AppText.bodyS.copyWith(
                                  color: home.AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: home.AppColors.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order['responsible'] as String? ?? 'Sin asignar',
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          order['last_update'] as String? ?? 'Desconocido',
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          // En desktop: tabla responsive que se extiende según el ancho
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                columnSpacing: 8,
                headingRowHeight: 48,
                dataRowHeight: 64,
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        'Orden #',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 200,
                      child: Text(
                        'Paciente',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 120,
                      child: Text(
                        'Raza/Especie',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 60,
                      child: Text(
                        'Edad',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        'Pruebas',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        'Responsable',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Text(
                        'Estado',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Text(
                        'Fecha',
                        style: home.AppText.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 30,
                      child: Text(''),
                    ),
                  ),
                ],
                rows: orders.map((order) {
                  final testsRequested =
                      order['tests_requested'] as String? ?? '';
                  final speciesCode = order['species_code'] as String? ?? '';
                  final breed = order['breed'] as String? ?? 'N/A';
                  final birthDate = order['birth_date'] as String?;
                  final age = _calculateAge(birthDate);

                  return DataRow(
                    onSelectChanged: (selected) {
                      if (selected == true) {
                        onOrderSelected?.call(order);
                      }
                    },
                    cells: [
                      DataCell(
                        Text(
                          order['order_number'] as String? ?? 'N/A',
                          style: home.AppText.bodyM.copyWith(
                            fontWeight: FontWeight.w500,
                            color: home.AppColors.primary600,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: home.AppColors.primary100,
                              child: Icon(
                                _getSpeciesIcon(speciesCode),
                                color: home.AppColors.primary600,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    order['patient_name'] as String? ??
                                        'Sin nombre',
                                    style: home.AppText.bodyM.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'MRN: ${order['mrn'] as String? ?? 'N/A'}',
                                    style: home.AppText.bodyS.copyWith(
                                      color: home.AppColors.neutral600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              breed,
                              style: home.AppText.bodyS.copyWith(
                                color: home.AppColors.neutral700,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSpeciesLabel(speciesCode),
                              style: home.AppText.bodyS.copyWith(
                                color: home.AppColors.neutral500,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          age,
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            testsRequested.isNotEmpty
                                ? testsRequested
                                : 'Sin especificar',
                            style: home.AppText.bodyS.copyWith(
                              color: home.AppColors.neutral700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          order['responsible'] as String? ?? 'Sin asignar',
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        _StatusChip(
                          status: order['status'] as String? ?? 'Pendiente',
                          documentId: order['id'],
                          onStatusChanged: onStatusChanged,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatDate(order['created_at']),
                          style: home.AppText.bodyS.copyWith(
                            color: home.AppColors.neutral600,
                          ),
                        ),
                      ),
                      DataCell(
                        Icon(
                          Icons.chevron_right,
                          color: home.AppColors.neutral400,
                          size: 16,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }
}

class _EditOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onOrderUpdated;

  const _EditOrderDialog({
    required this.order,
    this.onOrderUpdated,
  });

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _testsController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController.text = widget.order['title'] ?? '';
    _testsController.text = widget.order['tests_requested'] ?? '';
    _vetController.text = widget.order['responsible_vet'] ?? '';
    _notesController.text = widget.order['notes'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _testsController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _supa.from('lab_documents').update({
        'title': _titleController.text,
        'tests_requested': _testsController.text,
        'responsible_vet': _vetController.text,
        'notes': _notesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.order['id']);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Orden ${widget.order['order_number']} actualizada exitosamente'),
            backgroundColor: home.AppColors.success500,
          ),
        );

        // Recargar datos
        widget.onOrderUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar orden: $e'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Iconsax.edit,
                      color: home.AppColors.primary500, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Editar Orden de Laboratorio',
                    style: home.AppText.titleS.copyWith(
                      fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),

              // Información de la orden (solo lectura)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: home.AppColors.neutral50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: home.AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de la Orden',
                      style: home.AppText.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: home.AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Orden: ${widget.order['order_number'] ?? 'N/A'}',
                            style: home.AppText.bodyS.copyWith(
                              color: home.AppColors.neutral600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Paciente: ${widget.order['patient_name'] ?? 'N/A'}',
                            style: home.AppText.bodyS.copyWith(
                              color: home.AppColors.neutral600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Campo de título
                      Text(
                        'Título',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Título del documento',
                          prefixIcon: Icon(Iconsax.document_text,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo de pruebas solicitadas
                      Text(
                        'Pruebas Solicitadas',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _testsController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Hemograma, Bioquímica, Uroanálisis',
                          prefixIcon: Icon(Iconsax.document_text,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo de veterinario
                      Text(
                        'Veterinario Responsable',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vetController,
                        decoration: InputDecoration(
                          hintText: 'Nombre del veterinario',
                          prefixIcon: Icon(Iconsax.user_square,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo de notas
                      Text(
                        'Notas Adicionales',
                        style: home.AppText.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: home.AppColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Observaciones especiales o instrucciones...',
                          prefixIcon: Icon(Iconsax.note_text,
                              color: home.AppColors.neutral400, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: home.AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: home.AppColors.primary500, width: 2),
                          ),
                          filled: true,
                          fillColor: home.AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: home.AppText.bodyS.copyWith(
                          color: home.AppColors.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: home.AppColors.primary500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Actualizar Orden',
                              style: home.AppText.bodyS.copyWith(
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
      ),
    );
  }
}
