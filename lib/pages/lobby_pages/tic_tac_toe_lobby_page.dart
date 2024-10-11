import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/routes.dart';
import 'package:fairgames/util.dart';
import 'package:fairgames/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../models/player.dart';

class TicTacToeLobbyPage extends StatefulWidget {
  const TicTacToeLobbyPage({super.key});

  @override
  State<TicTacToeLobbyPage> createState() => _TicTacToeLobbyPageState();
}

class _TicTacToeLobbyPageState extends State<TicTacToeLobbyPage> {
  final logger = Logger();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firestore.player(Authentication.userId),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.hasData) {
            return loading
                ? const Loading()
                : Scaffold(
                    appBar: AppBar(title: const Text('Lobby')),
                    body: StreamBuilder(
                        stream: Firestore.lobbiesStream(),
                        builder: (context, snapshot) {
                          final player = futureSnapshot.data;

                          Future.microtask(() {
                            if (player != null &&
                                player.tictactoe.isNotEmpty &&
                                context.mounted) {
                              context.push(
                                  '${Routes.tictactoe}/${player.tictactoe}');
                            }
                          });

                          if (snapshot.hasData) {
                            final lobbies =
                                Firestore.lobbyListFromSnapshot(snapshot.data!);

                            return lobbies.isEmpty
                                ? Center(
                                    child: TextButton(
                                        onPressed: createLobbyDialog,
                                        child: const Text('Add a new lobby')))
                                : ListView.builder(
                                    itemCount: lobbies.length,
                                    itemBuilder: (context, index) {
                                      final lobby = lobbies[index];
                                      return ListTile(
                                          leading: const Icon(Icons.room),
                                          title: Text(lobby.name),
                                          subtitle: Text(
                                              '${lobby.players.length}/${2}'),
                                          onTap: () =>
                                              showJoinDialog(lobby, player!));
                                    });
                          } else {
                            logger.e(snapshot.stackTrace);
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        }),
                    floatingActionButton: FloatingActionButton(
                        onPressed: createLobbyDialog,
                        tooltip: 'Create New Lobby',
                        child: const Icon(Icons.add)));
          } else {
            return const Loading();
          }
        });
  }

  Future<void> createLobbyDialog() async {
    final controller = TextEditingController();
    if (context.mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('Create Lobby'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter lobby name', labelText: 'Lobby name')),
                actions: <Widget>[
                  TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop()),
                  TextButton(
                      onPressed: controller.text.isNotEmpty
                          ? null
                          : () {
                              Firestore.addLobby(
                                  name: controller.text,
                                  playerId: Authentication.user!.uid);
                              Navigator.of(context).pop();
                            },
                      child: const Text('Create'))
                ]);
          });
    }
  }

  Future<void> showJoinDialog(Lobby lobby, Player player) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Join Lobby?'),
              content: Text('Are you sure you want to join "${lobby.name}"?'),
              actions: <Widget>[
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop()),
                TextButton(
                    child: const Text('Yes'),
                    onPressed: () async {
                      if (lobby.players.length > 1) {
                        Navigator.of(context).pop();
                        snackBar(context, 'lobby already full!');
                      } else {
                        Navigator.of(context).pop();
                        setState(() => loading = true);
                        await Firestore.joinLobby(
                            lobbyId: lobby.id,
                            playerId: Authentication.user!.uid);
                        player.tictactoe = lobby.id;
                        await Firestore.setActiveTicTacToe(player);
                        setState(() => loading = false);
                      }
                    })
              ]);
        });
  }
}
