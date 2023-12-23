import 'dart:async';
import 'dart:io';

import 'package:ciclo_pomodoro/values/constants.dart';
import 'package:ciclo_pomodoro/widgets/break_time_indicator.dart';
import 'package:ciclo_pomodoro/widgets/focus_time_indicator.dart';
import 'package:ciclo_pomodoro/widgets/sound_preference.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:system_tray/system_tray.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
          colorScheme:
              ColorScheme.fromSwatch().copyWith(primary: primaryColor)),
      home: const MyHomePage(title: appName),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int focusCycle = 4;
  final int shortBreak = 5;
  final player = AudioPlayer();
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  final Uri sourceUri = Uri.parse(sourceUrl);

  int focusTime = 25;
  int currentFocus = 0;
  bool isShortBreak = false;
  bool isCompleted = false;
  Timer? cancellableTimer;
  List<double> focusTimeProgress = List.filled(4, 0);
  List<double> breakTimeProgress = List.filled(3, 0);

  void _toggleWakeLock(bool value) {
    bool canWakeLock = true;
    try {
      canWakeLock = !Platform.isLinux;
    } catch (e) {
      // Platform error
    }
    try {
      if (canWakeLock) Wakelock.toggle(enable: value);
    } catch (e) {
      // Wakelock error
    }
  }

  void _setFocusTime(int timeInMinutes) {
    setState(() {
      focusTime = timeInMinutes;
    });
    Navigator.pop(context);
  }

  Future<void> _playFocusStart() async {
    await player.play(AssetSource('blip.mp3'));
  }

  Future<void> _playFocusEnd() async {
    await player.play(AssetSource('achive.mp3'));
  }

  Future<void> _playCycleEnd() async {
    final soundPreferences = await prefs;
    final bool soundEnabled = soundPreferences.getBool(endSoundKey) ?? true;
    if (soundEnabled) await player.play(AssetSource('fantasia.mp3'));
  }

  Future<void> _playFail() async {
    final soundPreferences = await prefs;
    final bool soundEnabled = soundPreferences.getBool(stopSoundKey) ?? true;
    if (soundEnabled) await player.play(AssetSource('fail.wav'));
  }

  void _startFocus() {
    if (currentFocus == 0) _toggleWakeLock(true);

    setState(() {
      currentFocus++;
    });

    _playFocusStart();

    cancellableTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      int index = currentFocus - 1;
      double nextFocusTimeProgress = focusTimeProgress[index] + 1;

      if (nextFocusTimeProgress == focusTime) {
        timer.cancel();
        if (currentFocus < focusCycle) {
          _playFocusEnd();
          _startShortBreak();
        } else {
          _playCycleEnd();
          setState(() {
            isCompleted = true;
          });
          _toggleWakeLock(false);
        }
      }

      setState(() {
        focusTimeProgress[index] = nextFocusTimeProgress;
      });
    });
  }

  void _startShortBreak() {
    setState(() {
      isShortBreak = true;
    });

    cancellableTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      int index = currentFocus - 1;
      double nextBreakTimeProgress = breakTimeProgress[index] + 1;

      if (nextBreakTimeProgress == shortBreak) {
        timer.cancel();
        _startFocus();
        setState(() {
          isShortBreak = false;
        });
      }

      setState(() {
        breakTimeProgress[index] = nextBreakTimeProgress;
      });
    });
  }

  void _stopFocus({bool withSound = true}) {
    cancellableTimer?.cancel();

    setState(() {
      cancellableTimer = null;
      currentFocus = 0;
      isShortBreak = false;
      isCompleted = false;
      focusTimeProgress = List.filled(4, 0);
      breakTimeProgress = List.filled(3, 0);
    });

    if (withSound) _playFail();
  }

  double _getFocusProgress({required int index}) {
    return ((focusTimeProgress[index] * 100) / focusTime) / 100;
  }

  double _getBreakProgress({required int index}) {
    return ((breakTimeProgress[index] * 100) / shortBreak) / 100;
  }

  Future<void> initSystemTray() async {
    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: appName,
      iconPath: 'assets/tomato.png',
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: 'Começar',
          onClicked: (menuItem) => currentFocus == 0 ? _startFocus() : null),
      MenuItemLabel(
          label: 'Parar',
          onClicked: (menuItem) =>
              cancellableTimer != null && !isCompleted ? _stopFocus() : null),
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
    ]);

    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        appWindow.show();
      }
    });
  }

  @override
  void initState() {
    if (Platform.isLinux) initSystemTray();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4)),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '$focusTime min',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
                onPressed: () async {
                  await launchUrl(sourceUri);
                },
                icon: const Icon(
                  Icons.code,
                )),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Image.asset(
                      'assets/tomato.png',
                      width: 75,
                      height: 75,
                    ),
                  ),
                  const Text(
                    appName,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('15 minutos'),
              selected: focusTime == 15,
              textColor: primaryColor,
              selectedColor: Colors.white,
              selectedTileColor: primaryColor50,
              onTap: currentFocus != 0 ? null : () => _setFocusTime(15),
            ),
            ListTile(
              title: const Text('25 minutos (padrão)'),
              selected: focusTime == 25,
              textColor: primaryColor,
              selectedColor: Colors.white,
              selectedTileColor: primaryColor50,
              onTap: currentFocus != 0 ? null : () => _setFocusTime(25),
            ),
            ListTile(
              title: const Text('35 minutos'),
              selected: focusTime == 35,
              textColor: primaryColor,
              selectedColor: Colors.white,
              selectedTileColor: primaryColor50,
              onTap: currentFocus != 0 ? null : () => _setFocusTime(35),
            ),
            const SoundPreference(
              soundKey: stopSoundKey,
              label: 'Som ao parar',
            ),
            const SoundPreference(
              soundKey: endSoundKey,
              label: 'Som ao concluir',
            )
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15),
              child: Icon(
                isCompleted
                    ? Icons.done
                    : isShortBreak
                        ? Icons.pause_circle
                        : currentFocus > 0
                            ? Icons.timer
                            : Icons.timer_off,
                size: 60,
                color: isCompleted
                    ? Colors.green
                    : currentFocus > 0
                        ? Colors.primaries.first
                        : Colors.grey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Container(
                decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : currentFocus != 0
                            ? primaryColor50
                            : Colors.grey,
                    borderRadius: const BorderRadius.all(Radius.circular(6))),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    isShortBreak
                        ? '$currentFocusº intervalo 5min: Descanse, tome um café, uma água...'
                        : currentFocus == 0
                            ? 'Comece um ciclo Pomodoro!'
                            : isCompleted
                                ? 'Ciclo completo! Descanse 15min ou mais a cada ciclo.'
                                : '$currentFocusº tempo: Mantenha o foco!',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text(
                '$currentFocus / $focusCycle',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  FocusTimeIndicator(progress: _getFocusProgress(index: 0)),
                  BreakTimeIndicator(
                    progress: _getBreakProgress(index: 0),
                  ),
                  FocusTimeIndicator(progress: _getFocusProgress(index: 1)),
                  BreakTimeIndicator(
                    progress: _getBreakProgress(index: 1),
                  ),
                  FocusTimeIndicator(progress: _getFocusProgress(index: 2)),
                  BreakTimeIndicator(
                    progress: _getBreakProgress(index: 2),
                  ),
                  FocusTimeIndicator(progress: _getFocusProgress(index: 3))
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 7.5),
                  child: ElevatedButton(
                    onPressed: currentFocus == 0 ? _startFocus : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('Começar'), Icon(Icons.play_arrow)],
                    ),
                  ),
                )),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 15, left: 7.5),
                  child: ElevatedButton(
                    onPressed: cancellableTimer != null && !isCompleted
                        ? _stopFocus
                        : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('Parar'), Icon(Icons.stop)],
                    ),
                  ),
                )),
              ],
            ),
            if (isCompleted)
              Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: ElevatedButton(
                        onPressed: () => _stopFocus(withSound: false),
                        child: const Text('Ok')),
                  ))
                ],
              )
          ],
        )),
      ),
    );
  }
}
