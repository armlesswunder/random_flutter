import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_app/model/audit.dart';
import 'package:random_app/model/my_json_utils.dart';
import 'package:random_app/model/prefs.dart';
import 'package:random_app/model/web_client.dart';
import 'package:random_app/widget/page/settings/global_settings.dart';
import 'package:share_plus/share_plus.dart';

import 'data.dart';
import 'display_item.dart';
import 'utils.dart';

/// System Files
String colorsFileName = "colors.txt";

void clearDefaultFile() {
  defaultFile = '';
  prefs.setString('defaultFile', '');
}

void deleteFile(String path) {
  File file = File(path);
  if (file.existsSync()) {
    file.deleteSync();
  } else {
    Directory(path).deleteSync();
  }
}

Future load(String path) async {
  Directory d = Directory(path);
  if (d.existsSync()) {
    loadDirectory(directory: path);
  } else {
    await loadFile(path);
  }
}

Future loadFile(String path, {bool setDefault = true}) async {
  if (path.isEmpty) return;

  try {
    await loadFileContents(path);
  } catch (err) {
    print(err);
  }
  String temp = path;
  defaultFile = temp;
  if (isWeb() || isWebMode) {
    defaultFile = temp;
    prefs.setString("defaultFile", temp);
    loadCheckData();
    useCheckboxes = prefs.getBool(useCheckboxesKey()) ?? false;
    cbViewMode = prefs.getInt(checkboxFilterKey()) ?? 0;
    useFavs = prefs.getBool(useFavKey()) ?? false;
    saveScrollPosition = prefs.getBool(saveScrollPositionKey()) ?? false;
    hideActions = prefs.getBool(hideActionsKey()) ?? false;
    hideSearchBar = prefs.getBool(hideSearchBarKey()) ?? false;
    hideTabs = prefs.getBool(hideTabsKey()) ?? false;
    scaleFactor = prefs.getDouble(scaleKey()) ?? 1.0; //
    searchDisplayController.text = prefs.getString(cacheSearchStrKey()) ?? "";
    cachePos = prefs.getDouble(cachePosKey());
    return;
  }

  if (false && isMobile()) {
    var arr = path.split(Platform.pathSeparator);
    var dir = await getBaseDir();
    androidDir = '${dir.path}${Platform.pathSeparator}playlists';
    //defaultDir = androidDir;
    var s = arr[arr.length - 1];
    s = s.replaceAll(' ', '_');
    var st = '$androidDir${Platform.pathSeparator}$s';
    File file = File(st);
    await writeFile(path: file.path);
    temp = file.path;
    defaultFile = temp;
  }

  if (setDefault) {
    defaultFile = temp;
    Directory directory = File(temp).parent;

    //if (isAndroid() && directory.path == androidDir) {
    //  prefs.setString("defaultFile", temp);
    //} else if (isWindows() && directory.path == prefs.getString('defaultDir')) {
    //  prefs.setString("defaultFile", temp);
    //}
    prefs.setString("defaultFile", temp);
    prefs.setString("defaultDir", directory.path);

    useCheckboxes = prefs.getBool(useCheckboxesKey()) ?? false;
    cbViewMode = prefs.getInt(checkboxFilterKey()) ?? 0;
    useFavs = prefs.getBool(useFavKey()) ?? false;
    saveScrollPosition = prefs.getBool(saveScrollPositionKey()) ?? false;
    hideActions = prefs.getBool(hideActionsKey()) ?? false;
    hideSearchBar = prefs.getBool(hideSearchBarKey()) ?? false;
    hideTabs = prefs.getBool(hideTabsKey()) ?? false;
    scaleFactor = prefs.getDouble(scaleKey()) ?? 1.0;
    searchDisplayController.text = prefs.getString(cacheSearchStrKey()) ?? "";
    cachePos = prefs.getDouble(cachePosKey());
  }

  var arr = defaultFile.split(Platform.pathSeparator);
  var checkFileName = arr[arr.length - 1];
  Directory dd = Directory(dataDir);
  var checkFilePath = '${dd.path}${Platform.pathSeparator}${checkFileName}_cb';
  if (!dd.listSync().map((e) => e.path).contains(checkFileName)) {
    File(checkFilePath).createSync();
  }
  var favFilePath = '${dd.path}${Platform.pathSeparator}${checkFileName}_fav';
  if (!dd.listSync().map((e) => e.path).contains(favFilePath)) {
    File(favFilePath).createSync();
  }
  await loadCheckData();
  loadFavData();
  getAuditData();
  resetScroll = !saveScrollPosition;
}

