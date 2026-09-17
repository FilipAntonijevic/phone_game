import 'dart:math';

class CellPos {
  const CellPos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is CellPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

enum GameStatus { playing, won, noMoreMoves }

/// 8 columns × 15 rows board. Circles hold values 1–9; null means cleared.
class GameBoard {
  GameBoard({Random? random})
      : _random = random ?? Random(),
        cells = List.generate(
          rows,
          (_) => List<int?>.generate(cols, (_) => null),
        ) {
    fillRandom();
  }

  static const int cols = 8;
  static const int rows = 15;

  final Random _random;
  final List<List<int?>> cells;

  int score = 0;
  GameStatus status = GameStatus.playing;
  CellPos? selection;

  void fillRandom() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        cells[r][c] = _random.nextInt(9) + 1;
      }
    }
    score = 0;
    status = GameStatus.playing;
    selection = null;
  }

  int? valueAt(CellPos pos) => cells[pos.row][pos.col];

  bool get isCleared {
    for (final row in cells) {
      for (final v in row) {
        if (v != null) return false;
      }
    }
    return true;
  }

  /// All occupied cells inside the axis-aligned rectangle whose diagonals
  /// are [a] and [b] (inclusive).
  List<CellPos> cellsInRectangle(CellPos a, CellPos b) {
    final minR = min(a.row, b.row);
    final maxR = max(a.row, b.row);
    final minC = min(a.col, b.col);
    final maxC = max(a.col, b.col);

    final result = <CellPos>[];
    for (var r = minR; r <= maxR; r++) {
      for (var c = minC; c <= maxC; c++) {
        if (cells[r][c] != null) {
          result.add(CellPos(r, c));
        }
      }
    }
    return result;
  }

  int sumRectangle(CellPos a, CellPos b) {
    var sum = 0;
    for (final pos in cellsInRectangle(a, b)) {
      sum += cells[pos.row][pos.col]!;
    }
    return sum;
  }

  bool isValidMove(CellPos a, CellPos b) =>
      a != b && sumRectangle(a, b) == 10;

  /// Returns two corner cells that form a scoring rectangle, or null.
  /// Prefers the smallest rectangle (fewest occupied cells, then area).
  (CellPos, CellPos)? findHint() {
    (CellPos, CellPos)? best;
    var bestCount = 1 << 30;
    var bestArea = 1 << 30;

    for (var r1 = 0; r1 < rows; r1++) {
      for (var c1 = 0; c1 < cols; c1++) {
        for (var r2 = r1; r2 < rows; r2++) {
          for (var c2 = 0; c2 < cols; c2++) {
            if (r1 == r2 && c2 <= c1) continue;
            final a = CellPos(r1, c1);
            final b = CellPos(r2, c2);
            if (!isValidMove(a, b)) continue;

            final occupied = cellsInRectangle(a, b);
            final count = occupied.length;
            final area = ((max(r1, r2) - min(r1, r2) + 1) *
                    (max(c1, c2) - min(c1, c2) + 1))
                .toInt();
            if (count < bestCount ||
                (count == bestCount && area < bestArea)) {
              bestCount = count;
              bestArea = area;
              best = (a, b);
            }
          }
        }
      }
    }
    return best;
  }

  bool hasAnyValidMove() => findHint() != null;

  void _clearCells(Iterable<CellPos> positions) {
    for (final pos in positions) {
      cells[pos.row][pos.col] = null;
    }
  }

  void _refreshEndState() {
    if (isCleared) {
      status = GameStatus.won;
    } else if (!hasAnyValidMove()) {
      status = GameStatus.noMoreMoves;
    } else {
      status = GameStatus.playing;
    }
  }

  /// Returns true if a successful clear happened.
  /// Empty cells are valid rectangle corners (start/end).
  bool tap(CellPos pos) {
    if (status != GameStatus.playing) return false;

    if (selection == null) {
      selection = pos;
      return false;
    }

    if (selection == pos) {
      selection = null;
      return false;
    }

    final first = selection!;
    selection = null;

    if (!isValidMove(first, pos)) {
      // Invalid rectangle — start a new selection on the second tap.
      selection = pos;
      return false;
    }

    final toClear = cellsInRectangle(first, pos);
    _clearCells(toClear);
    score += toClear.length;
    _refreshEndState();
    return true;
  }

  bool isSelected(CellPos pos) => selection == pos;
}
