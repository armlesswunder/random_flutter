import 'package:flutter/material.dart';

import '../model/data.dart';
import '../view/theme.dart';

Widget buildListSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: TextField(
      style: TextStyle(color: darkMode ? Colors.white : Colors.black),
      controller: searchListDisplayController,
      onChanged: onSearchListChanged,
      decoration: InputDecoration(
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
          onPressed: () => searchListClearPressed(),
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

void searchListClearPressed() {
  searchListDisplayController.text = "";
  updateViews();
}

void onSearchListChanged(String text) {
  updateViews();
}
