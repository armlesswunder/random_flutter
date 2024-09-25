import 'package:flutter/material.dart';
import 'package:random_app/model/prefs.dart';

import '../../model/data.dart';
import '../../view/theme.dart';

Widget buildMainSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: TextField(
      focusNode: searchFocus,
      onTapOutside: (e) {
        mainFocus.requestFocus();
      },
      style: TextStyle(color: darkMode ? Colors.white : Colors.black),
      controller: searchDisplayController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(14),
        isDense: true,
        filled: true,
        fillColor: darkMode ? Colors.white24 : Colors.black26,
        hintText: 'Search',
        hintStyle: TextStyle(color: darkMode ? Colors.white : Colors.black),
        prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search,
              color: darkMode ? Colors.white : Colors.black,
            )),
        suffixIcon: IconButton(
          padding: const EdgeInsets.only(right: 16),
          onPressed: () => searchClearPressed(),
          icon:
              Icon(Icons.clear, color: darkMode ? Colors.white : Colors.black),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48.0),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

void searchClearPressed() {
  searchDisplayController.text = "";
  scrollDataController.jumpTo(0);
  updateViews();
  prefs.setString(cacheSearchStrKey(), "");
}

void onSearchChanged(String text) {
  scrollDataController.jumpTo(0);
  updateViews();
  prefs.setString(cacheSearchStrKey(), text);
}
