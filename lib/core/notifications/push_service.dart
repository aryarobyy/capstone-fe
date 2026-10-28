import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceRegistration {
  final String token;

  final String type;

  const DeviceRegistration({required this.token, required this.type});
}

final pushMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> initPush() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed, push disabled: $e');
    return;
  }
  FirebaseMessaging.onMessage.listen((message) {
    final n = message.notification;
    if (n == null) return;
    pushMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text([n.title, n.body].whereType<String>().join('\n'))),
    );
  });
}

Future<DeviceRegistration?> fetchDeviceRegistration() async {
  if (Firebase.apps.isEmpty) return null;
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  final token = await messaging.getToken();
  if (token == null || token.isEmpty) return null;
  final type = kIsWeb
      ? 'web'
      : defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
  return DeviceRegistration(token: token, type: type);
}
