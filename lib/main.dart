import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'Screens/chat_home_screen.dart';
import 'Screens/chat_screen.dart';
import 'Screens/registration_screen.dart';
import 'Screens/signin_screen.dart';
import 'Screens/welcome_screens.dart';

import 'core/Call_listener.dart';
import 'core/call/call_mini_overlay.dart';
import 'core/call/call_session.dart';
import 'core/navigation.dart';
import 'core/services/chat_theme.dart';
import 'theme_notifier.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Benachrichtigungen',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await ChatTheme.loadTheme();
  await ChatTheme.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallSession()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, themeMode, __) {
        return ValueListenableBuilder<int>(
          valueListenable: reloadNotifier,
          builder: (_, __, ___) {
            final isDark = themeMode == ThemeMode.dark;

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
                themeMode: themeMode,

                theme: ThemeData(
                  useMaterial3: true,
                  scaffoldBackgroundColor: Colors.white,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFF121212),
                ),

                initialRoute: auth.currentUser != null
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

                /// 🔑 THIS IS THE KEY FIX
                builder: (context, child) {
                  return Stack(
                    children: [
                      child!,
                      const CallMiniOverlay(), // floating always
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