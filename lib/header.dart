import 'package:flutter/material.dart';

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
    return ClipPath(
      clipper: _CurveClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top,
          left: 8,
          right: 8,
          bottom: 36,
        ),
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
      ),
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 24)
      ..quadraticBezierTo(size.width / 2, size.height + 24, size.width,
          size.height - 24)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
