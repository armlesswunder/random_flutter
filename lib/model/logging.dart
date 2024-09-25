import 'dart:io';

import 'package:logger/logger.dart';
import 'package:random_app/model/data.dart';
import 'package:random_app/model/utils.dart';

List<String> output = [];

class MyFileOutput extends LogOutput {
  MyFileOutput();

  File? file;

  @override
  Future<void> init() {
    super.init();
    var ts = getFileTimestamp(DateTime.now());
    var fp = '$cacheDir${Platform.pathSeparator}log$ts.txt';
    file = File(fp);
    if (file!.existsSync()) file?.createSync();
    return Future(() => null);
  }

  @override
  void output(OutputEvent event) async {
    if (file != null) {
      for (var line in event.lines) {
        await file?.writeAsString("${line.toString()}\n",
            mode: FileMode.writeOnlyAppend);
      }
    } else {
      for (var line in event.lines) {
        print(line);
      }
    }
  }
}
