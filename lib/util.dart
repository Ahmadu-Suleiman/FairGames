import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:vibration/vibration.dart';

void snackBar(BuildContext context, String message) => WidgetsBinding.instance
    .addPostFrameCallback((_) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.all(20))));

List<String> toList(dynamic data) {
  if (data is List<dynamic>) {
    return data.whereType<String>().toList();
  } else if (data is String) {
    return [data];
  } else {
    return [];
  }
}

void vibrate() async {
  if (await Vibration.hasVibrator() ?? false) Vibration.vibrate();
}

void showConfetti(BuildContext context) =>
    WidgetsBinding.instance.addPostFrameCallback((_) => Confetti.launch(context,
        options:
            const ConfettiOptions(particleCount: 100, spread: 70, y: 0.6)));
