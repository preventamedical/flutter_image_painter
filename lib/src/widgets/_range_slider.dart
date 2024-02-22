import 'package:flutter/material.dart';

///
class RangedSlider extends StatelessWidget {
  ///Range Slider widget for strokeWidth
  const RangedSlider({
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  ///Default value of strokewidth.
  final double value;

  /// Callback for value change.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider.adaptive(
      max: 2,
      min: 0.5,
      divisions: 4,
      value: value,
      onChanged: onChanged,
    );
  }
}
