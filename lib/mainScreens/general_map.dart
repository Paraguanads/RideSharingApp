import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeneralMap extends StatefulWidget {
  final LatLng initialPosition;

  GeneralMap({required this.initialPosition});

  @override
  _GeneralMapState createState() => _GeneralMapState();
}

class _GeneralMapState extends State<GeneralMap> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (GoogleMapController googleMapController) {
          mapController = googleMapController;
        },
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition,
          zoom: 10.0,
        ),
      ),
    );
  }
}
