import 'dart:async';

import 'package:flutter/material.dart';
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

/// Keys cleared by «reset all settings». Favourites, reading progress,
/// tasbeeh counts, location and per-group reminders are user data and stay.
const settingKeys = [
  'accent', 'themeMode', 'arabicDigits', 'autoAdvance', 'haptics', 'sound',
  'keepAwake', 'tashkeel', 'fontFamily', 'fontScale', 'autoMethod', 'method',
  'adhan', 'salawatOn', 'salawatEvery', 'salawatFrom', 'salawatTo',
];

const fontFamilies = [
  'Noto Naskh Arabic', 'Amiri', 'Scheherazade New', 'Cairo', 'Reem Kufi',
  'Tajawal',
];

/// Settings tab. Every write calls [Store.changed], which rebuilds the theme
/// and the shell tabs, this page included.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static void _set(Future<void> write, {bool reschedule = false}) {
    // SharedPreferences updates its cache synchronously, so readers see the
    // new value before the disk write completes.
    unawaited(write);
    Store.changed();
    if (reschedule) Reminders.reschedule();
  }

  Future<void> _resetAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط الإعدادات؟'),
        content: const Text(
            'تعود جميع الإعدادات إلى قيمها الافتراضية. المفضلة والتقدم في القراءة والموقع تبقى كما هي.'),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final accent = Store.i('accent', def: WaZaqerTheme.seed.toARGB32());
    final loc = savedLocation();
    final auto = Store.b('autoMethod', def: true);
    final scale = Store.i('fontScale', def: 100);
    final font = Store.s('fontFamily') ?? fontFamilies.first;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.primary)),
        );
    Widget toggle(String title, String key, bool def, {bool reschedule = false}) =>
        SwitchListTile(
          title: Text(title),
          value: Store.b(key, def: def),
          onChanged: (v) => _set(Store.setB(key, v), reschedule: reschedule),
        );

    return Column(
      children: [
        WaZaqerHeader(
          title: 'الإعدادات',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              color: scheme.onPrimary,
              tooltip: 'إعادة ضبط الإعدادات',
              onPressed: () => _resetAll(context),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              section('واجهة التطبيق'),
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

              section('تصفح الأذكار'),
              toggle('التنقل التلقائي', 'autoAdvance', true),
              toggle('الاهتزاز بعد الذكر', 'haptics', true),
              toggle('صوت النقر', 'sound', false),
              toggle('بقاء الشاشة مضاءة', 'keepAwake', true),

              section('عرض وقراءة الأذكار'),
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

              section('مواقيت الصلاة'),
              SwitchListTile(
                title: const Text('الحساب أوتوماتيكيا'),
                subtitle: const Text('طريقة الحساب حسب المنطقة'),
                value: auto,
                onChanged: (v) => _set(Store.setB('autoMethod', v), reschedule: true),
              ),
              ListTile(
                enabled: !auto,
                title: const Text('طريقة الحساب'),
                subtitle: Text(loc != null
                    ? currentMethod(loc).name
                    : methodById(Store.s('method')).name),
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
              toggle('تنبيه الأذان', 'adhan', false, reschedule: true),

              section('صلِّ على محمد ﷺ'),
              ListTile(
                title: const Text('تذكير الصلاة على النبي'),
                subtitle: Text(salawatSummary(arabic: arabic)),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalawatSettingsPage()),
                ),
              ),

              section('عن التطبيق'),
              ListTile(
                title: const Text('الإصدار'),
                subtitle: Text(appVersion),
              ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرابط')));
                },
              ),
              const ListTile(
                title: Text('مصدر المحتوى'),
                subtitle: Text(
                    'نصوص الأذكار من كتب الحديث المشهورة، وهي ملكية عامة، مع تخريج كل ذكر. '
                    'الخطوط العربية برخصة SIL Open Font License.'),
              ),
            ],
          ),
        ),
      ],
    );
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
                  title: Text('بسم الله الرحمن الرحيم',
                      style: TextStyle(fontFamily: f, fontSize: 22)),
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
}
