import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/Welcome_Screen.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
 final _auth =FirebaseAuth.instance ; 
  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  title: 'MessageMe app',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
  initialRoute: _auth.currentUser!= null ? ChatScreen.screenRoute :WelcomeScreen.screenRoute,
  routes: {
    WelcomeScreen.screenRoute : (context) => const WelcomeScreen(),
    SignInScreen.screenRoute: (context) => const SignInScreen(),
    RegistrationScreen.screenRoute : (context) => const RegistrationScreen(),
    ChatScreen.screenRoute : (context) => const ChatScreen(),
  },
);

  }
}
