import 'dart:io';

class DisplayItem {
  String trueData = '';
  bool selected = false;

  DisplayItem(this.trueData);

  String getDisplayData() {
    Directory d = Directory(trueData);
    String sep = trueData.contains('/') ? '/' : '\\';
    String tempStr = trueData;
    try {
      if (d.existsSync()) {
        tempStr = trueData.split(sep).last.replaceAll('_', ' ');
        //return d.path.split('\\').last;
      } else {
        tempStr = trueData.split(sep).last.replaceAll('_', ' ');
      }
    } catch (e) {
      tempStr = trueData.replaceAll('_', ' ');
    }

    if (tempStr.contains('.')) {
      var i = tempStr.lastIndexOf('.');
      tempStr = tempStr.substring(0, i);
    }

    return tempStr;
  }

  bool isDirectory() {
    Directory d = Directory(trueData);
    return d.existsSync();
  }
}
