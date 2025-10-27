import 'package:flutter/material.dart';
import 'prefs/theme_prefs.dart';
import 'screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = ThemePrefs();
  final dark = await prefs.getDarkMode();
  runApp(MyApp(initialDark: dark, prefs: prefs));
}


class MyApp extends StatefulWidget {
  final bool initialDark;
  final ThemePrefs prefs;
  const MyApp({super.key, required this.initialDark, required this.prefs});


  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  late bool _dark;


  @override
  void initState() {
    super.initState();
    _dark = widget.initialDark;
  }


  void _toggleTheme() async {
    setState(() => _dark = !_dark);
    await widget.prefs.setDarkMode(_dark);
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo 4 Persistence',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: _dark ? Brightness.dark : Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: const HomeScreen(),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                children: [
                  const ListTile(title: Text('Settings')),
                  SwitchListTile(
                    title: const Text('Dark mode'),
                    value: _dark,
                    onChanged: (_) => _toggleTheme(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}