Future<Directory> getBaseDir() async {
  if (isDesktop()) return await getApplicationDocumentsDirectory();

  var extS = await getExternalStorageDirectory();
  var androidStor = await getApplicationDocumentsDirectory();
  return extS ?? androidStor;
}

String getCheckedFilePath({String? filePath}) {
  if (isWebMode) {
    var arr = (filePath ?? defaultFile).split('/');
    var checkFileName = arr[arr.length - 1];
    return 'data/${checkFileName}_cb';
  } else if (isWeb()) {
    return 'checked_items_key_${filePath ?? defaultFile}_cb';
  }
  var arr = (filePath ?? defaultFile).split(Platform.pathSeparator);
  var checkFileName = arr[arr.length - 1];
  Directory dd = Directory(dataDir);
  return '${dd.path}${Platform.pathSeparator}${checkFileName}_cb';
}

void saveCheckData({String? filePath}) {
  var checkFilePath = getCheckedFilePath(filePath: filePath);
  String str = checkedItems.reduce((value, element) => '$value\n$element');
  if (isWebMode) {
    WebClient().put('$webPath/$checkFilePath', str);
  } else if (isWeb()) {
    prefs.setString(checkFilePath, str);
  } else {
    File(checkFilePath).writeAsStringSync(str);
  }
}

Future loadCheckData() async {
  checkedItems = [];
  var checkFilePath = getCheckedFilePath();
  List<String>? data = [];
  if (isWebMode) {
    try {
      var resp = await WebClient().get('$webPath/$checkFilePath');
      data = resp.split('\n');
    } catch (e) {
      await WebClient().put('$webPath/$checkFilePath', ''); //
      data = [];
    }
  } else if (isWeb()) {
    data = prefs.getString(checkFilePath)?.split('\n');
  } else {
    data = File(checkFilePath).readAsStringSync().split('\n');
  }
  checkedItems.addAll(data ?? []);
}

String getFavFilePath({String? filePath}) {
  var arr = (filePath ?? defaultFile).split(Platform.pathSeparator);
  var favFileName = arr[arr.length - 1];
  Directory dd = Directory(dataDir);
  return '${dd.path}${Platform.pathSeparator}${favFileName}_fav';
}

void saveFavData() {
  var favFilePath = getFavFilePath();
  String str = favItems.reduce((value, element) => '$value\n$element');
  File(favFilePath).writeAsStringSync(str);
}

void loadFavData() {
  favItems = [];
  var favFilePath = getFavFilePath();
  favItems.addAll(File(favFilePath).readAsStringSync().split('\n'));
}

Future loadFileContents(String path) async {
  displayList.clear();
  var str = '';

  if (isWebMode) {
    str = await WebClient().get('$webPath/$path');
  } else if (!isWeb()) {
    File file = File(path);
    var s = file.openRead().map(utf8.decode);
    await s.forEach((element) {
      str += element;
    });
  } else {
    //var file = await DefaultCacheManager().getSingleFile(testUrl);
    //var lines = file.readAsLinesSync();
    //lines.forEach((element) {
    //  str += '$element\n';
    //});
    str = prefs.getString(path) ?? '';
  }

  if (path.contains('.json')) {
    String jsonStr = str;
    List<dynamic> list = json.decode(jsonStr);

    for (int i = 0; i < list.length; i++) {
      var element = list[i];
      var displayItem =
          DisplayItem(element.toString(), isJson: true, map: element);
      displayList.add(displayItem);
    }
  } else {
    var fileList = str.split('\n');
    for (int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      if (element.trim().isEmpty) continue;
      var displayItem = DisplayItem(element);
      displayList.add(displayItem);
    }
  }
}

