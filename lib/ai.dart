import 'dart:math';
import 'game_logic.dart';
class AI {
  final Random _r = Random();
  int getMove(List<String> board, String aiPlayer, String difficulty) {
    String human = aiPlayer == 'X' ? 'O' : 'X';
    List<int> empty = [for (int i=0;i<9;i++) if (board[i]=='') i];
    if (empty.isEmpty) return -1;
    switch(difficulty) {
      case 'Fácil': return empty[_r.nextInt(empty.length)];
      case 'Normal':
        for (int i in empty) { board[i]=human; if (GameLogic.checkWinner(board)==human) { board[i]=''; return i; } board[i]=''; }
        return empty[_r.nextInt(empty.length)];
      case 'Difícil': return _minimax(board, aiPlayer, human, aiPlayer, 0, 3).index;
      case 'Avançado': return _minimax(board, aiPlayer, human, aiPlayer, 0, 5).index;
      case 'Expert': default: return _minimax(board, aiPlayer, human, aiPlayer, 0, 9).index;
    }
  }
  _Result _minimax(List<String> board, String ai, String human, String current, int depth, int maxDepth) {
    String? winner = GameLogic.checkWinner(board);
    if (winner == ai) return _Result(10-depth, -1);
    if (winner == human) return _Result(depth-10, -1);
    if (winner == 'VELHA' || depth >= maxDepth) return _Result(0, -1);
    List<int> empty = [for (int i=0;i<9;i++) if (board[i]=='') i];
    List<_Result> moves = [];
    for (int i in empty) { board[i]=current; var result = _minimax(board, ai, human, current==ai?human:ai, depth+1, maxDepth); moves.add(_Result(result.score, i)); board[i]=''; }
    if (current==ai) { moves.sort((a,b)=>b.score.compareTo(a.score)); } else { moves.sort((a,b)=>a.score.compareTo(b.score)); }
    return moves.first;
  }
}
class _Result { int score; int index; _Result(this.score, this.index); }
