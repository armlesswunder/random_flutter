import 'dart:io';

import 'package:flutter/material.dart';
import 'package:random_app/model/data.dart';
import 'package:random_app/model/file.dart';
import 'package:random_app/model/utils.dart';

class EditPage extends StatefulWidget {
  const EditPage({Key? key}) : super(key: key);

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = File(defaultFile).readAsStringSync();
  }

  @override
  void dispose() {
    save();
    Future.delayed(const Duration(milliseconds: 500), () {
      updateViews();
    });
    _controller.dispose();
    super.dispose();
  }

  void save() {
    String s = _controller.text;
    File(defaultFile).writeAsStringSync(s);
    load(defaultFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
            child: Column(
          children: [
            buildContainer(TextButton(
              onPressed: () {
                save();
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.greenAccent),
              ),
            )),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: _controller,
                  maxLines: null,
                )),
          ],
        )));
  }
}
