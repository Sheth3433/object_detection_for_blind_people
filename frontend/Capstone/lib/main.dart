import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:capstone/services/voice_service.dart';
import 'package:capstone/utils/voice_command_handler.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'services/api_service.dart';
import 'services/tts_service.dart';
import 'services/app_prefs.dart';

import 'utils/access_button.dart';
import 'utils/route_observe.dart';
import 'utils/voice_helper.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  cameras = await availableCameras();
  await TtsService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool("isDarkMode") ?? true;

    setState(() {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      themeMode = (themeMode == ThemeMode.dark)
          ? ThemeMode.light
          : ThemeMode.dark;
    });

    await prefs.setBool("isDarkMode", themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      navigatorObservers: [routeObserver],

      // ✅ Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF7C78FF),
          unselectedItemColor: Colors.black54,
        ),
      ),

      // ✅ Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1F22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1F22),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1F22),
          selectedItemColor: Color(0xFF7C78FF),
          unselectedItemColor: Colors.white70,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ SPLASH SCREEN
//////////////////////////////////////////////////////////////
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => opacity = 1);
    });

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AIVisionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5D67B4),
                  Color(0xFF0B1A5A),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -120,
            child: Container(
              width: 350,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF07124A),
                borderRadius: BorderRadius.circular(200),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "VISION WALK",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Hello Aarjav",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ AI VISION SCREEN (BOTTOM NAV)
//////////////////////////////////////////////////////////////
class AIVisionScreen extends StatefulWidget {
  const AIVisionScreen({super.key});

  @override
  State<AIVisionScreen> createState() => _AIVisionScreenState();
}

