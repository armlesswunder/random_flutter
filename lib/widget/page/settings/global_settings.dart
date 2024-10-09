import 'package:flutter/material.dart';
import 'package:random_app/model/data.dart';

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
  return Column(children: [
    Text(guideTxt),
  ]);
}
