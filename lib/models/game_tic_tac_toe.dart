class GameTicTacToe {
  String id;
  String player1;
  String player2;
  String player1Name;
  String player2Name;
  String turn;
  int score1;
  int score2;
  List<String> boardItems;
  int filled;

  String get turnName => turn == player1 ? player1Name : player2Name;

  bool isNotPlayer(String playerId) =>
      player1 != playerId && player2 != playerId;

  GameTicTacToe(
      {required this.id,
      required this.player1,
      required this.player2,
      required this.player1Name,
      required this.player2Name,
      required this.turn,
      required this.score1,
      required this.score2,
      required this.boardItems,
      required this.filled});
}