class _AIVisionScreenState extends State<AIVisionScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDetectPage(),
      const AssistantPage(),
      const ActivityPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
        Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
        Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
        Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) async {
          setState(() => selectedIndex = index);

          const pages = ["Home", "Assistant", "Activity", "Settings"];
          await TtsService.speak("Opened ${pages[index]} page");
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy), label: "AI Assistant"),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ HELP PAGE
//////////////////////////////////////////////////////////////
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Help & Instructions",
          style: TextStyle(color: titleColor),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionTitle(context, "✅ Quick Start"),
          _infoCard(
            context,
            "1) Open Home screen\n"
                "2) Point camera towards object\n"
                "3) Use Torch if dark\n"
                "4) Switch camera if needed\n"
                "5) Go to AI Assistant for voice help",
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, "📸 Home Screen Controls"),
          _infoCard(
            context,
            "🎥 Camera Preview: shows live view\n"
                "🔄 Switch Camera Button: change front/back camera\n"
                "🔦 Torch Button: ON/OFF flash light\n"
                "📌 Tip: Keep phone steady for best detection",
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, "🧠 AI Assistant (Voice + Chat)"),
          _infoCard(
            context,
            "🎤 Mic Button: Speak your question\n"
                "📩 Send Button: Type and send message\n"
                "🔊 Voice Output: AI can speak answers\n"
                "✅ Example: 'What is in front of me?'",
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, "📅 Activity (Calendar + Tasks)"),
          _infoCard(
            context,
            "📆 Calendar: select a date\n"
                "➕ Add Task: write task and set reminder\n"
                "✅ Checkbox: mark task done\n"
                "🗑 Delete: remove task anytime",
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, "🔍 Detection Pages (Modes)"),
          _infoCard(
            context,
            "Your app also supports these detection modes:\n\n"
                "📝 Text Detection\n"
                "📄 Document Detection\n"
                "💵 Currency Detection\n"
                "🍱 Food Labels\n"
                "📍 Find Mode\n"
                "🖼 Image Mode",
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, "⚠️ Safety Tips"),
          _infoCard(
            context,
            "✅ Use app in safe place\n"
                "✅ Use earphones for clear voice\n"
                "❌ Do not use while crossing roads\n"
                "✅ Keep brightness medium for battery save",
          ),
          const SizedBox(height: 14),
          Text(
            "If you face any issue, restart the app ✅",
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoCard(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ Drawer Widget
//////////////////////////////////////////////////////////////
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final iconColor = Theme.of(context).iconTheme.color;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E4D6D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "VisionWalk",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            drawerItem(context, Icons.text_fields, "Text Detection",
                const TextDetectionPage(), iconColor, textColor),
            drawerItem(context, Icons.description, "Document Detection",
                const DocumentDetectionPage(), iconColor, textColor),
            drawerItem(context, Icons.currency_exchange, "Currency Detection",
                const CurrencyDetectionPage(), iconColor, textColor),
            drawerItem(context, Icons.qr_code_scanner, "Food Labels",
                const FoodLabelsPage(), iconColor, textColor),
            drawerItem(context, Icons.gps_fixed, "Find Mode", const FindModePage(),
                iconColor, textColor),
            drawerItem(context, Icons.image_outlined, "Image Detection",
                const ImageDetectionPage(), iconColor, textColor),
            Divider(color: Colors.grey.withOpacity(0.3)),
            drawerItem(context, Icons.help_outline, "Help & Instructions",
                const HelpPage(), iconColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(BuildContext context, IconData icon, String title,
      Widget page, Color? iconColor, Color? textColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: () async {
        await VoiceHelper.speakAction(title); // 🔊 added
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ Activity Storage
//////////////////////////////////////////////////////////////
class ActivityStorage {
  static const String key = "activity_list";

  static Future<void> addActivity(String objectName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    final data = {"object": objectName, "time": DateTime.now().toString()};

    list.insert(0, jsonEncode(data));
    await prefs.setStringList(key, list);
  }

  static Future<List<Map<String, dynamic>>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}

/////////////////////////////////////////////////////////////
// ✅ HOME CAMERA PAGE
//////////////////////////////////////////////////////////////
class HomeDetectPage extends StatefulWidget {
  const HomeDetectPage({super.key});

  @override
  State<HomeDetectPage> createState() => _HomeDetectPageState();
}

class _HomeDetectPageState extends State<HomeDetectPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  int cameraIndex = 0;
  bool isTorchOn = false;
  Timer? detectionTimer;
  bool isDetecting = false;
  String lastSpokenObject = "";
  String detectedText = "Scanning...";   // ⭐⭐⭐ STATE VARIABLE

  @override
  void initState() {
    super.initState();
    initCamera(cameraIndex);

    startRealtimeDetection();
  }
  void startRealtimeDetection() {
    detectionTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => captureFrameRealtime(),
    );
  }

  Future<void> toggleTorch() async {
    if (_controller == null) return;

    try {
      if (isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        isTorchOn = !isTorchOn;
      });

      // 🔊 GLOBAL TTS (respects language + voice enabled)
      await VoiceHelper.speakAction(
        isTorchOn ? "Torch on" : "Torch off",
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Torch not supported on this device")),
      );

      await VoiceHelper.speakAction("Torch not supported");
    }
  }


  Future<void> initCamera(int index) async {
    await _controller?.dispose();

    _controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();

    if (mounted) setState(() {});
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No second camera found")),
      );
      return;
    }

    cameraIndex = (cameraIndex == 0) ? 1 : 0;
    await initCamera(cameraIndex);
    await VoiceHelper.speakAction("Camera switched");
  }

  Future<void> captureFrameRealtime() async {

    if (_controller == null || isDetecting) return;

    try {
      isDetecting = true;

      await _initializeControllerFuture;

      final picture = await _controller!.takePicture();

      final result =
      await ApiService.sendImage(File(picture.path));

      /// ⭐ USE THIS IF BACKEND RETURNS top_object
      final detectedObject =
          result["top_object"] ?? "Nothing";

      if (detectedObject != lastSpokenObject) {

        lastSpokenObject = detectedObject;

        /// ⭐ UPDATE UI
        setState(() {
          detectedText = "Detected: $detectedObject";
        });

        /// ⭐ SPEAK
        await TtsService.speak(
          "Detected $detectedObject",
        );
      }

    } catch (e) {

      print("Realtime detection error: $e");
    }

    isDetecting = false;
  }

  @override
  void dispose() {
    detectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: iconColor),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          "AI Vision",
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: iconColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned.fill(child: Container(color: Colors.black.withAlpha(115))),

                Positioned(
                  bottom: 90,
                  right: 20,
                  child: AccessButton(
                    label: isTorchOn ? "Torch off" : "Torch on",
                    onPressed: toggleTorch,
                    child: FloatingActionButton(
                      backgroundColor:
                      isTorchOn ? Colors.orange : const Color(0xFF7C78FF),
                      onPressed: null,
                      child: Icon(
                        isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                    ),
                  ),

                ),

                Positioned(
                  bottom: 20,
                  right: 20,
                  child: AccessButton(
                    label: "Switch camera",
                    onPressed: switchCamera,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF7C78FF),
                      onPressed: null,
                      child: const Icon(Icons.cameraswitch, color: Colors.white),
                    ),
                  ),

                ),

                /// 🔥 REALTIME DETECT TEXT
                Positioned(
                  bottom: 140,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detectedText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C78FF)),
            );
          }
        },
      ),
    );
  }
}

