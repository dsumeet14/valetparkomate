import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  // Use a singleton instance to prevent multiple initializations
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize local notifications
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    // Request notification permissions
    await _notifications.initialize(settings);
    final granted = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // You can handle the granted status if needed
  }

  /// Show a notification with a custom sound. This method is the primary one
  /// that should be called by your app's logic.
  Future<void> notifyWithSound({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Channel for new task assignments',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // The sound is played separately for reliability
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // We can use a unique ID to show multiple notifications
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notifications.show(id, title, body, details);

    // Play sound from assets
    final player = AudioPlayer();
    await player.setVolume(1.0); // Set volume to max for clear sound
    await player.play(AssetSource('sounds/beep.mp3'));
  }
}