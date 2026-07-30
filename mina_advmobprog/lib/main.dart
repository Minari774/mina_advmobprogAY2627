import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// entry point of the app
// wrapped with ChangeNotifierProvider so ThemeModel can be
// accessed anywhere in the app
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ), // ChangeNotifierProvider
  );
}

// root widget of the app
// just checks the theme from Provider and builds the MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(), // starts on the counter screen
    ); // MaterialApp
  }
}

// this is our app state (shared state using Provider)
// keeps track if dark mode is on or off
class ThemeModel with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  // switches the theme and tells all widgets listening to rebuild
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// Screen 1: Counter
// uses setState (ephemeral state), only this screen knows about _counter
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // local state, only exists here

  // adds 1 to counter and rebuilds the widget
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          // button to go to the theme toggle screen
          IconButton(
            icon: const Icon(Icons.settings_brightness),
            tooltip: 'Go to theme settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHome()),
              );
            },
          ), // IconButton
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Text
          ], // <Widget>[]
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}

// Screen 2: Theme toggle
// uses Provider (app state), shared with the rest of the app
class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
        actions: [
          // switch to toggle dark mode on/off
          Switch(
            value: themeModel.isDark,
            onChanged: (_) => themeModel.toggleTheme(),
          ), // Switch
        ],
      ), // AppBar
      body: Center(
        child: const Text('Toggle the theme using the switch in the app bar.'),
      ), // Center
    ); // Scaffold
  }
}