Future writeFile({String? path}) async {
  if (isWeb() || isWebMode) {
    var str = '';
    if ((path ?? defaultFile).contains('.json')) {
      var list = displayList.map((e) => e.map).toList();
      str = JsonUtils.getPrettyPrintJson(jsonEncode(list));
    } else {
      String tempStr = '';
      for (int i = 0; i < displayList.length; i++) {
        var element = displayList[i];
        tempStr += '${element.trueData}\n';
      }
      str = tempStr;
    }
    return isWebMode
        ? WebClient().put('$webPath/$defaultFile', str)
        : prefs.setString(defaultFile, str);
  } else {
    File file = File(path ?? defaultFile);
    String tempStr = '';
    if (file.path.contains('.json')) {
      var list = displayList.map((e) => e.map).toList();
      return file.writeAsString(JsonUtils.getPrettyPrintJson(jsonEncode(list)));
    } else {
      for (int i = 0; i < displayList.length; i++) {
        var element = displayList[i];
        tempStr += '${element.trueData}\n';
      }
      return file.writeAsString(tempStr);
    }
  }
}

String currentDir = '';

Future loadDirectory({String directory = ''}) {
  listList.clear();

  if (isWebMode) {
    return WebClient().loadFiles(webPath);
  }

  if (directory.isNotEmpty) {
    defaultDir = directory;
    currentDir = directory;
    if (true || isDesktop()) {
      prefs.setString('defaultDir', defaultDir);
    }
    Directory d = Directory(directory);
    var fileList = d.listSync();
    for (int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      var displayItem = DisplayItem(element.path);
      listList.add(displayItem);
    }
  } else if (defaultDir.isNotEmpty) {
    Directory d = Directory(defaultDir);
    var fileList = d.listSync();
    for (int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      var displayItem = DisplayItem(element.path);
      listList.add(displayItem);
    }
  }

  dataDir = '$defaultDir${Platform.pathSeparator}data';
  var badDir =
      '$defaultDir${Platform.pathSeparator}data${Platform.pathSeparator}data';
  if (!Directory(dataDir).existsSync()) {
    Directory(dataDir).createSync();
  }
  if (Directory(badDir).existsSync()) {
    Directory(badDir).deleteSync(recursive: true);
  }

  if (isMobile()) {
    listList.sort((a, b) {
      return a
          .getDisplayData()
          .toLowerCase()
          .compareTo(b.getDisplayData().toLowerCase());
    });
  } else {
    listList.sort((a, b) {
      return a
          .getDisplayData()
          .toLowerCase()
          .compareTo(b.getDisplayData().toLowerCase())
          .compareTo((b.isDirectory() ? 0 : 1));
    });
    listList.sort((a, b) {
      return (a.isDirectory() ? 0 : 1) - (b.isDirectory() ? 0 : 1);
    });
  }
  return Future(() => null);
}

void moveToParentDirectory(BuildContext context) async {
  cacheListsPosition = 0;
  try {
    if (currentDir.isEmpty) {
      currentDir = defaultDir;
    }
    Directory currentDirectory = Directory(currentDir);
    if (currentDirectory.existsSync() && currentDirectory.parent.existsSync()) {
      currentDir = currentDirectory.parent.path;
      load(currentDir);
      updateViews();
    }
  } catch (e) {
    print(e);
  }
}

