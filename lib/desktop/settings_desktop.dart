import 'package:material_ui/material_ui.dart';

import '../settings.dart';
import 'desktop_shell.dart' show KeyHint;

/// Desktop settings: section titles on the side, one section's tiles
/// beside them. The tiles are the same ones the mobile page lists.
class DesktopSettings extends StatefulWidget {
  const DesktopSettings({super.key});

  @override
  State<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<DesktopSettings> {
  int _section = 0;

  static const _shortcuts = [
    ('عدّ الذكر الحالي', 'Space / Enter'),
    ('الذكر التالي', '←'),
    ('الذكر السابق', '→'),
    ('وضع التركيز', 'F'),
    ('نسخ الذكر', 'Ctrl C'),
    ('البحث', 'Ctrl K'),
    ('الإعدادات', 'Ctrl ,'),
    ('التنقل بين الأقسام', 'Ctrl 1 – 4'),
    ('إعادة عدّ السبحة', 'Esc'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sections = [
      ...settingsSections(context, hideUnsupported: true),
      (
        title: 'اختصارات لوحة المفاتيح',
        icon: Icons.keyboard_outlined,
        tiles: <Widget>[
          for (final (what, keys) in _shortcuts)
            ListTile(title: Text(what), trailing: KeyHint(keys)),
        ],
      ),
    ];
    final current = sections[_section.clamp(0, sections.length - 1)];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final (i, s) in sections.indexed)
                      ListTile(
                        selected: i == _section,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: Icon(s.icon, size: 20),
                        title: Text(s.title),
                        onTap: () => setState(() => _section = i),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => resetAllSettings(context),
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('إعادة ضبط الإعدادات'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      bottom: 8,
                    ),
                    child: Text(
                      current.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  ...current.tiles,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
