import 'dart:math';

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
  board.hintFill = 0;
  board.weakenFill = 0;
  board.blastFill = 0;
  board.blastArmed = false;
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
    board.tap(const CellPos(0, 0));
    expect(board.selection, const CellPos(0, 0));
    expect(board.tap(const CellPos(0, 3)), isTrue);
    expect(board.cells[0][1], isNull);
    expect(board.cells[0][2], isNull);
    expect(board.score, 2);
  });

  test('findHint returns corners that sum to 10', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[2][2] = 7;
    board.cells[2][3] = 3;
    final hint = board.findHint();
    expect(hint, isNotNull);
    expect(board.sumRectangle(hint!.$1, hint.$2), 10);
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

  test('score fills power meters; cast resets only that meter', () {
    final board = GameBoard();
    clearBoard(board);
    for (var r = 0; r < GameBoard.rows; r++) {
      for (var c = 0; c < GameBoard.cols; c++) {
        board.cells[r][c] = 9;
      }
    }
    board.cells[14][6] = 4;
    board.cells[14][7] = 6;

    void clearPair(int r, int c) {
      board.cells[r][c] = 5;
      board.cells[r][c + 1] = 5;
      expect(board.tap(CellPos(r, c)), isFalse);
      expect(board.tap(CellPos(r, c + 1)), isTrue);
    }

    // 10 pairs => +20 score
    for (var i = 0; i < 10; i++) {
      clearPair(i, 0);
    }
    expect(board.score, 20);
    expect(board.blastFill, GameBoard.blastCost);
    expect(board.blastReady, isTrue);
    expect(board.weakenFill, 20);
    expect(board.weakenReady, isFalse);
    expect(board.hintFill, 20);
    expect(board.hintReady, isFalse);

    // Cast blast — only blast meter resets.
    expect(board.armBlast(), isTrue);
    expect(board.blastFill, 0);
    expect(board.blastArmed, isTrue);
    expect(board.weakenFill, 20);
    expect(board.hintFill, 20);

    board.cells[12][0] = 8;
    expect(board.tap(const CellPos(12, 0)), isTrue);
    expect(board.score, 21);
    expect(board.blastFill, 1);
    expect(board.weakenFill, 21);
    expect(board.hintFill, 21);

    // Reach weaken ready at 30
    for (var i = 0; i < 5; i++) {
      clearPair(10, 0);
    }
    // +10 more from pairs, but one cell was already blasted from row12...
    // After 5 pairs of +2 = +10 => score 31
    expect(board.score, 31);
    expect(board.weakenReady, isTrue);
    expect(board.hintFill, 31);
    expect(board.hintReady, isFalse);

    final weakened = board.useWeaken();
    expect(weakened, isNotNull);
    expect(board.weakenFill, lessThan(GameBoard.weakenCost));
    // weakenFill was reset to 0 then maybe increased if removals scored
    expect(board.weakenReady, isFalse);
  });

  test('weaken reduces five random circles', () {
    final board = GameBoard(random: Random(1));
    clearBoard(board);
    board.weakenFill = GameBoard.weakenCost;
    for (var c = 0; c < 8; c++) {
      board.cells[0][c] = 2;
    }
    final changed = board.useWeaken();
    expect(changed, isNotNull);
    expect(changed!.length, 5);
    expect(board.weakenReady, isFalse);
    var twos = 0;
    var ones = 0;
    for (var c = 0; c < 8; c++) {
      if (board.cells[0][c] == 2) twos++;
      if (board.cells[0][c] == 1) ones++;
    }
    expect(ones, 5);
    expect(twos, 3);
  });

  test('blast destroys next occupied circle', () {
    final board = GameBoard();
    clearBoard(board);
    board.blastFill = GameBoard.blastCost;
    board.cells[0][0] = 9;
    expect(board.armBlast(), isTrue);
    expect(board.blastArmed, isTrue);
    expect(board.blastFill, 0);
    expect(board.tap(const CellPos(0, 0)), isTrue);
    expect(board.cells[0][0], isNull);
    expect(board.score, 1);
    expect(board.blastArmed, isFalse);
  });

  test('hint cast requires full meter and resets it', () {
    final board = GameBoard();
    clearBoard(board);
    board.cells[0][0] = 4;
    board.cells[0][1] = 6;
    expect(board.useHint(), isNull);
    board.hintFill = GameBoard.hintCost;
    final hint = board.useHint();
    expect(hint, isNotNull);
    expect(board.hintFill, 0);
  });
}
