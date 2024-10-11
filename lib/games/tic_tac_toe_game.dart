import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/game_tic_tac_toe.dart';
import 'package:fairgames/util.dart';
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../widgets/loading.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late Size size;
  Player? player;
  GameTicTacToe? game;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  bool get isUserTurn => game?.turn == player?.id;

  Future<void> initializeGame() async {
    player = await Firestore.player(Authentication.user!.uid);
    game = await Firestore.gameTicTacToe(widget.lobbyId);
    if (player != null) {
      if (game == null) {
        await Firestore.createGameTicTacToe(
            gameId: widget.lobbyId,
            player1Id: player!.id,
            player1Name: player!.username);
      } else {
        await Firestore.addPlayerGameTicTacToe(
            gameId: widget.lobbyId,
            playerId: player!.id,
            playerName: player!.username);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.sizeOf(context);

    return PopScope(
        canPop: false,
        child: StreamBuilder(
            stream: Firestore.tictactoeGameStream(widget.lobbyId),
            initialData: null,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print(game?.boardItems.toString());
                print(game?.filled.toString());
                game = Firestore.ticTacToeGameFromSnapshot(snapshot.data!);

                checkWinner();
                return Scaffold(
                    appBar: AppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        title: const Text('Tic Tac Toe')),
                    body: body);
              } else {
                return const Loading();
              }
            }));
  }

  Widget get top =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(game!.player1Name,
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(game!.score1.toString(),
              style: Theme.of(context).textTheme.titleLarge)
        ]),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(game!.player2Name,
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(game!.score2.toString(),
              style: Theme.of(context).textTheme.titleLarge)
        ])
      ]);

  Widget get body => SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: <Widget>[
            top,
            const Divider(height: 40),
            board,
            const SizedBox(height: 18),
            Text('Turn: ${game?.turnName}'),
            const SizedBox(height: 40),
            FilledButton.tonal(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () => Firestore.clear(game!),
                child: Text("Clear Score Board",
                    style: Theme.of(context).textTheme.displaySmall))
          ])));

  Widget get board => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainer),
      padding: const EdgeInsets.all(20),
      child: GridView.count(
          childAspectRatio: size.width / (size.height - 400),
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(
              9,
              (index) => GestureDetector(
                  onTap: () => tapped(index),
                  child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline)),
                      child: Center(
                          child: Text(game!.boardItems[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold))))))));

  void tapped(int index) async {
    if (isUserTurn && game!.boardItems[index] == '') {
      print('tap');
      if (player?.id == game?.player1) {
        game!.boardItems[index] = 'X';
      } else {
        game!.boardItems[index] = 'O';
      }

      await Firestore.updateBoard(game!);
      await Firestore.updateFilled(game!);
      await Firestore.updateTurn(game!);
    }
  }

  void checkWinner() {
    // Checking rows
    if (game!.boardItems[0] == game!.boardItems[1] &&
        game!.boardItems[0] == game!.boardItems[2] &&
        game!.boardItems[0] != '') {
      showWinner(game!.boardItems[0]);
    }
    if (game!.boardItems[3] == game!.boardItems[4] &&
        game!.boardItems[3] == game!.boardItems[5] &&
        game!.boardItems[3] != '') {
      showWinner(game!.boardItems[3]);
    }
    if (game!.boardItems[6] == game!.boardItems[7] &&
        game!.boardItems[6] == game!.boardItems[8] &&
        game!.boardItems[6] != '') {
      showWinner(game!.boardItems[6]);
    }

    // Checking Column
    if (game!.boardItems[0] == game!.boardItems[3] &&
        game!.boardItems[0] == game!.boardItems[6] &&
        game!.boardItems[0] != '') {
      showWinner(game!.boardItems[0]);
    }
    if (game!.boardItems[1] == game!.boardItems[4] &&
        game!.boardItems[1] == game!.boardItems[7] &&
        game!.boardItems[1] != '') {
      showWinner(game!.boardItems[1]);
    }
    if (game!.boardItems[2] == game!.boardItems[5] &&
        game!.boardItems[2] == game!.boardItems[8] &&
        game!.boardItems[2] != '') {
      showWinner(game!.boardItems[2]);
    }

    // Checking Diagonal
    if (game!.boardItems[0] == game!.boardItems[4] &&
        game!.boardItems[0] == game!.boardItems[8] &&
        game!.boardItems[0] != '') {
      showWinner(game!.boardItems[0]);
    }
    if (game!.boardItems[2] == game!.boardItems[4] &&
        game!.boardItems[2] == game!.boardItems[6] &&
        game!.boardItems[2] != '') {
      showWinner(game!.boardItems[2]);
    } else if (game!.filled == 9) {
      showDraw();
    }
  }

  Future<void> showWinner(String winner) async {
    await Firestore.clearBoard(
        game!); //todo assign x and o to player one and two
    if (winner == 'X') {
      await Firestore.updateScore1(game!);
    } else if (winner == 'O') {
      await Firestore.updateScore2(game!);
    }

    if (mounted) {
      snackBar(context, '$winner is Winner!!!');
      Firestore.clearBoard(game!);
    }
  }

  void showDraw() {
    if (mounted) {
      snackBar(context, 'Draw');
      Firestore.clearBoard(game!);
    }
  }
}
