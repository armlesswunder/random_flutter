import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_app/view/theme.dart';

import '../../model/data.dart';
import '../../model/display_item.dart';
import '../../model/file.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({super.key});

  @override
  State<StatefulWidget> createState() => AddDialogState();
}

class AddDialogState extends State<AddDialog> {
  final FocusNode _focusNode = FocusNode();

  void _onKey(RawKeyEvent event) {
    if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.enter) {
      onAddPressed(context);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKey: _onKey,
        child: Dialog(
            backgroundColor: darkMode ? dialogColor : Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: StatefulBuilder(builder: (BuildContext context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    obscureText: false,
                    maxLines: null,
                    style: TextStyle(
                        color: darkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: darkMode ? Colors.white60 : Colors.black54),
                      ),
                      hintStyle: TextStyle(
                          color: darkMode ? Colors.white60 : Colors.black54),
                      hintText: 'Name',
                      filled: true,
                      fillColor: !darkMode ? Colors.white : dialogColor,
                    ),
                    controller: addController,
                  ),
                  TextButton(
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () => onAddPressed(context)),
                ],
              );
            })));
  }
}

Dialog buildAddDialog() {
  return Dialog(
      backgroundColor: darkMode ? dialogColor : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: StatefulBuilder(builder: (BuildContext context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              obscureText: false,
              maxLines: null,
              style: TextStyle(color: darkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: darkMode ? Colors.white60 : Colors.black54),
                ),
                hintStyle: TextStyle(
                    color: darkMode ? Colors.white60 : Colors.black54),
                hintText: 'Name',
                filled: true,
                fillColor: !darkMode ? Colors.white : dialogColor,
              ),
              controller: addController,
            ),
            TextButton(
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () => onAddPressed(context)),
          ],
        );
      }));
}

void onAddPressed(BuildContext context) {
  displayList.add(DisplayItem(addController.text));
  writeFile();
  addController.text = '';
  updateViews();
  //state(() {});
  Navigator.pop(context);
}
