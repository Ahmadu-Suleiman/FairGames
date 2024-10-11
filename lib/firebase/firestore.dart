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

  static Stream<QuerySnapshot> lobbiesStream() => lobbies.snapshots();

  static Stream<DocumentSnapshot> playerStream(String id) =>
      players.doc(id).snapshots();

  static Stream<DocumentSnapshot> tictactoeGameStream(String id) =>
      games.doc(id).snapshots();

  static Future<void> createPlayer(Player player) async => await players
      .doc(player.id)
      .set({'username': player.username, 'tictactoe': player.tictactoe});

  static Future<void> setActiveTicTacToe(Player player) async =>
      await players.doc(player.id).update({'tictactoe': player.tictactoe});

  static Future<Player?> player(String id) async {
    try {
      final data = await players.doc(id).get();
      return Player(
          id: id, username: data['username'], tictactoe: data['tictactoe']);
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
          String player2Id = '',
          player1Name = '',
          player2Name = ''}) async =>
      await games.doc(gameId).set({
        'player1': player1Id,
        'player2': player2Id,
        'player1Name': player1Name,
        'player2Name': player2Name,
        'turn': player1Id,
        'score1': 0,
        'score2': 0,
        'boardItems': List.filled(9, ''),
        'filled': 0
      });

  static Future<GameTicTacToe?> gameTicTacToe(String gameId) async {
    final data = await games.doc(gameId).get();

    try {
      return GameTicTacToe(
          id: gameId,
          player1: data['player1'],
          player2: data['player2'],
          player1Name: data['player1Name'],
          player2Name: data['player2Name'],
          turn: data['turn'],
          score1: data['score1'],
          score2: data['score2'],
          boardItems: toList(data['boardItems']),
          filled: data['filled']);
    } catch (e) {
      return null;
    }
  }

  static Future<void> addPlayerGameTicTacToe(
      {required String gameId, String playerId = '', playerName = ''}) async {
    final game = await gameTicTacToe(gameId);

    if (game?.player1 != playerId && game?.player2 != playerId) {
      await games
          .doc(gameId)
          .update({'player2': playerId, 'player2Name': playerName});
    }
  }

  static GameTicTacToe? ticTacToeGameFromSnapshot(DocumentSnapshot snapshot) =>
      snapshot.exists
          ? GameTicTacToe(
              id: snapshot.id,
              player1: snapshot.get('player1'),
              player2: snapshot.get('player2'),
              player1Name: snapshot.get('player1Name'),
              player2Name: snapshot.get('player2Name'),
              turn: snapshot.get('turn'),
              score1: snapshot.get('score1'),
              score2: snapshot.get('score2'),
              boardItems: toList(snapshot.get('boardItems')),
              filled: snapshot.get('filled'))
          : null;

  static Future<void> updateTurn(GameTicTacToe game) async {
    String currentTurn =
        game.turn == game.player1 ? game.player2 : game.player1;
    await games.doc(game.id).update({'turn': currentTurn});
  }

  static Future<void> updateScore1(GameTicTacToe game) async {
    await games.doc(game.id).update({'score1': FieldValue.increment(1)});
  }

  static Future<void> updateScore2(GameTicTacToe game) async {
    await games.doc(game.id).update({'score2': FieldValue.increment(1)});
  }

  static Future<void> updateBoard(GameTicTacToe game) async {
    await games.doc(game.id).update({'boardItems': game.boardItems});
  }

  static Future<void> updateFilled(GameTicTacToe game) async {
    await games.doc(game.id).update({'filled': FieldValue.increment(1)});
  }

  static Future<void> clearBoard(GameTicTacToe game) async {
    await games
        .doc(game.id)
        .update({'boardItems': List.filled(9, ''), 'filled': 0});
  }

  static Future<void> clear(GameTicTacToe game) async {
    await games.doc(game.id).update({
      'score1': 0,
      'score2': 0,
      'boardItems': List.filled(9, ''),
      'filled': 0
    });
  }
}
