import 'dart:io';

import 'package:flutter/material.dart';

import '../../../model/data.dart';
import '../../../model/file.dart';
import '../../../model/prefs.dart';
import '../../../model/utils.dart';
import '../../../view/theme.dart';
import '../edit.dart';

class FileSettingsPage extends StatefulWidget {
  const FileSettingsPage({Key? key}) : super(key: key);

  @override
  State<FileSettingsPage> createState() => _FileSettingsPageState();
}

class _FileSettingsPageState extends State<FileSettingsPage> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('List Settings')),
        body: buildFileSettingsScreen(context, setState));
  }
}

Widget buildFileSettingsScreen(BuildContext context, StateSetter state) {
  return Column(children: [
    Column(children: buildBtns(context, state)),
  ]);
}

List<Widget> buildBtns(BuildContext context, StateSetter state) {
  return [
    if (!isWeb())
      Row(children: [
        SizedBox(width: 16),
        const Text('Use Favorites:'),
        Expanded(child: SizedBox()),
        Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            side: MaterialStateBorderSide.resolveWith(
              (states) => const BorderSide(width: 2.0, color: Colors.white70),
            ),
            value: useFavs,
            onChanged: (condition) {
              useFavs = condition ?? false;
              prefs.setBool(useFavKey(), useFavs);
              state(() {});
            }),
        SizedBox(width: 16),
      ]),
    Row(children: [
      SizedBox(width: 16),
      const Text('Use Checkboxes:'),
      Expanded(child: SizedBox()),
      Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: useCheckboxes,
          onChanged: (condition) {
            useCheckboxes = condition ?? false;
            prefs.setBool(useCheckboxesKey(), useCheckboxes);
            state(() {});
          }),
      SizedBox(width: 16),
    ]),
    if (!isWeb())
      Row(children: [
        SizedBox(width: 16),
        const Text('Save Scroll Position:'),
        Expanded(child: SizedBox()),
        Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            side: MaterialStateBorderSide.resolveWith(
              (states) => const BorderSide(width: 2.0, color: Colors.white70),
            ),
            value: saveScrollPosition,
            onChanged: (condition) {
              saveScrollPosition = condition ?? false;
              prefs.setBool(saveScrollPositionKey(), saveScrollPosition);
              state(() {});
            }),
        SizedBox(width: 16),
      ]),
    if (isAndroid())
      Row(children: [
        SizedBox(width: 16),
        const Text('Note Mode:'),
        Expanded(child: SizedBox()),
        Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            side: MaterialStateBorderSide.resolveWith(
              (states) => const BorderSide(width: 2.0, color: Colors.white70),
            ),
            value: useNotes,
            onChanged: (condition) {
              useNotes = condition ?? false;
              prefs.setBool('USES_NOTES', useNotes);
              state(() {});
            }),
        SizedBox(width: 16),
      ]),
    Row(children: [
      SizedBox(width: 16),
      const Text('Hide Actions:'),
      Expanded(child: SizedBox()),
      Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: hideActions,
          onChanged: (condition) {
            hideActions = condition ?? false;
            prefs.setBool(hideActionsKey(), hideActions);
            state(() {});
          }),
      const SizedBox(width: 16),
    ]),
    Row(children: [
      const SizedBox(width: 16),
      Text('UI Scale :: ${scaleFactor.toStringAsPrecision(1)} ::'),
      const SizedBox(width: 16),
      Slider(
          label: scaleFactor.toStringAsPrecision(1),
          min: .5,
          max: 4.0,
          value: scaleFactor,
          onChanged: (value) {
            scaleFactor = value;
            prefs.setDouble(scaleKey(), scaleFactor);
            state(() {});
          }),
      const SizedBox(width: 16),
    ]),
    if (!isWeb())
      Row(children: [
        const SizedBox(width: 16),
        const Text('Text Editor'),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.edit,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Edit',
          onPressed: () {
            editPressed(context);
          },
        )
      ]),
    !useCheckboxes || isWeb()
        ? Container(width: 1)
        : TextButton(
            onPressed: () {
              showConfirmDialog(context, () {
                var cbFilePath = getCheckedFilePath();
                var str = File(defaultFile).readAsStringSync();
                File(cbFilePath).writeAsStringSync(str);
                if (mainState != null) {
                  mainState!(() {});
                }
                state(() {});
                loadCheckData();
                loadFavData();
                resetScroll = true;
              });
            },
            child: Text('Select All')),
    !useCheckboxes || isWeb()
        ? Container(width: 1)
        : TextButton(
            onPressed: () {
              showConfirmDialog(context, () {
                var cbFilePath = getCheckedFilePath();
                File(cbFilePath).writeAsStringSync('');
                if (mainState != null) {
                  mainState!(() {});
                }
                state(() {});
                loadCheckData();
                loadFavData();
                resetScroll = true;
              });
            },
            child: Text('Unselect All'))
  ];
}

void editPressed(BuildContext context) {
  Navigator.push(context, MaterialPageRoute<void>(
    builder: (BuildContext context) {
      return const EditPage();
    },
  ));
}
