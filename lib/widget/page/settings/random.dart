import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../view/theme.dart';

Random random = Random(DateTime.now().millisecondsSinceEpoch);

int next(int min, int max) => min + random.nextInt(max - min);
dynamic randomInList(List<dynamic> list) => list[random.nextInt(list.length)];

class RandomPage extends StatefulWidget {
  const RandomPage({Key? key}) : super(key: key);

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
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
        appBar: AppBar(title: const Text('Random Tools')),
        body: buildRandomScreen(context, setState));
  }

  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();

  String value = 'Undefined';

  Widget buildRandomScreen(BuildContext context, StateSetter state) {
    return Column(children: [
      Row(children: [
        Expanded(child: buildStartRange()),
        const Text(' - '),
        Expanded(child: buildEndRange()),
      ]),
      Row(children: [
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: TextButton(
                onPressed: () {
                  try {
                    int start = int.parse(startController.text);
                    int end = int.parse(endController.text);
                    value = "${next(start, end + 1)}";
                    playRandomSFX();
                  } catch (e) {
                    value = 'Undefined';
                    playBadSFX();
                  }
                  state(() {});
                },
                child: const Text(
                  'Generate',
                  style: TextStyle(color: Colors.white70),
                ))),
        Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Text(value)),
      ]),
      GestureDetector(
        child: Container(
          width: coinSize,
          height: coinSize,
          decoration: BoxDecoration(
            color: coinColor.withAlpha(50),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(
            coinValue,
            style: TextStyle(
                fontSize: coinSize / 2, color: coinColor.withAlpha(200)),
          )),
        ),
        onTap: () {
          int times = 6;
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
            times -= 1;
            if (times <= 0) {
              timer.cancel();
              coinValue = randomInList(coinValues);
              coinColor = Colors.white70;
              playRandomSFX();
            } else {
              coinValue = randomInList(coinValues);
              coinColor = randomInList(colors);
            }
            state(() {});
          });
        },
      )
    ]);
  }

  String coinValue = 'H';
  List<String> coinValues = ['H', 'T'];

  Color coinColor = Colors.white70;
  double coinSize = 300;
  List<Color> colors = [
    Colors.white,
    Colors.white,
    Colors.blueAccent.shade100,
    Colors.greenAccent.shade100,
    Colors.redAccent.shade100
  ];

  List<String> sounds = [
    "sfx/1.mp3",
    "sfx/2.mp3",
    "sfx/3.mp3",
    "sfx/4.mp3",
    "sfx/5.mp3",
    "sfx/6.mp3",
    "sfx/7.mp3",
    "sfx/8.mp3",
    "sfx/9.mp3",
    "sfx/10.mp3",
    "sfx/11.mp3",
    "sfx/12.mp3",
  ];

  void playRandomSFX() {
    AudioPlayer player = AudioPlayer();
    String path = randomInList(sounds);
    player.play(AssetSource(path));
  }

  void playBadSFX() {
    AudioPlayer player = AudioPlayer();
    player.play(AssetSource("sfx/3.mp3"));
  }

  Widget buildStartRange() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
          keyboardType: TextInputType.number,
          onTap: () => startController.selection = TextSelection(
              baseOffset: 0, extentOffset: startController.value.text.length),
          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: darkMode ? Colors.white60 : Colors.black54),
              ),
              hintText: 'Start',
              hintStyle:
                  TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
              filled: true,
              fillColor: !darkMode ? Colors.white : dialogColor),
          controller: startController),
    );
  }

  Widget buildEndRange() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
          keyboardType: TextInputType.number,
          onTap: () => endController.selection = TextSelection(
              baseOffset: 0, extentOffset: endController.value.text.length),
          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: darkMode ? Colors.white60 : Colors.black54),
              ),
              hintText: 'End',
              hintStyle:
                  TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
              filled: true,
              fillColor: !darkMode ? Colors.white : dialogColor),
          controller: endController),
    );
  }
}
