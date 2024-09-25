import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/data.dart';
import '../../../model/ec.dart';
import '../../../view/theme.dart';
import 'header.dart';

Widget buildEncryptScreen(BuildContext context, StateSetter state) {
  return Column(children: [
    buildSettingsHeader(context, state),
    Row(children: [
      Expanded(
          child: TextField(
        onChanged: (text) {
          if (text.isNotEmpty) {
            try {
              dC.text = decrypt(text);
            } catch (e) {
              dC.text = '';
            }
          }
        },
        style: TextStyle(color: darkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: darkMode ? Colors.white60 : Colors.black54),
          ),
          hintStyle:
              TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
          hintText: 'Enc',
          filled: true,
          fillColor: !darkMode ? Colors.white : dialogColor,
        ),
        controller: eC,
      )),
      IconButton(
        icon: Icon(
          Icons.copy,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Copy',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: eC.text));
        },
      ),
    ]),
    Row(children: [
      Expanded(
          child: TextField(
        onChanged: (text) {
          if (text.isNotEmpty) {
            eC.text = encrypt(text).base16;
          }
        },
        style: TextStyle(color: darkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: darkMode ? Colors.white60 : Colors.black54),
          ),
          hintStyle:
              TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
          hintText: 'Dec',
          filled: true,
          fillColor: !darkMode ? Colors.white : dialogColor,
        ),
        controller: dC,
      )),
      IconButton(
        icon: Icon(
          Icons.copy,
          color: darkMode ? Colors.white70 : Colors.black87,
        ),
        tooltip: 'Copy',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: dC.text));
        },
      ),
    ])
  ]);
}
