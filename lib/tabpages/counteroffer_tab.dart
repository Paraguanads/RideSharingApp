import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../mainScreens/chat_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CounterOffersTab extends StatefulWidget {
  const CounterOffersTab({Key? key}) : super(key: key);

  @override
  _CounterOffersTabState createState() => _CounterOffersTabState();
}

class _CounterOffersTabState extends State<CounterOffersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<DocumentSnapshot> fetchDriver(String driverId) {
    return _firestore.collection('drivers').doc(driverId).get();
  }

  Future<DocumentSnapshot> fetchTripRequest(String tripRequestId) {
    return _firestore.collection('tripRequests').doc(tripRequestId).get();
  }

  Future<void> acceptCounterOffer(String counterOfferId, String tripRequestId, String driverId) async {
    try {
      await _firestore.collection('counterOffers').doc(counterOfferId).update({
        'status': 'Aceptada',
      });

      await _firestore.collection('tripRequests').doc(tripRequestId).update({
        'status': 'Aceptada',
        'counterOfferMadeByDriver': null,
      });

      await _firestore.collection('drivers').doc(driverId).update({
        'isBusy': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ¡Oferta aceptada con éxito!'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 100),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hubo un error al aceptar la oferta. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 100),
        ),
      );
    }
  }

  Future<void> rejectCounterOffer(String counterOfferId) async {
    try {
      await _firestore.collection('counterOffers').doc(counterOfferId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ¡Contraoferta rechazada!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hubo un error al rechazar la contraoferta. Inténtalo de nuevo.')),
      );
    }
  }

  Future<void> deleteCounterOffer(String counterOfferId) async {
    try {
      await _firestore.collection('counterOffers').doc(counterOfferId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ¡Contraoferta borrada!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hubo un error al borrar la contraoferta. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraofertas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('counterOffers').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('❌ Algo salió mal: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                '🍃 Por ahora, no hay contraofertas.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              if (data['driverId'] != currentUserId && data['status'] == 'Aceptada') {
                return const SizedBox.shrink();
              }

              if (data['driverId'] != currentUserId) {
                return FutureBuilder<DocumentSnapshot>(
                  future: fetchTripRequest(data['tripRequestId']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    Map<String, dynamic> tripRequestData = snapshot.data!.data() as Map<String, dynamic>;

                    if (tripRequestData['userId'] != currentUserId || tripRequestData['status'] == 'Aceptada') {
                      return const SizedBox.shrink();
                    }

                    return buildCounterOffer(document, data, tripRequestData);
                  },
                );
              }

              return buildCounterOffer(document, data, null);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildCounterOffer(DocumentSnapshot document, Map<String, dynamic> data, Map<String, dynamic>? tripRequestData) {
    final bool isDriver = data['driverId'] == currentUserId;

    if (data['status'] == 'Aceptada') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: fetchDriver(data['driverId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('❌ Hubo un error al cargar la información del conductor. Inténtalo de nuevo.');
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        Map<String, dynamic> driverData = snapshot.data!.data() as Map<String, dynamic>;

        double averageRating = driverData['averageRating'] ?? 0.0;

        return ListTile(
          title: Row(
            children: [
              Text(
                driverData['userName'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              RatingBarIndicator(
                rating: averageRating,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 20.0,
                direction: Axis.horizontal,
              ),
            ],
          ),
          subtitle: Text(
            '${data['vehicleBrand']} ${data['vehicleModel']} ${data['vehicleYear']}',
          ),
          trailing: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Tarifa propuesta: ',
                  style: DefaultTextStyle.of(context).style,
                ),
                TextSpan(
                  text: '${data['fare']} USD',
                  style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '\nEstado: ${data['status'] == 'Aceptada' ? 'Aceptada' : 'Pendiente'}',
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: data['status'] == 'Aceptada' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          isThreeLine: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Contraoferta de ${driverData['userName']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Vehículo: ${data['vehicleBrand']} ${data['vehicleModel']} ${data['vehicleYear']}'),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tarifa de contraoferta: ',
                            style: DefaultTextStyle.of(context).style,
                          ),
                          TextSpan(
                            text: '${data['fare']} USD',
                            style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    if (!isDriver && tripRequestData != null && tripRequestData['userId'] == currentUserId) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              await acceptCounterOffer(
                                document.id,
                                data['tripRequestId'],
                                data['driverId'],
                              );
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: data['tripRequestId'],
                                    userId: currentUserId,
                                    recipientId: data['driverId'],
                                  ),
                                ),
                              );
                            },
                            child: Text('Aceptar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await rejectCounterOffer(document.id);
                              Navigator.of(context).pop();
                            },
                            child: Text('Rechazar'),
                          ),
                        ],
                      ),
                    ],
                    if (!isDriver && tripRequestData != null && tripRequestData['userId'] != currentUserId && data['status'] == 'Aceptada') ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: data['tripRequestId'],
                                userId: currentUserId,
                                recipientId: data['driverId'],
                              ),
                            ),
                          );
                        },
                        child: Text('Ir al chat'),
                      ),
                    ],
                    if (isDriver) ...[
                      ElevatedButton(
                        onPressed: () async {
                          await deleteCounterOffer(document.id);
                          Navigator.of(context).pop();
                        },
                        child: Text('Borrar'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
