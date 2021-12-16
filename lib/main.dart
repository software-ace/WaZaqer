import 'package:flutter/material.dart';
import 'azqar.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      initialRoute: Azqar.id,
      routes: {
        Azqar.id: (context) => Azqar(),
      },
      title: 'WaZaqer',
      debugShowCheckedModeBanner: false,
    ),
  );
}
