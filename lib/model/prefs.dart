import 'dart:async';
import 'dart:io';

import 'package:random_app/model/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audit.dart';
import 'data.dart';
import 'file.dart';

late SharedPreferences prefs;

String useCheckboxesKey({String? path}) =>
    '${path ?? defaultFile}_useCheckboxes';
String checkboxFilterKey({String? path}) => '${path ?? defaultFile}_cbFilter';
String cachePosKey({String? path}) => '${path ?? defaultFile}_cachePos';
String useFavKey({String? path}) => '${path ?? defaultFile}_useFavs';
String saveScrollPositionKey({String? path}) =>
    '${path ?? defaultFile}_saveScrollPosition';
String hideActionsKey({String? path}) => '${path ?? defaultFile}_hideActions';
String cacheSearchStrKey({String? path}) =>
    '${path ?? defaultFile}_cacheSearchStr';
String listScrollCacheKey({String? path}) =>
    '${path ?? defaultFile}_listScrollCachePos';
//String checkedItemKey(String itemName) =>
//    '${defaultFile}_${itemName}_useCheckboxes';

Future getSettings() async {
  if (isAndroid()) {
    final directory = await getBaseDir();
    androidDir = '${directory.path}/playlists';
    androidTempDir = '${directory.path}/temp';
    var d = Directory(androidDir);
    var t = Directory(androidTempDir);
    if (isAndroid()) {
      directory.listSync().forEach((element) {
        var f = File(element.path);
        if (f.existsSync() &&
            f.path.endsWith('.zip') &&
            f.path.contains('playlist_backup_')) {
          f.deleteSync();
        }
      });
    }
    try {
      if (!d.existsSync()) {
        d.createSync();
      }
    } catch (e) {}
    try {
      if (t.existsSync()) {
        t.deleteSync();
      }
    } catch (e) {}
  }
  defaultDir = prefs.getString('defaultDir') ?? '';
  defaultFile = prefs.getString('defaultFile') ?? '';
  useNotes = prefs.getBool('USES_NOTES') ?? false;
  showDirectories = prefs.getBool('SHOW_DIRS') ?? false;
  showSystemFiles = prefs.getBool('SHOW_SYSTEM_FILES') ?? false;
  cacheListsPosition = prefs.getDouble(listScrollCacheKey()) ?? 0;
  getAuditData();
}
