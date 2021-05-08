import 'package:flutter/material.dart';
import 'package:stacked_themes/stacked_themes.dart';

class Settings extends StatefulWidget {
  static const String id = 'Settings';
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List themeNumbers = [
    'Cyan',
    'Red',
    'Purple',
    'Amber',
    'Green',
  ];
  List themeColors = [
    Colors.cyan[600],
    Colors.red[600],
    Colors.purple[600],
    Colors.amber[600],
    Colors.green[600],
  ];
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
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: GridView.builder(
            itemCount: themeNumbers.length,
            shrinkWrap: true,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => getThemeManager(context).selectThemeAtIndex(index),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  color: themeColors[index],
                  child: Center(
                    child: Text(themeNumbers[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
