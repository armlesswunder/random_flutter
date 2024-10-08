import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:random_app/model/utils.dart';
import 'package:random_app/model/web_client.dart';
import 'package:random_app/widget/page/image_zoom_page.dart';

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
    ImageProperties ip = imageProperties ?? ImageProperties({});
    double? imgWidth = ip.getWidth();
    double? imgHeight = ip.getHeight();
    double imgBaselineMultiplierW = MediaQuery.of(context).size.width / 1.5;
    double imgBaselineMultiplierH = MediaQuery.of(context).size.height / 1.5;

    if (imageStr.contains('=')) {
      str1 = imageStr.split('=')[1];
    }
    var list = [str1];
    if (str1.contains(';')) {
      list = str1.split(';');
    }
    List<Widget> widgets = [];
    if (!isWeb()) {
      list =
          list.map((e) => e.replaceAll('\\', Platform.pathSeparator)).toList();
    }
    for (String imgStr in list) {
      if (isWebMode) {
        widgets.add(_getMemoryImage(imgStr, imgWidth, imgHeight));
        continue;
      } else if (isWeb()) {
        widgets.add(_getWebImage(imgStr, imgWidth, imgHeight));
        continue;
      }

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
          widgets.add(_getFileImage(
              imgFile,
              min(imgWidth ?? imgBaselineMultiplierW, imgBaselineMultiplierW),
              min(imgHeight ?? imgBaselineMultiplierH,
                  imgBaselineMultiplierH)));
        } else {
          widgets.add(_getWebImage(imgStr, imgWidth, imgHeight));
        }
      } catch (e) {
        widgets.add(Container());
      }
    }
    return Wrap(
      children: widgets,
    );
  }

  Widget _getFileImage(File imgFile, double? imgWidth, double? imgHeight) {
    Image img = Image.file(
      imgFile,
      width: imgWidth,
      height: imgHeight,
      filterQuality: FilterQuality.high,
    );
    return GestureDetector(
        onLongPress: () {
          Navigator.push(context, MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return ImageZoomPage(imageProvider: img.image);
            },
          ));
        },
        child: img);
  }

  Widget _getMemoryImage(String imgStr, double? imgWidth, double? imgHeight) {
    var img = MemoryImageBuilder(
        imageStr: imgStr.replaceAll('\\', '/'),
        imgWidth: imgWidth,
        imgHeight: imgHeight);
    return img;
  }

  Widget _getWebImage(String imgStr, double? imgWidth, double? imgHeight) {
    var img = isWeb()
        ? Image.network(imgStr,
            width: imgWidth,
            height: imgHeight,
            filterQuality: FilterQuality.high)
        : FastCachedImage(
            url: imgStr,
            width: imgWidth,
            height: imgHeight,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, progress) {
              double progressSize = (imgWidth ?? imgSize) / 3;
              return SizedBox(
                  width: progressSize,
                  height: progressSize,
                  child: const CircularProgressIndicator());
            },
          );
    return _wrapGesture(img, Image.network(imgStr).image);
  }

  Widget _wrapGesture(Widget child, ImageProvider imageProvider) {
    if (isWeb()) {
      return Stack(children: [
        child,
        Positioned(
            right: 0,
            bottom: 0,
            child: IconButton(
                icon: Container(
                    color: Colors.black12, child: const Icon(Icons.search)),
                onPressed: () => _goToImageZoomer(imageProvider)))
      ]);
    } else {
      return Column(children: [
        GestureDetector(
            onLongPress: () => _goToImageZoomer(imageProvider), child: child),
      ]);
    }
  }

  void _goToImageZoomer(ImageProvider imageProvider) {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return ImageZoomPage(imageProvider: imageProvider);
      },
    ));
  }
}

class MemoryImageBuilder extends StatefulWidget {
  final String imageStr;
  final double? imgWidth;
  final double? imgHeight;

  const MemoryImageBuilder(
      {Key? key, required this.imageStr, this.imgWidth, this.imgHeight})
      : super(key: key);

  @override
  State<MemoryImageBuilder> createState() => _MemoryImageBuilderState();
}

class _MemoryImageBuilderState extends State<MemoryImageBuilder> {
  Future<String> get _calculation =>
      WebClient().get('assets${widget.imageStr}');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _calculation,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          Widget child;
          if (snapshot.hasData) {
            var img = Image.memory(
              Uint8List.fromList(snapshot.data?.codeUnits ?? []),
              width: widget.imgWidth,
              height: widget.imgHeight,
              filterQuality: FilterQuality.high,
            );
            child = _wrapGesture(img, img.image);
          } else {
            child = SizedBox(
                width: 60, height: 60, child: CircularProgressIndicator());
          }
          return child;
        });
  }

  Widget _wrapGesture(Widget child, ImageProvider imageProvider) {
    if (isWeb()) {
      return Stack(children: [
        child,
        Positioned(
            right: 0,
            bottom: 0,
            child: IconButton(
                icon: Container(
                    color: Colors.black12, child: const Icon(Icons.search)),
                onPressed: () => _goToImageZoomer(imageProvider)))
      ]);
    } else {
      return Column(children: [
        GestureDetector(
            onLongPress: () => _goToImageZoomer(imageProvider), child: child),
      ]);
    }
  }

  void _goToImageZoomer(ImageProvider imageProvider) {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return ImageZoomPage(imageProvider: imageProvider);
      },
    ));
  }
}
