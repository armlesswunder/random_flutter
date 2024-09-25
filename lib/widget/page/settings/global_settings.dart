import 'package:flutter/material.dart';
import 'package:random_app/model/data.dart';

import 'header.dart';

Widget buildGlobalSettingsScreen(BuildContext context, StateSetter state) {
  return Column(children: [
    buildSettingsHeader(context, state),
    Text(guideTxt),
  ]);
}
