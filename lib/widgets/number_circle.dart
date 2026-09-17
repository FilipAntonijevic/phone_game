import 'package:flutter/material.dart';

class NumberCircle extends StatelessWidget {
  const NumberCircle({
    super.key,
    required this.value,
    required this.selected,
    required this.inRectangle,
    required this.clearing,
    required this.onTap,
  });

  final int? value;
  final bool selected;
  final bool inRectangle;
  final bool clearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Empty cells stay tappable so they can be rectangle corners.
    if (value == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFFF0C75E).withValues(alpha: 0.22)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? const Color(0xFFF0C75E)
                    : const Color(0xFF2A4038),
                width: selected ? 2.5 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF0C75E).withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      );
    }

    final Color fill;
    final Color border;
    final Color textColor;

    if (clearing) {
      fill = const Color(0xFF7CDBA8);
      border = const Color(0xFFB8F0D0);
      textColor = const Color(0xFF0B3D2E);
    } else if (selected) {
      fill = const Color(0xFFF0C75E);
      border = const Color(0xFFFFE7A3);
      textColor = const Color(0xFF2A2108);
    } else if (inRectangle) {
      fill = const Color(0xFF3D7A5F);
      border = const Color(0xFF6FCB9A);
      textColor = const Color(0xFFF3F7F1);
    } else {
      fill = const Color(0xFF244536);
      border = const Color(0xFF3E6A54);
      textColor = const Color(0xFFE8F2EC);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: selected ? 2.5 : 1.5),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF0C75E).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '$value',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
