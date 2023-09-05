import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../mainScreens/driver_main_screen.dart';
import '../authentication/signup_driver_screen.dart';
import '../widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateForm() {
    if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "❌ El correo no es válido");
    } else if (passwordTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❌ La contraseña no puede estar vacía");
    } else {
      loginDriverNow();
    }
  }

  loginDriverNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(message: "Procesando. Espera un poco...");
      },
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance.collection("drivers")
            .doc(firebaseUser.uid)
            .get();

        if (driverSnapshot.exists) {
          bool isDriver = driverSnapshot.get("isDriver");

          if (!isDriver) {
            await FirebaseAuth.instance.signOut();
            Navigator.pop(context);
            Fluttertoast.showToast(msg: "❌ No puedes iniciar sesión como pasajero");
          } else {
            Fluttertoast.showToast(msg: "🥳 ¡Iniciaste sesión con éxito!");
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isDriverLoggedIn', true);
            Navigator.push(context, MaterialPageRoute(builder: (c) => DriverMainScreen()));
          }
        } else {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "❌ No puedes iniciar sesión como pasajero.");
        }
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "😥 Ha ocurrido un error. Intenta de nuevo.");
      }
    } catch (error) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "😥 Ha ocurrido un error. Intenta de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Image.asset("images/logo-no-background.png"),
              ),
              SizedBox(height: 10),
              Text(
                "Inicia sesión como conductor",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "¿Cuál es tu correo electrónico?",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  hintText: "Ingresa tu contraseña",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  validateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                ),
                child: Text(
                  "Iniciar sesión",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                child: Text(
                  "¿No tienes una cuenta? Crea una aqui 👈",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => SignUpScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
