import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Game Lobbies')),
        body: StreamBuilder(
            stream: Firestore.lobbiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final lobbies = Firestore.lobbyListFromSnapshot(snapshot.data!);

              return ListView.builder(
                  itemCount: lobbies.length,
                  itemBuilder: (context, index) {
                    final lobby = lobbies[index];
                    return ListTile(
                        trailing: const Icon(Icons.gamepad),
                        title: Text(lobby.name),
                        subtitle: Text('${lobby.players.length}/${2}'),
                        onTap: () => _showJoinDialog(context, lobby));
                  });
            }),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _createLobbyDialog(context),
            tooltip: 'Create New Lobby',
            child: const Icon(Icons.add)));
  }

  Future<void> _createLobbyDialog(BuildContext context) async {
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

  Future<void> _showJoinDialog(BuildContext context, Lobby lobby) async {
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
                      await Firestore.joinLobby(
                          lobbyId: lobby.id,
                          playerId: Authentication.user!.uid);
                      if (context.mounted) {
                        context.push('${Routes.tictactoe}/${lobby.id}');
                        Navigator.of(context).pop();
                      }
                    })
              ]);
        });
  }
}
