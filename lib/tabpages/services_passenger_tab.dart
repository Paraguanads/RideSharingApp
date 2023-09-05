import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({Key? key}) : super(key: key);

  @override
  _ServicesTabState createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  Stream<QuerySnapshot>? _requestsStream;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeRequestsStream(_auth.currentUser);
  }

  void _initializeRequestsStream(User? currentUser) async {
    if (currentUser == null) {
      _requestsStream = Stream<QuerySnapshot>.empty();
    } else {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUser.uid)
          .get();

      bool isDriver = userSnapshot.data()?['isDriver'] ?? false;

      if (isDriver) {
        Stream<QuerySnapshot> waitingRequestsStream = FirebaseFirestore.instance
            .collection('tripRequests')
            .where('status', isEqualTo: 'En espera')
            .where('hasDriver', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots();

        Stream<QuerySnapshot> negotiationRequestsStream = FirebaseFirestore
            .instance
            .collection('tripRequests')
            .where('status', isNotEqualTo: 'Aceptada')
            .orderBy('status')
            .where('driverId', isEqualTo: currentUser.uid)
            .where('hasCounterOffer', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .snapshots();

        Stream<QuerySnapshot> acceptedRequestsStream = FirebaseFirestore
            .instance
            .collection('tripRequests')
            .where('status', isEqualTo: 'Aceptada')
            .where('driverId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots();

        Stream<QuerySnapshot> completedRequestsStream = FirebaseFirestore
            .instance
            .collection('tripRequests')
            .where('status', isEqualTo: 'Culminada')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots();

        _requestsStream = StreamGroup.merge([
          waitingRequestsStream,
          negotiationRequestsStream,
          acceptedRequestsStream,
          completedRequestsStream
        ]);
      } else {
        _requestsStream = FirebaseFirestore.instance
            .collection('tripRequests')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _auth.currentUser != null
          ? _auth.currentUser!.reload().then((_) => _auth.currentUser)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de servicios'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _requestsStream ?? Stream.empty(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                print('❌ Error en la obtención de los datos: ${snapshot.error}');
                return _handleError(snapshot.error);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Cargando datos...');
                return const CircularProgressIndicator();
              }

              if (snapshot.hasData && snapshot.data != null) {
                List<TripRequest> requests = snapshot.data!.docs
                    .map((doc) =>
                    TripRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No hay servicios disponibles para ti en este momento.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    TripRequest request = requests[index];
                    return ListTile(
                      onTap: () => showTripRequestDetails(context, request),
                      title: Text(
                        'Servicio #${request.id}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${request.status}',
                        style: TextStyle(
                          color: request.status == 'Aceptada' ? Colors.green : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Column(
                        children: [
                          if (request.userId == _auth.currentUser!.uid &&
                              request.status == 'Aceptada')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _showRatingDialog(context, request.id, request.driverId);
                                },
                                child: Text('¡Llegué!'),
                                style: ButtonStyle(
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.green),
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.white),
                                ),
                              ),
                            ),
                          if (request.userId == _auth.currentUser!.uid &&
                              request.status == 'En espera')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTripRequest(request.id),
                            ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                print('No hay datos disponibles.');
                return const Center(child: Text('No hay datos disponibles.'));
              }
            },
          ),
        );
      },
    );
  }

  Widget _handleError(dynamic error) {
    print('❌ Error en la obtención de los datos: $error');
    Fluttertoast.showToast(
      msg:
      "😢 Lo sentimos, no pudimos conectar con la base de datos. Por favor, intente de nuevo. 🔄",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    return const Center(child: Text('❌ Ocurrió un error. Intenta de nuevo.'));
  }

  void deleteTripRequest(String tripRequestId) async {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      QuerySnapshot counterOffersSnapshot = await FirebaseFirestore.instance
          .collection('counterOffers')
          .where('tripRequestId', isEqualTo: tripRequestId)
          .get();

      counterOffersSnapshot.docs.forEach((documentSnapshot) {
        transaction.delete(documentSnapshot.reference);
      });

      transaction
          .delete(FirebaseFirestore.instance.collection('tripRequests').doc(tripRequestId));
    }).then((_) {
      Fluttertoast.showToast(
        msg: "🗑 Tu servicio ha sido eliminado",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {});
    }).catchError((e) {
      print('❌ Ocurrió un error al borrar la solicitud y sus contraofertas: $e');
    });
  }

  Future<double> _showCounterOfferDialog(BuildContext context) async {
    double counterOffer = 0;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hacer una contraoferta (USD)'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              counterOffer = double.tryParse(value) ?? 0;
            },
            decoration: InputDecoration(
              hintText: 'Introduce tu contraoferta...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    return counterOffer;
  }

  void showTripRequestDetails(BuildContext context, TripRequest request) async {
    try {
      List<Placemark> pickupPlacemarks = await placemarkFromCoordinates(
        request.pickupLocation.latitude,
        request.pickupLocation.longitude,
      );
      List<Placemark> destinationPlacemarks = await placemarkFromCoordinates(
        request.destinationLocation.latitude,
        request.destinationLocation.longitude,
      );

      String pickupLocationName = pickupPlacemarks.isNotEmpty
          ? pickupPlacemarks[0].name ?? ''
          : 'Desconocido';
      String destinationLocationName = destinationPlacemarks.isNotEmpty
          ? destinationPlacemarks[0].name ?? ''
          : 'Desconocido';

      String vehicleDetails = '';

      DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(request.driverId)
          .get();

      if (driverSnapshot.exists) {
        Map<String, dynamic>? driverData =
        driverSnapshot.data() as Map<String, dynamic>?;
        double currentEarnings = driverData?['earnings'] ?? 0.0;
        double fare = request.fare ?? 0.0;
        double newEarnings = currentEarnings + fare;

        await driverSnapshot.reference.update({'earnings': newEarnings});
      }

      if (request.driverId != null && request.status == 'Aceptada') {
        DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(request.driverId)
            .get();
        if (driverSnapshot.exists) {
          Map<String, dynamic>? carDetails =
          (driverSnapshot.data() as Map<String, dynamic>?)?['car_details']
          as Map<String, dynamic>?;
          if (carDetails != null) {
            String vehicleBrand = carDetails['car_brand'] as String? ?? '';
            String vehicleModel = carDetails['car_model'] as String? ?? '';
            int vehicleYear = carDetails['car_year'] as int? ?? 0;
            String vehicleColor = carDetails['car_color'] as String? ?? '';
            vehicleDetails =
            'Detalles del vehículo: $vehicleBrand $vehicleModel $vehicleYear $vehicleColor';
          }
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Detalles de la solicitud'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Lugar de recogida:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(pickupLocationName),
                  SizedBox(height: 10),
                  Text(
                    'Lugar de llegada:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(destinationLocationName),
                  SizedBox(height: 10),
                  Text(
                    'Tarifa propuesta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('\$${request.fare}'),
                  SizedBox(height: 10),
                  Text(
                    'Estado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(request.status),
                  if (request.status == 'Aceptada') SizedBox(height: 10),
                  if (request.status == 'Aceptada')
                    Text(
                      vehicleDetails,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              if (request.status != 'Aceptada')
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      );
    } catch (e) {
      print('❌ Error al obtener los datos de ubicación: $e');
      Fluttertoast.showToast(
        msg: '😢 Ocurrió un error al obtener los datos de ubicación. Por favor, inténtalo de nuevo.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _showRatingDialog(
      BuildContext context, String chatId, String? driverId) async {
    int selectedRating = 0;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⭐ Calificar al conductor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecciona una calificación de 1 a 5 estrellas:', style: TextStyle(fontWeight: FontWeight.bold)),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 30.0,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  selectedRating = rating.toInt();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (selectedRating > 0) {
                  await FirebaseFirestore.instance
                      .collection('tripRequests')
                      .doc(chatId)
                      .update({
                    'rating': selectedRating,
                    'status': 'Culminada',
                  });

                  if (driverId != null) {
                    DocumentReference driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);

                    FirebaseFirestore.instance.runTransaction((transaction) async {
                      DocumentSnapshot driverSnapshot = await transaction.get(driverRef);

                      if (driverSnapshot.exists) {
                        Map<String, dynamic> driverData =
                        driverSnapshot.data() as Map<String, dynamic>;
                        int currentTotalRating = driverData['totalRating'] ?? 0;
                        int currentNumberOfRatings = driverData['numberOfRatings'] ?? 0;

                        int newTotalRating = currentTotalRating + selectedRating;
                        int newNumberOfRatings = currentNumberOfRatings + 1;
                        double newAverageRating = newTotalRating / newNumberOfRatings;

                        transaction.update(driverRef, {
                          'totalRating': newTotalRating,
                          'numberOfRatings': newNumberOfRatings,
                          'averageRating': newAverageRating,
                        });
                      }
                    });
                  }

                  setState(() {});
                  Navigator.of(context).pop();

                  print('La solicitud con ID $chatId se ha marcado como "Culminada".');

                  Fluttertoast.showToast(
                    msg: '💛 ¡Gracias por calificar al conductor!',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              },
              child: const Text('Calificar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
