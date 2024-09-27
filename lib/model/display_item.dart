import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_app/model/file.dart';
import 'package:random_app/model/image_properties.dart';
import 'package:random_app/model/utils.dart';

import '../view/theme.dart';
import '../widget/components/image_builder.dart';
import 'audit.dart';
import 'data.dart';

class DisplayItem {
  String trueData = '';
  bool selected = false;
  bool isJson = false;
  Map<String, dynamic>? map;

  DisplayItem(this.trueData, {this.isJson = false, this.map});

  String getSearchStr() {
    if (isJson && map!.containsKey('searchable')) {
      return map?['searchable'] ?? trueData;
    }
    return getDisplayData();
  }

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

    return decodeString(tempStr);
  }

  Widget buildJSONItem(BuildContext context, int index) {
    String title = map?['title'] ?? "";
    String description = map?['description'] ?? "";
    String info = map?['info'] ?? "";
    String image = map?['image'] ?? "";

    Widget btn = useCheckboxes
        ? _buildDataListCheckbox(index)
        : _buildMoveToBottomButton(index);
    return GestureDetector(
        key: Key('OrderedList-$index'),
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  buildAdvancedDialog(this, index));
        },
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: getDisplayData()));
        },
        child: buildContainer(Row(children: [
          Expanded(
              child: Column(children: [
            Row(children: [
              if (image.isNotEmpty) ...[
                ImageBuilder(imageStr: image),
                const SizedBox(width: 8)
              ],
              if (title.isNotEmpty)
                Expanded(
                    child: Text(
                  title,
                  style: const TextStyle(fontSize: 24),
                ))
            ]),
            if (description.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                  )),
          ])),
          if (info.isNotEmpty)
            IconButton(
                onPressed: () {
                  showConfirmDialog(context, null,
                      title: 'Info', child: _buildInfo());
                },
                icon: const Icon(Icons.info_outline)),
          btn
        ])));
  }

  Widget _buildInfo() {
    String info = map?['info'] ?? "";
    List<dynamic> infoList = map?['info_list'] ?? [];
    return SingleChildScrollView(
      child: Column(
        children: [Text(info), ..._buildInfoList(infoList)],
      ),
    );
  }

  List<Widget> _buildInfoList(List<dynamic> infoList) {
    if (infoList.isEmpty) return [];
    List<Widget> temp = [];

    for (var json in infoList) {
      String image = json['image'] ?? '';

      bool? selected = json['selected'];
      ImageProperties imageProperties =
          ImageProperties(json['image_properties'] ?? {});
      String description = json['desc'] ?? json['description'] ?? '';
      temp.add(Row(children: [
        Expanded(
            child: ImageBuilder(
                imageStr: image, imageProperties: imageProperties)),
        Expanded(child: Text(description)),
        if (selected != null)
          StatefulBuilder(builder:
              (BuildContext context, void Function(void Function()) setState) {
            return Checkbox(
                value: json["selected"] ?? false,
                onChanged: (v) {
                  json["selected"] = v!;
                  setState(() {}); //
                  writeFile();
                });
          })
      ]));
    }

    return temp;
  }

  Widget _buildDataListCheckbox(int index) {
    if (hideActions || !useCheckboxes) return Container();
    DisplayItem displayItem = displayList[index];
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: checkedItems
              .contains(displayItem.trueData.replaceAll('\n', '<nl>')),
          onChanged: (checked) {
            if (checked!) {
              checkedItems.add(displayItem.trueData.replaceAll('\n', '<nl>'));
            } else {
              checkedItems
                  .remove(displayItem.trueData.replaceAll('\n', '<nl>'));
            }

            addAuditData(displayItem.getDisplayData().replaceAll('\n', '<nl>'),
                true, checked, 0);
            saveCheckData();
            setState(() {});
          });
    });
  }

  Widget _buildMoveToBottomButton(int index) {
    if (hideActions) return Container();
    return IconButton(
      icon: Icon(
        Icons.move_down,
        color: darkMode ? Colors.white70 : Colors.black87,
      ),
      tooltip: 'Move to Bottom',
      onPressed: () async {
        var d = displayList.removeAt(index);
        displayList.add(d);

        /// TODO don't await?
        addAuditData(d.getDisplayData(), false, false, index);
        mainState!(() {});
        writeFile();
      },
    );
  }

  bool isDirectory() {
    if (isWeb()) return false;
    Directory d = Directory(trueData);
    return d.existsSync();
  }

  bool isSystemFile() {
    if (isWeb()) return false;
    var display = getDisplayData();
    if (isDirectory() && display == 'data') {
      return true;
    }
    if (display.endsWith('_cb') || display.endsWith('_fav')) {
      return true;
    }
    List<String> systemFiles = [getColorsFile().path];
    return systemFiles.contains(trueData);
  }
}
