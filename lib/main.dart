import 'dart:async';
import 'dart:convert';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:lemon_app/services/api_client.dart';
import 'package:location/location.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'services/websocket_client.dart';
import 'models/UserLocation.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(const MyApp());
}

final apiClient = ApiClient(tokenProvider: () async {
  // TODO: Get the bearer token of the current user.
  return '';
});

final webSocketClient = WebsocketClient();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Stream Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AudioRecognize(),
    );
  }
}

class AudioRecognize extends StatefulWidget {
  const AudioRecognize({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AudioRecognizeState();
}

class _AudioRecognizeState extends State<AudioRecognize> {
  final RecorderStream _recorder = RecorderStream();
  stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  double _confidence = 1.0;

  bool recognizing = false;
  bool recognizeFinished = false;
  String text = '';
  StreamSubscription<List<int>>? _audioStreamSubscription;
  BehaviorSubject<List<int>>? _audioStream;

  // get deviceId
  String? deviceId;

  UserLocation? userCurrentLocation;
  var _isGettingLocation = false;

  String backendUrl = "http://192.168.4.122:8080";

  Future<String?> _getDeviceId() async {
    String? result = await PlatformDeviceId.getDeviceId;
    debugPrint("result deviceId: " + result!);
    setState(() {
      deviceId = result;
    });

    return result;
  }

  @override
  void initState() {
    super.initState();

    _recorder.initialize();
    _speech = stt.SpeechToText();
    _getDeviceId().then((id) {
      _startWebSocket(id!);
    });

    // _speech.initialize();
  }

  _startWebSocket(String id) {
    // String rilDeviceId = deviceId!;
    debugPrint("deviceId: $id");

    webSocketClient.connect(
      "ws://192.168.4.122:8080/v1/ws?deviceId=$id",
      {
        'Authorization': 'Bearer ....',
      },
    );
  }

// mendapatkan lokasi user sekarang
  void _getCurrentUserLocaton() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });
    _locationData = await location.getLocation();

    setState(() {
      _isGettingLocation = false;
    });
    _sendUserGeolocation(_locationData.latitude!, _locationData.longitude!);
    return;
  }

  _sendUserGeolocation(double lat, double long) {
    // _getDeviceId();
    // debugPrint(" deviceId: $deviceId latitude and longitude: " +
    //     lat.toString() +
    //     "long : " +
    //     long.toString());
    userCurrentLocation =
        UserLocation(deviceId: deviceId!, latitude: lat, longitude: long);

    var payload = {
      'type': 'user_location',
      'msg_geolocation_user': userCurrentLocation!.toJson()
    };
    webSocketClient.send(jsonEncode(payload));
  }

  void streamingRecognize() async {
    _audioStream = BehaviorSubject<List<int>>();
    _audioStreamSubscription = _recorder.audioStream.listen((event) {
      _audioStream!.add(event);
    });

    await _recorder.start();

    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString((await rootBundle
        .loadString('assets/micro-scanner-402411-a937b7573580.json')));
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();

    final responseStream = speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        _audioStream!);

    var responseText = '';

    responseStream.listen((data) {
      final currentText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');

      if (data.results.first.isFinal) {
        responseText += '\n' + currentText;
        setState(() {
          text = responseText;
          recognizeFinished = true;
        });
      } else {
        setState(() {
          text = responseText + '\n' + currentText;
          recognizeFinished = true;
        });
      }
    }, onDone: () {
      if (text.contains("help")) {
        sendHelpRequest();
      }
      setState(() {
        recognizing = false;
      });
    });
  }

  void stopRecording() async {
    await _recorder.stop();
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
    setState(() {
      recognizing = false;
    });
  }

  void sendHelpRequest() async {
    await apiClient.sendSos(userCurrentLocation!);
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: 'en-US');

  void _listen() async {
    await _speech.initialize(
      onStatus: (val) => setState(() => _isListening = false),
      onError: (val) => print('onError: $val'),
    );
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (val) => setState(() {
        text = val.recognizedWords;
        // print("hasil: " + text);
        if (val.hasConfidenceRating && val.confidence > 0) {
          _confidence = val.confidence;
        }
        if (text.contains("help")) {
          sendHelpRequest();
        }
      }),
    );
  }

  void stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    // initSpeech();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio File Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (recognizeFinished)
              _RecognizeContent(
                text: text,
              ),
            StreamBuilder(
              stream: Stream.periodic(Duration(seconds: 1))
                  .asyncMap((i) => _getCurrentUserLocaton()),
              builder: (context, snapshot) => Text(''),
            ),
            ElevatedButton.icon(
              onPressed: !_isListening ? _listen : stopListening,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(CircleBorder()),
                fixedSize: MaterialStateProperty.all(Size(200, 200)),
              ),
              icon: Icon(Icons.mic, color: Colors.red),
              label: _isListening // recognizing // aslinya ini
                  ? const Text('Stop recording')
                  : const Text('Start Streaming from mic'),
              // onPressed: recognizing ? stopRecording : streamingRecognize,
              // child: _isListening // recognizing // aslinya ini
              //     ? const Text('Stop recording')
              //     : const Text('Start Streaming from mic'),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _RecognizeContent extends StatelessWidget {
  final String? text;

  const _RecognizeContent({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const Text(
            'The text recognized by the Google Speech Api:',
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            text ?? '---',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
    );
  }
}
