import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_board.dart';
import '../widgets/number_circle.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard _board;
  late DateTime _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Set<CellPos> _flashClear = {};
  Set<CellPos> _previewRect = {};
  Set<CellPos> _hintCorners = {};

  @override
  void initState() {
    super.initState();
    _board = GameBoard();
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_board.status != GameStatus.playing) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final total = _elapsed.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _restart() {
    setState(() {
      _board = GameBoard();
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
      _flashClear = {};
      _previewRect = {};
      _hintCorners = {};
    });
  }

  void _showHint() {
    if (_board.status != GameStatus.playing) return;
    final hint = _board.findHint();
    if (hint == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _board.selection = null;
      _previewRect = {};
      _hintCorners = {hint.$1, hint.$2};
    });
  }

  Future<void> _onTap(CellPos pos) async {
    if (_board.status != GameStatus.playing) return;

    setState(() => _hintCorners = {});

    final first = _board.selection;

    if (first != null && first != pos) {
      final rect = _board.cellsInRectangle(first, pos);
      final sum = _board.sumRectangle(first, pos);
      setState(() {
        _previewRect = rect.toSet();
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;

      if (sum == 10) {
        HapticFeedback.lightImpact();
        setState(() {
          _flashClear = rect.toSet();
          _previewRect = {};
        });
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (!mounted) return;
        setState(() {
          _board.tap(pos);
          _flashClear = {};
          _elapsed = DateTime.now().difference(_startedAt);
        });
        return;
      }
    }

    setState(() {
      _previewRect = {};
      _board.tap(pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayTitle = switch (_board.status) {
      GameStatus.won => 'You won',
      GameStatus.noMoreMoves => 'No more moves',
      GameStatus.playing => null,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F1C17),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFFE6F0EA),
                      ),
                      Expanded(
                        child: Text(
                          'Sum Ten',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: const Color(0xFFF3F7F1),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      _HudChip(label: 'Score', value: '${_board.score}'),
                      const SizedBox(width: 10),
                      _HudChip(label: 'Time', value: _timeLabel),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _board.status == GameStatus.playing
                          ? _showHint
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5EC8E8),
                        disabledForegroundColor: const Color(0xFF3A5560),
                      ),
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
                      label: const Text(
                        'Hint',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 6.0;
                        final cellW =
                            (constraints.maxWidth - gap * (GameBoard.cols - 1)) /
                                GameBoard.cols;
                        final cellH =
                            (constraints.maxHeight - gap * (GameBoard.rows - 1)) /
                                GameBoard.rows;
                        final size = cellW < cellH ? cellW : cellH;
                        final gridW =
                            size * GameBoard.cols + gap * (GameBoard.cols - 1);
                        final gridH =
                            size * GameBoard.rows + gap * (GameBoard.rows - 1);

                        return Center(
                          child: SizedBox(
                            width: gridW,
                            height: gridH,
                            child: Column(
                              children: [
                                for (var r = 0; r < GameBoard.rows; r++) ...[
                                  if (r > 0) const SizedBox(height: gap),
                                  Row(
                                    children: [
                                      for (var c = 0;
                                          c < GameBoard.cols;
                                          c++) ...[
                                        if (c > 0) const SizedBox(width: gap),
                                        SizedBox(
                                          width: size,
                                          height: size,
                                          child: NumberCircle(
                                            value: _board.cells[r][c],
                                            selected: _board
                                                .isSelected(CellPos(r, c)),
                                            inRectangle: _previewRect
                                                    .contains(CellPos(r, c)) ||
                                                _flashClear
                                                    .contains(CellPos(r, c)),
                                            clearing: _flashClear
                                                .contains(CellPos(r, c)),
                                            hinted: _hintCorners
                                                .contains(CellPos(r, c)),
                                            onTap: () =>
                                                _onTap(CellPos(r, c)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (overlayTitle != null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.62),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Material(
                        color: const Color(0xFF173528),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                overlayTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: const Color(0xFFF3F7F1),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Score ${_board.score} · Time $_timeLabel',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFFB7CFC2),
                                    ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    foregroundColor: const Color(0xFF0B3D2E),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _restart,
                                  child: const Text('Play again'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: const Text(
                                  'Back to menu',
                                  style: TextStyle(
                                    color: Color(0xFFD7E8DE),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E4A3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8EAA9A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF3F7F1),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
