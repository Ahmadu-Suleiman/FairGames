import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/routes.dart';
import 'package:fairgames/util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';

class TicTacToeLobbyPage extends StatefulWidget {
  const TicTacToeLobbyPage({super.key});

  @override
  State<TicTacToeLobbyPage> createState() => _TicTacToeLobbyPageState();
}

class _TicTacToeLobbyPageState extends State<TicTacToeLobbyPage> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return StreamProvider.value(
        value: Firestore.playerStream(Authentication.user!.uid),
        initialData: null,
        child: Scaffold(
            appBar: AppBar(title: const Text('Lobby')),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder(
                    stream: Firestore.lobbiesStream(),
                    builder: (context, snapshot) {
                      final doc = context.watch<DocumentSnapshot?>();
                      final player = Firestore.playerFromSnapshot(doc);

                      Future.microtask(() {
                        if (player != null &&
                            player.tictactoe.isNotEmpty &&
                            context.mounted) {
                          context
                              .push('${Routes.tictactoe}/${player.tictactoe}');
                        }
                      });

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final lobbies =
                          Firestore.lobbyListFromSnapshot(snapshot.data!);

                      return ListView.builder(
                          itemCount: lobbies.length,
                          itemBuilder: (context, index) {
                            final lobby = lobbies[index];
                            return ListTile(
                                leading: const Icon(Icons.room),
                                title: Text(lobby.name),
                                subtitle: Text('${lobby.players.length}/${2}'),
                                onTap: () => showJoinDialog(lobby, player!));
                          });
                    }),
            floatingActionButton: FloatingActionButton(
                onPressed: createLobbyDialog,
                tooltip: 'Create New Lobby',
                child: const Icon(Icons.add))));
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
