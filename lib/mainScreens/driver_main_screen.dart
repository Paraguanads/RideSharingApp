import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mainScreens/main_screen.dart';
import '../models/service_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final tripRequestsCollection = FirebaseFirestore.instance.collection('tripRequests');

  Stream<List<TripRequest>> getPendingTripRequests() {
    return tripRequestsCollection
        .where('status', isEqualTo: 'En espera')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TripRequest.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}

class DriverMainScreen extends StatefulWidget {
  @override
  _DriverMainScreenState createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  StreamSubscription<LocationData>? _locationSubscription;
  DatabaseService dbService = DatabaseService();
  late GoogleMapController mapController;
  LatLng? _initialCameraPosition;
  LatLng? _currentLocationLatLng;
  final Location _location = Location();
  final _dbService = DatabaseService();
  Set<Marker> _markers = {};
  String? _mapStyle;
  bool isLoading = true;
  TripRequest? _selectedTripRequest;
  bool isTrackingLocation = true;

  void updateFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (FirebaseAuth.instance.currentUser != null) {
      final driverRef = FirebaseDatabase.instance.ref().child('drivers').child(FirebaseAuth.instance.currentUser!.uid);
      driverRef.get().then((DataSnapshot dataSnapshot) {
        if (dataSnapshot.exists) {
          driverRef.update({'token': token});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_style.json').then((string) {
      _mapStyle = string;
    });
    _initPermissions().then((_) => setState(() {
      isLoading = false;
    }));
    _dbService.getPendingTripRequests().listen((tripRequests) {
      _updateMarkers(tripRequests);
    });
    _checkDriverStatus();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(_mapStyle);
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted && isTrackingLocation) {
        setState(() {
          _currentLocationLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentLocationLatLng!, zoom: 16),
            ),
          );
        });
      }
    });

    if (_currentLocationLatLng != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocationLatLng!, zoom: 16),
        ),
      );
    }
  }

  void _moveCameraToLatLng(LatLng latLng) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16),
      ),
    );
  }

  void _updateMarkers(List<TripRequest> tripRequests) {
    Set<Marker> newMarkers = {};
    for (var tripRequest in tripRequests) {
      if (tripRequest.id != null && tripRequest.pickupLocation != null) {
        newMarkers.add(Marker(
          markerId: MarkerId(tripRequest.id),
          position: LatLng(
            tripRequest.pickupLocation.latitude,
            tripRequest.pickupLocation.longitude,
          ),
          onTap: () {
            setState(() {
              _selectedTripRequest = tripRequest;
            });
            _showTripRequestPopup(context);
          },
        ));
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  Future<void> _showTripRequestPopup(BuildContext context) async {
    if (_selectedTripRequest == null) {
      return;
    }

    setState(() {
      isTrackingLocation = false;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Orden de servicio 🚕 ${_selectedTripRequest!.id}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Column(
                  children: [
                    Text(
                      'Datos de ubicación',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Recogida: ',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'presione para ver el mapa 📍',
                            style: TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _moveCameraToLatLng(LatLng(
                                  _selectedTripRequest!.pickupLocation.latitude,
                                  _selectedTripRequest!.pickupLocation.longitude,
                                ));
                                Navigator.of(context).pop();
                              },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Destino: ',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'presione para ver el mapa 📍',
                            style: TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _moveCameraToLatLng(LatLng(
                                  _selectedTripRequest!.destinationLocation.latitude,
                                  _selectedTripRequest!.destinationLocation.longitude,
                                ));
                                Navigator.of(context).pop();
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'Datos de pago',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tarifa propuesta: \$${_selectedTripRequest!.fare.toString()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Método de pago: ',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${_selectedTripRequest!.paymentMethod}',
                            style: TextStyle(
                              color: _selectedTripRequest!.paymentMethod == 'Pago móvil'
                                  ? Colors.deepOrange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: _buildTripRequestActions(),
        );
      },
    );

    setState(() {
      isTrackingLocation = true;
    });
  }

  List<Widget> _buildTripRequestActions() {
    if (_selectedTripRequest?.status == 'Aceptada') {
      return [
        TextButton(
          child: Text('Regresar', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ];
    } else {
      return [
        TextButton(
          child: Text('Contraoferta', style: TextStyle(color: Colors.green)),
          onPressed: () {
            if (_selectedTripRequest != null) {
              Navigator.of(context).pop();
              _showCounterOfferPopup(context);
            }
          },
        ),
        TextButton(
          child: Text('Regresar', style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ];
    }
  }

  void _showCounterOfferPopup(BuildContext context) async {
    if (await _checkIfDriverIsBusy()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No puedes hacer una contraoferta mientras estás ocupado en otro servicio.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        double counterOffer = 0;
        return AlertDialog(
          title: const Text('Hacer una contraoferta (USD)'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              counterOffer = double.tryParse(value) ?? 0;
            },
            decoration: InputDecoration(hintText: "¿Cuál es tu mejor precio?"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                User? currentUser = FirebaseAuth.instance.currentUser;

                if (_selectedTripRequest != null && currentUser != null) {
                  DocumentSnapshot tripRequestDocument = await FirebaseFirestore.instance.collection('tripRequests').doc(_selectedTripRequest!.id).get();
                  Map<String, dynamic> data = tripRequestDocument.data() as Map<String, dynamic>;

                  if (counterOffer < _selectedTripRequest!.fare) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ La contraoferta debe ser mayor o igual a la tarifa propuesta.'),
                      ),
                    );
                    return;
                  }

                  if (data['counterOfferMadeByDriver'] == currentUser.uid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Ya has hecho una contraoferta a este viaje y está pendiente de respuesta.'),
                      ),
                    );
                    Navigator.of(context).pop();
                    return;
                  }

                  await FirestoreService().createCounterOffer(
                    _selectedTripRequest!.id,
                    counterOffer,
                    currentUser.uid,
                  );

                  await FirebaseFirestore.instance
                      .collection('tripRequests')
                      .doc(_selectedTripRequest!.id)
                      .update({'counterOfferMadeByDriver': currentUser.uid});

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ¡Contraoferta enviada! Mantente alerta mientras esperas la respuesta del pasajero.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Ocurrió un error al crear la contraoferta'),
                    ),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfDriverIsBusy() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance.collection('drivers').doc(currentUser.uid).get();
      if (driverSnapshot.exists) {
        Map<String, dynamic>? driverData = driverSnapshot.data() as Map<String, dynamic>?;
        if (driverData != null && driverData.containsKey('currentServiceStatus') && driverData['currentServiceStatus'] != null) {
          String currentServiceStatus = driverData['currentServiceStatus'];

          if (currentServiceStatus == 'Aceptada') {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _initPermissions() async {
    await _initMap();
  }

  Future<void> _initMap() async {
    await requestLocationPermission();
    await _getCurrentLocation();
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationData locationData = await _location.getLocation();
    setState(() {
      _initialCameraPosition =
          LatLng(locationData.latitude!, locationData.longitude!);
      _currentLocationLatLng = _initialCameraPosition;
    });
  }

  Future<void> _checkDriverStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance.collection('drivers').doc(currentUser.uid).get();
      if (driverSnapshot.exists) {
        Map<String, dynamic> driverData = driverSnapshot.data() as Map<String, dynamic>;
        String currentServiceStatus = driverData['currentServiceStatus'];

        if (currentServiceStatus == 'Aceptada') {
          print('El conductor tiene un servicio aceptado');
        } else {
          print('El conductor no tiene un servicio aceptado');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return MainScreen(
        isDriver: true,
        body: GoogleMap(
          initialCameraPosition:
          CameraPosition(target: _initialCameraPosition!, zoom: 15),
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
        ),
      );
    }
  }
}
