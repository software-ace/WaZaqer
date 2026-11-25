import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'digits.dart';
import 'header.dart';
import 'location.dart';
import 'prayer.dart';
import 'reminders.dart';
import 'store.dart';
import 'theme.dart';

/// Kept in step with pubspec.yaml by test/settings_test.dart.
const appVersion = '1.0.0';
const sourceUrl = 'https://github.com/software-ace/WaZaqer';
const sponsorUrl = 'https://github.com/sponsors/software-ace';

/// Keys cleared by «reset all settings». Favourites, reading progress,
/// tasbeeh counts, location and per-group reminders are user data and stay.
const settingKeys = [
  'accent',
  'themeMode',
  'arabicDigits',
  'autoAdvance',
  'haptics',
  'sound',
  'keepAwake',
  'tashkeel',
  'fontFamily',
  'fontScale',
  'autoMethod',
  'method',
  'adhan',
  'salawatOn',
  'salawatEvery',
  'salawatFrom',
  'salawatTo',
];

const fontFamilies = [
  'Noto Naskh Arabic',
  'Amiri',
  'Scheherazade New',
  'Cairo',
  'Reem Kufi',
  'Tajawal',
];

/// One titled group of settings: mobile lists every section on one page,
/// desktop shows one at a time beside a list of section titles.
typedef SettingsSection = ({String title, IconData icon, List<Widget> tiles});

const _androidOnly = 'متاح على أندرويد فقط';

void _set(Future<void> write, {bool reschedule = false}) {
  // SharedPreferences updates its cache synchronously, so readers see the
  // new value before the disk write completes.
  unawaited(write);
  Store.changed();
  if (reschedule) Reminders.reschedule();
}

/// Every settings tile, grouped. With [hideUnsupported] (desktop and web
/// layouts), options the platform can't honour are hidden (haptics) or shown
/// disabled with the reason (reminders, which need Android's background
/// scheduler).
List<SettingsSection> settingsSections(
  BuildContext context, {
  bool hideUnsupported = false,
}) {
  final arabic = Store.b('arabicDigits', def: true);
  final accent = Store.i('accent', def: WaZaqerTheme.seed.toARGB32());
  final loc = savedLocation();
  final auto = Store.b('autoMethod', def: true);
  final scale = Store.i('fontScale', def: 100);
  final font = Store.s('fontFamily') ?? fontFamilies.first;
  final androidOnly = hideUnsupported && !Reminders.supported;

  Widget toggle(
    String title,
    String key,
    bool def, {
    bool reschedule = false,
  }) => SwitchListTile(
    title: Text(title),
    value: Store.b(key, def: def),
    onChanged: (v) => _set(Store.setB(key, v), reschedule: reschedule),
  );

  return [
    (
      title: 'واجهة التطبيق',
      icon: Icons.palette_outlined,
      tiles: [
        ListTile(
          title: const Text('لون التطبيق'),
          trailing: CircleAvatar(radius: 12, backgroundColor: Color(accent)),
          onTap: () => _pickAccent(context, accent),
        ),
        ListTile(
          title: const Text('المظهر'),
          subtitle: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('تلقائي')),
              ButtonSegment(value: 1, label: Text('فاتح')),
              ButtonSegment(value: 2, label: Text('داكن')),
            ],
            selected: {Store.i('themeMode')},
            onSelectionChanged: (s) => _set(Store.setI('themeMode', s.first)),
          ),
        ),
        toggle('أرقام عربية', 'arabicDigits', true),
      ],
    ),
    (
      title: 'تصفح الأذكار',
      icon: Icons.touch_app_outlined,
      tiles: [
        toggle('التنقل التلقائي', 'autoAdvance', true),
        // no vibration motor on desktop; browsers rarely expose one
        if (!hideUnsupported) toggle('الاهتزاز بعد الذكر', 'haptics', true),
        toggle('صوت النقر', 'sound', false),
        toggle('بقاء الشاشة مضاءة', 'keepAwake', true),
      ],
    ),
    (
      title: 'عرض وقراءة الأذكار',
      icon: Icons.text_fields,
      tiles: [
        toggle('تشكيل الأحرف', 'tashkeel', true),
        ListTile(
          title: const Text('نوع الخط'),
          subtitle: Text(font),
          onTap: () => _pickFont(context, font),
        ),
        ListTile(
          title: const Text('حجم الخط'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: scale > 70
                    ? () => _set(Store.setI('fontScale', scale - 10))
                    : null,
              ),
              Text('${digits(scale, arabic: arabic)}٪'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: scale < 200
                    ? () => _set(Store.setI('fontScale', scale + 10))
                    : null,
              ),
            ],
          ),
        ),
      ],
    ),
    (
      title: 'مواقيت الصلاة',
      icon: Icons.schedule,
      tiles: [
        SwitchListTile(
          title: const Text('الحساب أوتوماتيكيا'),
          subtitle: const Text('طريقة الحساب حسب المنطقة'),
          value: auto,
          onChanged: (v) => _set(Store.setB('autoMethod', v), reschedule: true),
        ),
        ListTile(
          enabled: !auto,
          title: const Text('طريقة الحساب'),
          subtitle: Text(
            loc != null
                ? currentMethod(loc).name
                : methodById(Store.s('method')).name,
          ),
          onTap: () => _pickMethod(context),
        ),
        ListTile(
          title: const Text('الموقع'),
          subtitle: Text(loc?.name ?? 'غير محدد'),
          onTap: () => chooseLocation(context),
          trailing: loc == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.location_off_outlined),
                  tooltip: 'مسح الموقع',
                  onPressed: () async {
                    await clearLocation();
                    Reminders.reschedule();
                  },
                ),
        ),
        if (androidOnly)
          const SwitchListTile(
            title: Text('تنبيه الأذان'),
            subtitle: Text(_androidOnly),
            value: false,
            onChanged: null,
          )
        else
          toggle('تنبيه الأذان', 'adhan', false, reschedule: true),
      ],
    ),
    (
      title: 'صلِّ على محمد ﷺ',
      icon: Icons.favorite_border,
      tiles: [
        if (androidOnly)
          const ListTile(
            enabled: false,
            title: Text('تذكير الصلاة على النبي'),
            subtitle: Text(_androidOnly),
          )
        else
          ListTile(
            title: const Text('تذكير الصلاة على النبي'),
            subtitle: Text(salawatSummary(arabic: arabic)),
            // mirrors under RTL, so it points left in Arabic
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalawatSettingsPage()),
            ),
          ),
      ],
    ),
    (
      title: 'عن التطبيق',
      icon: Icons.info_outline,
      tiles: [
        ListTile(title: const Text('الإصدار'), subtitle: Text(appVersion)),
        ListTile(
          title: const Text('الرخصة'),
          subtitle: const Text('GPL-3.0، تطبيق حر ومفتوح المصدر'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'وَذَكِر',
            applicationVersion: appVersion,
            applicationLegalese: 'GPL-3.0',
          ),
        ),
        ListTile(
          title: const Text('الشيفرة المصدرية'),
          subtitle: const Text(sourceUrl),
          trailing: const Icon(Icons.copy),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: sourceUrl));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
          },
        ),
        ListTile(
          title: const Text('ادعم المشروع'),
          subtitle: const Text(sponsorUrl),
          trailing: const Icon(Icons.volunteer_activism_outlined),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: sponsorUrl));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تم نسخ رابط الدعم')));
          },
        ),
        const ListTile(
          title: Text('مصدر المحتوى'),
          subtitle: Text(
            'نصوص الأذكار من كتب الحديث المشهورة، وهي ملكية عامة، مع تخريج كل ذكر. '
            'الخطوط العربية برخصة SIL Open Font License.',
          ),
        ),
      ],
    ),
  ];
}

