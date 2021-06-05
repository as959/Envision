import 'dart:async';
import 'package:FlutterMobilenet/widgets/home.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:FlutterMobilenet/widgets/recognition.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
      ),
      theme: ThemeData.light(),
      home: IntroPage(firstCamera),
    ),
  );
}

class IntroPage extends StatefulWidget {
  var firstCamera;
  IntroPage(firstCamera) {
    this.firstCamera = firstCamera;
  }
  @override
  _IntroPageState createState() => _IntroPageState(firstCamera);
}

class _IntroPageState extends State<IntroPage> {
  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text;
  double _confidence = 1.0;
  String feedback = "";
  String language = 'en-IN';
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  FlutterTts flutterTts;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  @override
  void initState() {
    super.initState();
    initTts();
    this._text = 'Welcome Alice!';
    _speech = stt.SpeechToText();
  }

  initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        print("playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _speak(String sentence) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    print("speaking");
    var result = await flutterTts.speak(sentence);
    if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  SetLanguage _langset = SetLanguage();
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      print("initialized!!$available");
      if (available) {
        _text = "";
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            print("recogonizing");
            _text = val.recognizedWords;
            if (_text == "settings") {
              feedback = "Settings Page";
            } else if (_text == "start") {
              feedback = "Welcome to Envison";
            } else {
              feedback = "Try again";
            }
            print("____Command executed:______|$feedback|");
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
    print("I AM SPEAKING!!");
    _speak(feedback);
    feedback = "";
  }

  var firstCamera;
  _IntroPageState(firstCamera) {
    this.firstCamera = firstCamera;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () {
            _langset.langsettings(volume, pitch, rate, language);
            // Navigate to second route when tapped.
            _stop();

            _listen();
            if (_text == "settings") {
              _text = "Welcome back";
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            } else if (_text == "start") {
              _text = "Welcome back";
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(
                    camera: firstCamera,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: EdgeInsets.only(top: 50),
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/intropageF.JPG'),
                    fit: BoxFit.fill)),
            padding: EdgeInsets.all(10.0),
            alignment: Alignment.topRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(
                        Icons.settings,
                        color: Colors.black,
                        size: 35,
                      ),
                      onPressed: () {
                        // Navigate to second route when tapped.
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Settings()),
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 50),
                  child: Text(
                    'Envision',
                    style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.black),
                  ),
                ),
                Expanded(
                    child: Container(
                  margin: EdgeInsets.only(top: 400),
                  child: Text(
                    _text,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: Colors.black),
                  ),
                ))
              ],
            ),
          ),
        ));
  }
}

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  FlutterTts flutterTts;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text;
  double _confidence = 1.0;
  String feedback = "";
  String language = 'en-IN';
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    initTts();
    this._text = 'Change settings';
    _speech = stt.SpeechToText();
  }

  initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      setState(() {
        print("playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _speak(String sentence) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    print("speaking");
    var result = await flutterTts.speak(sentence);
    if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
            padding: EdgeInsets.fromLTRB(20, 50, 30, 30),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                          padding: EdgeInsets.all(0),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context)),
                      Text(
                        'Settings',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Text(
                    _text,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: Colors.black),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  _buildSliders(),
                  SizedBox(
                    height: 100,
                  ),
                  Center(
                    child: AvatarGlow(
                      animate: _isListening,
                      glowColor: Theme.of(context).primaryColor,
                      endRadius: 100.0,
                      duration: const Duration(milliseconds: 2000),
                      repeatPauseDuration: const Duration(milliseconds: 100),
                      repeat: true,
                      child: Container(
                        height: 100,
                        width: 100,
                        child: FloatingActionButton(
                          onPressed: _listen,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ])));
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      print("initialized!!$available");
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            print("recogonizing");
            _text = val.recognizedWords;
            int index = 0;
            index = _text.indexOf("increase");
            if (index == -1) {
              index = _text.indexOf("decrease");
            }
            if (index == -1) {
              index = _text.indexOf("manual");
            }
            if (index == -1) {
              index = _text.indexOf("go");
            }
            _text = _text.substring(index);
            print("MY TEXT IS:$_text");
            if (_text == "increase volume") {
              volume = volume + 0.1;
              feedback = "Increasing volume";
            } else if (_text == "decrease volume") {
              volume = volume - 0.1;
              feedback = "Decreasing volume";
            } else if (_text == "increase pitch") {
              pitch = pitch + 0.1;
              feedback = "Increasing volume";
            } else if (_text == "decrease pitch") {
              pitch = pitch - 0.1;
              feedback = "Decreasing volume";
            } else if (_text == "increase rate") {
              rate = rate + 0.1;
              feedback = "Increasing rate";
            } else if (_text == "decrease rate") {
              rate = rate - 0.1;
              feedback = "Increasing rate";
            } else if (_text == "go back") {
              Navigator.pop(context);
              feedback = "Going to main page";
            } else if (_text == "manual") {
              feedback =
                  "Welcome to Envision, here are few commands to use application smoothly.Number one say settings to open settings page.Number two say increase or decrease followed by volume rate or pitch to adjust the speech.Number three say start to open the application and press button at center to change from currency and surroundings mode.Thankyou";
            } else {
              feedback = "Couldn't understand";
            }
            print("____Command executed:______|$feedback|");
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
    print("I AM SPEAKING!!");
    _speak(feedback);
    feedback = "";
  }

  Widget _buildSliders() {
    return Column(
      children: [_volume(), _pitch(), _rate()],
    );
  }

  Widget _volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) {
          setState(() => volume = newVolume);
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $volume");
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() => pitch = newPitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $pitch",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() => rate = newRate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $rate",
      activeColor: Colors.green,
    );
  }
}
