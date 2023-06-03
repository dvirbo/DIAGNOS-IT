import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:canvas/models/CanvasPoint.dart';
import 'package:canvas/view/CanvasPainter.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Arguments class for passing data to the CanvasPage
class CanvasPageArguments {
  final String name;
  final int age;

  CanvasPageArguments({required this.name, required this.age});
}

class CanvasPage extends StatefulWidget {
  final CanvasPageArguments arguments;

  const CanvasPage({Key? key, required this.arguments}) : super(key: key);

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  ui.Image? _loadedImage; // New variable to store the preloaded image
  final canvasPoints = <CanvasPoint>[]; // List to store canvas points
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final sessionId = DateTime.now()
      .millisecondsSinceEpoch
      .toString(); // Unique session ID for file naming
  final GlobalKey _globalKey = GlobalKey();
  late StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late BehaviorSubject<AccelerometerEvent> _accelerometerSubject;

  String get name => widget.arguments.name; // Extracting name from arguments
  int get age => widget.arguments.age; // Extracting age from arguments

  late DateTime _startTime;
  double _lastTiltX = 0.0;
  double _lastTiltY = 0.0;
  int currentImageIndex = 0;
  bool isDrawingEnabled = false;
  bool isMouseHovering = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Preload the image when the page is initialized
    _preloadImage();

    _accelerometerSubject = BehaviorSubject.seeded(AccelerometerEvent(0, 0, 0));
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _accelerometerSubject.add(event);
    });
  }

// Function to preload the image from the database
  Future<void> _preloadImage() async {
    final imageUrls = await _getImageUrls();
    final currentImageUrl = imageUrls[currentImageIndex];
    _loadedImage = await loadImage(currentImageUrl);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Draw Shapes"),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.exit_to_app),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _getImageUrls(),
        builder: (context, snapshot) {
          if (_loadedImage == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final imageUrls = snapshot.data ?? [];
            return Column(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: Image.network(
                      imageUrls[currentImageIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        isDrawingEnabled = true;
                        canvasPoints.add(CanvasPoint(
                          offset: details.localPosition,
                          tiltX: 0.0,
                          tiltY: 0.0,
                        ));
                      });
                    },
                    onPanUpdate: (details) {
                      if (isDrawingEnabled) {
                        setState(() {
                          _lastTiltX = details.delta.dx;
                          _lastTiltY = details.delta.dy;
                          canvasPoints.add(CanvasPoint(
                            offset: details.localPosition,
                            tiltX: _lastTiltX,
                            tiltY: _lastTiltY,
                          ));
                        });
                      }
                    },
                    onPanEnd: (_) {
                      setState(() {
                        isDrawingEnabled = false;
                        canvasPoints.add(CanvasPoint(
                          offset: null,
                          tiltX: _lastTiltX,
                          tiltY: _lastTiltY,
                        ));
                      });
                    },
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: CustomPaint(
                            painter: CanvasPainter(
                              points: canvasPoints,
                              backgroundImage: _loadedImage!,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentImageIndex--;
                          if (currentImageIndex < 0) {
                            currentImageIndex = imageUrls.length - 1;
                          }
                          _preloadImage(); // Preload the new image
                          canvasPoints.clear(); // Clear the canvas points
                        });
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          isMouseHovering = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          isMouseHovering = false;
                        });
                      },
                      child: TextButton(
                        onPressed: () {
                          if (!isDrawingEnabled) {
                            _saveImage();
                          }
                        },
                        child: Text(isMouseHovering ? 'Save' : 'Click to save'),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentImageIndex++;
                          if (currentImageIndex >= imageUrls.length) {
                            currentImageIndex = 0;
                          }
                          _preloadImage(); // Preload the new image
                          canvasPoints.clear(); // Clear the canvas points
                        });
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<String> images = [];

  Future<List<String>> _getImageUrls() async {
    final storage = FirebaseStorage.instance;
    final storageRef = storage.ref().child('images');

    final ListResult result = await storageRef.listAll();
    final List<Reference> allFiles = result.items;

    final List<String> imageUrls = [];
    for (final file in allFiles) {
      final imageUrl = await file.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    return imageUrls;
  }

  Future<void> _saveImage() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final recorder = ui.PictureRecorder();
    final shape = await loadImage(images[currentImageIndex]);
    final double imageScale = imageSize.width / shape.width.toDouble();
    final double adjustedImageHeight = shape.height.toDouble() * imageScale;
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(
        0,
        0,
        imageSize.width,
        imageSize.height + adjustedImageHeight,
      ),
    );

    canvas.drawImageRect(
      shape,
      Rect.fromLTWH(0, 0, shape.width.toDouble(), shape.height.toDouble()),
      Rect.fromLTWH(0, 0, imageSize.width, adjustedImageHeight),
      Paint()..isAntiAlias = true,
    );

    canvas.drawImage(
      image,
      Offset(0, adjustedImageHeight),
      Paint(),
    );

    final picture = recorder.endRecording();
    image = await picture.toImage(
      imageSize.width.toInt(),
      (imageSize.height + adjustedImageHeight).toInt(),
    );

    byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    pngBytes = byteData!.buffer.asUint8List();

    final storage = FirebaseStorage.instance;
    final storageRef = storage
        .ref()
        .child('images/$sessionId/${images[currentImageIndex]}.png');
    await storageRef.putData(pngBytes);

    // Get the download URL of the uploaded image
    final imageUrl = await storageRef.getDownloadURL();
    print("Image URL: $imageUrl");
  }

  Future<ui.Image> loadImage(String imagePath) async {
    final completer = Completer<ui.Image>();
    final networkImage = NetworkImage(imagePath);

    final configuration = createLocalImageConfiguration(context);
    networkImage
        .resolve(configuration)
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }));

    return await completer.future;
  }

  Future<void> _saveCsvData(BuildContext context) async {
    if (canvasPoints.isNotEmpty) {
      try {
        String csvData =
            "Participant Name,Participant Age,X,Y,TiltX,TiltY,Time\n";
        for (CanvasPoint point in canvasPoints) {
          if (point.offset != null) {
            int ms = DateTime.now().difference(_startTime).inMilliseconds;
            csvData +=
                "$name,$age,${point.offset!.dx},${point.offset!.dy},${point.tiltX},${point.tiltY},$ms\n";
          }
        }

        final sessionDirectory = 'sessions/$sessionId';
        final imageName =
            images[currentImageIndex].split('/').last.split('.').first;
        final csvPath =
            '$sessionDirectory/${name}_${imageName}_drawing_data.csv';

        final storage = FirebaseStorage.instance;
        final storageRef = storage.ref().child(csvPath);
        final uploadTask =
            storageRef.putData(Uint8List.fromList(utf8.encode(csvData)));

        await uploadTask.whenComplete(() {
          const snackBar =
              SnackBar(content: Text("CSV data uploaded successfully!"));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      } catch (e) {
        print("Error: $e");
      }
    }
  }
}
