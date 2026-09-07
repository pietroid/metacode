import 'package:flutter/foundation.dart';

class CounterStore extends ChangeNotifier {
  int _value;

  CounterStore({int value = 0}) : _value = value;

  int get value => _value;
  set value(int value) {
    _value = value;
    notifyListeners();
  }

  void increment() {
    _value++;
    notifyListeners();
  }
}
