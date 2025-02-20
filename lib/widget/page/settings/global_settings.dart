import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_app/model/data.dart';
import 'package:random_app/model/utils.dart';

bool exportLists = true;
bool exportAssets = false;
bool exportData = false;

class GlobalSettingsPage extends StatefulWidget {
  const GlobalSettingsPage({Key? key}) : super(key: key);

  @override
  State<GlobalSettingsPage> createState() => _GlobalSettingsPageState();
}

class _GlobalSettingsPageState extends State<GlobalSettingsPage> {
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
        appBar: AppBar(title: const Text('Global Settings')),
        body: buildGlobalSettingsScreen(context, setState));
  }
}

Widget buildGlobalSettingsScreen(BuildContext context, StateSetter state) {
  String dir = isMobile() ? androidDir : defaultDir;
  return Column(children: [
    Row(children: [
      Expanded(child: Text('Your data directory: $dir')),
      IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: dir));
          },
          icon: const Icon(Icons.copy))
    ]),
    Row(children: [
      Text('Export Lists: '),
      Checkbox(
          value: exportLists,
          onChanged: (b) {
            exportLists = b ?? exportLists;
          }),
    ]),
    Row(children: [
      Text('Export Assets: '),
      Checkbox(
          value: exportAssets,
          onChanged: (b) {
            exportAssets = b ?? exportAssets;
          }),
    ]),
    Row(children: [
      Text('Export Data: '),
      Checkbox(
          value: exportData,
          onChanged: (b) {
            exportData = b ?? exportData;
          }),
    ]),
    Text(guideTxt),
  ]);
}
