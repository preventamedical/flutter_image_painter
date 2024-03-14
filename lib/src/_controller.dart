import 'package:flutter/material.dart';

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
    if(paintInfo.offsets.length > 5) _paintHistory.add(paintInfo);
    //notifyListeners();
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
}