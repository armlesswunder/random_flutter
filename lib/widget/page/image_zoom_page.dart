import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../model/utils.dart';

class ImageZoomPage extends StatefulWidget {
  final ImageProvider imageProvider;
  const ImageZoomPage({Key? key, required this.imageProvider})
      : super(key: key);

  @override
  State<ImageZoomPage> createState() => _ImageZoomPageState();
}

class _ImageZoomPageState extends State<ImageZoomPage> {
  late PhotoViewController controller;
  double scaleCopy = 1.0;

  double minScale = 0.1;
  double maxScale = 25.0;

  @override
  void initState() {
    super.initState();
    controller = PhotoViewController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                tooltip: 'Reset Scale',
                onPressed: () {
                  controller.scale = 1.0;
                },
                icon: const Icon(Icons.square_rounded))
          ],
        ),
        body: _wrapGesture(_buildContent()));
  }

  Widget _wrapGesture(Widget child) {
    if (isMobile()) {
      return child;
    }
    return Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            var amount = -0.8;
            if (pointerSignal.scrollDelta.dy.isNegative) {
              amount = amount * -1;
            }
            var newScale = (controller.scale ?? 1) + amount;
            print(newScale);
            if (newScale < maxScale && newScale > minScale) {
              controller.scale = newScale;
              setState(() {});
            }
          }
        },
        child: child);
  }

  Widget _buildContent() {
    return Column(children: <Widget>[
      Expanded(
          child: PhotoView(
        imageProvider: widget.imageProvider,
        controller: controller,
      )),
      Slider(
          value: controller.scale ?? 1.0,
          min: minScale,
          max: maxScale,
          onChanged: (n) {
            controller.scale = n;
            setState(() {});
          })
    ]);
  }
}