void openFile(BuildContext context, StateSetter state) async {
  final documentsDir = await getBaseDir();
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(initialDirectory: documentsDir.path, allowMultiple: true);
  if (result != null) {
    for (int i = 0; i < result.files.length; i++) {
      String? path = result.files[i].path;
      if (path != null) {
        if (Directory(path).existsSync()) continue;
        if (path.endsWith('.zip')) {
          final bytes = File(path).readAsBytesSync();
          final archive = ZipDecoder().decodeBytes(bytes);
          for (final file in archive) {
            var filename = file.name;
            if (file.isFile) {
              if (!filename.toLowerCase().startsWith('playlists') &&
                  !filename.toLowerCase().startsWith('assets')) {
                filename = 'playlists${Platform.pathSeparator}$filename';
              }
              final data = file.content as List<int>;
              var newPath =
                  '${isAndroid() ? documentsDir.path : defaultDir}${Platform.pathSeparator}$filename';
              print(newPath);
              if (File(newPath).existsSync()) {
                File(newPath).deleteSync();
              }
              File(newPath)
                ..createSync(recursive: true)
                ..writeAsBytesSync(data);
            }
          }
        } else {
          await loadFile(path);
        }
      }
    }
    loadDirectory();
    updateViews();
    state(() {});
  } else {
    // User canceled the picker
  }
}

Future importFile(String path, String data) async {
  if (path.isEmpty || data.isEmpty) return;
  File newFile = File(path);
  newFile.writeAsStringSync(data);

  defaultFile = path;
  Directory directory = File(path).parent;

  //if (isAndroid() && directory.path == androidDir) {
  prefs.setString("defaultFile", path);
  //}

  //defaultFile = path;
  //prefs.setString("defaultFile", path);
  loadDirectory();
  findSelectedList();
  loadFile(defaultFile);
  useCheckboxes = prefs.getBool(useCheckboxesKey()) ?? false;
  cbViewMode = prefs.getInt(checkboxFilterKey()) ?? 0;
  useFavs = prefs.getBool(useFavKey()) ?? false;
  saveScrollPosition = prefs.getBool(saveScrollPositionKey()) ?? false;
  cachePos = prefs.getDouble(cachePosKey());
}

void createFile(String path, BuildContext context, StateSetter state) async {
  await loadFile('$defaultDir/${path.replaceAll(' ', '_')}');
  loadDirectory();
  updateViews();
  state(() {});
}

void chooseDefaultDir(BuildContext context) async {
  //if (isAndroid()) return;
  var documentsDir = await getBaseDir();
  String? selectedDirectory = await FilePicker.platform
      .getDirectoryPath(initialDirectory: documentsDir.path);

  if (selectedDirectory != null) {
    defaultDir = selectedDirectory;
    currentDir = selectedDirectory;
    await prefs.setString('defaultDir', defaultDir);
    loadDirectory();
  }
}

Future<void> exportFile() async {
  if (isMobile()) {
    XFile xfile = XFile(defaultFile);
    if (useNotes) {
      DisplayItem displayItem = DisplayItem(defaultFile);
      String subject = displayItem.getDisplayData();
      String data = await xfile.readAsString();
      await Share.shareXFiles([xfile], subject: subject, text: data);
    } else {
      await Share.shareXFiles([xfile], text: 'Export Data');
    }
  }
}

void reloadFile(int index) async {
  defaultFile = listList[index].trueData;
  Directory directory = File(defaultFile).parent;

  //if (isAndroid() && directory.path == androidDir) {
  await prefs.setString("defaultFile", defaultFile);
  //}
  await loadFile(listList[index].trueData);
  updateViews();
}

