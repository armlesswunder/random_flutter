import 'package:flutter/material.dart';

import '../../model/data.dart';
import '../../model/display_item.dart';
import '../../model/file.dart';

class FavoriteButton extends StatefulWidget {
  final int index;
  const FavoriteButton({super.key, required this.index});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: IconButton(
      onPressed: () {
        setSelected(!isSelected());
      },
      icon: Icon(
        isSelected() ? Icons.favorite : Icons.favorite_border,
        color: Colors.red.shade300,
      ),
    ));
  }

  bool isSelected() {
    DisplayItem displayItem = displayList[widget.index];
    return favItems.contains(displayItem.trueData);
  }

  void setSelected(bool selected) {
    DisplayItem displayItem = displayList[widget.index];
    if (selected) {
      favItems.add(displayItem.trueData);
    } else {
      favItems.remove(displayItem.trueData);
    }

    //addAuditData(displayItem.getDisplayData());
    saveFavData();
    setState(() {});
  }
}
