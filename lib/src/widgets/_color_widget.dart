import 'package:flutter/material.dart';

class ColorItem extends StatelessWidget {
  const ColorItem({
    required this.color,
    required this.onTap,
    this.isSelected = false,
    Key? key,
  }) : super(key: key);

  final Color color;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white70 : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey[200]!,
            ),
          ),
          child: CircleAvatar(
              radius: isSelected ? 16 : 12, backgroundColor: color),
        ),
      ),
    );
  }
}

List<Color> editorColors = [
  const Color.fromARGB(0, 0, 0, 0),
  const Color.fromARGB(255, 255, 0, 0),
  const Color.fromARGB(255, 0, 255, 0),
  const Color.fromARGB(255, 0, 0, 255),
];
