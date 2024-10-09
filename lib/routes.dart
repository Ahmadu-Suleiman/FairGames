import 'package:fairgames/games/tic_tac_toe.dart';
import 'package:fairgames/pages/home_page.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static const String tictactoe = '/tictactoe';
  static final GoRouter router = GoRouter(routes: <RouteBase>[
    GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: <RouteBase>[
          GoRoute(
              path: tictactoe, builder: (context, state) => const TicTacToe())
        ])
  ]);
}
