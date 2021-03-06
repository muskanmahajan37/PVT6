import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:frontend/friendsAndContacts/friendsPage.dart';
import 'package:frontend/loginFiles/MySignInPage.dart';
import 'package:frontend/routePickerMap/Route.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';
import 'package:map_controller/map_controller.dart';
import 'package:user_location/user_location.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/userFiles/user.dart' as userlib;
import 'dart:convert';
import 'mapWithRoute.dart';

List<SavedRoute> savedRoutes = [];

class _MapPreviewPageState extends State<MapPreviewPage> {
  Location location;
  LatLng userLocation;
  bool openedThroughProfile;

  LatLng startPos = userlib.usersCurrentLocation;

  static LatLng latLng = LatLng(59.338738, 18.064034);
  String kmString = "0";
  String routeTimeString = "0";
  MapController mapController;
  StatefulMapController statefulMapController;
  StreamSubscription<StatefulMapControllerStateChange> sub;
  UserLocationOptions userLocationOptions;
  List<Marker> markers = [];
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  String routesData = "";

  var points = <LatLng>[];
  void loadData() async {}

  @override
  void initState() {
    location = new Location();

    getLocation();
    getSavedRoutes();

    setState(() {
      if (widget.points != null) {
        points = widget.points;
        kmString = widget.kmString;
        routeTimeString = widget.routeTimeString;
        openedThroughProfile = widget.openedThroughprofile;
      }
    });

    mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);
    statefulMapController.onReady.then((_) => loadData());

