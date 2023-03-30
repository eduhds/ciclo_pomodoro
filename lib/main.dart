import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ciclo Pomodoro',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color.fromRGBO(222, 0, 38, 1.0), // #de0026
      )),
      home: const MyHomePage(title: 'Ciclo Pomodoro'),
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
  final int focusTime = 25;
  final int focusCycle = 4;
  final int shortBreak = 5;
  final player = AudioPlayer();

  int currentFocus = 0;
  bool isShortBreak = false;
  bool isCompleted = false;
  Timer? cancellableTimer;
  List<double> focusTimeProgress = List.filled(4, 0);
  List<double> breakTimeProgress = List.filled(3, 0);

  Future<void> _playFocusStart() async {
    await player.play(AssetSource('blip.mp3'));
  }

  Future<void> _playFocusEnd() async {
    await player.play(AssetSource('achive.mp3'));
  }

  Future<void> _playFail() async {
    await player.play(AssetSource('fail.wav'));
  }

  void _startFocus() {
    setState(() {
      currentFocus++;
    });

    _playFocusStart();

    cancellableTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      int index = currentFocus - 1;
      double nextFocusTimeProgress = focusTimeProgress[index] + 1;

      if (nextFocusTimeProgress == focusTime) {
        timer.cancel();
        _playFocusEnd();
        if (currentFocus < focusCycle) {
          _startShortBreak();
        } else {
          setState(() {
            isCompleted = true;
          });
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
            Text(
              '$currentFocus',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'Pomodoro${isShortBreak ? " (Intervalo)" : ""}',
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [Text('Começar'), Icon(Icons.play_arrow)],
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [Text('Parar'), Icon(Icons.stop)],
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

class FocusTimeIndicator extends StatelessWidget {
  const FocusTimeIndicator({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey,
      valueColor: AlwaysStoppedAnimation(Colors.primaries.first),
    ));
  }
}

class BreakTimeIndicator extends StatelessWidget {
  const BreakTimeIndicator({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 2,
          value: progress,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation(Colors.primaries.first),
        ),
        Icon(
          progress >= 1 ? Icons.alarm_on : Icons.alarm,
          color: progress >= 1 ? Colors.primaries.first : Colors.grey,
        )
      ],
    );
  }
}
