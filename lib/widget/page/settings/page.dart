import 'package:flutter/material.dart';
import 'package:random_app/widget/page/settings/file_settings.dart';
import 'package:random_app/widget/page/settings/random.dart';

import 'audit.dart';
import 'episodes.dart';
import 'global_settings.dart';

int mode = 2;
int modeSearch = 1;
int modeAudit = 2;
int modeEncrypt = 3;
int modeEpisodes = 4;
int modeRandom = 5;
int modeFileSettings = 6;
int modeGlobalSettings = 8;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: SingleChildScrollView(
            child: Column(
          children: [
            //buildSettingsTile(
            //    Icons.search, 'Search', 'Search for items in the current list.',
            //    () {
            //  Navigator.push(context,
            //      MaterialPageRoute(builder: (context) => const SearchPage()));
            //}),
            buildSettingsTile(Icons.menu_book_outlined, 'Audit',
                'Shows most recent changes to the current list or all lists.',
                () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AuditPage()));
            }),
            buildSettingsTile(Icons.live_tv_outlined, 'Episode Generator',
                'Quickly create a list of episodes.', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EpisodesPage()));
            }),
            buildSettingsTile(Icons.shuffle_on_rounded, 'Random Tools',
                'Random in range and coin toss utility.', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const RandomPage()));
            }),
            buildSettingsTile(Icons.file_copy, 'List Settings',
                'Settings for the current list.', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FileSettingsPage()));
            }),
            buildSettingsTile(Icons.settings_applications, 'Global Settings',
                'Settings that are not list specific.', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GlobalSettingsPage()));
            }),
          ],
        )));
  }

  Widget buildSettingsTile(
      IconData iconData, String title, String desc, Function? callback) {
    return ListTile(
        leading: Icon(iconData, size: 24, color: Colors.white54),
        title: Text(title),
        subtitle: Text(
          desc,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        shape: const Border(bottom: BorderSide(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 24, color: Colors.white54),
        onTap: () {
          callback?.call();
        });
  }
}
