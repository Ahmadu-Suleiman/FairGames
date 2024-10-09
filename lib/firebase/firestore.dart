import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/models/player.dart';

class Firestore {
  static final firestore = FirebaseFirestore.instance;
  static final lobbies = FirebaseFirestore.instance.collection('lobbies');
  static final players = FirebaseFirestore.instance.collection('players');

  static Stream lobbiesStream() => lobbies.snapshots();

  static Future<void> addLobby(Player player, Lobby lobby) async =>
      await lobbies.add({
        'name': lobby.name,
        'creator': player.id,
        'players': [player.id]
      });

  static Future<Lobby> lobby(String id) async {
    final data = await lobbies.doc(id).get();

    return Lobby(
        id: id,
        name: data['name'],
        creator: data['creator'],
        players: data['players']);
  }

  static Future<void> deleteLobby(Lobby lobby) async =>
      await lobbies.doc(lobby.id).delete();
}
