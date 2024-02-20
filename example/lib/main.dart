import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Painter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ImagePainterExample(),
    );
  }
}

class ImagePainterExample extends StatefulWidget {
  @override
  _ImagePainterExampleState createState() => _ImagePainterExampleState();
}

class _ImagePainterExampleState extends State<ImagePainterExample> {
  final imageKey = GlobalKey<ImagePainterState>();

  void saveImage() async {
    final image = await imageKey.currentState?.controller.exportImage();
    await FileSaver.instance.saveFile(name: 'image.png', bytes: image);

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[700],
          padding: const EdgeInsets.only(left: 10),
          content: const Text("Image Exported successfully.",
                  style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Painter Example"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: saveImage,
          )
        ],
      ),
      body: ImagePainter.network(
        key: imageKey,
        vesselsImageUrl: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical.appspot.com/o/retinal_screenings%2F3_av.png?alt=media&token=64fc1907-5c14-459d-bcba-27711b466e9b',
        fundusImageUrl: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical.appspot.com/o/retinal_screenings%2F3.png?alt=media&token=728ad0c5-1140-489f-80de-df4fcf49f0d4',
        scalable: true,
        initialStrokeWidth: 2,
        initialColor: Colors.green,
        initialPaintMode: PaintMode.freeStyle,
      ),
    );
  }
/*
  PopupMenuItem _showOptionsRow() {
    TextDelegate textDelegate;

    final controller = imageKey.currentState?.controller;
    return PopupMenuItem(
      enabled: false,
      child: Center(
        child: SizedBox(
          child: Wrap(
            children: paintModes(textDelegate)
                .map(
                  (item) => SelectionItems(
                data: item,
                isSelected: controller?.mode == item.mode,
                selectedColor: widget.optionSelectedColor,
                unselectedColor: widget.optionUnselectedColor,
                onTap: () {
                  if (widget.onPaintModeChanged != null) {
                    widget.onPaintModeChanged!(item.mode);
                  }
                  controller?.setMode(item.mode);

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
          animation: controller,
          builder: (_, __) {
            return RangedSlider(
              value: controller.strokeWidth,
              onChanged: (value) {
                controller.setStrokeWidth(value);
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
              isSelected: color == controller.color,
              color: color,
              onTap: () {
                controller.setColor(color);
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

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.grey[200],
      child: Row(
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final icon = paintModes(textDelegate)
                  .firstWhere((item) => item.mode == controller.mode)
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
            animation: controller,
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
                        color: controller.color,
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
          MaterialButton(
              child: const Text("Submit"), onPressed: widget.onSubmitted),
          MaterialButton(
              child: const Text("Cancel"), onPressed: widget.onCancelled),

          MaterialButton(
              child: const Text("Erase All"), onPressed: ()
          async {
            controller.vesselsImage = await controller.clearVessels(controller.vesselsImage!);
          }),

          const Spacer(),
          IconButton(
            tooltip: textDelegate.undo,
            icon: widget.undoIcon ?? Icon(Icons.reply, color: Colors.grey[700]),
            onPressed: () {
              //widget.onUndo?.call();
              controller.undo();
            },
          ),
          IconButton(
            icon: Icon(Icons.display_settings, color: Colors.grey[700]),
            onPressed: () {
              controller.isDisplayed.value = !controller.isDisplayed.value;
            },
          ),
          IconButton(
            tooltip: textDelegate.clearAllProgress,
            icon: widget.clearAllIcon ??
                Icon(Icons.clear, color: Colors.grey[700]),
            onPressed: () {
              //widget.onClear?.call();
              controller.clear();
            },
          ),
        ],
      ),
    );
  }*/

}
