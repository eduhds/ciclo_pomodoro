import 'package:ciclo_pomodoro/values/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundPreference extends StatefulWidget {
  const SoundPreference(
      {super.key, required this.soundKey, required this.label});

  final String soundKey;
  final String label;

  @override
  State<SoundPreference> createState() => _SoundPreferenceState();
}

class _SoundPreferenceState extends State<SoundPreference> {
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  late Future<bool> soundEnabled;

  Future<void> _setSoundPreference(bool value) async {
    final soundPrefs = await prefs;
    setState(() {
      soundEnabled =
          soundPrefs.setBool(widget.soundKey, value).then((success) => value);
    });
  }

  @override
  void initState() {
    super.initState();
    soundEnabled = prefs.then((value) {
      return value.getBool(widget.soundKey) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(widget.label),
        FutureBuilder<bool>(
            future: soundEnabled,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Padding(
                    padding: EdgeInsets.all(5),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                case ConnectionState.active:
                case ConnectionState.done:
                  return Switch(
                      value: snapshot.data ?? true,
                      activeColor: primaryColor,
                      onChanged: (value) => _setSoundPreference(value));
              }
            })
      ],
    );
  }
}
