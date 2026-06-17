
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker_google/place_picker_google.dart';
import 'LocationModel.dart';



class GoogleMapsScreen extends StatefulWidget {
  GoogleMapsScreen();

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic> nearBySupplier = {};
  double currentLongitude = 0.0;
  double currentLatitude = 0.0;
  bool isFetchingNearBySupplier = false;
  String googleApikey = "AIzaSyD0oY8U_-sWgRRiaOC-U7_TAf0iSZGUHow";
  String mLocation = "Search Location";
  String address = '';
  late double currentLat;
  late double currentLang;
  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  Position? position;
  LatLng? markerPoint;

  @override
  void initState() {
    getCurrentLocation();

    super.initState();
  }

  Future<void> getCurrentLocation() async {
    // Request permission
    LocationPermission lpermission = await Geolocator.requestPermission();

    // Get the current position
    Position currentPosition = await GeolocatorPlatform.instance.getCurrentPosition();
    print("++++++ CURRENT LOCATION +++++++ ====> $currentPosition");

    // Update state synchronously
    setState(() {
      currentLat = currentPosition.latitude;
      currentLang = currentPosition.longitude;
      markerPoint = LatLng(currentPosition.latitude, currentPosition.longitude);
      position = currentPosition;
    });
    // Call async functions after state update
    getMarkers(currentPosition.latitude, currentPosition.longitude);
    await _goToMyLocation();
  }

  void getMarkers(double lat, double long) {
    print(lat);
    print(long);
    markerPoint = LatLng(lat, long);
    MarkerId markerId = MarkerId(lat.toString() + long.toString());
    Marker marker = Marker(
        markerId: markerId,
        position: LatLng(lat, long),
        infoWindow: InfoWindow(snippet: 'Address'));
    _markers.clear();
    setState(() {
      _markers[markerId] = marker;
      print('@@@@@@@@@@@@@@@@@@@@@@2');
      print(_markers);
    });
  }

  TextEditingController latitude = TextEditingController();

  Future<void> _goToMyLocation() async {
    final GoogleMapController controller = await _controller.future;
    print(position);
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(position!.latitude, position!.longitude),
        zoom: 19.151926040649414)));
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        title: Text(
          'Google Map',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,

          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            markers: Set<Marker>.of(_markers.values),
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
                target: position == null
                    ? LatLng(22.54, 88.36)
                    : LatLng(position!.latitude.toDouble(),
                    position!.longitude.toDouble()),
                zoom: 15),
            onMapCreated: (controller) {
              _controller.complete(controller);
              getMarkers(position!.latitude, position!.longitude);
            },
            onTap: (tapped) async {
              getMarkers(tapped.latitude, tapped.longitude);
            },
          ),
          Positioned(
            //search input bar
              top: 5,
              child: InkWell(
                  onTap: () async {
                    _openPlacePicker();

                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Card(
                      child: Container(
                          padding: EdgeInsets.only(left: 10),
                          width: MediaQuery.of(context).size.width - 80,
                          child: ListTile(
                            title: Text(
                              mLocation,
                              style: TextStyle(fontSize: 18),
                            ),
                            trailing: Icon(Icons.search),
                            dense: true,
                          )),
                    ),
                  )))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () async {
          currentLatitude = markerPoint!.latitude;
          currentLongitude = markerPoint!.longitude;

          List<Placemark> placemarks = await placemarkFromCoordinates(
            markerPoint!.latitude,
            markerPoint!.longitude,
          );

          final location = LocationModel(
            latitude: currentLatitude,
            longitude: currentLongitude,
            address:mLocation?? '',
          );

          // Return LocationModel to previous screen
          Navigator.pop(context, location);

        },
        label: Text(
          'Confirm Location',
          style: TextStyle(color: Colors.white),
        ),
        icon: Icon(
          Icons.location_on,
          color: Colors.white,
        ),
      ),
    );
  }

  void _openPlacePicker() async {

    LocationResult? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          onPlacePicked: (LocationResult result) async {

            print("Place Selected: ${result.formattedAddress}");
            print("Latitude: ${result.latLng?.latitude}, Longitude: ${result.latLng?.longitude}");

            if (result != null) {
              setState(() {
                final subLocality = result.subLocalityLevel1?.longName;
                print("SubLocalityLevel1: $subLocality");
                mLocation = subLocality!;

              });
              //form google_maps_webservice package
              final lat = result.latLng?.latitude;
              final lang = result.latLng?.longitude;
              var newlatlang = LatLng(lat!, lang!);
              final GoogleMapController controller =
              await _controller.future;

              controller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: newlatlang, zoom: 17)));
              getMarkers(lat, lang);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Location Confirmed: ${result.formattedAddress}")),
            );

            Navigator.of(context).pop(); // Close Place Picker after confirmation
          }, apiKey: googleApikey,
        ),
      ),
    );

    if (result == null) {
      print("User canceled or an error occurred");
      return;
    }
  }

}
