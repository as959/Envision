import 'dart:async';
import 'package:FlutterMobilenet/widgets/home.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:FlutterMobilenet/widgets/recognition.dart';

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
        brightness: Brightness.dark,
        primaryColor: Colors.white,
      ),
      theme: ThemeData.dark(),
      home: IntroPage(firstCamera),
    ),
  );
}

String language = 'en-IN';
double volume = 0.5;
double pitch = 1.0;
double rate = 0.5;

class IntroPage extends StatefulWidget {
  var firstCamera;
  IntroPage(firstCamera) {
    this.firstCamera = firstCamera;
  }
  @override
  _IntroPageState createState() => _IntroPageState(firstCamera);
}

class _IntroPageState extends State<IntroPage> {
  SetLanguage _langset = SetLanguage();

  var firstCamera;
  _IntroPageState(firstCamera) {
    this.firstCamera = firstCamera;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF120320),
        body: Container(
          padding: EdgeInsets.all(20.0),
          alignment: Alignment.topRight,
          color: Color(0xFF120320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: 20,
                  ),
                  IconButton(
                    padding: EdgeInsets.all(20),
                    icon: Icon(
                      Icons.settings,
                      color: Colors.white,
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
              Container(
                padding: EdgeInsets.all(50),
                margin: EdgeInsets.only(top: 200),
                child: IconButton(
                  icon: Icon(
                    Icons.apps,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    _langset.langsettings(volume, pitch, rate, language);
                    // Navigate to second route when tapped.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          camera: firstCamera,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                  child: Text(
                'Tap to get started',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ))
            ],
          ),
        ));
  }
}

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var selectedlanguages = {
    'English-IND': 'en-IN',
    'English-US': 'en-US',
    'Hindi-IND': 'hi-IN',
    'Marathi-IND': 'mr-IN'
  };
  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();

    selectedlanguages.forEach((key, value) {
      items.add(DropdownMenuItem(value: value, child: Text(key)));
    });

    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF120320),
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
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context)),
                    Text(
                      'Settings',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Set Prefered Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
                _languageDropDownSection(),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, top: 30, bottom: 20),
                  child: Text(
                    'Set Speech ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
                _buildSliders()
              ])),
    );
  }

  Widget _languageDropDownSection() => Container(
      padding: EdgeInsets.only(top: 20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(),
          onChanged: changedLanguageDropDownItem,
        )
      ]));

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
