class GameLogic {
  static const winPatterns = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
  static String? checkWinner(List<String> board) {
    for (var p in winPatterns) {
      if (board[p[0]] != '' && board[p[0]] == board[p[1]] && board[p[1]] == board[p[2]]) return board[p[0]];
    }
    if (!board.contains('')) return 'VELHA';
    return null;
  }
}
