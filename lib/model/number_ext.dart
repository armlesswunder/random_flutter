import 'data.dart';

extension DoubleExtension on double {
  double get ds => this * scaleFactor;
}

extension NumExtension on num {
  num get ds => this * scaleFactor;
}

extension IntExtension on int {
  int get ds => (this * scaleFactor).round();
}
