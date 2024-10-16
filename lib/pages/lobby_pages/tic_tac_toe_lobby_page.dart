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
  late Player player;
  final logger = Logger();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firestore.player(Authentication.userId),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.hasData) {
            player = futureSnapshot.data!;

            if (player.tictactoe.isNotEmpty && context.mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) =>
                  context.push('${Routes.tictactoe}/${player.tictactoe}'));
            }

            return loading
                ? const Loading()
                : Scaffold(
                    appBar: AppBar(title: const Text('Lobby')),
                    body: StreamBuilder(
                        stream: Firestore.lobbiesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final lobbies =
                                Firestore.lobbyListFromSnapshot(snapshot.data!);

                            return lobbies.isEmpty
                                ? Center(
                                    child: TextButton(
                                        onPressed: createLobbyDialog,
                                        child: const Text('Add a new lobby')))
                                : ListView.separated(
                                    itemCount: lobbies.length,
                                    itemBuilder: (context, index) {
                                      final lobby = lobbies[index];
                                      return ListTile(
                                          leading: const Icon(Icons.room),
                                          title: Text(lobby.name),
                                          subtitle: Text(
                                              '${lobby.players.length}/${2}'),
                                          onTap: () =>
                                              showJoinDialog(lobby, player));
                                    },
                                    separatorBuilder: (_, index) =>
                                        const Divider());
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
                          : () => createLobby(context, controller),
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
                    child: const Text('Yes'), onPressed: () => joinLobby(lobby))
              ]);
        });
  }

  void createLobby(
      BuildContext context, TextEditingController controller) async {
    Navigator.of(context).pop();
    setState(() => loading = true);
    final ref = await Firestore.addLobby(
        name: controller.text, id: Authentication.userId);
    await Firestore.createGameTicTacToe(
        gameId: ref.id, player1Id: player.id, player1Name: player.username);

    player.tictactoe = ref.id;
    await Firestore.setActiveTicTacToe(player);
    setState(() => loading = false);
  }

  void joinLobby(Lobby lobby) async {
    Navigator.of(context).pop();
    if (lobby.players.length > 1) {
      snackBar(context, 'Lobby already full!');
    } else {
      setState(() => loading = true);
      await Firestore.joinLobby(lobbyId: lobby.id, playerId: player.id);
      await Firestore.addPlayerGameTicTacToe(
          gameId: lobby.id, playerId: player.id, playerName: player.username);

      player.tictactoe = lobby.id;
      await Firestore.setActiveTicTacToe(player);
      setState(() => loading = false);
    }
  }
}
