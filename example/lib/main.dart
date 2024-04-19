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
    await FileSaver.instance.saveFile(name: 'image.jpg', bytes: image);

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
        vesselsImageUrl: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical-ai.appspot.com/o/retinal_screenings%2Foptos%2Fpredicted_vessel_maps%2F20230406_132955.jpg?alt=media&token=ac307754-56a9-47ba-815f-351a16f30a8b',
        fundusImageUrl: 'https://firebasestorage.googleapis.com/v0/b/preventa-medical.appspot.com/o/retinal_screenings%2F3.png?alt=media&token=728ad0c5-1140-489f-80de-df4fcf49f0d4',
        key: _imageKey,
        scalable: true,
        initialStrokeWidth: 2,
        textDelegate: TextDelegate(),
        initialColor: Colors.green,
        initialPaintMode: PaintMode.freeStyle,
        onSubmitted: () => print('test'),
        toolbar:

        Row(children: [
          MaterialButton(child: const Text("Submit"), onPressed: () => print('Submit')),
          MaterialButton(child: const Text("Cancel"), onPressed: () => print('Cancel')),
          MaterialButton(child: const Text("Save"),onPressed: () { print('Save'); },),

        ],)
      ),
    );
  }
}
