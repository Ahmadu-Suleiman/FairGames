import 'package:fairgames/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Games Catalog')),
        body: ListView(padding: const EdgeInsets.all(8), children: [
          ListTile(
              tileColor: Theme.of(context).colorScheme.secondaryContainer,
              leading: const Icon(Icons.grid_view),
              title: const Text('Tic Tac Toe'),
              onTap: () => context.push(Routes.tictactoe))
        ]));
  }
}
