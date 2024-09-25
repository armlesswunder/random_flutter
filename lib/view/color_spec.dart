import 'dart:io';

import 'package:flutter/material.dart';
import 'package:random_app/model/file.dart';

List<ColorSpec> colorSpecs = [];

class ColorSpec {
  late List<String> spec;
  late Color color;

  ColorSpec(String str) {
    String colorStr = str.substring(0, str.indexOf(';'));
    String specStr = str.substring(str.indexOf(';') + 1, str.length);
    color = Color(int.parse(colorStr, radix: 16));
    spec = specStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    Colors.deepOrangeAccent;
  }
}

void initColorSpecs() {
  File? f = getColorsFile();
  if (f != null && f.existsSync()) {
    for (String spec in f.readAsLinesSync()) {
      colorSpecs.add(ColorSpec(spec));
    }
  }
}

Color getColorSpec(String str) {
  String tempStr = str.trim().toLowerCase();
  for (ColorSpec spec in colorSpecs) {
    if (spec.spec.contains(tempStr)) return spec.color;
  }
  return Colors.white70;
}
