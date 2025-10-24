import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/widgets/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';


class SignInScreen extends StatefulWidget {
  static const String screenRoute = 'signin_screen' ;
  const SignInScreen ({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth= FirebaseAuth.instance ;
  late String email ;
  late String password ;
  bool showSpinner = false ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner ,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 اللوجو في الأعلى
              Container(
                height: 180.0,
                child: Image.asset('images/logo.jpeg'),
              ),
              const SizedBox(height: 50.0),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center ,
                onChanged: (value) {
                  email =value ;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your Email' ,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10 ,
                    horizontal: 20 ,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange , width: 1,),
                    borderRadius : BorderRadius.all(Radius.circular(10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue , width: 2,),
                    borderRadius : BorderRadius.all(Radius.circular(10) ,
                    ),
                    ),
        
                ),
              ),
        
              SizedBox(height: 8 ),
              TextField(
                 obscureText: true ,
                textAlign: TextAlign.center ,
                onChanged: (value) {
                  password = value ;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your password' ,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10 ,
                    horizontal: 20 ,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange , width: 1,),
                    borderRadius : BorderRadius.all(Radius.circular(10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue , width: 2,),
                    borderRadius : BorderRadius.all(Radius.circular(10) ,
                    ),
                    ),
        
                ), 
              ) ,
              SizedBox(height: 10,) ,
        
               MyButton(color: Colors.yellow[900]!, titel: 'Sign in ', onPressed: ()async {
                  setState(() {
                    showSpinner =true ;
                  });
                     try {
                     final user = await _auth.signInWithEmailAndPassword(email: email, password: password) ;
                     if (user!=null ){
                       Navigator.pushNamed(context, ChatScreen.screenRoute);
                       setState(() {
                         showSpinner = false ;
                       });
                     }
        
                     } catch (e) {
                      print(e) ;
                       setState(() {
                         showSpinner = false ;
                       });
                     }
        
               })
        
              
            ],
          ),
        ),
      ),
    );
  }
}
