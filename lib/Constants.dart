import 'package:flutter/material.dart';

const kAzqar = 'azqarBox';
//defaults

Color kMainTextColor = Colors.white;
Color kCounterColor = Colors.yellow;
const double kMainTextSize = 18.0;

List<ThemeData> getThemes() {
  return [
    ThemeData(
      accentColor: Colors.cyan[600],
      backgroundColor: Colors.cyan[50],
      buttonColor: Colors.cyan[200],
      cardColor: Colors.blueGrey,
    ),
    ThemeData(
      accentColor: Colors.red[600],
      backgroundColor: Colors.red[50],
      buttonColor: Colors.red[200],
      cardColor: Colors.blueGrey,
    ),
    ThemeData(
      accentColor: Colors.purple[600],
      backgroundColor: Colors.purple[50],
      buttonColor: Colors.purple[200],
      cardColor: Colors.blueGrey,
    ),
    ThemeData(
      accentColor: Colors.amber[600],
      backgroundColor: Colors.amber[50],
      buttonColor: Colors.amber[200],
      cardColor: Colors.blueGrey,
    ),
    ThemeData(
      accentColor: Colors.green[600],
      backgroundColor: Colors.green[50],
      buttonColor: Colors.green[200],
      cardColor: Colors.blueGrey,
    ),
  ];
}
