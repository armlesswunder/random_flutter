import 'dart:io';

import 'package:flutter/material.dart';

import '../../../model/data.dart';
import '../../../model/file.dart';
import '../../../model/prefs.dart';
import '../../../model/utils.dart';
import '../../../view/theme.dart';
import '../edit.dart';
import 'header.dart';

Widget buildFileSettingsScreen(BuildContext context, StateSetter state) {
  return Column(children: [
    buildSettingsHeader(context, state),
    Wrap(children: buildBtns(context, state)),
  ]);
}

List<Widget> buildBtns(BuildContext context, StateSetter state) {
  return [
    Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Use Favorites?'),
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
    ]),
    Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Use Checkboxes?'),
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
    ]),
    Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Save Scroll Position?'),
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
    ]),
    Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Note Mode?'),
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
    ]),
    Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Hide Actions?:'),
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
    ]),
    IconButton(
      icon: Icon(
        Icons.edit,
        color: darkMode ? Colors.white70 : Colors.black87,
      ),
      tooltip: 'Edit',
      onPressed: () {
        editPressed(context);
      },
    ),
    !useCheckboxes
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
    !useCheckboxes
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
