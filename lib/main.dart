import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nexxchat_firebase/Screens/call_screen.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/Screens/welcome_screens.dart';
import 'package:nexxchat_firebase/Screens/incoming_call_screen.dart';
import 'package:nexxchat_firebase/core/call/call_mini_overlay.dart';
import 'package:nexxchat_firebase/core/call/webrtc_call_engine.dart';
import 'package:nexxchat_firebase/core/call_listener.dart';
import 'package:nexxchat_firebase/core/navigation.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart';
import 'package:provider/provider.dart';
import 'package:nexxchat_firebase/core/services/notification_settings.dart'
    as app_notif;
import 'core/call/call_session.dart';
import 'theme_notifier.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("BG DATA: ${message.data}");
}

void setupFCMCallHandling() {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("ON MESSAGE: ${message.data}");

    if (message.data["type"] != "incoming_call") return;

    final callId = message.data["callId"];
    if (callId == null) return;

    globalNavigatorKey.currentState?.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          callId: callId,
          title: "Incoming Call",
          onAccept: () async {
            final user = auth.currentUser;
            if (user == null) return;

            await db.collection("calls").doc(callId).update({
              'status': 'accepted',
              'acceptedAt': FieldValue.serverTimestamp(),
              'acceptedAtMs': DateTime.now().millisecondsSinceEpoch,
            });

            final doc =
                await db.collection("calls").doc(callId).get();

            final callType =
                (doc.data()?['callType'] ?? 'audio') as String;

            final engine =
                WebRTCCallEngine(isCaller: false, callType: callType);

            await engine.init(
              callId: callId,
              userId: user.uid,
              userName: user.email ?? "User",
            );

            globalNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callId: callId,
                  engine: engine,
                  title: "Call",
                  userId: user.uid,
                  userName: user.email ?? "User",
                  callType: callType,
                ),
              ),
            );
          },
          onDecline: () async {
            await db.collection("calls").doc(callId).update({
              "status": "declined",
            });
          },
        ),
      ),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("OPENED: ${message.data}");
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseBgHandler);

  setupFCMCallHandling();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Notifications',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await ChatTheme.loadAll();
  await app_notif.NotificationSettings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallSession()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return ValueListenableBuilder<int>(
          valueListenable: reloadNotifier,
          builder: (context, _, __) {
            final isDark = currentMode == ThemeMode.dark;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                systemNavigationBarColor:
                    isDark ? const Color(0xFF121212) : Colors.white,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
            );

            return GlobalCallListener(
              child: MaterialApp(
                navigatorKey: globalNavigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'NexxChat',
                themeMode: currentMode,
                theme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                ),
                initialRoute: _auth.currentUser != null
                    ? ChatHomeScreen.screenRoute
                    : WelcomeScreen.screenRoute,
                routes: {
                  WelcomeScreen.screenRoute: (_) =>
                      const WelcomeScreen(),
                  SignInScreen.screenRoute: (_) =>
                      const SignInScreen(),
                  RegistrationScreen.screenRoute: (_) =>
                      const RegistrationScreen(),
                  ChatScreen.screenRoute: (_) => const ChatScreen(),
                  ChatHomeScreen.screenRoute: (_) =>
                      const ChatHomeScreen(),
                },
                builder: (context, child) {
                  return Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (_) => child!),
                      OverlayEntry(
                        builder: (_) => const CallMiniOverlay(),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}