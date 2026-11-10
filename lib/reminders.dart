import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'adhkar.dart';
import 'digits.dart';
import 'header.dart';
import 'location.dart';
import 'prayer.dart';
import 'store.dart';

// Morning/evening adhkar are timed from sunrise/sunset; ids from adhkar.json.
const morningId = 'g1', eveningId = 'g2';

/// Per-group reminder, stored as JSON under `rem:<groupId>`.
class GroupReminder {
  GroupReminder({
    required this.title,
    required this.minutes,
    this.on = false,
    this.sound = true,
    this.vibrate = true,
  });

  final String title;
  bool on, sound, vibrate;

  /// Morning/evening: minutes before sunrise/sunset. Others: minute of day.
  int minutes;

  static GroupReminder of(String id, String title) {
    final raw = Store.s('rem:$id');
    if (raw == null) {
      return GroupReminder(
          title: title, minutes: id == morningId || id == eveningId ? 30 : 20 * 60);
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return GroupReminder(
      title: j['t'] as String? ?? title,
      minutes: j['m'] as int,
      on: j['on'] as bool,
      sound: j['s'] as bool,
      vibrate: j['v'] as bool,
    );
  }

  Future<void> save(String id) async {
    await Store.setS('rem:$id',
        jsonEncode({'t': title, 'm': minutes, 'on': on, 's': sound, 'v': vibrate}));
    final ids = Store.list('remGroups');
    if (!ids.contains(id)) await Store.setList('remGroups', [...ids, id]);
    await Reminders.reschedule();
  }
}

/// Salawat interval choices in minutes.
const salawatIntervals = [30, 60, 120, 180, 240];

String intervalLabel(int m, {bool arabic = true}) => switch (m) {
      30 => 'كل نصف ساعة',
      60 => 'كل ساعة',
      120 => 'كل ساعتين',
      _ => 'كل ${digits(m ~/ 60, arabic: arabic)} ساعات',
    };

/// Home card pill: «كل ساعة • ٠٨:٠٠ ص - ١٠:٠٠ م».
String salawatSummary({bool arabic = true}) {
  if (!Store.b('salawatOn')) return 'التذكير متوقف';
  final from = Store.i('salawatFrom', def: 8 * 60);
  final to = Store.i('salawatTo', def: 22 * 60);
  return '${intervalLabel(Store.i('salawatEvery', def: 60), arabic: arabic)} • '
      '${clock(from ~/ 60, from % 60, arabic: arabic)} - '
      '${clock(to ~/ 60, to % 60, arabic: arabic)}';
}

/// «٥ دقائق»، «٣٠ دقيقة»
String minutesLabel(int n, {bool arabic = true}) {
  final d = digits(n, arabic: arabic);
  if (n == 1) return 'دقيقة واحدة';
  if (n == 2) return 'دقيقتين';
  if (n >= 3 && n <= 10) return '$d دقائق';
  return '$d دقيقة';
}

/// Local notifications for adhkar, salawat and adhan, with the system
/// sound only. Android only: the desktop builds have no background
/// scheduler, so there the settings are kept but nothing fires.
abstract final class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool get _supported => !kIsWeb && Platform.isAndroid;
  static Future<void> _queue = Future.value();

  // shortcut: one-off alarms for the next 7 days, refreshed on every app
  // start and settings change; a user who doesn't open the app for a week
  // stops getting reminders. Upgrade to a daily background job if that bites.
  static const _days = 7;

