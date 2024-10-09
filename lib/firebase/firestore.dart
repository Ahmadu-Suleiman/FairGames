import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/models/player.dart';

class Firestore {
  static final firestore = FirebaseFirestore.instance;
  static final lobbies = FirebaseFirestore.instance.collection('lobbies');
  static final players = FirebaseFirestore.instance.collection('players');

  static Stream<QuerySnapshot> lobbiesStream() => lobbies.snapshots();

  static Future<void> addPlayer(Player player, String id) async =>
      await players.doc(id).set({'username': player.username});

  static Future<Player?> player(String id) async {
    try {
      final data = await players.doc(id).get();

      return Player(id: id, username: data['username']);
    } catch (e) {
      return null;
    }
  }

  static List<Lobby> lobbyListFromSnapshot(QuerySnapshot lobbiesSnapshot) =>
      lobbiesSnapshot.docs
          .map((document) => Lobby(
              id: document.id,
              name: document['name'],
              creator: document['creator'],
              players: document['players']))
          .toList();

  static Future<void> addLobby(
          {required String name, required String playerId}) async =>
      await lobbies.add({
        'name': name,
        'creator': playerId,
        'players': [playerId]
      });

  static Future<Lobby> lobby(String id) async {
    final data = await lobbies.doc(id).get();

    return Lobby(
        id: id,
        name: data['name'],
        creator: data['creator'],
        players: data['players']);
  }

  static Future<void> joinLobby(
          {required String lobbyId, required String playerId}) async =>
      await lobbies.doc(lobbyId).update({
        'players': FieldValue.arrayUnion([playerId])
      });

  static Future<void> deleteLobby(Lobby lobby) async =>
      await lobbies.doc(lobby.id).delete();
}
