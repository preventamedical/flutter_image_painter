import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img_pkg;

import '_controller.dart';
import '_image_painter.dart';
import 'delegates/text_delegate.dart';
import 'widgets/_color_widget.dart';
import 'widgets/_mode_widget.dart';
import 'widgets/_range_slider.dart';

export '_image_painter.dart';

///[ImagePainter] widget.
@immutable
class ImagePainter extends StatefulWidget {
  const ImagePainter._({
    Key? key,
    this.vesselsImageUrl,
    this.fundusImageUrl,
    this.height,
    this.width,
    this.placeHolder,
    this.isScalable,
    this.brushIcon,
    this.clearAllIcon,
    this.colorIcon,
    this.undoIcon,
    this.controlsAtTop = true,
    this.colors,
    this.initialPaintMode,
    this.initialStrokeWidth,
    this.initialColor,
    this.onColorChanged,
    this.onStrokeWidthChanged,
    this.onPaintModeChanged,
    this.textDelegate,
    this.showControls = true,
    this.controlsBackgroundColor,
    this.optionSelectedColor,
    this.optionUnselectedColor,
    this.optionColor,
    this.onUndo,
    this.onClear,
    this.onSubmitted,
    this.onCancelled,
  }) : super(key: key);

  ///Constructor for loading image from network url.
  factory ImagePainter.network({
    required String vesselsImageUrl,
    required String fundusImageUrl,
    required Key key,
    double? height,
    double? width,
    Widget? placeholderWidget,
    bool? scalable,
    List<Color>? colors,
    Widget? brushIcon,
    Widget? undoIcon,
    Widget? clearAllIcon,
    Widget? colorIcon,
    PaintMode? initialPaintMode,
    double? initialStrokeWidth,
    Color? initialColor,

    ValueChanged<PaintMode>? onPaintModeChanged,
    ValueChanged<Color>? onColorChanged,
    ValueChanged<double>? onStrokeWidthChanged,
    TextDelegate? textDelegate,
    bool? controlsAtTop,
    bool? showControls,
    Color? controlsBackgroundColor,
    Color? selectedColor,
    Color? unselectedColor,
    Color? optionColor,
    VoidCallback? onUndo,
    VoidCallback? onClear,
    VoidCallback? onSubmitted,
    VoidCallback? onCancelled,
  }) {
    return ImagePainter._(
      key: key,
      vesselsImageUrl: vesselsImageUrl,
      fundusImageUrl: fundusImageUrl,
      height: height,
      width: width,
      placeHolder: placeholderWidget,
      isScalable: scalable,
      colors: colors,
      brushIcon: brushIcon,
      undoIcon: undoIcon,
      colorIcon: colorIcon,
      clearAllIcon: clearAllIcon,
      initialPaintMode: initialPaintMode,
      initialColor: initialColor,
      initialStrokeWidth: initialStrokeWidth,
      onPaintModeChanged: onPaintModeChanged,
      onColorChanged: onColorChanged,
      onStrokeWidthChanged: onStrokeWidthChanged,
      textDelegate: textDelegate,
      controlsAtTop: controlsAtTop ?? true,
      showControls: showControls ?? true,
      controlsBackgroundColor: controlsBackgroundColor,
      optionSelectedColor: selectedColor,
      optionUnselectedColor: unselectedColor,
      optionColor: optionColor,
      onUndo: onUndo,
      onClear: onClear,
      onSubmitted: onSubmitted,
      onCancelled: onCancelled,
    );
  }

  ///Only accessible through [ImagePainter.network] constructor.
  final String? vesselsImageUrl;

  ///Only accessible through [ImagePainter.network] constructor.
  final String? fundusImageUrl;

  ///Height of the Widget. Image is subjected to fit within the given height.
  final double? height;

  ///Width of the widget. Image is subjected to fit within the given width.
  final double? width;

  ///Widget to be shown during the conversion of provided image to [ui.Image].
  final Widget? placeHolder;

