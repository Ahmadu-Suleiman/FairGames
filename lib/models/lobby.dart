class Lobby {
  String id;
  String name;
  List<String> players;
  String creatorId;
  bool isActive;

  Lobby(
      {required this.id,
      required this.name,
      required this.players,
      required this.creatorId,
      required this.isActive});
}
