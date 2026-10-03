import 'package:flutter/material.dart';

void main() {
  runApp(const TripCApp());
}

class TripCApp extends StatelessWidget {
  const TripCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TripC',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('TripC'))),
    );
  }
}
