

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jippydriver_driver/utils/preferences.dart';

import '../services/audio_player_service.dart' show AudioPlayerService;

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("📱 Background FCM received: ${message.messageId}");

  // Initialize Firebase and services in background
  await Firebase.initializeApp();
  await Preferences.initPref();
  await AudioPlayerService.initAudio();

  // Play sound for background notification
  await AudioPlayerService.playSound(true);

  // Show local notification with sound
  await NotificationService().displayBackgroundNotification(message);
}

class NotificationService {
  // Special method for background notifications
  Future<void> displayBackgroundNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'background_order_channel',
        'Background Order Notifications',
        description: 'Order notifications when app is in background',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_ringtone'),
      );

      AndroidNotificationDetails notificationDetails =
      AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: channel.sound,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([1000, 1000, 1000, 1000]),
        timeoutAfter: 30000, // 30 seconds
      );

      const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true);

      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails,
          iOS: darwinNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'New Order',
        message.notification?.body ?? 'You have a new order',
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );

      log("✅ Background notification displayed with sound");
    } on Exception catch (e) {
      log("Background notification error: $e");
    }
  }
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initInfo() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (payload) {});
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      FirebaseMessaging.onBackgroundMessage(
          (message) => firebaseMessageBackgroundHandle(message));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
      }
    });
    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("driver");
  }

  static getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        log("getToken timeout - returning empty string");
        return null;
      });
      return token ?? '';
    } catch (e) {
      log("getToken error: $e - returning empty string");
      return '';
    }
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification?.body.toString() ?? ''}');
    try {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        'order_channel',
        'goRide-customer',
        description: 'Show QuickLAI Notification',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('order_ringtone'), // Add this
      );
      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(channel.id, channel.name,
              channelDescription: 'your channel Description',
              importance: Importance.high,
              priority: Priority.high,
              ticker: 'ticker',
            sound: channel.sound, // Use channel sound);
          );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);
      await FlutterLocalNotificationsPlugin().show(
        0,
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }
}




// import 'dart:convert';
// import 'dart:developer';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
//   log("BackGround Message :: ${message.messageId}");
// }
//
// class NotificationService {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   initInfo() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     var request = await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     if (request.authorizationStatus == AuthorizationStatus.authorized ||
//         request.authorizationStatus == AuthorizationStatus.provisional) {
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       var iosInitializationSettings = const DarwinInitializationSettings();
//       final InitializationSettings initializationSettings =
//           InitializationSettings(
//               android: initializationSettingsAndroid,
//               iOS: iosInitializationSettings);
//       await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//           onDidReceiveNotificationResponse: (payload) {});
//       setupInteractedMessage();
//     }
//   }
//
//   Future<void> setupInteractedMessage() async {
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       FirebaseMessaging.onBackgroundMessage(
//           (message) => firebaseMessageBackgroundHandle(message));
//     }
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       log("::::::::::::onMessage:::::::::::::::::");
//       if (message.notification != null) {
//         log(message.notification.toString());
//         display(message);
//       }
//     });
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//       log("::::::::::::onMessageOpenedApp:::::::::::::::::");
//       if (message.notification != null) {
//         log(message.notification.toString());
//       }
//     });
//     log("::::::::::::Permission authorized:::::::::::::::::");
//     await FirebaseMessaging.instance.subscribeToTopic("driver");
//   }
//
//   static getToken() async {
//     try {
//       String? token = await FirebaseMessaging.instance.getToken()
//           .timeout(const Duration(seconds: 10), onTimeout: () {
//         log("getToken timeout - returning empty string");
//         return null;
//       });
//       return token ?? '';
//     } catch (e) {
//       log("getToken error: $e - returning empty string");
//       return '';
//     }
//   }
//
//   void display(RemoteMessage message) async {
//     log('Got a message whilst in the foreground!');
//     log('Message data: ${message.notification?.body.toString() ?? ''}');
//     try {
//       AndroidNotificationChannel channel = const AndroidNotificationChannel(
//         'order_channel',
//         'goRide-customer',
//         description: 'Show QuickLAI Notification',
//         importance: Importance.max,
//         sound: RawResourceAndroidNotificationSound('order_ringtone'), // Add this
//       );
//       AndroidNotificationDetails notificationDetails =
//           AndroidNotificationDetails(channel.id, channel.name,
//               channelDescription: 'your channel Description',
//               importance: Importance.high,
//               priority: Priority.high,
//               ticker: 'ticker',
//             sound: channel.sound, // Use channel sound);
//           );
//       const DarwinNotificationDetails darwinNotificationDetails =
//           DarwinNotificationDetails(
//               presentAlert: true, presentBadge: true, presentSound: true);
//       NotificationDetails notificationDetailsBoth = NotificationDetails(
//           android: notificationDetails, iOS: darwinNotificationDetails);
//       await FlutterLocalNotificationsPlugin().show(
//         0,
//         message.notification?.title ?? 'Notification',
//         message.notification?.body ?? '',
//         notificationDetailsBoth,
//         payload: jsonEncode(message.data),
//       );
//     } on Exception catch (e) {
//       log(e.toString());
//     }
//   }
// }
