import 'package:flutter/material.dart';
import 'Settings.dart';
import 'azqar.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: Azqar.id,
    routes: {
      Azqar.id: (context) => Azqar(),
      Settings.id: (context) => Settings()
    },
    title: 'Azqar',
    debugShowCheckedModeBanner: false,
  ));
}
