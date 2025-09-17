import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/data/buscador.dart';
import 'package:zuliadog/features/data/repository.dart';

/// =======================
/// Zuliadog — Home (Desktop) v2.2 (one-file)
/// =======================
/// - Max content width: 1600px
/// - Densidad: Compacta
/// - Topbar: 72px
/// - Sidebar fija: 260px
/// - Main (izquierda): Bienvenida, Importantes (solo números), Rendimiento semanal, Actividad reciente.
/// - Right column: Calendario compacto + Tareas (ancho 320px).
/// - Anti-overflow: FAB abre hacia arriba + padding inferior extra en scroll.
/// - Fuentes -1pt, pills cortos, alineación superior de íconos/filas.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  bool useRealChart =
      false; // reemplaza placeholder cuando integres tu librería de charts
  RangeWeeks _range = RangeWeeks.w4;
  String _currentRoute = 'frame_home';

  // Variables para el buscador integrado
  final TextEditingController _searchController = TextEditingController();
  List<PatientSearchRow> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  // Repositorio de datos
  final DataRepository _repository = DataRepository();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        focusColor: AppColors.primary500.withOpacity(.12),
        hoverColor: AppColors.neutral50,
        splashColor: AppColors.primary500.withOpacity(.08),
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.primary500,
          secondary: AppColors.primary600,
          surface: Colors.white,
          onSurface: AppColors.neutral900,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                    width: 260,
                    child: _SideNav(
                        activeRoute: _currentRoute, onTap: _handleNavTap)),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        searchController: _searchController,
                        isSearching: _isSearching,
                        onSearch: _performSearch,
                        onSearchChanged: (value) {
                          if (value.length >= 2) {
                            _performSearch(value);
                          } else if (value.isEmpty) {
                            setState(() {
                              _showSearchResults = false;
                              _searchResults = [];
                            });
                          }
                        },
                      ),
                      const Divider(height: 1, color: AppColors.neutral200),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1600),
                              child: _currentRoute == 'frame_home'
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // MAIN
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _WelcomeHeader(
                                                doctorName: 'Doctor/a',
                                                onSync: () {
                                                  // Aquí irá la lógica para sincronizar con Supabase
                                                  print(
                                                      'Sincronizando datos con Supabase...');
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              _QuickActionsSection(),
                                              const SizedBox(height: 16),
                                              _ImportantSection(
                                                  loading: loading),
                                              const SizedBox(height: 16),
                                              _WeeklyPerformanceCard(
                                                loading: loading,
                                                range: _range,
                                                onRangeChanged: (r) =>
                                                    setState(() => _range = r),
                                                useRealChart: useRealChart,
                                              ),
                                              const SizedBox(height: 16),
                                              _RecentActivityTable(
                                                  loading: loading),
                                              const SizedBox(height: 40),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // RIGHT COLUMN
                                        const SizedBox(
                                            width: 320,
                                            child: _RightColumnContent()),
                                      ],
                                    )
                                  : _buildPageContent(_currentRoute),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Overlay de resultados de búsqueda
            if (_showSearchResults)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showSearchResults = false;
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  void _handleNavTap(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final results = await _repository.searchPatients(query, limit: 10);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error en búsqueda: $e');
    }
  }

  Widget _buildSearchResults() {
    if (!_showSearchResults) return const SizedBox.shrink();

    return Positioned(
      top: 80, // Debajo de la barra de búsqueda
      left: 32, // Alineado con el contenido principal
      right: 32, // Alineado con el contenido principal
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600, // Ancho máximo similar al campo de búsqueda
            maxHeight: 280,
          ),
          child: GestureDetector(
            onTap: () {}, // Prevenir que se cierre al tocar el contenido
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con gradiente
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary50, AppColors.primary100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.search_normal_1,
                            color: AppColors.primary600,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Resultados de búsqueda',
                            style: TextStyle(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_searchResults.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_searchResults.length}',
                                style: TextStyle(
                                  color: AppColors.primary700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showSearchResults = false;
                                _searchController.clear();
                                _searchResults = [];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.neutral200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppColors.neutral600,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenido con scroll
                    Flexible(
                      child: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary600),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Buscando...',
                                      style: TextStyle(
                                        color: AppColors.neutral600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.search_normal,
                                        color: AppColors.neutral400,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No se encontraron resultados',
                                        style: TextStyle(
                                          color: AppColors.neutral600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Intenta con otros términos de búsqueda',
                                        style: TextStyle(
                                          color: AppColors.neutral500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length > 5
                                      ? 5
                                      : _searchResults.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 0.5,
                                    color: AppColors.neutral100,
                                    indent: 12,
                                    endIndent: 12,
                                  ),
                                  itemBuilder: (context, index) {
                                    final patient = _searchResults[index];
                                    return _buildSearchResultItem(patient);
                                  },
                                ),
                    ),

                    // Footer con indicador de más resultados
                    if (_searchResults.length > 5)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.arrow_down_2,
                              color: AppColors.neutral500,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_searchResults.length - 5} resultados más',
                              style: TextStyle(
                                color: AppColors.neutral600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(PatientSearchRow patient) {
    return InkWell(
      onTap: () {
        // TODO: Navegar a detalles del paciente
        print('Seleccionado: ${patient.patientName}');
        setState(() {
          _showSearchResults = false;
          _searchController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar con especie
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSpeciesColor(patient.species ?? '').withOpacity(0.1),
                    _getSpeciesColor(patient.species ?? '').withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  patient.patientName.isNotEmpty
                      ? patient.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _getSpeciesColor(patient.species ?? ''),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Información del paciente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Dueño: ${patient.ownerName}',
                    style: TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (patient.historyNumber?.isNotEmpty == true) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Historia: ${patient.historyNumber}',
                      style: TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge de especie
            if (patient.species?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      _getSpeciesColor(patient.species ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  patient.species ?? '',
                  style: TextStyle(
                    color: _getSpeciesColor(patient.species ?? ''),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSpeciesColor(String species) {
    switch (species.toLowerCase()) {
      case 'canino':
      case 'perro':
        return const Color(0xFF8B5CF6); // Púrpura
      case 'felino':
      case 'gato':
        return const Color(0xFFF59E0B); // Naranja
      case 'ave':
      case 'pájaro':
        return const Color(0xFF10B981); // Verde
      case 'roedor':
        return const Color(0xFFEF4444); // Rojo
      default:
        return AppColors.primary600;
    }
  }

  Widget _buildPageContent(String route) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPageTitle(route),
              style: AppText.titleL,
            ),
            const SizedBox(height: 16),
            Text(
              'Contenido de ${_getPageTitle(route).toLowerCase()} - En desarrollo',
              style: AppText.bodyM.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getPageIcon(route),
                      size: 48,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Próximamente disponible',
                      style:
                          AppText.bodyM.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case 'frame_pacientes':
        return 'Pacientes';
      case 'frame_historias':
        return 'Historias Médicas';
      case 'frame_recetas':
        return 'Recetas';
      case 'frame_laboratorio':
        return 'Laboratorio';
      case 'frame_agenda':
        return 'Agenda & Calendario';
      case 'frame_visor_medico':
        return 'Visor médico';
      case 'frame_recursos':
        return 'Recursos';
      case 'frame_tickets':
        return 'Tickets';
      case 'frame_reportes':
        return 'Reportes';
      case 'frame_ajustes':
        return 'Ajustes';
      default:
        return 'Home';
    }
  }

  IconData _getPageIcon(String route) {
    switch (route) {
      case 'frame_pacientes':
        return Iconsax.pet;
      case 'frame_historias':
        return Iconsax.health;
      case 'frame_recetas':
        return Iconsax.note_text;
      case 'frame_laboratorio':
        return Iconsax.bill;
      case 'frame_agenda':
        return Iconsax.calendar_1;
      case 'frame_visor_medico':
        return Iconsax.document_text;
      case 'frame_recursos':
        return Iconsax.book_1;
      case 'frame_tickets':
        return Iconsax.receipt_2;
      case 'frame_reportes':
        return Iconsax.chart_2;
      case 'frame_ajustes':
        return Iconsax.setting_2;
      default:
        return Iconsax.home_2;
    }
  }
}

/// =======================
/// Sidebar
/// =======================
class _SideNav extends StatelessWidget {
  final String activeRoute;
  final void Function(String route) onTap;
  const _SideNav({required this.activeRoute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem('Home', Iconsax.home_2, 'frame_home'),
      _NavItem('Pacientes', Iconsax.pet, 'frame_pacientes'),
      _NavItem('Historias médicas', Iconsax.health, 'frame_historias'),
      _NavItem('Recetas', Iconsax.note_text, 'frame_recetas'),
      _NavItem('Laboratorio', Iconsax.bill, 'frame_laboratorio'),
      _NavItem('Agenda & Calendario', Iconsax.calendar_1, 'frame_agenda'),
      _NavItem('Visor médico', Iconsax.document_text, 'frame_visor_medico'),
      _NavItem('Recursos', Iconsax.book_1, 'frame_recursos'),
      _NavItem('Tickets', Iconsax.receipt_2, 'frame_tickets'),
      _NavItem('Reportes', Iconsax.chart_2, 'frame_reportes'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header con logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary500, AppColors.primary600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Iconsax.heart, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zuliadog', style: AppText.titleS),
                      Text('Veterinaria',
                          style: AppText.bodyS
                              .copyWith(color: AppColors.neutral500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menú principal
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (_, i) {
                final it = items[i];
                final active = it.route == activeRoute;
                return _SideItem(
                    label: it.label,
                    icon: it.icon,
                    active: active,
                    onTap: () => onTap(it.route));
              },
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: items.length,
            ),
          ),

          // Divider y ajustes
          const Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _SideItem(
                label: 'Ajustes',
                icon: Iconsax.setting_2,
                active: activeRoute == 'frame_ajustes',
                onTap: () => onTap('frame_ajustes')),
          ),

          // Usuario en la parte inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              border: const Border(
                top: BorderSide(color: AppColors.neutral200, width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor/a', style: AppText.bodyM),
                      Text('doctor@zuliadog.com',
                          style: AppText.bodyS
                              .copyWith(color: AppColors.neutral500)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Iconsax.more_2, size: 18),
                  tooltip: 'Menú de usuario',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  _NavItem(this.label, this.icon, this.route);
}

class _SideItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SideItem(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary500.withOpacity(.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: AppColors.primary500.withOpacity(.2), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.primary600 : AppColors.neutral600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyM.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColors.neutral900 : AppColors.neutral700,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// Topbar
/// =======================
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final Function(String) onSearch;
  final Function(String) onSearchChanged;

  const _TopBar({
    required this.searchController,
    required this.isSearching,
    required this.onSearch,
    required this.onSearchChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Breadcrumb
            Row(
              children: [
                Text('Home',
                    style: AppText.bodyM.copyWith(color: AppColors.neutral500)),
                const SizedBox(width: 8),
                Icon(Iconsax.arrow_right_3,
                    size: 16, color: AppColors.neutral400),
                const SizedBox(width: 8),
                Text('Dashboard',
                    style: AppText.bodyM.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),

            // Barra de búsqueda mejorada
            Container(
              width: 480,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neutral200, width: 1),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes, documentos, tickets, historias…',
                  hintStyle:
                      AppText.bodyM.copyWith(color: AppColors.neutral400),
                  prefixIcon: Icon(Iconsax.search_normal,
                      size: 20, color: AppColors.neutral500),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: () => onSearch(searchController.text),
                          icon: Icon(Iconsax.filter,
                              size: 18, color: AppColors.neutral500),
                          tooltip: 'Buscar',
                        ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Botones de acción
            _TopBarButton(
              icon: Iconsax.add,
              tooltip: 'Añadir',
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _TopBarButton(
              icon: Iconsax.calendar_1,
              tooltip: 'Calendario',
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _TopBarButton(
              icon: Iconsax.notification,
              tooltip: 'Notificaciones',
              badge: '3',
              onPressed: () {},
            ),
            const SizedBox(width: 16),

            // Avatar de usuario
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary500, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final VoidCallback onPressed;

  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.neutral50,
            foregroundColor: AppColors.neutral700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
        ),
        if (badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.danger500,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// =======================
/// Acciones rápidas
/// =======================
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Iconsax.user_add,
        label: 'Nuevo Paciente',
        color: AppColors.primary500,
        onTap: () {},
      ),
      _QuickAction(
        icon: Iconsax.calendar_add,
        label: 'Nueva Cita',
        color: AppColors.success500,
        onTap: () {},
      ),
      _QuickAction(
        icon: Iconsax.document_upload,
        label: 'Subir Documento',
        color: AppColors.warning500,
        onTap: () {},
      ),
      _QuickAction(
        icon: Iconsax.receipt_2,
        label: 'Crear Ticket',
        color: AppColors.danger500,
        onTap: () {},
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
            Text('Acciones rápidas', style: AppText.titleS),
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

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: action.color.withOpacity(.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: action.color.withOpacity(.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 14, color: action.color),
              const SizedBox(width: 4),
              Text(
                action.label,
                style: AppText.label.copyWith(
                  color: action.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// Header bienvenida
/// =======================
class _WelcomeHeader extends StatelessWidget {
  final String doctorName;
  final VoidCallback onSync;
  const _WelcomeHeader({required this.doctorName, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $doctorName', style: AppText.titleL),
                    const SizedBox(height: 4),
                    Text('Sistema de administración veterinario.',
                        style: AppText.bodyM
                            .copyWith(color: AppColors.neutral500)),
                  ]),
            ),
            // Botones de acción alineados arriba
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de sincronización
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withOpacity(.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSync,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de exportar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success500.withOpacity(.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Aquí irá la lógica para exportar datos
                        print('Exportando datos...');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.export_2,
                          color: Colors.white,
                          size: 20,
                        ),
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
}

/// =======================
/// Importantes – solo números (ultra compactos)
/// =======================
class _ImportantSection extends StatelessWidget {
  final bool loading;
  const _ImportantSection({required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      ImportantItem(title: 'Atendidos hoy', value: '18', icon: Iconsax.health),
      ImportantItem(title: 'Pendientes', value: '7', icon: Iconsax.clock),
      ImportantItem(title: 'Notas', value: '3', icon: Iconsax.note_2),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final it in items) ...[
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const _Skeleton(height: 80)
                  : _ImportantCard(item: it),
            ),
          ),
          if (it != items.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class ImportantItem {
  final String title, value;
  final IconData icon;
  ImportantItem({required this.title, required this.value, required this.icon});
}

class _ImportantCard extends StatelessWidget {
  final ImportantItem item;
  const _ImportantCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // icono arriba
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary500.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(item.icon, size: 20, color: AppColors.primary600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style:
                          AppText.label.copyWith(color: AppColors.neutral700)),
                  const SizedBox(height: 2),
                  Text(item.value, style: AppText.titleM),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// Rendimiento semanal (Chart placeholder)
/// =======================
enum RangeWeeks { w4, w12 }

class _WeeklyPerformanceCard extends StatelessWidget {
  final bool loading;
  final RangeWeeks range;
  final ValueChanged<RangeWeeks> onRangeChanged;
  final bool useRealChart;
  const _WeeklyPerformanceCard(
      {required this.loading,
      required this.range,
      required this.onRangeChanged,
      required this.useRealChart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Rendimiento semanal', style: AppText.titleS),
            const Spacer(),
            _RangeSelector(range: range, onChanged: onRangeChanged),
          ]),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const _Skeleton(height: 220)
                : const _ChartPlaceholder(),
          ),
        ]),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200)),
      child: const Center(
          child: Text('Gráfico semanal (placeholder)', style: AppText.bodyS)),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final RangeWeeks range;
  final ValueChanged<RangeWeeks> onChanged;
  const _RangeSelector({required this.range, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 250), // Ampliar espacio horizontal
      child: SegmentedButton<RangeWeeks>(
        segments: const [
          ButtonSegment(
              value: RangeWeeks.w4,
              label: Text('Semana'),
              icon: Icon(Iconsax.calendar_1, size: 16)),
          ButtonSegment(
              value: RangeWeeks.w12,
              label: Text('Mes'),
              icon: Icon(Iconsax.calendar_2, size: 16)),
        ],
        selected: {range},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary500
                    .withOpacity(0.12); // Fondo sutil solo para seleccionado
              }
              return Colors.transparent; // Sin fondo para no seleccionado
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary600;
              }
              return AppColors.neutral600;
            },
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(
                    color: AppColors.primary500.withOpacity(0.3), width: 1);
              }
              return BorderSide(color: AppColors.neutral200, width: 1);
            },
          ),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ),
    );
  }
}

/// =======================
/// Actividad reciente (tabla 8) — alineación TOP + pills cortos
/// =======================
class _RecentActivityTable extends StatelessWidget {
  final bool loading;
  const _RecentActivityTable({required this.loading});

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(8, (i) => _ActivityRow.sample(i));
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Actividad reciente', style: AppText.titleS),
          const SizedBox(height: 8),
          if (loading)
            const _Skeleton(height: 260)
          else
            _CompactTable(rows: rows),
        ]),
      ),
    );
  }
}

class _CompactTable extends StatelessWidget {
  final List<_ActivityRow> rows;
  const _CompactTable({required this.rows});
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(44),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.2)
      },
      defaultVerticalAlignment:
          TableCellVerticalAlignment.top, // TOP en lugar de middle
      children: [
        TableRow(
            decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.neutral200))),
            children: [
              _Th('#'),
              _Th('Descripción'),
              _Th('Estado'),
              _Th('Fecha/Hora'),
            ]),
        ...rows.map((r) => TableRow(
              decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: AppColors.neutral200, width: .75))),
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(r.icon, size: 18, color: AppColors.neutral700)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(r.description, style: AppText.bodyS)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _StatusTag(
                        label: r.status.label, color: r.status.color)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(r.dateTimeString,
                        style: AppText.bodyS
                            .copyWith(color: AppColors.neutral500))),
              ],
            )),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text,
          style: AppText.label.copyWith(color: AppColors.neutral700)));
}