  ///Defines whether the widget should be scaled or not. Defaults to [false].
  final bool? isScalable;

  ///List of colors for color selection
  ///If not provided, default colors are used.
  final List<Color>? colors;

  ///Icon Widget of strokeWidth.
  final Widget? brushIcon;

  ///Widget of Color Icon in control bar.
  final Widget? colorIcon;

  ///Widget for Undo last action on control bar.
  final Widget? undoIcon;

  ///Widget for clearing all actions on control bar.
  final Widget? clearAllIcon;

  ///Define where the controls is located.
  ///`true` represents top.
  final bool controlsAtTop;

  ///Initial PaintMode.
  final PaintMode? initialPaintMode;

  //the initial stroke width
  final double? initialStrokeWidth;

  //the initial color
  final Color? initialColor;

  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<double>? onStrokeWidthChanged;
  final ValueChanged<PaintMode>? onPaintModeChanged;

  //the text delegate
  final TextDelegate? textDelegate;

  ///It will control displaying the Control Bar
  final bool showControls;
  final Color? controlsBackgroundColor;
  final Color? optionSelectedColor;
  final Color? optionUnselectedColor;
  final Color? optionColor;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancelled;

  @override
  ImagePainterState createState() => ImagePainterState();
}

///
class ImagePainterState extends State<ImagePainter> {
  ui.Image? _vesselsImage;
  late Controller _controller;
  late final ValueNotifier<bool> _isLoaded;
  late final ValueNotifier<bool> _isDisplayed;
  late final TextEditingController _textController;
  late final TransformationController _transformationController;

