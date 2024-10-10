import 'package:fairgames/games/tic_tac_toe_game.dart';
import 'package:fairgames/pages/home_page.dart';
import 'package:fairgames/pages/lobby_pages/tic_tac_toe_lobby_page.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static const String tictactoe = '/tictactoe';
  static const String tictactoeLobby = '/tictactoe_lobby';
  static final GoRouter router = GoRouter(routes: <RouteBase>[
    GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: <RouteBase>[
          GoRoute(
              path: '$tictactoe/:id',
              builder: (context, state) =>
                  TicTacToeGame(lobbyId: state.pathParameters['id']!)),
          GoRoute(
              path: tictactoeLobby,
              builder: (context, state) => const TicTacToeLobbyPage())
        ])
  ]);
}
