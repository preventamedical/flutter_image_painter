import 'dart:async';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart';
import '_controller.dart';
import '_image_painter.dart';
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
    this.initialPaintMode,
    this.initialStrokeWidth,
    this.initialColor,
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
    PaintMode? initialPaintMode,
    double? initialStrokeWidth,
    Color? initialColor,
  }) {
    return ImagePainter._(
      key: key,
      vesselsImageUrl: vesselsImageUrl,
      fundusImageUrl: fundusImageUrl,
      height: height,
      width: width,
      placeHolder: placeholderWidget,
      isScalable: scalable,
      initialPaintMode: initialPaintMode,
      initialColor: initialColor,
      initialStrokeWidth: initialStrokeWidth,
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

  ///Initial PaintMode.
  final PaintMode? initialPaintMode;

  //the initial stroke width
  final double? initialStrokeWidth;

  //the initial color
  final Color? initialColor;

  @override
  ImagePainterState createState() => ImagePainterState();
}

///
class ImagePainterState extends State<ImagePainter> {
  late Controller controller;
  late final TransformationController _transformationController;

  int _strokeMultiplier = 1;

  @override
  void initState() {
    super.initState();

    controller = Controller();
    controller.update(
        mode: widget.initialPaintMode,
        strokeWidth: widget.initialStrokeWidth,
        color: widget.initialColor);

    _resolveAndConvertImage();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  bool get isEdited => controller.paintHistory.isNotEmpty;

  Size get imageSize => Size(controller.vesselsImage?.width.toDouble() ?? 0,
      controller.vesselsImage?.height.toDouble() ?? 0);

  ///Converts the incoming image type from constructor to [ui.Image]
  Future<void> _resolveAndConvertImage() async {
    if (widget.vesselsImageUrl != null) {
      controller.vesselsImage =
          await controller.loadNetworkImage(widget.vesselsImageUrl!);

      if (controller.vesselsImage == null) {
        throw ("${widget.vesselsImageUrl} couldn't be resolved.");
      } else {
        _setStrokeMultiplier();
      }
    } else {
      controller.isLoaded.value = true;
      //_isLoaded.value = true;
    }
  }

  ///Dynamically sets stroke multiplier on the basis of widget size.
  ///Implemented to avoid thin stroke on high res images.
  _setStrokeMultiplier() {
    if ((controller.vesselsImage!.height + controller.vesselsImage!.width) >
        1000) {
      _strokeMultiplier =
          (controller.vesselsImage!.height + controller.vesselsImage!.width) ~/
              1000;
    }
    controller.update(strokeMultiplier: _strokeMultiplier);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoaded,
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
          Expanded(
            child: FittedBox(
              alignment: FractionalOffset.center,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return InteractiveViewer(
                      transformationController: _transformationController,
                      maxScale: 2.4,
                      minScale: 1,
                      panEnabled: controller.mode == PaintMode.none,
                      scaleEnabled: widget.isScalable!,
                      onInteractionUpdate: _scaleUpdateGesture,
                      onInteractionEnd: _scaleEndGesture,
                      child: Stack(
                        children: [
                          Container(
                            height: imageSize.height,
                            width: imageSize.width,
                            child: Image.network(widget.fundusImageUrl!),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: controller.isDisplayed,
                            builder: (_, displayed, __) {
                              if (displayed) {
                                return CustomPaint(
                                  size: imageSize,
                                  willChange: true,
                                  isComplex: true,
                                  painter: DrawImage(
                                    image: controller.vesselsImage,
                                    controller: controller,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///Fires while user is interacting with the screen to record painting.
  void _scaleUpdateGesture(ScaleUpdateDetails onUpdate) {
    final _zoomAdjustedOffset =
        _transformationController.toScene(onUpdate.localFocalPoint);
    controller.setInProgress(true);
    if (controller.start == null) {
      controller.setStart(_zoomAdjustedOffset);
    }
    controller.setEnd(_zoomAdjustedOffset);
    if (controller.mode == PaintMode.freeStyle) {
      controller.addOffsets(_zoomAdjustedOffset);
    }
  }

  ///Fires when user stops interacting with the screen.
  void _scaleEndGesture(ScaleEndDetails onEnd) {
    controller.setInProgress(false);
    if (controller.start != null &&
        controller.end != null &&
        controller.mode == PaintMode.freeStyle) {
      controller.addOffsets(null);
      _addFreeStylePoints();
      controller.offsets.clear();
    } else if (controller.start != null && controller.end != null) {
      _addEndPoints();
    }
    controller.resetStartAndEnd();
  }

  void _addEndPoints() => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[controller.start, controller.end],
          mode: controller.mode,
          color: controller.color,
          strokeWidth: controller.scaledStrokeWidth,
        ),
      );

  void _addFreeStylePoints() => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[...controller.offsets],
          mode: PaintMode.freeStyle,
          color: controller.color,
          strokeWidth: controller.scaledStrokeWidth,
        ),
      );

  void _addPaintHistory(PaintInfo info) {
    if (info.mode != PaintMode.none) {
      controller.addPaintInfo(info);
    }
  }
}
