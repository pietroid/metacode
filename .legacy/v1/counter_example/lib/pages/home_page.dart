import 'package:flutter/material.dart';
import '../models/counter_store.dart';
import '../pages/counter_button.dart';

class HomePage extends StatelessWidget {
  final CounterStore counterStore;

  const HomePage({super.key, required this.counterStore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ListenableBuilder(
              listenable: counterStore,
              builder: (context, child) => Text(
                '${counterStore.value}',
                key: const Key('counterValue'),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: CounterButton(
              key: const Key('counterButton'),
              counterStore: counterStore,
            ),
          ),
        ],
      ),
    );
  }
}