  int _strokeMultiplier = 1;
  late TextDelegate textDelegate;
  @override
  void initState() {
    super.initState();
    _isLoaded = ValueNotifier<bool>(false);
    _isDisplayed = ValueNotifier<bool>(true);
    _controller = Controller();
    _controller.update(
        mode: widget.initialPaintMode,
        strokeWidth: widget.initialStrokeWidth,
        color: widget.initialColor);

    _resolveAndConvertImage();

    _textController = TextEditingController();
    _transformationController = TransformationController();
    textDelegate = widget.textDelegate ?? TextDelegate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _isLoaded.dispose();
    _textController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  bool get isEdited => _controller.paintHistory.isNotEmpty;

  Size get imageSize =>
      Size(_vesselsImage?.width.toDouble() ?? 0, _vesselsImage?.height.toDouble() ?? 0);

  ///Converts the incoming image type from constructor to [ui.Image]
  Future<void> _resolveAndConvertImage() async {
    if (widget.vesselsImageUrl != null) {
      _vesselsImage = await _loadNetworkImage(widget.vesselsImageUrl!);

      if (_vesselsImage == null) {
        throw ("${widget.vesselsImageUrl} couldn't be resolved.");
      } else {
        _setStrokeMultiplier();
      }
    } else {
      _isLoaded.value = true;
    }
  }

  ///Dynamically sets stroke multiplier on the basis of widget size.
  ///Implemented to avoid thin stroke on high res images.
  _setStrokeMultiplier() {
    if ((_vesselsImage!.height + _vesselsImage!.width) > 1000) {
      _strokeMultiplier = (_vesselsImage!.height + _vesselsImage!.width) ~/ 1000;
    }
    _controller.update(strokeMultiplier: _strokeMultiplier);
  }

  ///Completer function to convert network image to [ui.Image] before drawing on custompainter.
  Future<ui.Image> _loadNetworkImage(String path, {isVessels = true}) async {
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
        if (isVessels) {
          if (pixel.r > 0) photo.setPixelRgba(x, y, 255, 0, 0, 255);
          if (pixel.g > 0) photo.setPixelRgba(x, y, 0, 255, 0, 255);
          if (pixel.b > 0) photo.setPixelRgba(x, y, 0, 0, 255, 255);
        }
        if (pixel.r == 0 && pixel.g == 0 && pixel.b == 0) {
          photo.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    img1 = await convertImageToFlutterUi(photo);

    if (isVessels) _isLoaded.value = true;

    return img1;
  }

  Future<void> clearVessels() async {
    _isLoaded.value = false;
    img_pkg.Image photo = await convertFlutterUiToImage(_vesselsImage!);
    photo.clear(img_pkg.ColorRgba8(0, 0, 0, 0));
    photo.setPixelRgba(0, 0, 1, 1, 1, 255);
    _vesselsImage = await convertImageToFlutterUi(photo);
    _controller.clear();
    _isLoaded.value = true;
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoaded,
      builder: (_, loaded, __) {
        if (loaded) {
          return _paintImage();
        } else {
          return Container(
            height: widget.height ?? double.maxFinite,
            width: widget.width ?? double.maxFinite,
            child: Center(
              child: widget.placeHolder ?? const CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  ///paints image on given constrains for drawing if image is not null.
  Widget _paintImage() {
    return Container(
      height: widget.height ?? double.maxFinite,
      width: widget.width ?? double.maxFinite,
      child: Column(
        children: [
          if (widget.controlsAtTop && widget.showControls) _buildControls(),
          Expanded(
            child: FittedBox(
              alignment: FractionalOffset.center,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return InteractiveViewer(
                        transformationController: _transformationController,
                        maxScale: 2.4,
                        minScale: 1,
                        panEnabled: _controller.mode == PaintMode.none,
                        scaleEnabled: widget.isScalable!,
                        onInteractionUpdate: _scaleUpdateGesture,
                        onInteractionEnd: _scaleEndGesture,
                        child: Stack(
                          children: [
                            Container(
                              height: imageSize.height,
                              width: imageSize.width,
                              //color: Colors.transparent,
                              child: Image.network(widget.fundusImageUrl!),
                            ),
                            ValueListenableBuilder<bool>(
                                valueListenable: _isDisplayed,
                                builder: (_, displayed, __) {
                                  if (displayed) {
                                    return CustomPaint(
                                      size: imageSize,
                                      willChange: true,
                                      isComplex: true,
                                      painter: DrawImage(
                                        image: _vesselsImage,
                                        controller: _controller,
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                }),
                          ],
                        ));
                  },
                ),
              ),
            ),
          ),
          if (!widget.controlsAtTop && widget.showControls) _buildControls(),
          SizedBox(height: MediaQuery.of(context).padding.bottom)
        ],
      ),
    );
  }

  ///Fires while user is interacting with the screen to record painting.
  void _scaleUpdateGesture(ScaleUpdateDetails onUpdate) {
    final _zoomAdjustedOffset =
        _transformationController.toScene(onUpdate.localFocalPoint);
    _controller.setInProgress(true);
    if (_controller.start == null) {
      _controller.setStart(_zoomAdjustedOffset);
    }
    _controller.setEnd(_zoomAdjustedOffset);
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.addOffsets(_zoomAdjustedOffset);
    }
  }

  ///Fires when user stops interacting with the screen.
  void _scaleEndGesture(ScaleEndDetails onEnd) {
    _controller.setInProgress(false);
    if (_controller.start != null &&
        _controller.end != null &&
        _controller.mode == PaintMode.freeStyle) {
      _controller.addOffsets(null);
      _addFreeStylePoints();
      _controller.offsets.clear();
    } else if (_controller.start != null && _controller.end != null) {
      _addEndPoints();
    }
    _controller.resetStartAndEnd();
  }

  void _addEndPoints() => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[_controller.start, _controller.end],
          mode: _controller.mode,
          color: _controller.color,
          strokeWidth: _controller.scaledStrokeWidth,
        ),
      );

  void _addFreeStylePoints() => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[..._controller.offsets],
          mode: PaintMode.freeStyle,
          color: _controller.color,
          strokeWidth: _controller.scaledStrokeWidth,
        ),
      );

  ///Provides [ui.Image] of the recorded canvas to perform action.
  Future<ui.Image> _renderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawImage(image: _vesselsImage, controller: _controller);
    final size = Size(_vesselsImage!.width.toDouble(), _vesselsImage!.height.toDouble());
    painter.paint(canvas, size);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  PopupMenuItem _showOptionsRow() {
    return PopupMenuItem(
      enabled: false,
      child: Center(
        child: SizedBox(
          child: Wrap(
            children: paintModes(textDelegate)
                .map(
                  (item) => SelectionItems(
                    data: item,
                    isSelected: _controller.mode == item.mode,
                    selectedColor: widget.optionSelectedColor,
                    unselectedColor: widget.optionUnselectedColor,
                    onTap: () {
                      if (widget.onPaintModeChanged != null) {
                        widget.onPaintModeChanged!(item.mode);
                      }
                      _controller.setMode(item.mode);

                      Navigator.of(context).pop();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  PopupMenuItem _showRangeSlider() {
    return PopupMenuItem(
      enabled: false,
      child: SizedBox(
        width: double.maxFinite,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return RangedSlider(
              value: _controller.strokeWidth,
              onChanged: (value) {
                _controller.setStrokeWidth(value);
                if (widget.onStrokeWidthChanged != null) {
                  widget.onStrokeWidthChanged!(value);
                }
              },
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem _showColorPicker() {
    return PopupMenuItem(
      enabled: false,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: (widget.colors ?? editorColors).map((color) {
            return ColorItem(
              isSelected: color == _controller.color,
              color: color,
              onTap: () {
                _controller.setColor(color);
                if (widget.onColorChanged != null) {
                  widget.onColorChanged!(color);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  ///Generates [Uint8List] of the [ui.Image] generated by the [renderImage()] method.
  ///Can be converted to image file by writing as bytes.
  Future<Uint8List?> exportImage() async {
    late ui.Image _convertedImage;
    _convertedImage = await _renderImage();

    final byteData =
        await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _addPaintHistory(PaintInfo info) {
    if (info.mode != PaintMode.none) {
      _controller.addPaintInfo(info);
    }
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: widget.controlsBackgroundColor ?? Colors.grey[200],
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final icon = paintModes(textDelegate)
                  .firstWhere((item) => item.mode == _controller.mode)
                  .icon;
              return PopupMenuButton(
                tooltip: textDelegate.changeMode,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                icon: Icon(icon, color: widget.optionColor ?? Colors.grey[700]),
                itemBuilder: (_) => [_showOptionsRow()],
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return PopupMenuButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tooltip: textDelegate.changeColor,
                icon: widget.colorIcon ??
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                        color: _controller.color,
                      ),
                    ),
                itemBuilder: (_) => [_showColorPicker()],
              );
            },
          ),
          PopupMenuButton(
            tooltip: textDelegate.changeBrushSize,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon:
                widget.brushIcon ?? Icon(Icons.brush, color: Colors.grey[700]),
            itemBuilder: (_) => [_showRangeSlider()],
          ),
          const Spacer(),

          MaterialButton(child: const Text("Submit"), onPressed: widget.onSubmitted),

          MaterialButton(child: const Text("Cancel"), onPressed: widget.onCancelled),

          const Spacer(),

          IconButton(
            tooltip: textDelegate.undo,
            icon: widget.undoIcon ?? Icon(Icons.reply, color: Colors.grey[700]),
            onPressed: () {
              widget.onUndo?.call();
              _controller.undo();
            },
          ),
          IconButton(
            icon: Icon(Icons.display_settings, color: Colors.grey[700]),
            onPressed: () {
              _isDisplayed.value = !_isDisplayed.value;
            },
          ),
          IconButton(
            tooltip: textDelegate.clearAllProgress,
            icon: widget.clearAllIcon ??
                Icon(Icons.clear, color: Colors.grey[700]),
            onPressed: clearVessels,
          ),
        ],
      ),
    );
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
}
