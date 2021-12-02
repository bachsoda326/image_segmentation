import 'dart:typed_data';
import 'package:image/image.dart' as Img;

class Utils {
  static Future<Img.Image> _customColor({
    required Img.Image src,
    required List<int> removeColorRGB,
    required List<int> addColorRGB,
  }) async {
    var pixels = src.getBytes();
    bool hasCar = false;

    for (int i = 0, len = pixels.length; i < len; i += 4) {
      if (!hasCar &&
          pixels[i] == removeColorRGB[0] &&
          pixels[i + 1] == removeColorRGB[1] &&
          pixels[i + 2] == removeColorRGB[2]) {
        hasCar = true;
        break;
      }
    }

    for (int i = 0, len = pixels.length; i < len; i += 4) {
      if (pixels[i] == removeColorRGB[0] &&
          pixels[i + 1] == removeColorRGB[1] &&
          pixels[i + 2] == removeColorRGB[2]) {
        /*pixels[i] = addColorRGB[0];
        pixels[i + 1] = addColorRGB[1];
        pixels[i + 2] = addColorRGB[2];*/
        pixels[i + 3] = 0;
        // print('DONE');
      } else if (hasCar) {
        pixels[i + 0] = 0;
        pixels[i + 1] = 0;
        pixels[i + 2] = 0;
        pixels[i + 3] = 180;
      } else {
        pixels[i + 3] = 0;
      }
    }

    src.channels = Img.Channels.rgba;
    return src;
  }

  static Future<Uint8List?> changeBackgroundOfImage({
    required Uint8List bytes,
    required List<int> removeColorRGB,
    required List<int> addColorRGB,
  }) async {
    Img.Image? image = Img.decodeImage(bytes);
    if (image == null) return null;

    Img.Image newImage = await _customColor(
        src: image, removeColorRGB: removeColorRGB, addColorRGB: addColorRGB);
    var newPng = Img.encodePng(newImage);
    return Uint8List.fromList(newPng);
  }
}