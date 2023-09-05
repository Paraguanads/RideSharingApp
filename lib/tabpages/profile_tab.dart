import 'package:flutter/material.dart';
import '../global/global.dart';
import '../mainScreens/user_type_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTabPage extends StatefulWidget {
  ProfileTabPage({Key? key}) : super(key: key);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  final _passwordController = TextEditingController();
  bool isDriver = false;

  Future<String?> _showPasswordDialog() async {
    String? password;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirma tu identidad'),
          content: TextField(
            onChanged: (value) {
              password = value;
            },
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
            ),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _reauthenticateAndRetryUpdate() async {
    String email = fAuth.currentUser!.email!;

    String? password = await _showPasswordDialog();
    if (password == null) {
      return;
    }

    AuthCredential credential =
    EmailAuthProvider.credential(email: email, password: password);

    try {
      await fAuth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Contraseña incorrecta'),
        ));
        return;
      }
    }
    await _updateUserCredentials();
  }

  Future<void> _updateUserCredentials() async {
    try {
      await fAuth.currentUser!.updatePassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Datos actualizados exitosamente'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al actualizar los datos'),
      ));
    }
  }

  Future<void> _clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _checkUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDriver = prefs.getBool('isDriver');
    if (isDriver != null) {
      setState(() {
        this.isDriver = isDriver;
      });
    } else {
      String userId = fAuth.currentUser!.uid;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('drivers').doc(userId).get();
      if (snapshot.exists) {
        setState(() {
          this.isDriver = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = FirebaseAuth.instance.currentUser;
    var email =
    currentUser != null ? currentUser.email : 'No hay usuario logueado';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil 👤'),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: TextEditingController(text: email),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Tu correo electrónico (no se puede cambiar):',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña nueva:',
                labelStyle: TextStyle(color: Colors.white),
              ),
              obscureText: true,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
              ),
              onPressed: _reauthenticateAndRetryUpdate,
              child: const Text(
                'Actualizar contraseña',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                await _clearPreferences();
                await fAuth.signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (c) => UserTypeSelectionScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
