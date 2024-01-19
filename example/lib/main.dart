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
  final _imageKey = GlobalKey<ImagePainterState>();

  void saveImage() async {
    final image = await _imageKey.currentState?.exportImage();
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
        url: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical.appspot.com/o/retinal_screenings%2F3_av.png?alt=media&token=64fc1907-5c14-459d-bcba-27711b466e9b',
        bgUrl: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical.appspot.com/o/retinal_screenings%2F3.png?alt=media&token=728ad0c5-1140-489f-80de-df4fcf49f0d4',
        key: _imageKey,
        scalable: true,
        initialStrokeWidth: 2,
        textDelegate: TextDelegate(),
        initialColor: Colors.green,
        initialPaintMode: PaintMode.freeStyle,
      ),
    );
  }
}
