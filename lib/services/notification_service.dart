import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/classroom.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // UTC remains a safe fallback if the platform timezone cannot be resolved.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> rescheduleFromPreferences(List<Classroom> classes) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? false;
    await _plugin.cancelAllPendingNotifications();
    if (!enabled) return;

    final reminderTime = prefs.getString('notificationTime') ?? '17:30';
    final enabledDays = prefs.getStringList('notificationDays')
            ?.map(int.parse)
            .toSet() ??
        <int>{1, 2, 3, 4, 5, 6, 7};
    final parts = reminderTime.split(':');
    final reminderHour = int.tryParse(parts.first) ?? 17;
    final reminderMinute = int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30;

    for (final classroom in classes.where((c) => !c.archived && c.id != null)) {
      if (!enabledDays.contains(classroom.weekday)) continue;
      final before = _nextWeekdayAt(
        classroom.weekday,
        reminderHour,
        reminderMinute,
      );
      await _plugin.zonedSchedule(
        id: 100000 + classroom.id!,
        title: 'Aula de informática hoje',
        body: '${classroom.name} às ${classroom.startTime}.',
        scheduledDate: before,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'aulas_semanais',
            'Lembretes de aulas',
            channelDescription: 'Lembretes das aulas cadastradas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      final endParts = classroom.endTime.split(':');
      final endHour = int.tryParse(endParts.first) ?? 20;
      final endMinute = int.tryParse(endParts.length > 1 ? endParts[1] : '00') ?? 0;
      final totalMinutes = endHour * 60 + endMinute + 15;
      final afterHour = (totalMinutes ~/ 60) % 24;
      final afterMinute = totalMinutes % 60;
      final dayOffset = totalMinutes >= 24 * 60 ? 1 : 0;
      final followupWeekday = ((classroom.weekday - 1 + dayOffset) % 7) + 1;
      final after = _nextWeekdayAt(followupWeekday, afterHour, afterMinute);
      await _plugin.zonedSchedule(
        id: 200000 + classroom.id!,
        title: 'Registro da aula',
        body: 'Não esqueça de registrar o conteúdo de ${classroom.name}.',
        scheduledDate: after,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'registros_aulas',
            'Lembretes de registros',
            channelDescription: 'Lembretes para registrar o conteúdo das aulas',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextWeekdayAt(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day + 1,
        hour,
        minute,
      );
    }
    return candidate;
  }
}
