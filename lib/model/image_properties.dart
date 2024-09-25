import 'data.dart';

class ImageProperties {
  num width = imgSize;
  num height = imgSize;
  bool autoScale = false;
  bool nativeSize = false;
  Map<String, dynamic> map = {};

  ImageProperties(this.map) {
    width = map["width"] ?? width;
    height = map["height"] ?? height;
    autoScale = map["auto_scale"] ?? autoScale;
    nativeSize = map["native_size"] ?? nativeSize;
  }

  double? getWidth() {
    if (nativeSize) {
      return null;
    }
    return width.toDouble();
  }

  double? getHeight() {
    if (nativeSize) {
      return null;
    }
    return height.toDouble();
  }
}
