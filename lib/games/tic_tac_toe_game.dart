import 'package:fairgames/firebase/authentication.dart';
import 'package:fairgames/firebase/firestore.dart';
import 'package:fairgames/models/game_tic_tac_toe.dart';
import 'package:fairgames/models/lobby.dart';
import 'package:flutter/material.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late Lobby lobby;
  GameTicTacToe? game;

  late Size size;
  List<String> displayElement = ['', '', '', '', '', '', '', '', ''];
  int filledBoxes = 0;

  @override
  void initState() {
    super.initState();
    Firestore.lobby(widget.lobbyId)
        .then((lobby) => setState(() => this.lobby = lobby));
  }

  bool get isUserTurn => game?.turn == Authentication.user?.uid;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      child: StreamBuilder(
          stream: Firestore.tictactoeStream(widget.lobbyId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              game = Firestore.gameTicTacToeFromSnapshot(snapshot.data!);

              if (game == null) {
                Future.microtask(() => Firestore.createGameTicTacToe(
                    gameId: lobby.id, player1Id: lobby.players[0]));
                return Container();
              } else {
                return Scaffold(
                    appBar: AppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        title: const Text('Tic Tac Toe')),
                    body: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: <Widget>[
                              top,
                              const Divider(height: 40),
                              IgnorePointer(ignoring: isUserTurn, child: board),
                              const SizedBox(height: 40),
                              FilledButton.tonal(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  onPressed: clearScoreBoard,
                                  child: Text("Clear Score Board",
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall))
                            ]))));
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget get top =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('Player X',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(game!.score1.toString(),
              style: Theme.of(context).textTheme.titleLarge)
        ]),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('Player O',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(game!.score2.toString(),
              style: Theme.of(context).textTheme.titleLarge)
        ])
      ]);

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
                          child: Text(displayElement[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold))))))));

  void tapped(int index) {
    setState(() {
      if (isUserTurn && displayElement[index] == '') {
        displayElement[index] = 'O';
        filledBoxes++;
      } else if (!isUserTurn && displayElement[index] == '') {
        displayElement[index] = 'X';
        filledBoxes++;
      }

      Firestore.updateTurn(game!);
      checkWinner();
    });
  }

  void checkWinner() {
    // Checking rows
    if (displayElement[0] == displayElement[1] &&
        displayElement[0] == displayElement[2] &&
        displayElement[0] != '') {
      showWinDialog(displayElement[0]);
    }
    if (displayElement[3] == displayElement[4] &&
        displayElement[3] == displayElement[5] &&
        displayElement[3] != '') {
      showWinDialog(displayElement[3]);
    }
    if (displayElement[6] == displayElement[7] &&
        displayElement[6] == displayElement[8] &&
        displayElement[6] != '') {
      showWinDialog(displayElement[6]);
    }

    // Checking Column
    if (displayElement[0] == displayElement[3] &&
        displayElement[0] == displayElement[6] &&
        displayElement[0] != '') {
      showWinDialog(displayElement[0]);
    }
    if (displayElement[1] == displayElement[4] &&
        displayElement[1] == displayElement[7] &&
        displayElement[1] != '') {
      showWinDialog(displayElement[1]);
    }
    if (displayElement[2] == displayElement[5] &&
        displayElement[2] == displayElement[8] &&
        displayElement[2] != '') {
      showWinDialog(displayElement[2]);
    }

    // Checking Diagonal
    if (displayElement[0] == displayElement[4] &&
        displayElement[0] == displayElement[8] &&
        displayElement[0] != '') {
      showWinDialog(displayElement[0]);
    }
    if (displayElement[2] == displayElement[4] &&
        displayElement[2] == displayElement[6] &&
        displayElement[2] != '') {
      showWinDialog(displayElement[2]);
    } else if (filledBoxes == 9) {
      showDrawDialog();
    }
  }

  Future<void> showWinDialog(String winner) async {
    if (winner == 'X') {
      await Firestore.updateScore1(game!);
    } else if (winner == 'O') {
      await Firestore.updateScore2(game!);
    }

    if (mounted) {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(title: Text("$winner is Winner!!!"), actions: [
              TextButton(
                  child: const Text("Play Again"),
                  onPressed: () {
                    clearBoard();
                    Navigator.of(context).pop();
                  })
            ]);
          });
    }
  }

  void showDrawDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(title: const Text("Draw"), actions: [
            TextButton(
                onPressed: () {
                  clearBoard();
                  Navigator.of(context).pop();
                },
                child: const Text('Play Again'))
          ]);
        });
  }

  void clearBoard() {
    setState(() => displayElement.fillRange(0, 9, ''));
    filledBoxes = 0;
  }

  void clearScoreBoard() {
    Firestore.clearScoreBoard(game!);
    setState(() => displayElement.fillRange(0, 9, ''));
    filledBoxes = 0;
  }
}
