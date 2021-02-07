import 'package:azqar/Constants.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  static const String id = 'Settings';
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  double _currentFontSize = 19;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاعدادات'),
        backgroundColor: kMainColor,
        centerTitle: true,
      ),
      backgroundColor: kSecondaryColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'حجم الخط',
                  style: TextStyle(),
                  textAlign: TextAlign.right,
                ),
                Slider(
                  value: _currentFontSize,
                  onChanged: (value) {
                    setState(() {
                      print(value);
                      _currentFontSize = value;
                    });
                  },
                  min: 15,
                  max: 25,
                  divisions: 10,
                  // label: _currentFontSize.toString(),
                ),
                Text(_currentFontSize.toStringAsFixed(0))
              ],
            ),
          ),
          Row(
            children: [],
          )
        ],
      ),
    );
  }
}