class CapturedPreviewPage extends StatelessWidget {
  final String imagePath;

  const CapturedPreviewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Captured Image"),
        centerTitle: true,
      ),
      body: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
//////////////////////////////////////////////////////////////
// ✅ CAMERA TEMPLATE PAGE
//////////////////////////////////////////////////////////////
class CameraDetectionTemplatePage extends StatefulWidget {
  final String title;
  final String subtitle;

  const CameraDetectionTemplatePage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<CameraDetectionTemplatePage> createState() =>
      _CameraDetectionTemplatePageState();
}

class _CameraDetectionTemplatePageState
    extends State<CameraDetectionTemplatePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  int cameraIndex = 0;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    initCamera(cameraIndex);

    VoiceCommandHandler.onToggleTorch = toggleTorch;
    VoiceCommandHandler.onSwitchCamera = switchCamera;
    VoiceCommandHandler.onCapture = captureFrame;
  }

  Future<void> initCamera(int index) async {
    await _controller?.dispose();

    _controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No second camera found")),
      );
      return;
    }

    cameraIndex = (cameraIndex == 0) ? 1 : 0;
    await initCamera(cameraIndex);
  }

  Future<void> toggleTorch() async {
    if (_controller == null) return;

    try {
      if (isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        isTorchOn = !isTorchOn;
      });

      // 🔊 Speak AFTER state change
      await TtsService.speak(
        isTorchOn ? "Torch on" : "Torch off",
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Torch not supported on this device")),
      );

      await TtsService.speak("Torch not supported on this device");
    }
  }


  Future<void> captureFrame() async {
    if (_controller == null) return;

    try {
      await _initializeControllerFuture;

      final picture = await _controller!.takePicture();

      // 🔥 BACKEND CALL
      final result = await ApiService.captureDetect(File(picture.path));

      final String detectedObject = result["object"];

      // ✅ Save to local activity history
      await ActivityStorage.addActivity(detectedObject);

      // 🔊 VOICE OUTPUT (AFTER value exists)
      await TtsService.speak("Detected $detectedObject");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Detected: $detectedObject")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CapturedPreviewPage(imagePath: picture.path),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Detection failed ❌")),
      );
    }
  }

  @override
  void dispose() {
    VoiceCommandHandler.onToggleTorch = null;
    VoiceCommandHandler.onSwitchCamera = null;
    VoiceCommandHandler.onCapture = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title, style: TextStyle(color: titleColor)),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned.fill(child: Container(color: Colors.black.withAlpha(115))),

                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                // 📸 Capture Button (BOTTOM CENTER)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AccessButton(
                      label: "Capture image",
                      onPressed: captureFrame,
                      child: FloatingActionButton(
                        backgroundColor: const Color(0xFF7C78FF),
                        onPressed: captureFrame,
                        child: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),

                  ),
                ),


                Positioned(
                  bottom: 90,
                  right: 20,
                  child: AccessButton(
                    label: isTorchOn ? "Torch off" : "Torch on",
                    onPressed: toggleTorch,
                    child: FloatingActionButton(
                      backgroundColor:
                      isTorchOn ? Colors.orange : const Color(0xFF7C78FF),
                      onPressed: null,
                      child: Icon(
                        isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                    ),
                  ),


                ),

                Positioned(
                  bottom: 20,
                  right: 20,
                  child: AccessButton(
                    label: "Switch camera",
                    onPressed: switchCamera,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF7C78FF),
                      onPressed: null,
                      child: const Icon(Icons.cameraswitch, color: Colors.white),
                    ),
                  ),

                ),
              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C78FF)),
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ DETECTION PAGES
//////////////////////////////////////////////////////////////
class TextDetectionPage extends StatelessWidget {
  const TextDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Text Detection",
      subtitle: "Point camera at text (book/board) to read it.",
    );
  }
}

