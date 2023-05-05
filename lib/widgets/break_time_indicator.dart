import 'package:flutter/material.dart';

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
