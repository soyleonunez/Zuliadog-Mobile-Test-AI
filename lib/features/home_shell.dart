import 'package:flutter/material.dart';
import 'home.dart'; // usamos HomeBody para evitar Scaffold dentro de Scaffold

/// Shell mínimo y robusto:
/// - Desktop/Tablet ancha: NavigationRail
/// - Móvil/angosto: Drawer
/// - Contenido: SIEMPRE HomeBody (tu dashboard)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _railExtended = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final useRail = w >= 920;
        final extended = useRail ? (w >= 1280 ? true : _railExtended) : false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Zuliadog · Panel'),
            leading: useRail
                ? null
                : Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.notifications_none), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),

          // Drawer para móviles
          drawer: useRail ? null : const _AppDrawer(),

          body: Row(
            children: [
              if (useRail)
                _SideRail(
                  extended: extended,
                  onToggleExtend: () =>
                      setState(() => _railExtended = !_railExtended),
                ),
              if (useRail) const VerticalDivider(width: 1),

              // 👇 CONTENIDO: usa HomeBody (NO HomeView) para evitar Scaffold anidado
              const Expanded(child: HomeBody()),
            ],
          ),
        );
      },
    );
  }
}

/// Rail lateral para pantallas anchas.
/// Envolvemos en SizedBox(height: double.infinity) para evitar el assert 'hasSize'.
class _SideRail extends StatelessWidget {
  final bool extended;
  final VoidCallback onToggleExtend;

  const _SideRail({required this.extended, required this.onToggleExtend});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return SizedBox(
      // <- clave para evitar 'hasSize'
      height: double.infinity,
      child: NavigationRail(
        selectedIndex: 0, // Home activo
        extended: extended,
        groupAlignment: -1.0,
        useIndicator: true,
        minExtendedWidth: 248,
        indicatorShape: const StadiumBorder(),
        indicatorColor: c.primary.withValues(alpha: .12),
        leading: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: extended
              ? Row(
                  children: [
                    const SizedBox(width: 16),
                    const _Brand(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Contraer',
                      onPressed: onToggleExtend,
                      icon: const Icon(Icons.keyboard_double_arrow_left),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Brand(compact: true),
                    IconButton(
                      tooltip: 'Expandir',
                      onPressed: onToggleExtend,
                      icon: const Icon(Icons.keyboard_double_arrow_right),
                    ),
                  ],
                ),
        ),
        // Ítems del menú (placeholder visual)
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: Text('Pacientes'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: Text('Citas'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: Text('Recetas'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: Text('Documentos'),
          ),
        ],
        onDestinationSelected: (_) {}, // luego conectamos navegación real
      ),
    );
  }
}

/// Drawer para móviles: mismos ítems, sin navegación por ahora.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (_) => Navigator.of(context).maybePop(),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _Brand(),
        ),
        Divider(),
        NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: Text('Pacientes'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: Text('Citas'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication),
          label: Text('Recetas'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: Text('Documentos'),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  final bool compact;
  const _Brand({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (compact) {
      return const CircleAvatar(radius: 16, child: Icon(Icons.pets, size: 18));
    }
    return Row(
      children: [
        const CircleAvatar(radius: 16, child: Icon(Icons.pets, size: 18)),
        const SizedBox(width: 10),
        Text('Zuliadog',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
