import 'package:flutter/material.dart';
import 'package:random_app/model/number_ext.dart';
import 'package:random_app/model/prefs.dart';

import '../../model/data.dart';
import '../../view/theme.dart';

Widget buildMainSearchBar() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.0.ds, vertical: 2.0.ds),
    child: TextField(
      focusNode: searchFocus,
      onTapOutside: (e) {
        mainFocus.requestFocus();
      },
      style:
          textSizeStyle.copyWith(color: darkMode ? Colors.white : Colors.black),
      controller: searchDisplayController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(14.0.ds),
        isDense: true,
        filled: true,
        fillColor: darkMode ? Colors.white24 : Colors.black26,
        hintText: 'Search',
        hintStyle: TextStyle(color: darkMode ? Colors.white : Colors.black),
        prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.ds),
            child: Icon(
              Icons.search,
              size: 18.0.ds,
              color: darkMode ? Colors.white : Colors.black,
            )),
        suffixIcon: IconButton(
          padding: EdgeInsets.only(right: 16.0.ds),
          onPressed: () => searchClearPressed(),
          icon: Icon(Icons.clear,
              size: 18.0.ds, color: darkMode ? Colors.white : Colors.black),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48.0.ds),
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
