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
  board.weakenCharges = 0;
  board.blastCharges = 0;
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
    // Corners [0,0] and [0,3] are empty.
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

  test('weaken and blast unlock from score thresholds', () {
    final board = GameBoard();
    clearBoard(board);
    // Fill with 9s; keep one permanent scoring pair so the game stays playable.
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

    // 10 pairs => score 20
    for (var i = 0; i < 10; i++) {
      clearPair(i, 0);
    }
    expect(board.score, 20);
    expect(board.weakenCharges, 1);
    expect(board.blastCharges, 0);

    clearPair(10, 0);
    expect(board.score, 22);
    expect(board.blastCharges, 0);

    for (var i = 0; i < 4; i++) {
      clearPair(11, i * 2);
    }
    expect(board.score, 30);
    expect(board.weakenCharges, 1);
    expect(board.blastCharges, 1);
  });

  test('weaken reduces five random circles', () {
    final board = GameBoard(random: Random(1));
    clearBoard(board);
    board.weakenCharges = 1;
    for (var c = 0; c < 8; c++) {
      board.cells[0][c] = 2;
    }
    final changed = board.useWeaken();
    expect(changed, isNotNull);
    expect(changed!.length, 5);
    expect(board.weakenCharges, 0);
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
    board.blastCharges = 1;
    board.cells[0][0] = 9;
    expect(board.armBlast(), isTrue);
    expect(board.blastArmed, isTrue);
    expect(board.tap(const CellPos(0, 0)), isTrue);
    expect(board.cells[0][0], isNull);
    expect(board.score, 1);
    expect(board.blastArmed, isFalse);
  });
}
