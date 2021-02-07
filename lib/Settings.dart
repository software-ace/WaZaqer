import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  static const String id = 'Settings';
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاعدادات'),
        centerTitle: true,
      ),
    );
  }
}