class _ActivityRow {
  final IconData icon;
  final String description;
  final _Status status;
  final String dateTimeString;
  _ActivityRow(this.icon, this.description, this.status, this.dateTimeString);
  static _ActivityRow sample(int i) {
    final types = [
      (Iconsax.user_add, 'Alta de paciente: Max (Canino)'),
      (Iconsax.calendar_add, 'Cita creada para Luna'),
      (Iconsax.document_upload, 'Documento subido: RX_1234.pdf'),
      (Iconsax.receipt_2, 'Ticket abierto para Simba'),
    ];
    final t = types[i % types.length];
    final statuses = [
      _Status('completado', AppColors.success500),
      _Status('pendiente', AppColors.warning500),
      _Status('en proceso', AppColors.primary600),
    ];
    final s = statuses[i % statuses.length];
    return _ActivityRow(
        t.$1, t.$2, s, 'Hoy 10:${(i + 1).toString().padLeft(2, '0')}');
  }
}

class _Status {
  final String label;
  final Color color;
  _Status(this.label, this.color);
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 80,
          minWidth: 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// =======================
/// RIGHT COLUMN (Calendar + Tasks) — calendario minimal
/// =======================
class _RightColumnContent extends StatefulWidget {
  const _RightColumnContent();
  @override
  State<_RightColumnContent> createState() => _RightColumnContentState();
}

class _RightColumnContentState extends State<_RightColumnContent> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final List<_Task> tasks = [
    _Task('Llamar al dueño de Luna', '10:30', false),
    _Task('Revisar análisis de Max', '11:15', true),
    _Task('Confirmar cita de Simba', '14:00', false),
    _Task('Subir RX Bella', '15:20', false),
    _Task('Receta para Coco', '17:00', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MiniCalendarCard(
          month: _visibleMonth,
          onPrev: () => setState(() => _visibleMonth =
              DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
          onNext: () => setState(() => _visibleMonth =
              DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
        ),
        const SizedBox(height: 12),
        _TodayTasksCard(
            tasks: tasks,
            onToggle: (i) => setState(() => tasks[i] = tasks[i].toggle())),
      ],
    );
  }
}

class _MiniCalendarCard extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MiniCalendarCard(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    // En español, Lunes = 1, Domingo = 7
    final startWeekday = first.weekday; // 1=Lunes, 7=Domingo
    final daysInMonth = last.day;

    // Crear la lista de celdas del calendario (6 semanas = 42 días)
    final cells = <DateTime?>[];

    // Calcular cuántos días del mes anterior necesitamos para completar la primera semana
    // Si el primer día del mes es Lunes (1), necesitamos 0 días del mes anterior
    // Si es Martes (2), necesitamos 1 día del mes anterior, etc.
    final daysFromPrevMonth = startWeekday - 1;

    if (daysFromPrevMonth > 0) {
      final prevMonth = DateTime(month.year, month.month - 1);
      final daysInPrevMonth = DateTime(month.year, month.month, 0).day;
      final startDay = daysInPrevMonth - daysFromPrevMonth + 1;

      for (int i = startDay; i <= daysInPrevMonth; i++) {
        cells.add(DateTime(prevMonth.year, prevMonth.month, i));
      }
    }

    // Agregar todos los días del mes actual
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }

