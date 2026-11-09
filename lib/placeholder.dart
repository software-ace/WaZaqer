import 'package:flutter/material.dart';

import 'header.dart';

/// Temporary page for tabs and routes whose epics have not landed yet.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WaZaqerHeader(title: title, showBack: true),
          Expanded(
            child: Center(
              child: Text(
                'قريبًا',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
