import 'package:flutter/material.dart';

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
