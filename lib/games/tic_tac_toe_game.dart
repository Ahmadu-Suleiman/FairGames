import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/game_tic_tac_toe.dart';
import 'package:fairgames/util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../models/player.dart';
import '../widgets/loading.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  final logger = Logger();
  late Size size;
  bool loading = false;
  Player? player;
  GameTicTacToe? game;

  bool get isUserTurn => game?.turn == player?.id;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.sizeOf(context);
    return PopScope(
        canPop: false,
        child: FutureBuilder(
            future: Firestore.player(Authentication.userId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                player = snapshot.data;
                return loading ? const Loading() : streamBuilder;
              } else {
                logger.e(snapshot.stackTrace);
                return const Loading();
              }
            }));
  }

  Widget get streamBuilder => StreamBuilder(
      stream: Firestore.tictactoeGameStream(widget.lobbyId),
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          game = Firestore.ticTacToeGameFromSnapshot(snapshot.data!);
          if (game != null) checkWinner();

          if (game?.isNotPlayer(player!.id) ?? true) {
            Future.microtask(() {
              if (context.mounted) {
                context.pop(context);
              }
            });
            return const Loading();
          }

          return Scaffold(
              appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  title: const Text('Tic Tac Toe')),
              body: body);
        } else {
          return const Loading();
        }
      });

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
            if (player!.id != game!.creator) leaveGame,
            if (player!.id == game!.creator) controls
          ])));

  Widget get board => IgnorePointer(
      ignoring: game!.notAllPLayers,
      child: Container(
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Theme.of(context).colorScheme.outline)),
                          child: Center(
                              child: Text(game!.boardItems[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)))))))));

  Widget get leaveGame => FilledButton.tonal(
      style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary),
      onPressed: () async {
        setState(() => loading = true);
        await Firestore.leaveGame(game!);
        setState(() => loading = false);
        if (mounted) context.pop(context);
      },
      child:
          Text("Leave game", style: Theme.of(context).textTheme.displaySmall));

  Widget get controls => Column(children: [
        FilledButton.tonal(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Firestore.clear(game!),
            child: Text("Clear Score Board",
                style: Theme.of(context).textTheme.displaySmall)),
        const SizedBox(height: 20),
        FilledButton.tonal(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              setState(() => loading = true);
              await Firestore.endGame(game!);
              setState(() => loading = false);
              if (mounted) context.pop(context);
            },
            child: Text("End game",
                style: Theme.of(context).textTheme.displaySmall))
      ]);

  void tapped(int index) async {
    if (isUserTurn && game!.boardItems[index] == '') {
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
    } else if (game!.boardItems[3] == game!.boardItems[4] &&
        game!.boardItems[3] == game!.boardItems[5] &&
        game!.boardItems[3] != '') {
      showWinner(game!.boardItems[3]);
    } else if (game!.boardItems[6] == game!.boardItems[7] &&
        game!.boardItems[6] == game!.boardItems[8] &&
        game!.boardItems[6] != '') {
      showWinner(game!.boardItems[6]);
    }

    // Checking Column
    else if (game!.boardItems[0] == game!.boardItems[3] &&
        game!.boardItems[0] == game!.boardItems[6] &&
        game!.boardItems[0] != '') {
      showWinner(game!.boardItems[0]);
    } else if (game!.boardItems[1] == game!.boardItems[4] &&
        game!.boardItems[1] == game!.boardItems[7] &&
        game!.boardItems[1] != '') {
      showWinner(game!.boardItems[1]);
    } else if (game!.boardItems[2] == game!.boardItems[5] &&
        game!.boardItems[2] == game!.boardItems[8] &&
        game!.boardItems[2] != '') {
      showWinner(game!.boardItems[2]);
    }

    // Checking Diagonal
    else if (game!.boardItems[0] == game!.boardItems[4] &&
        game!.boardItems[0] == game!.boardItems[8] &&
        game!.boardItems[0] != '') {
      showWinner(game!.boardItems[0]);
    } else if (game!.boardItems[2] == game!.boardItems[4] &&
        game!.boardItems[2] == game!.boardItems[6] &&
        game!.boardItems[2] != '') {
      showWinner(game!.boardItems[2]);
    } else if (game!.filled == 9) {
      showDraw();
    }
  }

  void showWinner(String winner) {
    if (winner == 'X') {
      snackBar(context, '${game!.player1Name} is Winner!!!');
      Firestore.updateScore1(game!);
    } else if (winner == 'O') {
      snackBar(context, '${game!.player2Name} is Winner!!!');
      Firestore.updateScore2(game!);
    }

    Firestore.clearBoard(game!);
  }

  void showDraw() {
    snackBar(context, 'Draw');
    Firestore.clearBoard(game!);
  }
}
