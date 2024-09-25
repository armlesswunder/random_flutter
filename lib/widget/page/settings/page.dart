import 'package:flutter/material.dart';
import 'package:random_app/widget/page/settings/file_settings.dart';
import 'package:random_app/widget/page/settings/random.dart';
import 'package:random_app/widget/page/settings/search.dart';

import 'audit.dart';
import 'ec.dart';
import 'episodes.dart';
import 'global_settings.dart';
import 'header.dart';

int mode = 2;
int modeSearch = 1;
int modeAudit = 2;
int modeEncrypt = 3;
int modeEpisodes = 4;
int modeRandom = 5;
int modeFileSettings = 6;
int modeGlobalSettings = 8;

Widget buildSettingsScreen() {
  return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: getSettingsBody(context, state));
  });
}

Widget getSettingsBody(BuildContext context, StateSetter state) {
  if (mode == modeAudit) {
    return buildAuditScreen(context, state);
  }
  if (mode == modeSearch) {
    return buildSearchScreen(context, state);
  }
  if (mode == modeEncrypt) {
    return buildEncryptScreen(context, state);
  }
  if (mode == modeEpisodes) {
    return buildEpisodesScreen(context, state);
  }
  if (mode == modeRandom) {
    return buildRandomScreen(context, state);
  }
  if (mode == modeFileSettings) {
    return buildFileSettingsScreen(context, state);
  }
  if (mode == modeGlobalSettings) {
    return buildGlobalSettingsScreen(context, state);
  }
  return buildSettingsHeader(context, state);
}