  static Future<void> init(void Function(String groupId) onOpen) async {
    if (!_supported) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload?.isNotEmpty ?? false) onOpen(r.payload!);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        payload != null &&
        payload.isNotEmpty) {
      onOpen(payload);
    }
    await reschedule();
  }

  /// Asks for the notification permission (Android 13+); true if granted.
  static Future<bool> requestPermission() async {
    bool granted;
    try {
      granted = await Permission.notification.request().isGranted;
    } on Exception {
      granted = true; // desktop: no permission to ask for
    }
    await Store.setB('notifGranted', granted);
    return granted;
  }

  /// What the home card promises: morning and evening adhkar reminders.
  static Future<void> enableDefaults() async {
    for (final (id, title) in [
      (morningId, 'أذكار الصباح'),
      (eveningId, 'أذكار المساء'),
    ]) {
      if (Store.s('rem:$id') == null) {
        await (GroupReminder.of(id, title)..on = true).save(id);
      }
    }
  }

  /// Rebuilds every pending notification from the stored settings. Calls
  /// queue up so overlapping runs can't interleave cancel and schedule.
  static Future<void> reschedule() =>
      _queue = _queue.catchError((_) {}).then((_) => _reschedule());

  static Future<void> _reschedule() async {
    if (!_supported) return;
    await _plugin.cancelAll();
    if (!await Permission.notification.isGranted) return;
    final now = DateTime.now();
    final loc = savedLocation();
    final reminders = [
      for (final id in Store.list('remGroups'))
        (id, GroupReminder.of(id, '')),
    ].where((r) => r.$2.on);
    final salawat = Store.b('salawatOn');
    final every = Store.i('salawatEvery', def: 60);
    final from = Store.i('salawatFrom', def: 8 * 60);
    final to = Store.i('salawatTo', def: 22 * 60);
    final adhan = Store.b('adhan') && loc != null;
    var id = 0;

    Future<void> at(DateTime t, String title, String body, _Channel ch,
        [String? payload]) async {
      if (!t.isAfter(now)) return;
      await _plugin.zonedSchedule(
        id: id++,
        // an absolute instant, so no time-zone database is needed
        scheduledDate: tz.TZDateTime.from(t, tz.UTC),
        notificationDetails: NotificationDetails(android: ch.details),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    }

    for (var day = 0; day < _days; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      DateTime atMinute(int m) => DateTime(date.year, date.month, date.day, 0, m);
      final pt = loc == null ? null : prayerTimes(date, loc.lat, loc.lng, currentMethod(loc));
      for (final (gid, r) in reminders) {
        // without a location: sunrise ~06:00, sunset ~18:00
        final t = switch (gid) {
          morningId => (pt?.sunrise ?? atMinute(6 * 60)),
          eveningId => (pt?.maghrib ?? atMinute(18 * 60)),
          _ => atMinute(r.minutes),
        };
        await at(
          gid == morningId || gid == eveningId
              ? t.subtract(Duration(minutes: r.minutes))
              : t,
          r.title,
          'اضغط لقراءة الذكر',
          _Channel.adhkar(r.sound, r.vibrate),
          gid,
        );
      }
      if (salawat) {
        for (var m = from; m <= to; m += every) {
          await at(atMinute(m), 'صلِّ على محمد ﷺ',
              'اللهم صلِّ وسلم على نبينا محمد', _Channel.salawat);
        }
      }
      if (adhan) {
        for (final i in [0, 2, 3, 4, 5]) {
          await at(pt!.all[i], 'حان الآن وقت صلاة ${prayerNames[i]}', loc.name,
              _Channel.adhan);
        }
      }
    }
  }
}

/// Android fixes sound and vibration per channel at creation, so each
/// sound/vibration combination of the adhkar reminders gets its own.
class _Channel {
  const _Channel(this.id, this.name, {this.sound = true, this.vibrate = true});

  final String id, name;
  final bool sound, vibrate;

  static _Channel adhkar(bool sound, bool vibrate) => _Channel(
        'adhkar_${sound ? 1 : 0}${vibrate ? 1 : 0}',
        switch ((sound, vibrate)) {
          (true, true) => 'تذكير الأذكار: صوت واهتزاز',
          (true, false) => 'تذكير الأذكار: صوت',
          (false, true) => 'تذكير الأذكار: اهتزاز',
          (false, false) => 'تذكير الأذكار: صامت',
        },
        sound: sound,
        vibrate: vibrate,
      );
  static const salawat = _Channel('salawat', 'الصلاة على النبي ﷺ');
  static const adhan = _Channel('adhan', 'الأذان');

  AndroidNotificationDetails get details => AndroidNotificationDetails(
        id,
        name,
        importance: id == 'adhan' ? Importance.high : Importance.defaultImportance,
        playSound: sound,
        enableVibration: vibrate,
      );
}

