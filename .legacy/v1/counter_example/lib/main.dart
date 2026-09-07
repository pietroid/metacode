import 'package:flutter/material.dart';
import 'models/counter_store.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter Example',
      home: HomePage(counterStore: CounterStore()),
    );
  }
}