    // Agregar días del mes siguiente para completar 6 semanas (42 días)
    final nextMonth = DateTime(month.year, month.month + 1);
    final remainingCells = 42 - cells.length;
    for (int d = 1; d <= remainingCells; d++) {
      cells.add(DateTime(nextMonth.year, nextMonth.month, d));
    }

    // Siempre usar español para los días de la semana
    final weekdayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(_monthLabel(month), style: AppText.titleS),
              const Spacer(),
              IconButton(
                  icon: const Icon(Iconsax.arrow_left_2, size: 18),
                  tooltip: 'Mes anterior',
                  onPressed: onPrev),
              IconButton(
                  icon: const Icon(Iconsax.arrow_right_2, size: 18),
                  tooltip: 'Mes siguiente',
                  onPressed: onNext),
            ]),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekdayNames
                  .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral700,
                              )))))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Grid 6x7 compacto, ring en "hoy", sin fondo visible
            Column(
              children: List.generate(6, (row) {
                // 6 semanas fijas
                return Row(
                  children: List.generate(7, (col) {
                    final idx = row * 7 + col;
                    final date = cells[idx];
                    // Verificar si es el día de hoy
                    final isToday = date != null &&
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;

                    // Verificar si es del mes actual
                    final isCurrentMonth = date != null &&
                        date.month == month.month &&
                        date.year == month.year;

                    // Verificar si es fin de semana (sábado o domingo)
                    final isWeekend = date != null &&
                        (date.weekday == 6 || date.weekday == 7);

                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1, // ~28–30px según ancho del card
                        child: MouseRegion(
                          cursor: date != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: date != null ? () => _onDateTap(date) : null,
                            child: Container(
                              margin: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isToday
                                      ? AppColors.primary500
                                      : Colors.transparent,
                                  width: isToday ? 1.2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  date?.day.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isToday
                                        ? AppColors.primary600
                                        : isCurrentMonth
                                            ? (isWeekend
                                                ? AppColors
                                                    .neutral500 // Fin de semana más tenue
                                                : AppColors.neutral700)
                                            : AppColors
                                                .neutral400, // Días de otros meses más tenues
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime m) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${meses[m.month - 1]} ${m.year}';
  }

  // Función para manejar el tap en una fecha (preparado para futuros eventos)
  void _onDateTap(DateTime date) {
    // Aquí se implementará la lógica para mostrar eventos del día
    // Por ahora solo imprimimos la fecha seleccionada
    print('Fecha seleccionada: ${date.day}/${date.month}/${date.year}');

    // TODO: Implementar funcionalidad de eventos
    // - Mostrar eventos del día seleccionado
    // - Permitir crear nuevos eventos
    // - Mostrar modal con detalles del día
  }
}

class _Task {
  final String title;
  final String time;
  final bool done;
  _Task(this.title, this.time, this.done);
  _Task toggle() => _Task(title, time, !done);
}

class _TodayTasksCard extends StatelessWidget {
  final List<_Task> tasks;
  final ValueChanged<int> onToggle;
  const _TodayTasksCard({required this.tasks, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tareas de hoy', style: AppText.titleS),
          const SizedBox(height: 6),
          ...List.generate(tasks.length, (i) {
            final t = tasks[i];
            return _TaskRow(
              title: t.title,
              time: t.time,
              done: t.done,
              onChanged: (_) => onToggle(i),
            );
          }),
        ]),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String time;
  final bool done;
  final ValueChanged<bool?> onChanged;
  const _TaskRow(
      {required this.title,
      required this.time,
      required this.done,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.neutral200, width: .75))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // íconos/checkbox arriba
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: done,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: AppText.bodyS.copyWith(
                    color: done ? AppColors.neutral500 : AppColors.neutral900,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ))),
          const SizedBox(width: 8),
          _SmallTag(text: time, icon: Iconsax.clock),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SmallTag({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.neutral200)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.neutral700),
        const SizedBox(width: 4),
        Text(text, style: AppText.label.copyWith(color: AppColors.neutral700)),
      ]),
    );
  }
}