/// Bottom sheet from the reader's bell: reminder settings for one group.
Future<void> showReminderSheet(BuildContext context, DhikrGroup group) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReminderSheet(group: group),
    );

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.group});

  final DhikrGroup group;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late final _r = GroupReminder.of(widget.group.id, widget.group.title);

  void _update(void Function() f) {
    setState(f);
    _r.save(widget.group.id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final id = widget.group.id;
    final relative = id == morningId || id == eveningId;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_active_outlined,
                    color: scheme.primary),
              ),
              title: Text('إعدادات التذكير',
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(widget.group.title),
            ),
            SwitchListTile(
              title: const Text('تفعيل التذكير'),
              value: _r.on,
              onChanged: (v) async {
                if (v && !await Reminders.requestPermission()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('الإشعارات غير مسموح بها لهذا التطبيق')));
                  }
                  return;
                }
                _update(() => _r.on = v);
              },
            ),
            SwitchListTile(
              title: const Text('التنبيه بصوت'),
              value: _r.sound,
              onChanged: _r.on ? (v) => _update(() => _r.sound = v) : null,
            ),
            SwitchListTile(
              title: const Text('التنبيه بالاهتزاز'),
              value: _r.vibrate,
              onChanged: _r.on ? (v) => _update(() => _r.vibrate = v) : null,
            ),
            if (relative)
              ListTile(
                enabled: _r.on,
                title: Text(_r.minutes == 0
                    ? (id == morningId ? 'عند الشروق' : 'عند الغروب')
                    : '${id == morningId ? 'قبل الشروق' : 'قبل الغروب'} بـ '
                        '${minutesLabel(_r.minutes, arabic: arabic)}'),
                subtitle: savedLocation() == null
                    ? const Text('بدون موقع: الشروق ٦:٠٠ ص والغروب ٦:٠٠ م تقريبًا')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _r.on && _r.minutes > 0
                          ? () => _update(() => _r.minutes -= 5)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _r.on && _r.minutes < 180
                          ? () => _update(() => _r.minutes += 5)
                          : null,
                    ),
                  ],
                ),
              )
            else
              ListTile(
                enabled: _r.on,
                title: const Text('وقت التذكير'),
                trailing: Text(clock(_r.minutes ~/ 60, _r.minutes % 60,
                    arabic: arabic)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: _r.minutes ~/ 60, minute: _r.minutes % 60),
                  );
                  if (t != null) _update(() => _r.minutes = t.hour * 60 + t.minute);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Salawat reminder: on/off, interval and the daily window it runs in.
class SalawatSettingsPage extends StatefulWidget {
  const SalawatSettingsPage({super.key});

  @override
  State<SalawatSettingsPage> createState() => _SalawatSettingsPageState();
}

class _SalawatSettingsPageState extends State<SalawatSettingsPage> {
  Future<void> _set(Future<void> write) async {
    await write;
    setState(() {});
    Store.changed();
    await Reminders.reschedule();
  }

  Future<void> _pickTime(String key, int current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (t != null) await _set(Store.setI(key, t.hour * 60 + t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final arabic = Store.b('arabicDigits', def: true);
    final on = Store.b('salawatOn');
    final every = Store.i('salawatEvery', def: 60);
    final from = Store.i('salawatFrom', def: 8 * 60);
    final to = Store.i('salawatTo', def: 22 * 60);
    return Scaffold(
      body: Column(
        children: [
          const WaZaqerHeader(title: 'صلِّ على محمد ﷺ', showBack: true),
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('تفعيل التذكير'),
                  subtitle: const Text('تذكير بالصلاة على النبي ﷺ على مدار اليوم'),
                  value: on,
                  onChanged: (v) async {
                    if (v && !await Reminders.requestPermission()) return;
                    await _set(Store.setB('salawatOn', v));
                  },
                ),
                ListTile(
                  enabled: on,
                  title: const Text('التكرار'),
                  trailing: DropdownButton<int>(
                    value: every,
                    onChanged: on
                        ? (v) => _set(Store.setI('salawatEvery', v!))
                        : null,
                    items: [
                      for (final m in salawatIntervals)
                        DropdownMenuItem(
                            value: m,
                            child: Text(intervalLabel(m, arabic: arabic))),
                    ],
                  ),
                ),
                ListTile(
                  enabled: on,
                  title: const Text('من'),
                  trailing: Text(clock(from ~/ 60, from % 60, arabic: arabic)),
                  onTap: () => _pickTime('salawatFrom', from),
                ),
                ListTile(
                  enabled: on,
                  title: const Text('إلى'),
                  trailing: Text(clock(to ~/ 60, to % 60, arabic: arabic)),
                  onTap: () => _pickTime('salawatTo', to),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
