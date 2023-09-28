import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audit.dart';
import 'data.dart';

late SharedPreferences prefs;

String useCheckboxesKey() => '${defaultFile}_useCheckboxes';
String checkedItemKey(String itemName) =>
    '${defaultFile}_${itemName}_useCheckboxes';

Future getSettings() async {
  if (Platform.isAndroid) {
    final directory = await getApplicationDocumentsDirectory();
    androidDir = '${directory.path}/playlists';
    var d = Directory(androidDir);
    var c = await d.exists();
    if (!c) {
      await d.create();
    }
  }
  defaultDir =
      Platform.isAndroid ? androidDir : prefs.getString('defaultDir') ?? '';
  defaultFile = prefs.getString('defaultFile') ?? '';
  useNotes = prefs.getBool('USES_NOTES') ?? false;
  getAuditData();
}
