import 'package:flutter/material.dart';

/// Gradient band behind header content. The arch shape around it comes from
/// [MihrabPage], which every shell page sits on.
class HeaderGradient extends StatelessWidget {
  const HeaderGradient({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top)
          .add(padding ?? const EdgeInsets.fromLTRB(8, 0, 8, 36)),
      child: child,
    );
  }
}

/// Gradient app header with a curved bottom edge. RTL-aware back arrow.
class WaZaqerHeader extends StatelessWidget {
  const WaZaqerHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return HeaderGradient(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 36),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: Icon(rtl ? Icons.arrow_forward : Icons.arrow_back),
              color: scheme.onPrimary,
              onPressed: () => Navigator.maybePop(context),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

/// Page background: full-bleed gradient with the content area cut out as a
/// single giant pointed arch (mihrab) whose legs run to the bottom corners
/// as border pillars. Content renders on top, inside the arch.
class MihrabPage extends StatelessWidget {
  const MihrabPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        ClipPath(
          clipper: const MihrabClipper(),
          child: ColoredBox(color: scheme.surface),
        ),
        child,
      ],
    );
  }
}

/// Interior of the single giant arch framing the page.
class MihrabClipper extends CustomClipper<Path> {
  const MihrabClipper();

  @override
  Path getClip(Size size) {
    const f = 14.0; // pillar width
    final cx = size.width / 2;
    // apex just below the header band so the arch line stays visible
    final y0 = (size.height * 0.32).clamp(270.0, 420.0).toDouble();
    final cy = y0 + size.height * 0.20;
    return Path()
      ..moveTo(f, size.height)
      ..quadraticBezierTo(cx - size.width * 0.40, cy, cx, y0)
      ..quadraticBezierTo(
        cx + size.width * 0.40,
        cy,
        size.width - f,
        size.height,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