void exportAllFiles() async {
  if (isWeb()) {
    var encoder = ZipEncoder();
    var archive = Archive();
    for (DisplayItem item in listList) {
      String listName = item.trueData;
      String checkedName = getCheckedFilePath(filePath: listName);
      String checkedStr = prefs.getString(checkedName) ?? '';
      List<String> listData = (prefs.getString(listName) ?? '').split('\n');
      String temp = '';
      if (listName.contains('.json')) {
        temp = JsonUtils.getPrettyPrintJson(jsonEncode(listData));
      } else {
        String tempStr = '';
        for (int i = 0; i < listData.length; i++) {
          var element = listData[i];
          tempStr += '$element\n';
        }
        temp = tempStr;
      }
      var fileBytes = Uint8List.fromList(temp.codeUnits);
      ArchiveFile archiveFiles = ArchiveFile.stream(
        listName,
        fileBytes.lengthInBytes,
        InputStream(fileBytes),
      );
      archive.addFile(archiveFiles);
      if (checkedStr.isNotEmpty) {
        var checkedBytes = Uint8List.fromList(checkedStr.codeUnits);
        ArchiveFile archiveFiles = ArchiveFile.stream(
          checkedName,
          checkedBytes.lengthInBytes,
          InputStream(checkedBytes),
        );
        archive.addFile(archiveFiles);
      }
    }
    var outputStream = OutputStream(
      byteOrder: LITTLE_ENDIAN,
    );
    var bytes = encoder.encode(archive,
        level: Deflate.BEST_COMPRESSION, output: outputStream);
    //await FileSaver.instance
    //    .saveFile(name: 'out.zip', bytes: Uint8List.fromList(bytes ?? []));
    return;
  }

  String playlistDir = getDefaultDirPath();
  Directory appDir = await getBaseDir();
  String appDirPath = appDir.path;
  print(playlistDir);
  print(appDirPath);

  if (isMobile()) {
    var ps = Platform.pathSeparator;
    var encoder = ZipFileEncoder();
    String zipPath =
        '$appDirPath${Platform.pathSeparator}playlist_backup_${getFileTimestamp(DateTime.now())}.zip';
    print(zipPath);
    var exportDir = Directory(appDir.path + ps + 'export');
    if (exportDir.existsSync()) {
      exportDir.deleteSync(recursive: true);
    }
    exportDir.createSync();
    if (exportLists || exportData) {
      for (FileSystemEntity f
          in Directory(playlistDir).listSync(recursive: true)) {
        File file = File(f.path);
        if ((file.path.endsWith('_cb') || file.path.endsWith('_fav')) &&
            !exportData) {
          continue;
        }
        if (!file.path.endsWith('_cb') &&
            !file.path.endsWith('_fav') &&
            !exportLists) {
          continue;
        }
        if (file.existsSync()) {
          var newFile = File(f.path
              .replaceAll('${ps}playlists$ps', '${ps}export/playlists$ps'));
          if (!newFile.existsSync()) {
            newFile.createSync(recursive: true);
          }
          newFile.writeAsBytesSync(file.readAsBytesSync());
        }
      }
    }
    if (exportAssets) {
      for (FileSystemEntity f
          in Directory(assetDir).listSync(recursive: true)) {
        File file = File(f.path);
        if (file.existsSync()) {
          var newFile = File(
              f.path.replaceAll('${ps}assets$ps', '${ps}export/assets$ps'));
          if (!newFile.existsSync()) {
            newFile.createSync(recursive: true);
          }
          newFile.writeAsBytesSync(file.readAsBytesSync());
        }
      }
    }

    encoder.create(zipPath);
    exportDir.listSync().forEach((e) {
      if (File(e.path).existsSync()) {
        encoder.addFile(File(e.path));
      } else {
        encoder.addDirectory(Directory(e.path));
      }
    });
    encoder.close();
    XFile xfile = XFile(zipPath);
    await Share.shareXFiles([xfile], text: 'Export Backup Data');
  }
}

void createSystemFiles() {
  File colorsFile = getColorsFile();
  if (!colorsFile.existsSync()) {
    colorsFile.createSync();
  }
}

File getColorsFile() {
  String colorsPath =
      "${getDefaultDirPath()}${Platform.pathSeparator}$colorsFileName";
  return File(colorsPath);
}

String getDefaultDirPath() {
  if (isMobile()) {
    return defaultDir;
  } else {
    if (defaultDirExists()) {
      Directory d = Directory(defaultDir);
      return d.path;
    } else {
      return "";
    }
  }
}

bool defaultDirExists() {
  if (defaultDir.isNotEmpty) {
    Directory d = Directory(defaultDir);
    return d.existsSync();
  }
  return false;
}