class DocumentDetectionPage extends StatelessWidget {
  const DocumentDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Document Detection",
      subtitle: "Keep document flat and capture properly.",
    );
  }
}

class CurrencyDetectionPage extends StatelessWidget {
  const CurrencyDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Currency Detection",
      subtitle: "Point camera at currency note for value detection.",
    );
  }
}

class FoodLabelsPage extends StatelessWidget {
  const FoodLabelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Food Labels",
      subtitle: "Point camera at food packet label to read details.",
    );
  }
}

class FindModePage extends StatelessWidget {
  const FindModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Find Mode",
      subtitle: "Move camera slowly to locate object direction.",
    );
  }
}

class ImageDetectionPage extends StatelessWidget {
  const ImageDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraDetectionTemplatePage(
      title: "Image Detection",
      subtitle: "Point camera at image to understand content.",
    );
  }
}

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

mixin SpeakOnPageOpen<T extends StatefulWidget> on State<T>
implements RouteAware {

  String get pageName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ✅ REQUIRED IMPLEMENTATIONS (EMPTY BUT VALID)

  @override
  void didPush() {
    TtsService.speak("Opened $pageName page");
  }

  @override
  void didPop() {}

  @override
  void didPopNext() {
    TtsService.speak("Back to $pageName page");
  }

  @override
  void didPushNext() {}
}
//////////////////////////////////////////////////////////////
// ✅ AI ASSISTANT PAGE (Same Feature)
//////////////////////////////////////////////////////////////
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> with SpeakOnPageOpen{
  @override
  String get pageName => "AI Assistant";
  final TextEditingController controller = TextEditingController();
  List<Map<String, String>> messages = [];

  get _speech => null;

  void sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      controller.clear();
    });

    try {
      final reply = await ApiService.sendChatMessage(text);

      setState(() {
        messages.add({"role": "ai", "text": reply});
      });

      // 🔊 SPEAK AI RESPONSE
      await TtsService.speak(reply);

    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "text": "Backend not responding ❌"
        });
      });

      // 🔊 SPEAK ERROR
      await TtsService.speak("Backend not responding");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text("AI Assistant", style: TextStyle(color: titleColor)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF7C78FF)
                          : const Color(0xFF2B2C31),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "You" : "AI Assistant",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg["text"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1F22),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type your query or instruction...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF7C78FF),
                  child: AccessButton(
                    label: "Microphone",
                    onPressed: () async {
                      bool available = await VoiceService.init();
                      print("Speech available: $available");

                      if (available) {
                        await VoiceService.startListening((command) async {
                          await VoiceCommandHandler.handle(command);
                          //await VoiceService.stopListening();
                          Future<void> startListening(Function(String) onResult) async {
                            await _speech.listen(
                              onResult: (result) {
                                if (result.finalResult) {
                                  onResult(result.recognizedWords.toLowerCase());
                                }
                              },
                              listenMode: ListenMode.confirmation,
                              partialResults: false,
                              cancelOnError: false,
                            );
                          }
                        });
                      }
                    },
                    child: IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.mic, color: Colors.white),
                    ),
                  ),

                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white10,
                  child: AccessButton(
                    label: "Send message",
                    onPressed: sendMessage,
                    child: IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//////////////////////////////////////////////////////////////
// ✅ Calendar Storage (Same Feature)
//////////////////////////////////////////////////////////////
class CalendarTaskStorage {
  static const String key = "calendar_tasks";

  static String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    return jsonDecode(raw);
  }

  static Future<void> addTask({
    required DateTime date,
    required String task,
    DateTime? reminderTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll();

    final dKey = _dateKey(date);
    all[dKey] = all[dKey] ?? [];

    all[dKey].add({
      "title": task,
      "done": false,
      "reminder": reminderTime?.toString(),
    });

    await prefs.setString(key, jsonEncode(all));
  }

  static Future<List<Map<String, dynamic>>> getTasks(DateTime date) async {
    final all = await _loadAll();
    final dKey = _dateKey(date);
    if (all[dKey] == null) return [];
    return List<Map<String, dynamic>>.from(all[dKey]);
  }

  static Future<void> toggleDone(DateTime date, int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll();

    final dKey = _dateKey(date);
    if (all[dKey] == null) return;

    all[dKey][index]["done"] = value;

    await prefs.setString(key, jsonEncode(all));
  }

  static Future<void> deleteTask(DateTime date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAll();

    final dKey = _dateKey(date);
    if (all[dKey] == null) return;

    all[dKey].removeAt(index);

    await prefs.setString(key, jsonEncode(all));
  }
}

//////////////////////////////////////////////////////////////
// ✅ ACTIVITY PAGE (Same Feature)
//////////////////////////////////////////////////////////////
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> detectedHistory = [];

  final TextEditingController taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadAll();
  }


  Future<void> loadAll() async {
    tasks = await CalendarTaskStorage.getTasks(selectedDay);
    detectedHistory = await ActivityStorage.getActivities();
    setState(() {});
  }

  Future<void> addTaskWithReminder() async {
    final text = taskController.text.trim();
    if (text.isEmpty) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    DateTime? reminderDateTime;
    if (pickedTime != null) {
      reminderDateTime = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }

    await CalendarTaskStorage.addTask(
      date: selectedDay,
      task: text,
      reminderTime: reminderDateTime,
    );

    taskController.clear();
    await loadAll();
    await TtsService.speak(
      "Task added on ${selectedDay.day}/${selectedDay.month} at "
          "${pickedTime?.hour}:${pickedTime?.minute}. Task is $text",
    );

  }

  String formatTime(String time) {
    final dt = DateTime.tryParse(time);
    if (dt == null) return time;

    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final hour = h == 0 ? 12 : h;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:$min $ampm";
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).appBarTheme.foregroundColor;
    final iconColor = Theme.of(context).iconTheme.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text("Activity", style: TextStyle(color: titleColor)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: iconColor),
            onPressed: loadAll,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) async {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                      await loadAll();
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF7C78FF),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detected Objects History 👁️",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: detectedHistory.isEmpty
                            ? Text(
                          "No detected history yet...",
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        )
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: detectedHistory.length > 10
                              ? 10
                              : detectedHistory.length,
                          itemBuilder: (context, index) {
                            final item = detectedHistory[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF444469),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${item["object"]}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatTime(item["time"]),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: taskController,
                        decoration: InputDecoration(
                          hintText: "Add task for the day...",
                          filled: true,
                          fillColor: Theme.of(context)
                              .cardColor
                              .withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AccessButton(
                      label: "Add task",
                      onPressed: addTaskWithReminder,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C78FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: null,
                        child: const Icon(Icons.alarm_add),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 320,
                  child: tasks.isEmpty
                      ? Text(
                    "No tasks for this day ✅",
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.8),
                    ),
                  )
                      : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      final bool done = item["done"] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .cardColor
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: done,
                              activeColor: const Color(0xFF7C78FF),
                              onChanged: (val) async {
                                await CalendarTaskStorage.toggleDone(
                                  selectedDay,
                                  index,
                                  val ?? false,
                                );
                                await loadAll();
                              },
                            ),
                            Expanded(
                              child: Text(
                                "${item["title"]}",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontSize: 16,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                            AccessButton(
                              label: "Delete task",
                              onPressed: () async {
                                await CalendarTaskStorage.deleteTask(selectedDay, index);
                                await loadAll();
                              },
                              child: const Icon(Icons.delete, color: Colors.redAccent),
                            ),

                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ SETTINGS PAGE (Only Theme Switch Same Feature)
//////////////////////////////////////////////////////////////
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool voiceOutput = true;
  bool vibrationAlert = true;

  // ✅ NEW: Selected Language
  String selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    selectedLanguage = await AppPrefs.getLanguage();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final bool isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    const SizedBox(width: 10),
                    Text(
                      isDark ? "Dark Mode" : "Light Mode",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  onChanged: (val) async {
                    await appState.toggleTheme();
                    await TtsService.speak(
                      val ? "Dark mode enabled" : "Light mode enabled",
                    );
                  },

                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _settingSwitchTile(
            icon: Icons.volume_up,
            title: "Voice Output",
            subtitle: voiceOutput ? "ON" : "OFF",
            value: voiceOutput,
            onChanged: (val) async {
              setState(() => voiceOutput = val);
              await AppPrefs.setVoiceEnabled(val);

              await TtsService.speak(
                val ? "Voice output enabled" : "Voice output disabled",
              );
            },

          ),

          _settingSwitchTile(
            icon: Icons.vibration,
            title: "Vibration Alert",
            subtitle: vibrationAlert ? "ON" : "OFF",
            value: vibrationAlert,
            onChanged: (val) async {
              setState(() => vibrationAlert = val);
              await VoiceHelper.speakAction(val ? "Vibration on" : "Vibration off");

              await TtsService.speak(
                val ? "Vibration On" : "Vibration Off",
              );
            },

          ),

          const SizedBox(height: 14),

          _settingButtonTile(
            icon: Icons.text_increase,
            title: "Text Size",
            subtitle: "Medium",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Text Size option coming soon ✅")),
              );
            },
          ),

          // ✅ UPDATED: Voice Language Dropdown inside tile
          _settingButtonTile(
            icon: Icons.record_voice_over,
            title: "Voice Language",
            subtitle: selectedLanguage,
            onTap: () {}, // no need tap
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                DropdownMenuItem(value: "Gujarati", child: Text("Gujarati")),
              ],
              onChanged: (val) async {
                if (val == null) return;

                setState(() => selectedLanguage = val);
                await TtsService.changeLanguage(val);

                await TtsService.speak(
                  val == "Hindi"
                      ? "भाषा बदल दी गई है"
                      : val == "Gujarati"
                      ? "ભાષા બદલાઈ ગઈ છે"
                      : "Language changed successfully",
                );
              },


            ),
          ),

          _settingButtonTile(
            icon: Icons.security,
            title: "Privacy & Permissions",
            subtitle: "Camera, Mic",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Permissions page coming soon ✅")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ✅ UPDATED: trailing optional added
  Widget _settingButtonTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),

            // ✅ if dropdown exists show it, else show arrow
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}