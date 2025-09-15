import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zuliadog/features/menu.dart';

// Dashboard (Home)
import 'home.dart';
// placeholders para otras pestañas
import 'widgets/patients.dart';
import 'widgets/appointments.dart';
import 'widgets/prescriptions.dart';
import 'widgets/documents.dart';
import 'widgets/resources.dart';
import 'widgets/services.dart';
import 'widgets/clinicalkpi.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.role = UserRole.doctor,
    this.initialRoute = '/dashboard',
    this.userName,
  });

  final UserRole role;
  final String initialRoute;
  final String? userName;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late List<AppMenuItem> _menu;
  late int _index;
  bool _railExtended = true;
  bool _greeted = false;

  @override
  void initState() {
    super.initState();
    _menu = visibleMenu(widget.role);
    final idx = indexForRoute(_menu, widget.initialRoute, fallback: 0);
    _index = (idx >= 0 && idx < _menu.length) ? idx : 0;

    // Saludo al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_greeted &&
          widget.userName != null &&
          widget.userName!.trim().isNotEmpty) {
        _greeted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('¡Bienvenido, ${widget.userName}!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _selectIndex(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final item = _menu[_index];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isRail = w >= 920;
      final extended = isRail ? (w >= 1280 ? true : _railExtended) : false;

      return Scaffold(
        appBar: AppBar(
          title: Text(item.label),
          leading: isRail
              ? null
              : Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Menú',
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
          actions: [
            IconButton(
              tooltip: 'Buscar',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
            const SizedBox(width: 4),
            _UserButton(name: widget.userName ?? 'Usuario', onPressed: () {}),
            const SizedBox(width: 8),
          ],
        ),
        drawer: isRail
            ? null
            : _MobileDrawer(
                items: _menu,
                selectedIndex: _index,
                onSelect: (i) {
                  _selectIndex(i);
                  Navigator.of(context).maybePop();
                },
                userName: widget.userName,
              ),
        body: Row(
          children: [
            if (isRail)
              _SideRail(
                items: _menu,
                selectedIndex: _index,
                extended: extended,
                onSelect: _selectIndex,
                onToggleExtend: () =>
                    setState(() => _railExtended = !_railExtended),
                userName: widget.userName,
              ),
            if (isRail) const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: _pagesForMenu(_menu),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _pagesForMenu(List<AppMenuItem> items) {
    return items
        .map((m) =>
            KeyedSubtree(key: ValueKey(m.route), child: _pageForRoute(m.route)))
        .toList();
  }

  Widget _pageForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return const HomePage(); // ← Home inmediato
      case '/patients':
        return const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: PatientsCard()));
      case '/appointments':
        return const Scaffold(
            body: Padding(
                padding: EdgeInsets.all(16), child: AppointmentsCard()));
      case '/prescriptions':
        return const Scaffold(
            body: Padding(
                padding: EdgeInsets.all(16), child: PrescriptionsCard()));
      case '/documents':
        return const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: DocumentsCard()));
      case '/resources':
        return const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: ResourcesCard()));
      case '/services':
        return const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: ServicesCard()));
      case '/kpi':
        return const Scaffold(
            body:
                Padding(padding: EdgeInsets.all(16), child: ClinicalKpiCard()));
      case '/settings':
        return const _SettingsView();
      default:
        return const HomePage();
    }
  }
}

/// ------- menú -------

class _SideRail extends StatelessWidget {
  final List<AppMenuItem> items;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleExtend;
  final String? userName;

  const _SideRail({
    required this.items,
    required this.selectedIndex,
    required this.extended,
    required this.onSelect,
    required this.onToggleExtend,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: extended,
      minExtendedWidth: 248,
      groupAlignment: -1.0,
      useIndicator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      destinations: [
        for (final m in items)
          NavigationRailDestination(
            icon: _BadgeIcon(
              icon: m.icon,
              count: m.badgeBuilder?.call(),
              selected: false,
            ),
            selectedIcon: _BadgeIcon(
              icon: m.selectedIcon ?? m.icon,
              count: m.badgeBuilder?.call(),
              selected: true,
            ),
            label: Text(m.label),
          ),
      ],
      onDestinationSelected: onSelect,
      indicatorShape: const StadiumBorder(),
      indicatorColor: c.primary.withValues(alpha: .12),
      trailing: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _UserMiniCard(name: userName ?? 'Usuario'),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final List<AppMenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String? userName;

  const _MobileDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _Brand(),
        ),
        const Divider(),
        for (final m in items)
          NavigationDrawerDestination(
            icon: _BadgeIcon(
                icon: m.icon, count: m.badgeBuilder?.call(), selected: false),
            selectedIcon: _BadgeIcon(
                icon: m.selectedIcon ?? m.icon,
                count: m.badgeBuilder?.call(),
                selected: true),
            label: Text(m.label),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _UserMiniCard(name: userName ?? 'Usuario'),
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

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool selected;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final badge = count != null && count! > 0
        ? Badge(
            backgroundColor: selected ? c.onPrimary : c.primary,
            textColor: selected ? c.primary : c.onPrimary,
            label: Text(count!.toString()),
            child: Icon(icon),
          )
        : Icon(icon);

    return badge;
  }
}

class _UserButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;
  const _UserButton({required this.name, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        children: [
          const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 8),
          Text(name, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _UserMiniCard extends StatelessWidget {
  final String name;
  const _UserMiniCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: c.surfaceContainerHighest.withValues(alpha: .45),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('Veterinario',
                  style: t.bodySmall?.copyWith(color: Colors.grey[700])),
            ]),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Ajustes (en construcción)',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
