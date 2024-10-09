import 'package:flutter/material.dart';

import '../../../model/data.dart';
import '../../../model/ecs.dart';
import '../../../view/theme.dart';
import 'ec.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
        appBar: AppBar(title: const Text('Search')),
        body: Column(children: [
          TextField(
            onChanged: (text) {
              if (text == ecp) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EncryptPage()));
                setState(() {});
              } else {
                searchList = displayList
                    .where((element) => element
                        .getDisplayData()
                        .toLowerCase()
                        .contains(text.toLowerCase()))
                    .toList();

                setState(() {});
              }
            },
            style: TextStyle(color: darkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: darkMode ? Colors.white60 : Colors.black54),
              ),
              hintStyle:
                  TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
              hintText: 'Search',
              filled: true,
              fillColor: !darkMode ? Colors.white : dialogColor,
            ),
            controller: searchController,
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: searchList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                        decoration: BoxDecoration(
                            color: !darkMode ? Colors.black12 : Colors.white10,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12))),
                        margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                        searchList[index].getDisplayData())),
                              ),
                            ),
                          ],
                        ));
                  })),
        ]));
  }
}
