import 'package:flutter/material.dart';
import 'package:stacked_themes/stacked_themes.dart';

import 'azqar.dart';

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
        backgroundColor: Theme.of(context).accentColor,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(children: [
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                activeColor: Theme.of(context).accentColor,
                onChanged: (value) {
                  setState(() {
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
        Container(
          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                  child: Text('Theme 1'),
                  elevation: 3.0,
                  color: Colors.cyan[600],
                  onPressed: () {
                    getThemeManager(context).selectThemeAtIndex(0);
                  }),
              RaisedButton(
                  child: Text('Theme 2'),
                  elevation: 3.0,
                  color: Colors.red[600],
                  onPressed: () {
                    getThemeManager(context).selectThemeAtIndex(1);
                  }),
              RaisedButton(
                  child: Text('Theme 3'),
                  elevation: 3.0,
                  color: Colors.purple[600],
                  onPressed: () {
                    getThemeManager(context).selectThemeAtIndex(2);
                  }),
            ],
          ),
        ),
        SizedBox(
          height: 100,
        ),
        RaisedButton(
          child: Text('حفظ الاعدادات'),
          onPressed: () {
            Navigator.popAndPushNamed(context, Azqar.id,
                arguments: _currentFontSize);
          },
        )
      ]),
    );
  }
}
