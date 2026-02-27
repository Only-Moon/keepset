import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget {
  final String title;
  final IconData iconName;
  final VoidCallback onIconTap;

  const MyAppBar({
    super.key,
    required this.title,
    required this.iconName,
    required this.onIconTap,
  });

  static const double _barHeight = 96;
  static const double _horizontalPadding = 20;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: _barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 🔒 key fix
            children: [
              // ───── TITLE
              Text(
                title,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
              ),

              const Spacer(),

              // ───── ACTION BUTTON (controlled size, no IconButton)
              GestureDetector(
                onTap: onIconTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconName,
                    size: 22,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
