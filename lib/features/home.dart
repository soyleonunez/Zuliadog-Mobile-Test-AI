// home.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _Breadcrumb(),
        actions: const [
          _TopSearch(width: 320),
          SizedBox(width: 8),
          _IconBtn(icon: Icons.notifications_none_rounded),
          SizedBox(width: 8),
          _AvatarBtn(),
          SizedBox(width: 16),
        ],
      ),
      body: const HomeBody(),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              children: const [
                _WelcomeHeader(),
                SizedBox(height: 24),
                _QuickActions(),
                SizedBox(height: 24),
                _ResourcesCard(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const SizedBox(
            width: 380,
            child: _RightColumn(),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Row(children: [
      const SizedBox(width: 16),
      Text('Zuliadog', style: style.bodyMedium?.copyWith(color: Colors.indigo)),
      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      Text('Home', style: style.bodyMedium?.copyWith(color: Colors.black87)),
    ]);
  }
}

class _TopSearch extends StatelessWidget {
  final double width;
  const _TopSearch({required this.width});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar pacientes, documentos...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.grey[600]),
      tooltip: 'Notifications',
    );
  }
}

class _AvatarBtn extends StatelessWidget {
  const _AvatarBtn();
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: const AssetImage('Assets/Images/App.png'),
      backgroundColor: Colors.grey[200],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Hola, Doctora',
          style: style.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Aquí tienes un resumen de tu día.',
          style: style.bodyMedium?.copyWith(color: Colors.grey[600])),
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        QuickActionCard(icon: Icons.pets, label: 'Pacientes'),
        QuickActionCard(
            icon: Icons.medical_services_outlined, label: 'Historias'),
        QuickActionCard(icon: Icons.receipt_long_outlined, label: 'Recetas'),
        QuickActionCard(icon: Icons.local_library_outlined, label: 'Recursos'),
        QuickActionCard(icon: Icons.folder_open_outlined, label: 'Archivos'),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const QuickActionCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 28, color: const Color(0xFF5E81F4)),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard();
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recursos',
      child: Column(children: const [
        ResourceItemCard(
            title: 'Guía de dosificación de medicamentos',
            subtitle: 'Actualizado hace 2 días'),
        SizedBox(height: 12),
        ResourceItemCard(
            title: 'Protocolo de anestesia para caninos',
            subtitle: 'Actualizado hace 1 semana'),
        SizedBox(height: 12),
        ResourceItemCard(
            title: 'Valores de referencia de laboratorio',
            subtitle: 'Actualizado hace 1 mes'),
      ]),
    );
  }
}

class ResourceItemCard extends StatelessWidget {
  final String title, subtitle;
  const ResourceItemCard(
      {super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ])),
        IconButton(onPressed: () {}, icon: const Icon(Icons.download_rounded)),
      ]),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _Card(title: 'Calendario', child: CompactCalendar()),
        SizedBox(height: 16),
        _TasksPanel(),
      ],
    );
  }
}

class CompactCalendar extends StatelessWidget {
  const CompactCalendar({super.key});
  @override
  Widget build(BuildContext context) {
    final days = ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Julio 2024', style: TextStyle(fontWeight: FontWeight.w600)),
        Row(children: [
          _IconBtn(icon: Icons.chevron_left),
          _IconBtn(icon: Icons.chevron_right),
        ]),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        children: days
            .map((d) => Center(
                child: Text(d,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12))))
            .toList(),
      ),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 35,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemBuilder: (_, i) {
          final is15 = i == 15;
          return Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: is15 ? const Color(0xFF5E81F4) : null,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text('${i % 31 + 1}',
                  style: TextStyle(
                      color: is15 ? Colors.white : Colors.black87,
                      fontSize: 12)),
            ),
          );
        },
      ),
    ]);
  }
}

class _TasksPanel extends StatefulWidget {
  const _TasksPanel();
  @override
  State<_TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<_TasksPanel> {
  final tasks = <_Task>[
    _Task('Llamar al propietario de "Max" para seguimiento'),
    _Task('Revisar resultados de laboratorio de "Luna"', done: true),
    _Task('Preparar pedido de medicamentos'),
    _Task('Esterilizar instrumental quirúrgico'),
  ];
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Tareas del día',
      child: Column(children: [
        for (final t in tasks)
          CheckboxListTile(
            value: t.done,
            onChanged: (v) => setState(() => t.done = v ?? false),
            title: Text(t.title,
                style: t.done
                    ? const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough)
                    : null),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Añadir Tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81F4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Task {
  _Task(this.title, {this.done = false});
  final String title;
  bool done;
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}
