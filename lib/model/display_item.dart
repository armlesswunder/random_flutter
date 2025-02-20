import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_app/model/file.dart';
import 'package:random_app/model/image_properties.dart';
import 'package:random_app/model/number_ext.dart';
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

  String getCheckedItem() {
    if (defaultFile.endsWith('.json')) {
      Map<String, dynamic> jData = Map.of(map!);
      jData.remove('info_list');
      return jsonEncode(jData);
    } else {
      return trueData.replaceAll('\n', '<nl>');
    }
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

    return decodeString(tempStr).trim();
  }

  Widget buildJSONItem(BuildContext context, int index) {
    String title = map?['title'] ?? map?['name'] ?? "";
    String description = map?['description'] ?? "";
    String info = map?['info'] ?? "";
    List<dynamic>? infoList = map?['info_list'];
    List<dynamic> descList = map?['desc_list'] ?? [];
    String image = map?['image'] ?? "";
    ImageProperties imageProperties = ImageProperties(
        map?['image_properties'] ??
            {'width': imgSize.ds, 'height': imgSize.ds});

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
                ImageBuilder(
                  imageStr: image,
                  imageProperties: imageProperties,
                ),
                const SizedBox(width: 8)
              ],
              if (title.isNotEmpty)
                Expanded(
                    child: Text(
                  title,
                  style: TextStyle(fontSize: 24.0.ds),
                ))
            ]),
            if (description.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(description, style: textSizeStyle)),
            if (descList.isNotEmpty) Wrap(children: _buildDescList(descList))
          ])),
          if (info.isNotEmpty || (infoList != null && infoList.isNotEmpty))
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
        children: [
          Text(info, style: textSizeStyle),
          ..._buildInfoList(infoList)
        ],
      ),
    );
  }

  List<Widget> _buildDescList(List<dynamic> descList) {
    if (descList.isEmpty) return [];
    List<Widget> temp = [];
    for (var json in descList) {
      String image = json['image'] ?? '';

      //bool? selected = json['selected'];
      ImageProperties imageProperties = ImageProperties(
          json['image_properties'] ?? {'width': 36.ds, 'height': 36.ds});
      String name = json['name'] ?? '';
      temp.add(Column(children: [
        if (image.isNotEmpty)
          ImageBuilder(imageStr: image, imageProperties: imageProperties),
        if (name.isNotEmpty) Text(' $name ', style: textSizeStyle),
        //if (selected != null)
        //  Padding(
        //      padding: const EdgeInsets.only(left: 16),
        //      child: StatefulBuilder(builder: (BuildContext context,
        //          void Function(void Function()) setState) {
        //        return Checkbox(
        //            value: json["selected"] ?? false,
        //            onChanged: (v) {
        //              json["selected"] = v!;
        //              setState(() {}); //
        //              writeFile();
        //            });
        //      }))
      ]));
    }

    return temp;
  }

  List<Widget> _buildInfoList(List<dynamic> infoList) {
    if (infoList.isEmpty) return [];
    List<Widget> temp = [];

    var div = const Divider(thickness: .5);
    temp.add(div);
    for (var json in infoList) {
      String image = json['image'] ?? '';

      bool? selected = json['selected'];
      ImageProperties imageProperties =
          ImageProperties(json['image_properties'] ?? {});
      String description = json['desc'] ?? json['description'] ?? '';
      temp.add(Row(children: [
        if (image.isNotEmpty)
          ImageBuilder(imageStr: image, imageProperties: imageProperties),
        if (description.isNotEmpty)
          Expanded(child: Text(description, style: textSizeStyle)),
        if (selected != null)
          Padding(
              padding: const EdgeInsets.only(left: 16),
              child: StatefulBuilder(builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return Checkbox(
                    value: json["selected"] ?? false,
                    onChanged: (v) {
                      json["selected"] = v!;
                      setState(() {}); //
                      writeFile();
                    });
              }))
      ]));
      temp.add(div);
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
          value: checkedItems.contains(displayItem.getCheckedItem()),
          onChanged: (checked) {
            var data = displayItem.getCheckedItem();
            if (checked!) {
              checkedItems.add(data);
            } else {
              checkedItems.remove(data);
            }

            addAuditData(displayItem.getCheckedItem(), true, checked, 0);
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
    if (isWebMode) {
      if (trueData.contains('.')) {
        return false;
      } else {
        return true;
      }
    }
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
