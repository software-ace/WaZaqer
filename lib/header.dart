import 'package:material_ui/material_ui.dart';

/// The app's mark: «و» in gold on the icon's navy, for desktop and web bars.
class AppMark extends StatelessWidget {
  const AppMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF011D28),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFB8964A)),
    ),
    child: const Text(
      'و',
      style: TextStyle(
        fontFamily: 'Noto Naskh Arabic',
        color: Color(0xFFE8D7A8),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Gradient band behind header content.
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

/// Gradient app header with a curved bottom edge. Back arrow mirrors under RTL.
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
    return HeaderGradient(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 36),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              // arrow_back mirrors itself under RTL (matchTextDirection); swapping
              // to arrow_forward here would flip it twice
              icon: const Icon(Icons.arrow_back),
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
