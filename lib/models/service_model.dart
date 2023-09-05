import 'package:cloud_firestore/cloud_firestore.dart';

class TripRequest {
  final String id;
  final GeoPoint pickupLocation;
  final GeoPoint destinationLocation;
  final double fare;
  final String status;
  final String userId;
  final String? driverId;
  final String? paymentMethod;
  final bool hasCounterOffer;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleColor;

  TripRequest({
    required this.id,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.fare,
    required this.status,
    required this.userId,
    this.driverId,
    this.paymentMethod,
    required this.hasCounterOffer,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleColor,
  });

  factory TripRequest.fromMap(String id, Map<String, dynamic> map) {
    return TripRequest(
      id: id,
      pickupLocation: map['pickupLocation'],
      destinationLocation: map['destinationLocation'],
      fare: map['fare'],
      status: map['status'],
      userId: map['userId'],
      driverId: map['driverId'],
      paymentMethod: map['paymentMethod'],
      hasCounterOffer: map['hasCounterOffer'] ?? false,
      vehicleBrand: map['vehicleBrand'],
      vehicleModel: map['vehicleModel'],
      vehicleYear: map['vehicleYear'],
      vehicleColor: map['vehicleColor'],
    );
  }

  String get vehicleDetails {
    if (vehicleBrand != null &&
        vehicleModel != null &&
        vehicleYear != null &&
        vehicleColor != null) {
      return 'Detalles del vehículo: $vehicleBrand $vehicleModel $vehicleYear $vehicleColor';
    } else {
      return 'Detalles del vehículo: Desconocido';
    }
  }
}

class CounterOffer {
  String id;
  String tripRequestId;
  String driverId;
  double fare;
  String vehicleBrand;
  String vehicleModel;
  int vehicleYear;
  String vehicleColor;

  CounterOffer({
    required this.id,
    required this.tripRequestId,
    required this.driverId,
    required this.fare,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripRequestId': tripRequestId,
      'driverId': driverId,
      'fare': fare,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
    };
  }

  static CounterOffer fromMap(Map<String, dynamic> map) {
    return CounterOffer(
      id: map['id'],
      tripRequestId: map['tripRequestId'],
      driverId: map['driverId'],
      fare: map['fare'],
      vehicleBrand: map['vehicleBrand'],
      vehicleModel: map['vehicleModel'],
      vehicleYear: map['vehicleYear'],
      vehicleColor: map['vehicleColor'],
    );
  }
}