    sub = statefulMapController.changeFeed.listen((change) => setState(() {}));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    userLocationOptions = UserLocationOptions(
      context: context,
      mapController: mapController,
      markers: markers,
      onLocationUpdate: (LatLng pos) => userLocation = pos,
      updateMapLocationOnPositionChange: false,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
          child: Stack(children: <Widget>[
        FlutterMap(
          mapController: mapController,
          options: new MapOptions(
            center: openedThroughProfile == true
                ? LatLng(points.first.latitude, points.first.longitude)
                : LatLng(startPos.latitude, startPos.longitude),
            minZoom: 4.0,
            maxZoom: 20,
            plugins: [
              // ADD THIS
              UserLocationPlugin(),
            ],
          ),
          layers: [
            new TileLayerOptions(
                urlTemplate: FlutterConfig.get('MAPBOXAPI_URL'),
                additionalOptions: {
                  'accessToken': FlutterConfig.get('MAPBOX_ID'),
                  'id': 'Streets-copy'
                }),
            MarkerLayerOptions(markers: markers),
            // ADD THIS

            new PolylineLayerOptions(polylines: [
              new Polyline(
                points: points,
                color: Colors.blue.shade500.withOpacity(0.6),
                strokeWidth: 4.0,
              )
            ]),

            userLocationOptions,
          ],
        ),

        Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MapWithRoute(
                                            pointsImport: points,
                                            latLngImport: latLng)),
                                  );
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                backgroundColor: colorBeige,
                                child: Icon(
                                  Icons.play_circle_filled,
                                  size: 36.0,
                                  color: colorDarkRed,
                                ),
                              )
                            ]))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: colorBeige,
                      onPressed: () {
                        getKm(context);
                        mapController.move(
                            LatLng(latLng.latitude, latLng.longitude), 15);
                      },
                      child: Row(
                        children: <Widget>[
                          Icon(
                            FontAwesomeIcons.dice,
                            color: colorDarkRed,
                          ),
                          Text("Random", style: style.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: colorBeige,
                      onPressed: () {
                        saveRoute(context, points);
                      },
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.save, color: colorDarkRed),
                          Text("Save", style: style.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: colorBeige,
                      onPressed: () {
                        setState(() {
                          savedRoutes.sort((a, b) => double.parse(a.distans)
                              .compareTo(double.parse(b.distans)));
                        });
                        showSavedRoutes(context);
                      },
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.folder,
                            color: colorDarkRed,
                          ),
                          Text("Saved", style: style.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 20,
                child: Container(
                  width: 220,
                  height: 45,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          color: Colors.white),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text("  Distance  ",
                                  style: style.copyWith(
                                      color: Colors.black, fontSize: 15)),
                              Text(" $kmString" + "km",
                                  style: style.copyWith(fontSize: 20)),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              Text("  Estimated Time  ",
                                  style: style.copyWith(
                                      color: Colors.black, fontSize: 15)),
                              Text("$routeTimeString",
                                  style: style.copyWith(fontSize: 20)),
                            ],
                          ),
                        ],
                      )),
                ))),
        // ...
      ])),
      appBar: AppBar(
          title: new Text('Route Preview', style: style.copyWith()),
          backgroundColor: colorDarkBeige),
    );
  }

  getLocation() async {
    var location = new Location();
    location.onLocationChanged().listen((currentLocation) {
      print(currentLocation.latitude);
      print(currentLocation.longitude);
      setState(() {
        latLng = LatLng(currentLocation.latitude, currentLocation.longitude);
      });

      print("getLocation:$latLng");
    });
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Dialoger

  saveRoute(BuildContext context, var points) {
    var savePoints = points;
    String name = "";
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorBeige,
              title: Text(
                "Save Route",
                style: style.copyWith(
                  fontSize: 28,
                ),
              ),
              content: Row(
                children: <Widget>[
                  SizedBox(width: 15),
                  SizedBox(
                    width: 200.0,
                    height: 60.0,
                    child: TextField(
                      onChanged: (val) {
                        setState(() => name = val);
                      },
                      decoration: new InputDecoration(
                        labelText: "Input a name",
                        labelStyle: style.copyWith(fontSize: 13),
                        border: new OutlineInputBorder(
                            borderSide: new BorderSide(color: Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  color: Colors.red,
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: style.copyWith(fontSize: 13)),
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  color: Colors.green,
                  onPressed: () async {
                    if (routesData != "") {
                      print(routesData);

                      final response = await http.post(
                          Uri.parse(
                              "https://group6-15.pvt.dsv.su.se/route/saveRoute"),
                          encoding: Encoding.getByName("utf-8"),
                          body: {
                            'name': name,
                            'route': routesData,
                            'uid': userlib.uid,
                            'distans': kmString.toString()
                          });
                      print(response.body);
                      if (response.statusCode == 200) {
                        getSavedRoutes();
                        showSaveAlertDialog(context);
                        //Navigator.pop(context);

                      }
                    } else {
                      showFailAlertDialog(context);
                    }
                  },
                  child: Text("Save", style: style.copyWith(fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  getKm(BuildContext context) {
    TextEditingController kmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorBeige,
              title: Text(
                "Generate a route",
                style: style.copyWith(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              content: Row(
                children: <Widget>[
                  SizedBox(
                    width: 18,
                  ),
                  SizedBox(
                    width: 200.0,
                    height: 60.0,
                    child: TextField(
                      controller: kmController,
                      decoration: new InputDecoration(
                        labelText: "How long? (In Km)",
                        labelStyle: style.copyWith(fontSize: 15),
                        border: new OutlineInputBorder(
                            borderSide: new BorderSide(color: Colors.black)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ], // Only numbers c
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.red,
                  onPressed: () => Navigator.pop(context, "-1"),
                  child: Text("Cancel",
                      style: style.copyWith(
                        fontSize: 13.0,
                      )),
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.green,
                  onPressed: () {
                    kmString = kmController.text.toString();

                    generateRoute(LatLng(latLng.latitude, latLng.longitude));
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Generate",
                    style: style.copyWith(
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  showSavedRoutes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorBeige,
              title: Text(
                "Saved routes",
                style: style.copyWith(
                  fontSize: 28,
                ),
              ),
              content: Row(
                children: <Widget>[
                  Container(
                    height: 300,
                    width: 200,
                    child: new ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: savedRoutes.length,
                        itemBuilder: (BuildContext context, int index) {
                          SavedRoute c = savedRoutes?.elementAt(index);
                          return GestureDetector(
                            child: Container(
                                height: 75,
                                margin: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: colorPrimaryRed,
                                  border: Border.all(width: 3.0),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          20.0) //         <--- border radius here
                                      ),
                                ),
                                child: Center(
                                    child: Card(
                                  elevation: 0,
                                  color: colorPrimaryRed,
                                  shadowColor: colorPrimaryRed,
                                  child: Text(
                                    '${savedRoutes[index].name}\n ${savedRoutes[index].distans} km',
                                    style: style.copyWith(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ))),
                            onTap: () async {
                              return showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: colorBeige,
                                      title: Text(
                                        '${savedRoutes[index].name}',
                                        style: style.copyWith(
                                          fontSize: 28,
                                        ),
                                      ),
                                      content: Text(
                                        '${savedRoutes[index].distans} km',
                                        style: style.copyWith(),
                                      ),
                                      actions: <Widget>[
                                        FlatButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Close',
                                              style: style.copyWith(
                                                  fontSize: 15,
                                                  color: Colors.black)),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            FontAwesomeIcons.trash,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            deleteSavedRoutes(savedRoutes[index]
                                                .id
                                                .toString());
                                            Navigator.pop(context);
                                          },
                                        ),
                                        RaisedButton(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          color: Colors.green,
                                          onPressed: () {
                                            openSavedRoutes(savedRoutes[index]
                                                .id
                                                .toString());
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          child: Text('Open',
                                              style:
                                                  style.copyWith(fontSize: 15)),
                                        ),
                                      ],
                                    );
                                  });
                            },
                          );
                        }),
                  ),
                ],
              ),
              actions: <Widget>[
                RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.red,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: style.copyWith(fontSize: 13),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  showFailAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      backgroundColor: colorPeachPink,
      title: Text(
        "Error (No Route)",
        style: TextStyle(color: Colors.red),
      ),
      content: Text("Please make sure a route is present on the map!"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showSaveAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Saved"),
      content: Text("Your Route was saved"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void openSavedRoutes(String id) async {
    final data = await http
        .get("https://group6-15.pvt.dsv.su.se/route/getRoute?id=${id}");
    print(data.body);
    if (data.statusCode == 200) {
      points.clear();

      var jsonfile = json.decode(data.body);

      var routedata = jsonfile['routes'][0];
      var route = routedata["geometry"]["coordinates"];
      kmString = (routedata["distance"] / 1000).toStringAsFixed(2);
      var estimatedTime = (routedata["duration"] / 3600)
          .toStringAsFixed(2)
          .toString(); // MAN KAN ÄNDRA GÅNGHASTIGHET FÖR ATT FÅ MER ACCURATE
      routeTimeString = estimatedTime;
      for (var i = 0; i < route.length; i++) {
        points.add(new LatLng(route[i][1], route[i][0]));
      }
      mapController.move(
          LatLng(points.first.latitude, points.first.longitude), 15);
    } else {
      // ERROR HÄR
    }
  }

  void generateRoute(LatLng pos) async {
    print("GENERATING ROUTE");
    var km = int.parse(kmString);
    points.clear();
    var Postion = latLng;
    final data = await http.get(
        "https://group6-15.pvt.dsv.su.se/route/new?posX=${pos.latitude}&posY=${pos.longitude}&distans=${km}");

    var jsonfile = json.decode(data.body);
    routesData = "";

    routesData += jsonfile["waypoints"][0]["location"].join(', ') + "/";
    routesData += jsonfile["waypoints"][1]["location"].join(', ') + "/";
    routesData += jsonfile["waypoints"][2]["location"].join(', ') + "";

    print(routesData);
    var routedata = jsonfile['routes'][0];
    var route = routedata["geometry"]["coordinates"];
    kmString = (routedata["distance"] / 1000).toStringAsFixed(2);
    var estimatedTime = (routedata["duration"] / 3600)
        .toStringAsFixed(2)
        .toString(); // MAN KAN ÄNDRA GÅNGHASTIGHET FÖR ATT FÅ MER ACCURATE
    routeTimeString = estimatedTime;
    for (var i = 0; i < route.length; i++) {
      points.add(new LatLng(route[i][1], route[i][0]));
    }
    print(points);
  }

  void deleteSavedRoutes(String id) async {
    final response = await http.post(
        Uri.parse("https://group6-15.pvt.dsv.su.se/route/delete"),
        encoding: Encoding.getByName("utf-8"),
        body: {
          'id': id,
          'uid': userlib.uid,
        });
    print(response.body);
    if (response.statusCode == 200) {
      getSavedRoutes();
      Navigator.pop(context);
    }
  }
}

void getSavedRoutes() async {
  final response = await http.get(
      "https://group6-15.pvt.dsv.su.se/route/getSavedRoutes?uid=${userlib.uid}");
  if (response.statusCode == 200) {
    savedRoutes = (json.decode(response.body) as List)
        .map((i) => SavedRoute.fromJson(i))
        .toList();
  } else {
    // ERROR HÄR
  }
}

class MapPreviewPage extends StatefulWidget {
  @override
  var km;
  var points = <LatLng>[];
  String kmString = "0";
  String routeTimeString = "0";
  bool openedThroughprofile = false;
  MapPreviewPage(
      {Key key,
      this.km,
      this.kmString,
      this.points,
      this.routeTimeString,
      this.openedThroughprofile})
      : super(key: key);
  _MapPreviewPageState createState() => _MapPreviewPageState();
}
