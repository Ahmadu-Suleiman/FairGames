import 'package:flutter/material.dart';

void snackBar(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.all(20)));

void showAfterBuild(BuildContext context, Function function) =>
    Future.microtask(() {
      if (context.mounted) function;
    });

List<String> toList(dynamic data) {
  if (data is List<dynamic>) {
    return data.whereType<String>().toList();
  } else if (data is String) {
    return [data];
  } else {
    return [];
  }
}
