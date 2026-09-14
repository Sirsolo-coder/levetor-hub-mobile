import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_provider.dart';
import 'services/api_service.dart';
import 'screens/main_navigation_screen.dart';


// =========================================================
// LOCAL NOTIFICATIONS
// =========================================================

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
  'levetor_hub_notifications',
  'Levetor Hub Notifications',
  description:
      'Notifications from Levetor Hub about orders, payments and updates.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);


// =========================================================
// BACKGROUND FIREBASE MESSAGE HANDLER
// =========================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Background notification received: '
    '${message.messageId}',
  );
}


// =========================================================
// INITIALIZE LOCAL NOTIFICATIONS
// =========================================================

Future<void> _initializeLocalNotifications() async {
  const androidInitializationSettings =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings =
      InitializationSettings(
    android: androidInitializationSettings,
  );

  await localNotifications.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (
      NotificationResponse response,
    ) {
      debugPrint(
        'Local notification tapped. '
        'Payload: ${response.payload}',
      );
    },
  );

  final androidPlugin =
      localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      notificationChannel,
    );

    await androidPlugin.requestNotificationsPermission();
  }
}


// =========================================================
// SHOW FOREGROUND NOTIFICATION
// =========================================================

Future<void> _showForegroundNotification(
  RemoteMessage message,
) async {
  final notification = message.notification;

  String title =
      notification?.title ??
      message.data['title']?.toString() ??
      'Levetor Hub';

  String body =
      notification?.body ??
      message.data['body']?.toString() ??
      'You have a new notification.';

  title = title.trim();
  body = body.trim();

  if (title.isEmpty) {
    title = 'Levetor Hub';
  }

  if (body.isEmpty) {
    body = 'You have a new notification.';
  }

  final androidDetails =
      AndroidNotificationDetails(
    notificationChannel.id,
    notificationChannel.name,
    channelDescription:
        notificationChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  final notificationDetails =
      NotificationDetails(
    android: androidDetails,
  );

  final notificationId =
      DateTime.now()
          .millisecondsSinceEpoch
          .remainder(2147483647);

  await localNotifications.show(
    id: notificationId,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
    payload: message.data.toString(),
  );
}


// =========================================================
// INITIALIZE FIREBASE CLOUD MESSAGING
// =========================================================

Future<void> _initializeNotifications() async {
  final messaging =
      FirebaseMessaging.instance;

  // ---------------------------------------------------------
  // REQUEST FIREBASE NOTIFICATION PERMISSION
  // ---------------------------------------------------------

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  debugPrint(
    'Notification permission status: '
    '${settings.authorizationStatus}',
  );

  // ---------------------------------------------------------
  // GET FCM TOKEN
  // ---------------------------------------------------------

  try {
    final token =
        await messaging.getToken();

    debugPrint(
      'FCM TOKEN: $token',
    );
  } catch (e) {
    debugPrint(
      'Unable to get FCM token: $e',
    );
  }

  // ---------------------------------------------------------
  // TOKEN REFRESH
  // ---------------------------------------------------------

  FirebaseMessaging.instance.onTokenRefresh.listen(
    (newToken) async {
      debugPrint(
        'FCM TOKEN REFRESHED: $newToken',
      );

      try {
        final prefs =
            await SharedPreferences.getInstance();

        final customerId =
            prefs.getInt('customer_id');

        if (customerId == null) {
          debugPrint(
            'No logged-in customer for refreshed FCM token.',
          );
          return;
        }

        final registered =
            await ApiService.registerFcmToken(
          customerId: customerId,
          fcmToken: newToken,
        );

        debugPrint(
          registered
              ? 'Refreshed FCM token registered successfully.'
              : 'Refreshed FCM token registration failed.',
        );
      } catch (e) {
        debugPrint(
          'FCM token refresh registration error: $e',
        );
      }
    },
  );

  // ---------------------------------------------------------
  // FOREGROUND MESSAGES
  // ---------------------------------------------------------

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      debugPrint(
        'Foreground notification received.',
      );

      debugPrint(
        'Title: ${message.notification?.title}',
      );

      debugPrint(
        'Body: ${message.notification?.body}',
      );

      debugPrint(
        'Data: ${message.data}',
      );

      await _showForegroundNotification(
        message,
      );
    },
  );
}


// =========================================================
// MAIN
// =========================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------
  // FIREBASE
  // ---------------------------------------------------------

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  // ---------------------------------------------------------
  // BACKGROUND MESSAGE HANDLER
  // ---------------------------------------------------------

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // ---------------------------------------------------------
  // LOCAL NOTIFICATION SYSTEM
  // ---------------------------------------------------------

  await _initializeLocalNotifications();

  // ---------------------------------------------------------
  // FIREBASE MESSAGING
  // ---------------------------------------------------------

  await _initializeNotifications();

  // ---------------------------------------------------------
  // START APPLICATION
  // ---------------------------------------------------------

  runApp(
    const LevetorHubApp(),
  );
}


// =========================================================
// APPLICATION
// =========================================================

class LevetorHubApp extends StatelessWidget {
  const LevetorHubApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ProductProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) =>
              CartProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) =>
              CustomerProvider()
                ..loadCustomer(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'Levetor Hub',

        theme: ThemeData(
          useMaterial3: true,

          colorScheme:
              ColorScheme.fromSeed(
            seedColor:
                const Color(0xFF29B6F6),
            brightness:
                Brightness.light,
          ),

          scaffoldBackgroundColor:
              Colors.white,

          appBarTheme:
              const AppBarTheme(
            backgroundColor:
                Colors.white,
            foregroundColor:
                Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),
        ),

        home:
            const MainNavigationScreen(),
      ),
    );
  }
}