import 'package:flutter/foundation.dart';

class AppRefreshNotifier {
  static final ValueNotifier<int> signal = ValueNotifier<int>(0);

  static void notify() {
    signal.value++;
  }
}