/// =======================
/// Skeleton + Tokens
/// =======================
class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      decoration: BoxDecoration(
          color: AppColors.neutral200.withOpacity(.45),
          borderRadius: BorderRadius.circular(12)));
}

class AppColors {
  static const primary500 = Color(0xFF5E81F4);
  static const primary600 = Color(0xFF4B6BE0);
  static const primary700 = Color(0xFF3B5BD6);
  static const primary200 = Color(0xFFB8C8FF);
  static const primary100 = Color(0xFFD6E2FF);
  static const primary50 = Color(0xFFF0F4FF);
  static const neutral900 = Color(0xFF0E1116);
  static const neutral700 = Color(0xFF2C333A);
  static const neutral600 = Color(0xFF475467);
  static const neutral500 = Color(0xFF667085);
  static const neutral400 = Color(0xFF98A2B3);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral100 = Color(0xFFF1F3F4);
  static const neutral50 = Color(0xFFF8FAFC);
  static const success500 = Color(0xFF22C55E);
  static const warning500 = Color(0xFFF59E0B);
  static const danger500 = Color(0xFFEF4444);
}

class AppText {
  // -1pt vs versiones anteriores
  static const titleL = TextStyle(
      fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.neutral900);
  static const titleM = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.neutral900);
  static const titleS = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neutral900);
  static const bodyM = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.neutral900);
  static const bodyS = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral900);
  static const label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral900);
}