/// Settings tab. Every write calls [Store.changed], which rebuilds the theme
/// and the shell tabs, this page included.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        WaZaqerHeader(
          title: 'الإعدادات',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              color: scheme.onPrimary,
              tooltip: 'إعادة ضبط الإعدادات',
              onPressed: () => resetAllSettings(context),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final s in settingsSections(context)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Text(
                    s.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.primary),
                  ),
                ),
                ...s.tiles,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Asks, then clears every key in [settingKeys]; user data stays.
Future<void> resetAllSettings(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('إعادة ضبط الإعدادات؟'),
      content: const Text(
        'تعود جميع الإعدادات إلى قيمها الافتراضية. المفضلة والتقدم في القراءة والموقع تبقى كما هي.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('إعادة الضبط'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  for (final k in settingKeys) {
    await Store.remove(k);
  }
  _set(Future.value(), reschedule: true);
}

void _pickAccent(BuildContext context, int current) => showModalBottomSheet(
  context: context,
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          for (final c in WaZaqerTheme.accents)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.pop(sheet);
                _set(Store.setI('accent', c.toARGB32()));
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 3,
                    color: c.toARGB32() == current
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                  ),
                ),
                child: CircleAvatar(radius: 22, backgroundColor: c),
              ),
            ),
        ],
      ),
    ),
  ),
);

void _pickFont(BuildContext context, String current) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (sheet) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        for (final f in fontFamilies)
          ListTile(
            title: Text(
              'بسم الله الرحمن الرحيم',
              style: TextStyle(fontFamily: f, fontSize: 22),
            ),
            subtitle: Text(f),
            trailing: f == current ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(sheet);
              _set(Store.setS('fontFamily', f));
            },
          ),
      ],
    ),
  ),
);

void _pickMethod(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (sheet) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        for (final m in methods)
          ListTile(
            title: Text(m.name),
            trailing: m.id == methodById(Store.s('method')).id
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              Navigator.pop(sheet);
              _set(Store.setS('method', m.id), reschedule: true);
            },
          ),
      ],
    ),
  ),
);
