import 'package:flutter/material.dart';
import 'package:random_app/widget/page/settings/page.dart';

import '../../../view/theme.dart';

Widget buildSettingsHeader(BuildContext context, StateSetter state) {
  return Column(children: [
    Wrap(children: [
      IconButton(
        icon: Icon(
          Icons.search,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Search',
        onPressed: () {
          mode = modeSearch;
          state(() {});
        },
      ),
      IconButton(
        icon: Icon(
          Icons.menu_book,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Audit',
        onPressed: () {
          mode = modeAudit;
          state(() {});
        },
      ),
      IconButton(
        icon: Icon(
          Icons.live_tv_rounded,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Episode Generator',
        onPressed: () {
          mode = modeEpisodes;
          state(() {});
        },
      ),
      IconButton(
        icon: Icon(
          Icons.shuffle_rounded,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Random Utils',
        onPressed: () {
          mode = modeRandom;
          state(() {});
        },
      ),
      IconButton(
        icon: Icon(
          Icons.file_copy,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'File Settings',
        onPressed: () {
          mode = modeFileSettings;
          state(() {});
        },
      ),
      IconButton(
        icon: Icon(
          Icons.settings_applications,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Global Settings',
        onPressed: () {
          mode = modeGlobalSettings;
          state(() {});
        },
      ),
    ]),
  ]);
}
