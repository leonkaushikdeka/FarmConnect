// ============================================================
// Firebase Service — Push Notifications (FCM)
// ============================================================
// Setup instructions:
// 1. Add Firebase to your Flutter project:
//    - Go to https://console.firebase.google.com/
//    - Create a project (or use the same one as the backend)
//    - Add an Android app: register package name "com.example.farmconnect"
//      (or your actual package name from android/app/build.gradle)
//    - Download google-services.json and place it at:
//        android/app/google-services.json
//    - Add the Google Services Gradle plugin:
//        android/build.gradle:  classpath 'com.google.gms:google-services:4.4.3'
//        android/app/build.gradle: apply plugin: 'com.google.gms.google-services'
//    - Add Firebase Messaging dependency in android/app/build.gradle:
//        implementation 'com.google.firebase:firebase-messaging:24.4.0'
//    - For iOS:
//        - Add GoogleService-Info.plist to ios/Runner via Xcode
//        - Enable Push Notifications in Xcode > Signing & Capabilities
// 2. Run: flutter pub get
// 3. Run: flutterfire configure (optional, auto-generates config)
// ============================================================

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

// -----------------------------------------------------------------
// Local notifications plugin (for foreground messages on Android)
// -----------------------------------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// -----------------------------------------------------------------
// Initialize Firebase and configure messaging
// -----------------------------------------------------------------
Future<void> initializeFirebase() async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();

  // Request notification permissions (iOS)
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  print('Firebase messaging permission status: ${settings.authorizationStatus}');

  // Configure local notifications for foreground display (Android)
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Get the current FCM token and register it with the backend
  await _registerFcmToken();

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

  // Handle messages when the app is in the background but not terminated
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

  // Handle background messages (top-level function — see below)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('FCM Token refreshed: $newToken');
    await _registerFcmToken(token: newToken);
  });
}

// -----------------------------------------------------------------
// Get the current FCM token
// -----------------------------------------------------------------
Future<String?> getFcmToken() async {
  return await FirebaseMessaging.instance.getToken();
}

// -----------------------------------------------------------------
// Register FCM token with the backend API
// -----------------------------------------------------------------
Future<void> _registerFcmToken({String? token}) async {
  token ??= await getFcmToken();
  if (token == null) {
    print('FCM token is null — skipping registration');
    return;
  }

  try {
    final api = ApiService();
    // Assumes the user is already logged in and token is set
    final response = await api.post('/notifications/token', {
      'fcmToken': token,
    });
    print('FCM token registered with backend: ${response}');
  } catch (e) {
    print('Failed to register FCM token with backend: $e');
  }
}

// -----------------------------------------------------------------
// Handle foreground messages (show local notification)
// -----------------------------------------------------------------
void _handleForegroundMessage(RemoteMessage message) {
  print('Received foreground FCM message: ${message.notification?.title}');

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'farmconnect_channel',
          'FarmConnect Notifications',
          channelDescription: 'Order updates and farmer notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _buildPayload(message),
    );
  }
}

// -----------------------------------------------------------------
// Handle notification tap (app opened from notification)
// -----------------------------------------------------------------
void _handleMessageOpenedApp(RemoteMessage message) {
  print('App opened from FCM notification: ${message.notification?.title}');
  _navigateToOrderDetail(message);
}

// -----------------------------------------------------------------
// Handle notification tap from local notifications plugin
// -----------------------------------------------------------------
Future<void> _handleNotificationTap(String? payload) async {
  if (payload != null) {
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload));
      _navigateToOrderScreen(data);
    } catch (_) {}
  }
}

// -----------------------------------------------------------------
// Navigate to order detail screen (used by the router)
// -----------------------------------------------------------------
void _navigateToOrderDetail(RemoteMessage message) {
  final data = message.data;
  if (data.containsKey('orderId')) {
    _navigateToOrderScreen(data);
  }
}

// -----------------------------------------------------------------
// Navigate to order screen with order details
// This is called via the root navigator — adjust integration
// based on your routing setup (e.g., GoRouter, auto_route).
// -----------------------------------------------------------------
void _navigateToOrderScreen(Map<String, dynamic> data) {
  // NOTE: The actual navigation depends on your routing architecture.
  // The simplest approach is to use a GlobalKey<NavigatorState>
  // or a state management solution (provider, riverpod, etc.)
  // to push the OrderDetailScreen when a notification is tapped.
  //
  // Example with GlobalKey:
  //   navigatorKey.currentState?.pushNamed(
  //     '/order-detail',
  //     arguments: {'orderId': data['orderId']},
  //   );
  print('Navigating to order detail: ${data['orderId']}');
}

// -----------------------------------------------------------------
// Build a JSON string payload for local notification taps
// -----------------------------------------------------------------
String _buildPayload(RemoteMessage message) {
  final combined = {
    ...message.data,
    if (message.notification != null) 'title': message.notification?.title,
    if (message.notification != null) 'body': message.notification?.body,
  };
  return jsonEncode(combined);
}

// -----------------------------------------------------------------
// TOP-LEVEL background message handler
// This function MUST be top-level (not inside a class).
// It is called when the app is terminated and a message arrives.
// -----------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call initializeApp() first.
  await Firebase.initializeApp();

  print('Handling a background message: ${message.messageId}');

  // Show a local notification for the background message
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'farmconnect_channel',
          'FarmConnect Notifications',
          channelDescription: 'Order updates and farmer notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _buildPayload(message),
    );
  }
}

// -----------------------------------------------------------------
// Send FCM token to backend (convenience, called from login flow)
// -----------------------------------------------------------------
Future<void> sendTokenToBackend() async {
  await _registerFcmToken();
}