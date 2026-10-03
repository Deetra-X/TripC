import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class TripCApp extends StatelessWidget {
  const TripCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(body: Center(child: Text('TripC'))),
    );
  }
}
