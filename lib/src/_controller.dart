import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_pkg;

import '../image_painter.dart';

class Controller extends ChangeNotifier {
  late double _strokeWidth;
  late Color _color;
  late PaintMode _mode;
  late bool _fill;
  final List<Offset?> _offsets = [];
  final List<PaintInfo> _paintHistory = [];
  Offset? _start, _end;
  int _strokeMultiplier = 1;
  bool _paintInProgress = false;
  ui.Image? vesselsImage;

  Paint get brush => Paint()
    ..color = _color
    ..strokeWidth = _strokeWidth * _strokeMultiplier
    ..style = shouldFill ? PaintingStyle.fill : PaintingStyle.stroke;

  PaintMode get mode => _mode;
  double get strokeWidth => _strokeWidth;
  double get scaledStrokeWidth => _strokeWidth * _strokeMultiplier;
  bool get busy => _paintInProgress;
  bool get fill => _fill;
  Color get color => _color;
  List<PaintInfo> get paintHistory => _paintHistory;
  List<Offset?> get offsets => _offsets;
  Offset? get start => _start;
  Offset? get end => _end;
  final ValueNotifier<bool> isLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDisplayed = ValueNotifier<bool>(true);

  Controller({
    double strokeWidth = 4.0,
    Color color = Colors.red,
    PaintMode mode = PaintMode.freeStyle,
  }) {
    _strokeWidth = strokeWidth;
    _color = color;
    _mode = mode;
  }

  void addPaintInfo(PaintInfo paintInfo) {
    _paintHistory.add(paintInfo);
    notifyListeners();
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.clear();
      notifyListeners();
    }
  }

  void setStrokeWidth(double val) {
    _strokeWidth = val;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    notifyListeners();
  }

  void setStart(Offset? offset) {
    _start = offset;
    notifyListeners();
  }

  void setEnd(Offset? offset) {
    _end = offset;
    notifyListeners();
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
    notifyListeners();
  }

  void update({
    double? strokeWidth,
    Color? color,
    bool? fill,
    PaintMode? mode,
    String? text,
    int? strokeMultiplier,
  }) {
    _strokeWidth = strokeWidth ?? _strokeWidth;
    _color = color ?? _color;
    _mode = mode ?? _mode;
    _strokeMultiplier = strokeMultiplier ?? _strokeMultiplier;
    notifyListeners();
  }

  void setInProgress(bool val) {
    _paintInProgress = val;
    notifyListeners();
  }

  bool get shouldFill {
    return false;
  }

  Future<ui.Image> clearVessels(ui.Image image) async {
    isLoaded.value = false;
    img_pkg.Image photo = await convertFlutterUiToImage(image);
    photo.clear(img_pkg.ColorRgba8(0, 0, 0, 0));
    photo.setPixelRgba(0, 0, 1, 1, 1, 255);
    image = await convertImageToFlutterUi(photo);
    isLoaded.value = true;
    notifyListeners();
    return image;
  }

  ///Completer function to convert network image to [ui.Image] before drawing on custompainter.
  Future<ui.Image> loadNetworkImage(String path) async {
    final completer = Completer<ImageInfo>();
    final img = NetworkImage(path);
    img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) => completer.complete(info)));
    final imageInfo = await completer.future;

    img_pkg.Image? photo;
    ui.Image img1 = imageInfo.image;

    photo = await convertFlutterUiToImage(img1);

    for (int x = 0; x < photo.width; x++) {
      for (int y = 0; y < photo.height; y++) {
        final pixel = photo.getPixelSafe(x.toInt(), y.toInt());
          if (pixel.r > 0) photo.setPixelRgba(x, y, 255, 0, 0, 255);
          if (pixel.g > 0) photo.setPixelRgba(x, y, 0, 255, 0, 255);
          if (pixel.b > 0) photo.setPixelRgba(x, y, 0, 0, 255, 255);

        if (pixel.r == 0 && pixel.g == 0 && pixel.b == 0) {
          photo.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    img1 = await convertImageToFlutterUi(photo);

    isLoaded.value = true;

    return img1;
  }

  Future<img_pkg.Image> convertFlutterUiToImage(ui.Image uiImage) async {
    final uiBytes = await uiImage.toByteData();

    final image = img_pkg.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: uiBytes!.buffer,
        numChannels: 4);

    return image;
  }

  Future<ui.Image> convertImageToFlutterUi(img_pkg.Image image) async {
    if (image.format != img_pkg.Format.uint8 || image.numChannels != 4) {
      final cmd = img_pkg.Command()
        ..image(image)
        ..convert(format: img_pkg.Format.uint8, numChannels: 4);
      final rgba8 = await cmd.getImageThread();
      if (rgba8 != null) {
        image = rgba8;
      }
    }

    ui.ImmutableBuffer buffer =
    await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

    ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
        height: image.height,
        width: image.width,
        pixelFormat: ui.PixelFormat.rgba8888);

    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);

    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;

    return uiImage;
  }

  ///Provides [ui.Image] of the recorded canvas to perform action.
  Future<ui.Image> renderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawImage(image: vesselsImage, controller: this);
    final size = Size(vesselsImage!.width.toDouble(), vesselsImage!.height.toDouble());
    painter.paint(canvas, size);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }


  ///Generates [Uint8List] of the [ui.Image] generated by the [renderImage()] method.
  ///Can be converted to image file by writing as bytes.
  Future<Uint8List?> exportImage() async {
    late ui.Image _convertedImage;
    _convertedImage = await renderImage();
    final byteData =
    await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}