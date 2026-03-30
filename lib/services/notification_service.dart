// notification_service.dart
// Fetches all friends and their last interaction dates, then uses
// ReminderChecker to determine which reminders to show.
// Uses flutter_local_notifications to deliver them.
// Notification checks are triggered on app foreground (HomeScreen init),
// not via background tasks — simpler and sufficient for MVP.
//
// Note: flutter_local_notifications does NOT work on web. All calls are
// guarded by a kIsWeb check so the app still runs in the browser.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import 'reminder_checker.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Must be called once, before checkAndNotify(). Safe to call multiple times.
  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _initialized = true;
  }

  /// Queries Supabase for current friends + last interaction dates,
  /// runs ReminderChecker, and fires local notifications for due reminders.
  static Future<void> checkAndNotify() async {
    if (kIsWeb) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Fetch all friends for this user.
    final friendsData = await client
        .from('friends')
        .select()
        .eq('user_id', userId);

    final friends = (friendsData as List)
        .map((e) => Friend.fromMap(e))
        .where((f) =>
            f.label == RelationshipLabel.active ||
            f.label == RelationshipLabel.obligatory)
        .toList();

    if (friends.isEmpty) return;

    // Fetch last interaction date per friend in one query.
    final friendIds = friends.map((f) => f.id).toList();
    final interactionsData = await client
        .from('interactions')
        .select('friend_id, created_at')
        .inFilter('friend_id', friendIds)
        .order('created_at', ascending: false);

    final lastDates = <String, DateTime>{};
    for (final row in interactionsData as List) {
      final fid = row['friend_id'] as String;
      if (!lastDates.containsKey(fid)) {
        lastDates[fid] = DateTime.parse(row['created_at'] as String);
      }
    }

    final reminders = ReminderChecker.check(
      friends: friends,
      lastInteractionDates: lastDates,
      now: DateTime.now(),
    );

    for (final reminder in reminders) {
      await _plugin.show(
        reminder.friend.id.hashCode.abs() % 100000,
        reminder.title,
        reminder.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'closer_reminders',
            'Relationship Reminders',
            channelDescription:
                'Reminders to maintain your active relationships',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }
}
