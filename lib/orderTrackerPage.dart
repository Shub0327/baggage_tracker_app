import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';



class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);
  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  String googleapi ='Enter Your KEy';
  static const LatLng destination = LatLng(19.049542394223693, 73.01570489250031);
  static const LatLng sourceLocation = LatLng(19.029474915484236, 73.0156972709885);

  List<LatLng> polylineCoordinates = [];
  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleapi, // Your Google Map Key
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
            (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  }



  LocationData? currentLocation;
  Future<bool> _handleLocationPermission() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseDatabase database = FirebaseDatabase.instance;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('/lat').get();
    if (snapshot.exists) {
      print(snapshot.value);
    } else {
      print('No data available.');
    }
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }
  // Future<void> _getCurrentPosition() async {
  //   final hasPermission = await _handleLocationPermission();
  //   if (!hasPermission) return;
  //   await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high)
  //       .then((Position position) {
  //     setState(() => _currentPosition = position);
  //   }).catchError((e) {
  //     debugPrint(e);
  //   });
  // }
  void getCurrentLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }


    location.getLocation().then(
          (location) {
        currentLocation = location;
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen(
          (newLoc) {
        currentLocation = newLoc;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13.5,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    getPolyPoints();
    getCurrentLocation();
    super.initState();
  }

  final Completer<GoogleMapController> _controller = Completer();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(child: Text("Track Bag",style: TextStyle(color: Colors.black,fontSize: 16),)),
      ),
      body:

           GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
              currentLocation!.latitude!, currentLocation!.longitude!),
          zoom: 13.5,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: LatLng(
                currentLocation!.latitude!, currentLocation!.longitude!),
          ),
          const Marker(
            markerId: MarkerId("source"),
            position: sourceLocation,
          ),
               const Marker(
            markerId: MarkerId("destination"),
            position: destination

          ),
        },
        onMapCreated: (mapController) {
          _controller.complete(mapController);
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId("route"),
            points: polylineCoordinates,
            color: const Color(0xFF7B61FF),
            width: 6,
          ),
        },
      ),
    );
  }
}
