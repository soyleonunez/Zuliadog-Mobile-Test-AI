import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    Widget action({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
    }) {
      final scheme = Theme.of(context).colorScheme;
      return _HoverCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[700])),
                    ],
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, size: 18),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 250.ms)
          .moveY(begin: 6, end: 0, duration: 250.ms);
    }

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 1000;
        final children = [
          Expanded(
              child: action(
                  icon: Iconsax.additem,
                  title: 'Nueva historia',
                  subtitle: 'Crea un expediente clínico',
                  onTap: () {})),
          const SizedBox(width: 12),
          Expanded(
              child: action(
                  icon: Iconsax.paperclip,
                  title: 'Redactar receta',
                  subtitle: 'Medicamentos y dosis',
                  onTap: () {})),
          const SizedBox(width: 12),
          Expanded(
              child: action(
                  icon: Iconsax.calculator,
                  title: 'Cálculo de dosis',
                  subtitle: 'mg/kg con seguridad',
                  onTap: () {})),
          const SizedBox(width: 12),
          Expanded(
              child: action(
                  icon: Iconsax.document_upload,
                  title: 'Subir documento',
                  subtitle: 'PDF/Imágenes al visor',
                  onTap: () {})),
        ];

        return isWide
            ? Row(children: children)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  children[0],
                  const SizedBox(height: 12),
                  children[2],
                  const SizedBox(height: 12),
                  children[1],
                  const SizedBox(height: 12),
                  children[3],
                ],
              );
      },
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: _hover
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _hover
                  ? Theme.of(context).colorScheme.primary.withOpacity(.18)
                  : Colors.black12),
          color: Theme.of(context).cardColor,
          boxShadow: _hover
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 12,
                      offset: const Offset(0, 8))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
