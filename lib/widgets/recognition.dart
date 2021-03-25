import 'dart:async';
import 'package:FlutterMobilenet/services/tensorflow-service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Recognition extends StatefulWidget {
  Recognition({Key key, @required this.ready}) : super(key: key);

  // indicates if the animation is finished to start streaming (for better performance)
  final bool ready;

  @override
  _RecognitionState createState() => _RecognitionState();
}

// to track the subscription state during the lifecicle of the component
enum SubscriptionState { Active, Done }

//for voice command
enum TtsState { playing, stopped }
String language;
double volume = 0.5;
double pitch = 1.0;
double rate = 0.5;

class SetLanguage {
  langsettings(vol, pi, rat, lang) {
    print("language setings successfully|$lang");
    language = lang;
    print("Lnaguage___________________$language");
    volume = vol;
    pitch = pi;
    rate = rat;
  }
}

class _RecognitionState extends State<Recognition> {
  FlutterTts flutterTts;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  // current list of recognition
  List<dynamic> _currentRecognition = [];

  // listens the changes in tensorflow recognitions
  StreamSubscription _streamSubscription;

  // tensorflow service injection
  TensorflowService _tensorflowService;

  @override
  void initState() {
    super.initState();
    initTts();
    _tensorflowService = TensorflowService();
    // starts the streaming to tensorflow results
    _startRecognitionStreaming();
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

  var prefix = {
    'en-IN': 'There is a ',
    'en-US': 'That is a',
    'hi-IN': 'आपके सामने',
    'mr-IN': 'तुमच्य सामोर'
  };
  var postfix = {
    'en-IN': 'in front ',
    'en-US': 'in front',
    'hi-IN': 'है',
    'mr-IN': 'aahe'
  };
  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_currentRecognition[0]['label'] != null) {
      if (_currentRecognition[0]['label'].isNotEmpty) {
        print("lanmguage$language");
        var sentence = prefix[language] +
            _currentRecognition[0]['label'] +
            postfix[language];
        var result = await flutterTts.speak(sentence);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  _startRecognitionStreaming() {
    if (_streamSubscription == null) {
      print("here:$_streamSubscription");
      _streamSubscription =
          _tensorflowService.recognitionStream.listen((recognition) {
        print("here:$_streamSubscription");
        if (recognition != null) {
          // rebuilds the screen with the new recognitions
          setState(() {
            _currentRecognition = recognition;
            _speak();
          });
        } else {
          _currentRecognition = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 50),
        decoration: BoxDecoration(
            color: Color(0xFF120320),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0))),
        height: 250,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.ready
              ? <Widget>[
                  // shows recognition title
                  Text(
                    "Recognitions",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
                  ),

                  // shows recognitions list
                  Expanded(child: _contentWidget()),
                  IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 60.0,
                      ),
                      onPressed: null)
                ]
              : <Widget>[],
        ),
      ),
    );
  }

  Widget _contentWidget() {
    var _width = MediaQuery.of(context).size.width;
    var _padding = 20.0;
    var _labelWitdth = 150.0;
    var _labelConfidence = 50.0;
    var _barWitdth = _width - _labelWitdth - _labelConfidence - _padding * 2.0;

    if (_currentRecognition.length > 0) {
      return Container(
        height: 150,
        child: ListView.builder(
          itemCount: _currentRecognition.length,
          itemBuilder: (context, index) {
            if (_currentRecognition.length > index) {
              return Container(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _currentRecognition[index]['label'],
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    Container(
                      width: _barWitdth,
                      child: LinearProgressIndicator(
                        backgroundColor: Color.fromRGBO(255, 255, 255, 0.4),
                        value: _currentRecognition[index]['confidence'],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      width: _labelConfidence,
                      child: Text(
                        (_currentRecognition[index]['confidence'] * 100)
                                .toStringAsFixed(0) +
                            ' %',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    } else {
      return Text('');
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
