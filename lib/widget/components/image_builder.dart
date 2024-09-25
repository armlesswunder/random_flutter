import 'dart:io';
import 'dart:math';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:random_app/model/utils.dart';

import '../../model/data.dart';
import '../../model/image_properties.dart';

class ImageBuilder extends StatefulWidget {
  final String imageStr;
  final ImageProperties? imageProperties;

  const ImageBuilder({Key? key, required this.imageStr, this.imageProperties})
      : super(key: key);

  @override
  State<ImageBuilder> createState() => _ImageBuilderState();
}

class _ImageBuilderState extends State<ImageBuilder> {
  @override
  Widget build(BuildContext context) {
    return buildImage(widget.imageStr, imageProperties: widget.imageProperties);
  }

  Widget buildImage(String imageStr, {ImageProperties? imageProperties}) {
    var str1 = imageStr;
    if (imageStr.contains('=')) {
      str1 = imageStr.split('=')[1];
    }
    var list = [str1];
    if (str1.contains(';')) {
      list = str1.split(';');
    }
    List<Widget> widgets = [];
    list = list.map((e) => e.replaceAll('\\', Platform.pathSeparator)).toList();
    ImageProperties ip = imageProperties ?? ImageProperties({});
    double? imgWidth = ip.getWidth();
    double? imgHeight = ip.getHeight();
    double imgBaselineMultiplierW = MediaQuery.of(context).size.width / 1.5;
    double imgBaselineMultiplierH = MediaQuery.of(context).size.height / 1.5;
    for (String imgStr in list) {
      try {
        var arr = [imgStr, ''];
        var name = '';
        if (imgStr.contains(mainSep)) {
          arr = imgStr.split(mainSep);
        }
        var imgUrl = '${arr[0]}';
        name = arr[1];
        imgUrl = '$assetDir$imgUrl';
        File imgFile = File(imgUrl);
        if (!imgFile.existsSync()) {
          try {
            String foundPath = Directory(assetDir)
                .listSync(recursive: true)
                .map((e) => e.path)
                .firstWhere((element) => element
                    .getFileName()
                    .toLowerCase()
                    .contains(imgStr.getFileName().toLowerCase()));
            print(foundPath);
            imgFile = File(foundPath);
            name = imgStr;
          } catch (e) {
            imgUrl = '${arr[0]}';
          }
        }
        if (imgFile.existsSync()) {
          widgets.add(
            Image.file(
              imgFile,
              width: min(
                  imgWidth ?? imgBaselineMultiplierW, imgBaselineMultiplierW),
              height: min(
                  imgHeight ?? imgBaselineMultiplierH, imgBaselineMultiplierH),
              filterQuality: FilterQuality.high,
            ),
          );
        } else {
          widgets.add(Column(children: [
            FastCachedImage(
              url: imgUrl,
              width: imgWidth,
              height: imgHeight,
              filterQuality: FilterQuality.high,
              loadingBuilder: (context, progress) {
                return SizedBox(
                    width: imgWidth ?? imgSize / 2,
                    height: imgHeight ?? imgSize / 2,
                    child: const CircularProgressIndicator());
              },
            ),
            //Image.network(imgUrl, width: imgSize, height: imgSize),
            //Text(name)
          ]));
        }
      } catch (e) {
        widgets.add(Container());
      }
    }
    return Wrap(
      children: widgets,
    );
  }
}
