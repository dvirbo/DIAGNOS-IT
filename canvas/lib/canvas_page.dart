import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:canvas/models/CanvasPoint.dart';
import 'package:canvas/view/CanvasPainter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:collection'; // For SplayTreeMap
import 'package:flutter/cupertino.dart';


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

  Offset getCanvasOffset(Offset offset, Size size) {
    // Calculate the canvas offset based on the image size and canvas size
    double canvasWidth = _loadedImage!.width.toDouble();
    double canvasHeight = _loadedImage!.height.toDouble();
    double scaleFactor = size.width / canvasWidth;
    double canvasOffsetX = (size.width - canvasWidth * scaleFactor) / 2;
    double canvasOffsetY = (size.height - canvasHeight * scaleFactor) / 2;

    // Adjust the offset based on the canvas offset
    return Offset(
      (offset.dx - canvasOffsetX) / scaleFactor,
      (offset.dy - canvasOffsetY) / scaleFactor,
    );
  }

// Function to preload the image from the database
  final _imageCache = SplayTreeMap<int, ui.Image>();

  Future<void> _preloadImage() async {
    final imageUrls = await _getImageUrls();
    final currentImageUrl = imageUrls[currentImageIndex];

    // Check the cache for the requested image
    if (_imageCache.containsKey(currentImageUrl.hashCode)) {
      _loadedImage = _imageCache[currentImageUrl.hashCode];
      return;
    }

    _loadedImage = await loadImage(currentImageUrl);

    // Add the downloaded image to the cache and ensure the cache size is capped at 10
    _imageCache[currentImageUrl.hashCode] = _loadedImage!;
    if (_imageCache.length > 10) {
      _imageCache.remove(_imageCache.firstKey());
    }
  }

  void _clearCanvas() {
    setState(() {
      canvasPoints.clear();
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubject.close();
    super.dispose();
  }

  double canvasOffsetX = 0.0;
  double canvasOffsetY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Draw Shapes"),
        actions: [
          IconButton(
            onPressed: _clearCanvas,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Canvas',
          ),
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
                    child: Center(
                      child: Image.network(
                        imageUrls[currentImageIndex],
                        fit: BoxFit.contain,
                      ),
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
                          offset: getCanvasOffset(details.localPosition,
                              MediaQuery.of(context).size),
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
                            offset: getCanvasOffset(details.localPosition,
                                MediaQuery.of(context).size),
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

/*
The _saveCsvData() method is responsible for saving the drawing data in CSV format to Firebase storage.
Its primary function is to:
Prepare a CSV formatted string containing the drawing data. 
This includes the participant's name, age, X and Y coordinates of every drawn point, TiltX and TiltY (the delta values in both directions), and the time.
Define the CSV file's path in Firebase Storage using the session ID, user name, and image name.
Upload the CSV file to Firebase Storage under the defined path.
This method is called within the _saveImage() method to upload the CSV file to Firebase Storage when a user saves their drawing.
*/

  Future<void> _saveImage() async {
    // First, get the screenshot of the drawing and existing image
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image screenshot = await boundary.toImage();

    // Save the screenshot to Firebase Storage under the user's name folder
    ByteData? byteData =
        await screenshot.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final storage = FirebaseStorage.instance;
    final userFolderRef = storage
        .ref()
        .child('users_data/$name'); // Create a reference to the user's folder
    final sessionId = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Generate a unique session ID
    final screenshotStorageRef = userFolderRef
        .child('$sessionId/screenshot.png'); // Define the screenshot path

    await screenshotStorageRef.putData(pngBytes);

    // Get the download URL of the uploaded screenshot
    final screenshotUrl = await screenshotStorageRef.getDownloadURL();
    print("Screenshot URL: $screenshotUrl");

    // Save the CSV Data to Firebase Storage under the user's name folder
    await _saveCsvData(userFolderRef
        .child('$sessionId/drawing_data.csv')); // Pass the CSV file path
  }

  Future<void> _saveCsvData(Reference csvStorageRef) async {
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

        final uploadTask =
            csvStorageRef.putData(Uint8List.fromList(utf8.encode(csvData)));

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

Future<ui.Image> loadImage(String imagePath) async {
    final completer = Completer<ui.Image>();
    final networkImage = NetworkImage(imagePath);

    final configuration = createLocalImageConfiguration(context);
    final resolvedStream = networkImage.resolve(configuration);

    resolvedStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }));

    return await completer.future;
  }


}
