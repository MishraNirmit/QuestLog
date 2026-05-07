import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/quest_provider.dart';
import 'screens/home_screen.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Text(
          "QuestLog Guardian\nApp Locked until tasks are 100% complete!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LockService.instance.initializeBackgroundService();

  // Always start the service unconditionally
  // The service itself will decide whether to lock the target app based on settings and completion status
  await LockService.instance.startMonitoring("", true);

  final provider = QuestProvider();
  await provider.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuestLog',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00FF00), // Neon Green
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF00),
          secondary: Color(0xFFFF0000), // Blood Red
        ),
        fontFamily: 'Roboto', // Replace with a Sci-Fi font later
      ),
      home: const HomeScreen(),
    );
  }
}
