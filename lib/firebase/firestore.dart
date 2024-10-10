import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fairgames/models/game_tic_tac_toe.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:fairgames/models/player.dart';
import 'package:fairgames/util.dart';

class Firestore {
  static final firestore = FirebaseFirestore.instance;
  static final lobbies = FirebaseFirestore.instance.collection('lobbies');
  static final players = FirebaseFirestore.instance.collection('players');
  static final games = FirebaseFirestore.instance.collection('games');
  static final tictactoe = games.doc().collection('tictactoe');

  static Stream<QuerySnapshot> lobbiesStream() => lobbies.snapshots();

  static Stream<DocumentSnapshot> playerStream(String id) =>
      players.doc(id).snapshots();

  static Stream<DocumentSnapshot> tictactoeStream(String id) =>
      tictactoe.doc(id).snapshots();

  static Future<void> addPlayer(Player player) async => await players
      .doc(player.id)
      .set({'username': player.username, 'tictactoe': ''});

  static Future<void> setActiveTicTacToe(Player player) async =>
      await players.doc(player.id).update({'tictactoe': player.tictactoe});

  static Future<Player?> player(String id) async {
    try {
      final data = await players.doc(id).get();
      return Player(id: id, username: data['username'], tictactoe: '');
    } catch (e) {
      return null;
    }
  }

  static Player? playerFromSnapshot(DocumentSnapshot? snapshot) =>
      snapshot == null
          ? null
          : Player(
              id: snapshot.id,
              username: snapshot.get('username'),
              tictactoe: snapshot.get('tictactoe'));

  static List<Lobby> lobbyListFromSnapshot(QuerySnapshot lobbiesSnapshot) =>
      lobbiesSnapshot.docs
          .map((document) => Lobby(
              id: document.id,
              name: document['name'],
              creator: document['creator'],
              players: toList(document['players'])))
          .toList();

  static Future<void> addLobby(
          {required String name, required String playerId}) async =>
      await lobbies.add({'name': name, 'creator': playerId, 'players': []});

  static Future<Lobby> lobby(String id) async {
    final data = await lobbies.doc(id).get();

    return Lobby(
        id: id,
        name: data['name'],
        creator: data['creator'],
        players: toList(data['players']));
  }

  static Future<void> joinLobby(
          {required String lobbyId, required String playerId}) async =>
      await lobbies.doc(lobbyId).update({
        'players': FieldValue.arrayUnion([playerId])
      });

  static Future<void> deleteLobby(Lobby lobby) async =>
      await lobbies.doc(lobby.id).delete();

  static Future<void> createGameTicTacToe(
          {required String gameId,
          String player1Id = '',
          String player2Id = ''}) async =>
      await tictactoe.doc(gameId).set({
        'player1': player1Id,
        'player2': player2Id,
        'turn': player1Id,
        'score1': 0,
        'score2': 0
      });

  static Future<GameTicTacToe?> gameTicTacToe(String gameId) async {
    final data = await tictactoe.doc(gameId).get();

    return GameTicTacToe(
        id: gameId,
        player1: data['player1'],
        player2: data['player2'],
        turn: data['turn'],
        score1: data['score1'],
        score2: data['score2']);
  }

  static GameTicTacToe? gameTicTacToeFromSnapshot(DocumentSnapshot snapshot) =>
      snapshot.exists
          ? GameTicTacToe(
              id: snapshot.id,
              player1: snapshot.get('player1'),
              player2: snapshot.get('player2'),
              turn: snapshot.get('turn'),
              score1: snapshot.get('score1'),
              score2: snapshot.get('score2'))
          : null;

  static Future<void> updateTurn(GameTicTacToe game) async {
    String currentTurn =
        game.turn == game.player1 ? game.player2 : game.player1;
    await tictactoe.doc(game.id).update({'turn': currentTurn});
  }

  static Future<void> updateScore1(GameTicTacToe game) async {
    await tictactoe.doc(game.id).update({'score1': FieldValue.increment(1)});
  }

  static Future<void> updateScore2(GameTicTacToe game) async {
    await tictactoe.doc(game.id).update({'score2': FieldValue.increment(1)});
  }

  static Future<void> clearScoreBoard(GameTicTacToe game) async {
    await tictactoe.doc(game.id).update({'score1': 0, 'score2': 0});
  }
}
