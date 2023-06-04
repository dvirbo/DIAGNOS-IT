import 'package:canvas/canvas_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Rest of your code...

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw Shapes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const HomePage());
        } else if (settings.name == '/canvas') {
          final args = settings.arguments as CanvasPageArguments;
          return MaterialPageRoute(
            builder: (context) => CanvasPage(arguments: args),
          );
        }
        return null; // Add this line to handle unknown routes
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool buttonEnabled = false;

  @override
  void initState() {
    nameController.addListener(() {
      checkFieldsNotEmpty();
    });
    ageController.addListener(() {
      checkFieldsNotEmpty();
    });
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void checkFieldsNotEmpty() {
    setState(() {
      buttonEnabled =
          nameController.text.isNotEmpty && ageController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Age',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: buttonEnabled
                  ? () {
                      Navigator.pushNamed(
                        context,
                        '/canvas',
                        arguments: CanvasPageArguments(
                          name: nameController.text,
                          age: int.tryParse(ageController.text) ?? 0,
                        ),
                      );
                    }
                  : null,
              child: const Text('Draw Shapes'),
            ),
          ],
        ),
      ),
    );
  }
}
