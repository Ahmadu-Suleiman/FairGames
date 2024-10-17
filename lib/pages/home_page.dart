import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/player.dart';
import 'package:fairgames/routes.dart';
import 'package:fairgames/util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    checkPlayer();
  }

  Future<void> checkPlayer() async {
    final player = await Firestore.player(Authentication.user!.uid);
    if (player == null && mounted) {
      showAddPlayerDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text('Games Catalog')),
        body: Builder(builder: (context) {
          return ListView(padding: const EdgeInsets.all(8), children: [
            ListTile(
                tileColor: Theme.of(context).colorScheme.secondaryContainer,
                leading: const Icon(Icons.grid_view),
                title: const Text('Tic Tac Toe'),
                subtitle: const Text('Play with a friend online'),
                onTap: () => context.push(Routes.tictactoeLobby))
          ]);
        }));
  }

  Future<void> showAddPlayerDialog() async {
    final controller = TextEditingController();
    if (context.mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('Create Player account'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter player name',
                        labelText: 'Player name')),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          Navigator.of(context).pop();
                          Firestore.createPlayer(Player(
                              id: Authentication.user!.uid,
                              username: controller.text,
                              tictactoe: ''));
                        } else {
                          snackBar(context, 'Name cannot be empty');
                        }
                      },
                      child: const Text('Create'))
                ]);
          });
    }
  }
}
