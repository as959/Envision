import 'dart:async';
import 'package:FlutterMobilenet/services/tensorflow-service.dart';
import 'package:avatar_glow/avatar_glow.dart';
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
  String modelpath, labelpath;
  int choice = 0;
  var modelpathlist = [
    "assets/mobilenet_v1_1.0_224.tflite",
    "assets/model_unquant.tflite"
  ];
  var labelpathlist = ["assets/labels.txt", "assets/currencynew.txt"];
  @override
  void initState() {
    super.initState();
    this.modelpath = modelpathlist[choice];
    this.labelpath = labelpathlist[choice];
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
    'en-US': 'That is a ',
    'hi-IN': 'आपके सामने ',
    'mr-IN': 'तुमच्य सामोर '
  };
  var postfix = {
    'en-IN': ' in front ',
    'en-US': ' in front',
    'hi-IN': ' है',
    'mr-IN': 'aahe'
  };
  var sentence;
  Future _speak(int n) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_currentRecognition != null || n == 1) {
      print("________________$_currentRecognition");
      print("language$language");
      if (n == 0) {
        sentence = prefix[language] +
            _currentRecognition[0]['label'] +
            postfix[language];
      } else {
        print("Feedback mode");
        sentence = feedback;
      }
      print("Playing feedbacky");
      var result = await flutterTts.speak(sentence);
      if (result == 1) setState(() => ttsState = TtsState.playing);
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
            _speak(0);
          });
        } else {
          _currentRecognition = [];
        }
      });
    }
  }

  String feedback = "Starting";

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 50),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0))),
        height: 300,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.ready
              ? <Widget>[
                  // shows recognition title
                  Text(
                    "Recognition",
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: Colors.black),
                  ),

                  // shows recognitions list
                  Expanded(child: _contentWidget()),
                  Container(
                    width: 100,
                    height: 100,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          choice = 1 - choice;
                          modelpath = modelpathlist[choice];
                          labelpath = labelpathlist[choice];
                          if (choice == 1)
                            feedback = "Currency mode activated";
                          else
                            feedback = " Surrounding mode activated";
                          _speak(1);
                          _tensorflowService.loadModel(modelpath, labelpath);
                        });
                      },
                      backgroundColor: Colors.indigo[900],
                      child: Icon(
                          choice == 0
                              ? Icons.all_inbox
                              : Icons.attach_money_rounded,
                          size: 45),
                    ),
                  ),
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
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    Container(
                      width: _barWitdth,
                      child: LinearProgressIndicator(
                        backgroundColor: Color.fromRGBO(0, 0, 0, 0.4),
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
                        style: TextStyle(color: Colors.black),
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
