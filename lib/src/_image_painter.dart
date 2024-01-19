import 'dart:ui';
import 'package:flutter/material.dart' hide Image;

import '_controller.dart';

///Handles all the painting ongoing on the canvas.
class DrawImage extends CustomPainter {
  ///Converted image from [ImagePainter] constructor.
  final Image? image;

  //Controller is a listenable with all of the paint details.
  late Controller _controller;

  ///Constructor for the canvas
  DrawImage({
    required Controller controller,
    this.image,
  }) : super(repaint: controller) {
    _controller = controller;
  }

  @override
  void paint(Canvas canvas, Size size) {
    ///paints [ui.Image] on the canvas for reference to draw over it.
    paintImage(
      canvas: canvas,
      image: image!,
      filterQuality: FilterQuality.high,
      rect: Rect.fromPoints(
        const Offset(0, 0),
        Offset(size.width, size.height),
      ),
    );

    ///paints all the previous paintInfo history recorded on [PaintHistory]
    for (final item in _controller.paintHistory) {
      final _offset = item.offsets;
      final _painter = item.paint;
      switch (item.mode) {
        case PaintMode.freeStyle:
          if (_painter.color == Colors.transparent) {
            _painter.isAntiAlias = true;
            _painter.blendMode = BlendMode.clear;
            _painter.style = PaintingStyle.stroke;
          }
          for (int i = 0; i < _offset.length - 1; i++) {
            if (_offset[i] != null && _offset[i + 1] != null) {
              final _path = Path()
                ..moveTo(_offset[i]!.dx, _offset[i]!.dy)
                ..lineTo(_offset[i + 1]!.dx, _offset[i + 1]!.dy);
              canvas.drawPath(_path, _painter..strokeCap = StrokeCap.round);
            } else if (_offset[i] != null && _offset[i + 1] == null) {
              canvas.drawPoints(PointMode.points, [_offset[i]!],
                  _painter..strokeCap = StrokeCap.round);
            }
          }
          break;
        default:
      }
    }

    ///Draws ongoing action on the canvas while in-drag.
    if (_controller.busy) {
      final _start = _controller.start;
      final _end = _controller.end;
      final _paint = _controller.brush;

      print('$_start, $_end, ${_paint.color}');
      switch (_controller.mode) {
        case PaintMode.freeStyle:
          if (_paint.color == Colors.transparent) {
            _paint.isAntiAlias = true;
            _paint.blendMode = BlendMode.clear;
            _paint.style = PaintingStyle.stroke;
          }
          final points = _controller.offsets;
          for (int i = 0; i < _controller.offsets.length - 1; i++) {
            if (points[i] != null && points[i + 1] != null) {
              canvas.drawLine(
                  Offset(points[i]!.dx, points[i]!.dy),
                  Offset(points[i + 1]!.dx, points[i + 1]!.dy),
                  _paint..strokeCap = StrokeCap.round);
            } else if (points[i] != null && points[i + 1] == null) {
              canvas.drawPoints(PointMode.points,
                  [Offset(points[i]!.dx, points[i]!.dy)], _paint);
            }
          }
          break;

        default:
      }
    }
  }

  @override
  bool shouldRepaint(DrawImage oldInfo) {
    return oldInfo._controller != _controller;
  }
}

///All the paint method available for use.

enum PaintMode {
  ///Prefer using [None] while doing scaling operations.
  none,

  ///Allows for drawing freehand shapes or text.
  freeStyle,
}

///[PaintInfo] keeps track of a single unit of shape, whichever selected.
class PaintInfo {
  ///Mode of the paint method.
  final PaintMode mode;

  //Used to save color
  final Color color;

  //Used to store stroke size of the mode.
  final double strokeWidth;

  ///Used to save offsets.
  ///Two point in case of other shapes and list of points for [FreeStyle].
  List<Offset?> offsets;

  Paint get paint => Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = shouldFill ? PaintingStyle.fill : PaintingStyle.stroke;

  bool get shouldFill {
    return false;
  }

  ///In case of string, it is used to save string value entered.
  PaintInfo({
    required this.mode,
    required this.offsets,
    required this.color,
    required this.strokeWidth,
  });
}
