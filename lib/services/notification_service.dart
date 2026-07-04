import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> scheduleAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    await _scheduleDailyTaskCount();
    await _scheduleMoneyDueReminders();
    await _scheduleTaskReminders();
  }

  Future<void> _scheduleDailyTaskCount() async {
    final tasks = await DatabaseService.instance.getTasks();
    final pending = tasks.where((t) => !t.isDone).length;
    await _plugin.zonedSchedule(
      1001,
      'MyLife tasks',
      pending == 1 ? '1 pending task for today.' : '$pending pending tasks waiting.',
      _nextNineAm(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_tasks',
          'Daily task summary',
          channelDescription: 'Daily pending task count at 9 AM',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleMoneyDueReminders() async {
    final money = await DatabaseService.instance.getMoneyEntries();
    final now = DateTime.now();
    for (final entry in money.where((m) => !m.isPaid && m.id != null)) {
      final reminder = DateTime(entry.dueDate.year, entry.dueDate.month, entry.dueDate.day - 1, 9);
      if (!reminder.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        200000 + entry.id!,
        'Money reminder',
        '${entry.personOrBill} is due tomorrow: Rs ${entry.amount.toStringAsFixed(0)}',
        tz.TZDateTime.from(reminder, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'money_due',
            'Money due reminders',
            channelDescription: 'Reminders one day before money due dates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _scheduleTaskReminders() async {
    final tasks = await DatabaseService.instance.getTasks();
    final now = tz.TZDateTime.now(tz.local);

    for (final task in tasks.where((t) => !t.isDone && t.reminderAt != null)) {
      final reminderTime = tz.TZDateTime.from(task.reminderAt!, tz.local);
      if (!reminderTime.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        100000 + task.id!,
        'Task Reminder',
        task.title,
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminders for individual tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
