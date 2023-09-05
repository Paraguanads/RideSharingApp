import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../global/global.dart';
import 'driver_main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarInfoScreen extends StatefulWidget {
  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  TextEditingController carModelTextEditingController =
  TextEditingController();
  TextEditingController carNumberTextEditingController =
  TextEditingController();
  TextEditingController carColorTextEditingController =
  TextEditingController();
  TextEditingController carBrandTextEditingController =
  TextEditingController();
  TextEditingController carYearTextEditingController =
  TextEditingController();

  List<String> carTypesList = ["Particular", "Delivery", "Moto"];
  String? selectedCarType;

  saveCarInfo() async {
    Map<String, dynamic> driverCarInfoMap = {
      "car_color": carColorTextEditingController.text.trim(),
      "car_number": carNumberTextEditingController.text.trim(),
      "car_model": carModelTextEditingController.text.trim(),
      "car_brand": carBrandTextEditingController.text.trim(),
      "car_year": int.parse(carYearTextEditingController.text.trim()),
      "type": selectedCarType,
    };

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference driverDocRef = firestore.collection("drivers").doc(currentFirebaseUser!.uid);

    await driverDocRef.update({
      "car_details": driverCarInfoMap,
    });

    Fluttertoast.showToast(msg: "✅ Los detalles de tu vehículo fueron guardados");
    Navigator.push(context, MaterialPageRoute(builder: (c) => DriverMainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(
                height: 24,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Image.asset("images/logo-no-background.png"),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Ingresa los detalles de tu vehículo",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: carBrandTextEditingController,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Marca del vehículo",
                  hintText: "Ingresa la marca de tu vehículo. (Ej. Chevrolet)",
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
                controller: carModelTextEditingController,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Modelo de tu vehiculo",
                  hintText: "¿Cuál es el modelo? (Ej. Optra)",
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
                controller: carNumberTextEditingController,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Número de registro",
                  hintText: "Ingresa la placa de tu vehículo (Ej. AA876TT, BAY98Y)",
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
                controller: carColorTextEditingController,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Color del vehículo",
                  hintText: "Ingresa el color de tu vehículo",
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
                controller: carYearTextEditingController,
                style: TextStyle(color: Colors.grey),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Año del vehículo",
                  hintText: "Ingresa el año de tu vehículo",
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
              SizedBox(
                height: 20,
              ),
              DropdownButton(
                iconSize: 26,
                dropdownColor: Colors.white,
                hint: Text(
                  "Elige el tipo de vehículo que conduces",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
                value: selectedCarType,
                onChanged: (newValue) {
                  setState(() {
                    selectedCarType = newValue.toString();
                  });
                },
                items: carTypesList.map((car) {
                  return DropdownMenuItem(
                    value: car,
                    child: Text(
                      car,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(
                height: 100,
              ),
              ElevatedButton(
                onPressed: () {
                  if (carColorTextEditingController.text.isNotEmpty &&
                      carNumberTextEditingController.text.isNotEmpty &&
                      carModelTextEditingController.text.isNotEmpty &&
                      carBrandTextEditingController.text.isNotEmpty &&
                      carYearTextEditingController.text.isNotEmpty &&
                      selectedCarType != null) {
                    saveCarInfo();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                ),
                child: Text(
                  "Guardar",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}