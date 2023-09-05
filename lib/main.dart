import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../mainScreens/user_type_selection_screen.dart';
import '../authentication/login_driver_screen.dart';
import '../authentication/login_passenger_screen.dart';
import '../mainScreens/passenger_main_screen.dart';
import '../mainScreens/driver_main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (e is FirebaseException) {
      print(e.message);
    }
    // TODO: Manejo de errores
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  Future<bool> isPassengerLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPassengerLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LlévaMe',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: FutureBuilder<bool>(
        future: isPassengerLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // TODO: Manejo de errores
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              bool isPassengerLoggedIn = snapshot.data!;
              if (isPassengerLoggedIn) {
                return PassengerMainScreen();
              } else {
                return UserTypeSelectionScreen();
              }
            }
          } else {
            return SplashScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/userTypeSelection': (context) => UserTypeSelectionScreen(),
        '/loginDriver': (context) => LoginScreen(),
        '/loginPassenger': (context) => LoginPassengerScreen(),
        '/passengerMainScreen': (context) => PassengerMainScreen(),
        '/driverMainScreen': (context) => DriverMainScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
