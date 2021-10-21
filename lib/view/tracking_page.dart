import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bike_tracking/controller/entity_controller.dart';
import 'package:bike_tracking/controller/global.dart';
import 'package:bike_tracking/model/trip_list.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:intl/intl.dart';

class TrackingPage extends StatefulWidget {
  TrackingPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  List<double>? _gpsValues;
  double _speedValues = 0.0;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  late Timer _timer;
  late Trip thisTrip;

  checkGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    var accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    var gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();
    var userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    var magnetometer =
        _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    var gps = _gpsValues?.map((double v) => v.toStringAsFixed(7)).toList();
    var speed = _speedValues.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking...'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text("Data will be recorded every " +
              Global.currentIntervalValue.round().toString() +
              "s"),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[Text('Start time: ' + startTime)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Accelerometer: $accelerometer'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('UserAccelerometer: $userAccelerometer'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Gyroscope: $gyroscope'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Magnetometer: $magnetometer'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Location: $gps'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Speed: $speed m/s'),
                    ],
                  ),
                ),
                ElevatedButton(
                  child: const Text(
                    "End Tracking",
                  ),
                  onPressed: () {
                    _timer.cancel();
                    thisTrip.endTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now());
                    Global.tripList.trip.add(thisTrip);
                    Global.dispose();
                    dispose();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    thisTrip = new Trip(startTime, startTime, Global.vehicleType, <Data>[]);
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      Geolocator.getPositionStream().listen(
        (Position position) {
          setState(() {
            _gpsValues = <double>[
              position.latitude,
              position.longitude,
              position.altitude
            ];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      Geolocator.getPositionStream().listen(
        (Position position) {
          setState(() {
            _speedValues = position.speed;
          });
        },
      ),
    );
    //
    //
    // The timer is here
    _timer = Timer.periodic(
        Duration(seconds: Global.currentIntervalValue.round()), (timer) {
      Data data = new Data(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          _accelerometerValues!,
          _gyroscopeValues!,
          _userAccelerometerValues!,
          _magnetometerValues!,
          _gpsValues!,
          _speedValues);
      thisTrip.data.add(data);
      //print(_accelerometerValues);
    });
  }
}
