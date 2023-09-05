import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import '../mainScreens/main_screen.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class PassengerMainScreen extends StatefulWidget {
  const PassengerMainScreen({Key? key}) : super(key: key);

  @override
  _PassengerMainScreenState createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  bool firstTimeMarkerDrag = true;
  bool _showMessage = true;
  late GoogleMapController mapController;
  final Location _location = Location();
  final FirestoreService _firestoreService = FirestoreService();
  LatLng? _currentLocationLatLng;
  Set<Marker> _markers = {};
  String? _selectedPaymentMethod;
  String? _mapStyle;
  TextEditingController _fareController = TextEditingController();
  OverlayEntry? overlayEntry;
  StreamSubscription<LocationData>? _locationSubscription;
  String? tripId;

  void updateFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (FirebaseAuth.instance.currentUser != null) {
      final driverRef = FirebaseDatabase.instance.ref().child('users').child(FirebaseAuth.instance.currentUser!.uid);
      driverRef.get().then((DataSnapshot dataSnapshot) {
        if (dataSnapshot.exists) {
          driverRef.update({'token': token});
        }
      });
    }
  }

  void _showConfirmationDialog(String tripId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('✅ ¡Servicio solicitado con éxito!'),
          content: Text('ID de tu servicio: $tripId'),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showMessage = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_style.json').then((string) {
      _mapStyle = string;
    });
    _initMap();
    updateFCMToken();
  }

  Future<void> endTrip() async {
    await FirebaseFirestore.instance.collection('tripRequests').doc(tripId).update({
      'status': 'Culminada'
    });
  }

  Future<void> _showTripRequestDialog() async {
    _showMessage = false;

    var userTripRequests = await FirebaseFirestore.instance
        .collection('tripRequests')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'Aceptada')
        .get();

    if (userTripRequests.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ya tienes una solicitud de viaje abierta. No puedes realizar otra solicitud.'),
        ),
      );
      setState(() {
        _showMessage = true;
      });
      return;
    }

    userTripRequests = await FirebaseFirestore.instance
        .collection('tripRequests')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'En espera')
        .get();

    if (userTripRequests.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ya tienes una solicitud de viaje en espera. No puedes realizar otra solicitud.'),
        ),
      );
      setState(() {
        _showMessage = true;
      });
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Solicitar viaje'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _fareController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tarifa (USD)',
                    hintText: '¿Cuánto quieres pagar?',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  hint: Text('Método de pago'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                  items: <String>['Efectivo', 'Pago móvil'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showMessage = true;
                });
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: Text('Solicitar'),
              onPressed: () async {
                if (_fareController.text.isEmpty || _selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Por favor, rellene todos los campos.'),
                    ),
                  );
                } else {
                  userTripRequests = await FirebaseFirestore.instance
                      .collection('tripRequests')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .where('status', isEqualTo: 'En espera')
                      .get();

                  if (userTripRequests.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Ya tienes una solicitud de viaje en proceso.'),
                      ),
                    );
                    Navigator.of(context).pop();
                    setState(() {
                      _showMessage = true;
                    });
                    return;
                  }

                  double fare = double.tryParse(_fareController.text) ?? 0.0;
                  tripId = await _firestoreService.createTripRequest(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                    pickupLocation: GeoPoint(_currentLocationLatLng!.latitude, _currentLocationLatLng!.longitude),
                    destinationLocation: GeoPoint(_markers.first.position.latitude, _markers.first.position.longitude),
                    fare: fare,
                    paymentMethod: _selectedPaymentMethod!,
                  );
                  if (tripId != null) {
                    await FirebaseFirestore.instance.collection('tripRequests').doc(tripId).update({
                      'paymentMethod': _selectedPaymentMethod,
                    });
                    Navigator.of(context).pop();
                    _showConfirmationDialog(tripId!);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateDestinationMarker(LatLng newPosition) {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('destination'),
        position: newPosition,
        draggable: true,
        onDragEnd: (newPosition) {
          _updateDestinationMarker(newPosition);
          if (firstTimeMarkerDrag) {
            firstTimeMarkerDrag = false;
          }
        },
      ));
    });
  }

  Future<void> _initMap() async {
    await requestLocationPermission();
    _currentLocationLatLng = await _getCurrentLocation();
    if (_currentLocationLatLng != null) {
      _updateDestinationMarker(_currentLocationLatLng!);
    }
  }

  Future<void> requestLocationPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      LocationData locationData = await _location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('❌ Error obteniendo localización: $e');
      return null;
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
    if (_currentLocationLatLng != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocationLatLng!, zoom: 15),
        ),
      );
    }
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if(mounted) {
        setState(() {
          _currentLocationLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  void _onMapTap(LatLng position) {
    _updateDestinationMarker(position);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocationLatLng == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.access_alarm,
                color: Colors.yellow,
                size: 60,
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Cargando tu ubicación. Esto tomará unos segundos...'),
              ),
            ],
          ),
        ),
      );
    } else {
      final tripRequestRef = FirebaseFirestore.instance.collection('tripRequests').doc(tripId);
      return MainScreen(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentLocationLatLng!, zoom: 15),
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: true,
              markers: _markers,
              onTap: _onMapTap,
            ),
            if (_showMessage)
              Positioned(
                bottom: 120,
                right: 10,
                child: FloatingActionButton(
                  onPressed: _showTripRequestDialog,
                  child: Icon(Icons.local_taxi),
                ),
              ),
            StreamBuilder<DocumentSnapshot>(
              stream: tripRequestRef.snapshots(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("❌ Algo salió mal");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Cargando");
                }

                if (snapshot.data == null || snapshot.data!.data() == null) {
                  return SizedBox.shrink();
                }

                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                if (data['status'] == 'Aceptada') {
                  return Positioned(
                    bottom: 180,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: endTrip,
                      child: Icon(Icons.check),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            Positioned(
              bottom: 1,
              left: 1,
              child: AnimatedOpacity(
                opacity: _showMessage ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMessage = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Deja presionado y arrastra el marcador \nrojo 📍 para elegir tu destino. Luego \npresiona el icono 🟡 del 🚖',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        isDriver: false,
      );
    }
  }
}
