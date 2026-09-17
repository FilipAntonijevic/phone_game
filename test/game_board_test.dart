import 'package:flutter_test/flutter_test.dart';
import 'package:phone_game/models/game_board.dart';

void clearBoard(GameBoard board) {
  for (var r = 0; r < GameBoard.rows; r++) {
    for (var c = 0; c < GameBoard.cols; c++) {
      board.cells[r][c] = null;
    }
  }
  board.score = 0;
  board.status = GameStatus.playing;
  board.selection = null;
}

void main() {
  test('rectangle sum clears when total is 10', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][0] = 4;
    board.cells[0][1] = 6;
    board.cells[1][0] = 9;
    board.cells[1][1] = 1;

    expect(board.sumRectangle(const CellPos(0, 0), const CellPos(0, 1)), 10);

    board.tap(const CellPos(0, 0));
    final cleared = board.tap(const CellPos(0, 1));
    expect(cleared, isTrue);
    expect(board.cells[0][0], isNull);
    expect(board.cells[0][1], isNull);
    expect(board.score, 2);
    expect(board.cells[1][0], 9);
  });

  test('full rectangle diagonal clears interior cells too', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][0] = 2;
    board.cells[0][1] = 3;
    board.cells[1][0] = 2;
    board.cells[1][1] = 3;

    board.tap(const CellPos(0, 0));
    expect(board.tap(const CellPos(1, 1)), isTrue);
    expect(board.score, 4);
    expect(board.isCleared, isTrue);
    expect(board.status, GameStatus.won);
  });

  test('empty cells can be rectangle corners', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][1] = 4;
    board.cells[0][2] = 6;
    // Corners [0,0] and [0,3] are empty.
    board.tap(const CellPos(0, 0));
    expect(board.selection, const CellPos(0, 0));
    expect(board.tap(const CellPos(0, 3)), isTrue);
    expect(board.cells[0][1], isNull);
    expect(board.cells[0][2], isNull);
    expect(board.score, 2);
  });

  test('reports no more moves when none remain', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][0] = 3;
    board.cells[0][2] = 3;
    expect(board.hasAnyValidMove(), isFalse);
  });

  test('won when board is empty', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][0] = 5;
    board.cells[0][1] = 5;
    board.tap(const CellPos(0, 0));
    board.tap(const CellPos(0, 1));
    expect(board.status, GameStatus.won);
  });
}
