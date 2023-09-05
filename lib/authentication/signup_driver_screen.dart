import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/progress_dialog.dart';
import '../global/global.dart';
import '../mainScreens/car_info_screen.dart';
import 'login_driver_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController idTextEditingController = TextEditingController();

  validateForm() async {
    String id = idTextEditingController.text.trim();

    if (userNameTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❌ El nombre de usuario es obligatorio");
    } else if (nameTextEditingController.text.length < 3) {
      Fluttertoast.showToast(msg: "❌ El nombre debe tener al menos tres caracteres");
    } else if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "❌ El correo no es válido");
    } else if (!RegExp(r'^[VE]\d+$').hasMatch(id)) {
      Fluttertoast.showToast(
          msg: "❌ La cédula de identidad debe comenzar con 'V' o 'E' seguido de números");
    } else if (phoneTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❌ El número de teléfono es obligatorio");
    } else if (passwordTextEditingController.text.length < 6) {
      Fluttertoast.showToast(
          msg: "❌ La contraseña debe tener al menos 6 caracteres");
    } else {
      saveDriverInfoNow();
    }
  }

  saveDriverInfoNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return const ProgressDialog(
          message: "Procesando. Espera un poco...",
        );
      },
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        String? token = await FirebaseMessaging.instance.getToken();

        Map<String, dynamic> driverMap = {
          "driverId": firebaseUser.uid,
          "name": nameTextEditingController.text.trim(),
          "userName": userNameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "identity": idTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
          "totalRating": 0,
          "numberOfRatings": 0,
          "averageRating": 0.0,
          "userType": "driver",
          "isDriver": true,
          "isBusy": false,
          "token": token,
        };

        CollectionReference driversRef =
        FirebaseFirestore.instance.collection("drivers");
        await driversRef.doc(firebaseUser.uid).set(driverMap);

        currentFirebaseUser = firebaseUser;
        Fluttertoast.showToast(
            msg: "✅ ¡La cuenta ha sido creada! ¡Bienvenido! 🥳");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPassenger', false);
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => CarInfoScreen()));
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: "😥 La cuenta no pudo ser creada. ¿Intentamos de nuevo?");
      }
    } catch (error) {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "😥 Ha ocurrido un error. Intenta de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/logo-no-background.png"),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                "Regístrate como conductor",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: nameTextEditingController,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  hintText: "¿Cómo te llamas?",
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
                controller: userNameTextEditingController,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Nombre de usuario",
                  hintText: "Elige un nombre de usuario. Solo caracteres alfanuméricos.",
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
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
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
                controller: idTextEditingController,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Cédula de Identidad",
                  hintText: "Ingresa tu cédula de identidad (Ej. V14521452)",
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
                controller: phoneTextEditingController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  hintText: "Ingresa tu número móvil (Ej. 04125445454)",
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
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  hintText: "Coloca una contraseña para tu perfil (al menos seis caracteres)",
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
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  validateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                ),
                child: const Text(
                  "Crear cuenta",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                child: const Text(
                  "¿Ya tienes una cuenta? Inicia sesión aquí",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isPassenger', true);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
