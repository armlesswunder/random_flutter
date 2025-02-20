import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class BlackScreen extends StatefulWidget {
  const BlackScreen({Key? key}) : super(key: key);

  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen> {
  bool toggleHelp = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: toggleHelp ? AppBar() : null,
        body: InkWell(
            splashFactory: NoSplash.splashFactory,
            onTap: () async {
              if (toggleHelp) {
                toggleHelp = false;
                setState(() {});
                await Future.delayed(const Duration(seconds: 1));
                await modeFullScreen();
              } else {
                toggleHelp = true;
                setState(() {});
                await Future.delayed(const Duration(seconds: 1));
                await modeNormalScreen();
              }
            },
            onSecondaryTap: () => setState(() {
                  Navigator.of(context).pop();
                }), //
            child: Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: Center(child: Text(getMsg())))));
  }

  String getMsg() {
    if (toggleHelp) {
      return '\n\nClick anywhere to toggle fullscreen\n\n';
    } else {
      return '';
    }
  }
}

Future<void> modeFullScreen() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (await windowManager.isFullScreen()) return;

  await windowManager.setFullScreen(true);
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  return Future.delayed(const Duration(seconds: 1));
}

Future<void> modeNormalScreen() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!await windowManager.isFullScreen()) return;

  await windowManager.setFullScreen(false);
  await windowManager.setTitleBarStyle(TitleBarStyle.normal);
  return Future.delayed(const Duration(seconds: 1));
}
