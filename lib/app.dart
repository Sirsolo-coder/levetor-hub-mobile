import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:provider/provider.dart';

// ignore: unused_import
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';
class LevetorHubApp extends StatelessWidget {
  const LevetorHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Levetor Hub',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: const HomeScreen(),
    );
  }
}