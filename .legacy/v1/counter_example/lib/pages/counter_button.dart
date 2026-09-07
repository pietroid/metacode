import 'package:flutter/material.dart';
import '../models/counter_store.dart';

class CounterButton extends StatelessWidget {
  final CounterStore counterStore;

  const CounterButton({super.key, required this.counterStore});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: counterStore.increment,
      child: const Text('Add'),
    );
  }
}
