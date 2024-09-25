import 'package:flutter/material.dart';

Widget container(Widget child) {
  return Container(
    padding: const EdgeInsets.all(8),
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: const BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.all(Radius.circular(12))),
    child: child,
  );
}
