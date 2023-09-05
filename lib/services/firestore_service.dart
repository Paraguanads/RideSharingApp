import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createTripRequest({
    required String userId,
    required GeoPoint pickupLocation,
    required GeoPoint destinationLocation,
    required double fare,
    required String paymentMethod,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('tripRequests').add({
        'userId': userId,
        'pickupLocation': pickupLocation,
        'destinationLocation': destinationLocation,
        'status': 'En espera',
        'timestamp': FieldValue.serverTimestamp(),
        'fare': fare,
        'counterOffersCount': 0,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('❌ Error al crear la solicitud de viaje: $e');
    }
  }

  Future<void> createCounterOffer(
      String tripRequestId,
      double fare,
      String driverId) async {
    try {
      DocumentSnapshot driverDocument =
      await _firestore.collection('drivers').doc(driverId).get();

      if (driverDocument.exists) {
        Map<String, dynamic> carDetails = driverDocument['car_details'];
        String vehicleBrand = carDetails['car_brand'];
        String vehicleModel = carDetails['car_model'];
        int vehicleYear = carDetails['car_year'];

        await _firestore.collection('counterOffers').add({
          'tripRequestId': tripRequestId,
          'fare': fare,
          'driverId': driverId,
          'vehicleBrand': vehicleBrand,
          'vehicleModel': vehicleModel,
          'vehicleYear': vehicleYear,
        });

        await _firestore.collection('tripRequests').doc(tripRequestId).update({
          'counterOffersCount': FieldValue.increment(1),
        });
      } else {
        throw Exception('❌ Hubo un error. Reinicia la aplicación.');
      }
    } catch (e) {
      throw Exception('❌ Error al crear la contraoferta: $e');
    }
  }
}