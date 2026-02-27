import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keepset/theme/keepset_theme.dart';

import 'customappbar.dart';

class KeepsetScaffold extends StatelessWidget {
  final String title;
  final IconData actionIcon;
  final VoidCallback onActionTap;
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const KeepsetScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.selectedIndex,
    required this.onTabChanged,
    this.actionIcon = Iconsax.add,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final ks = KeepsetTheme.of(context);

    return Scaffold(
      backgroundColor: ks.background,
      body: Stack(
        children: [
          // CONTENT
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 120, bottom: 110),
              child: body,
            ),
          ),

          // TOP BAR
          SafeArea(
            child: MyAppBar(
              title: title,
              iconName: actionIcon,
              onIconTap: onActionTap,
            ),
          ),

          // BOTTOM BAR
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _BottomBar(
                  selectedIndex: selectedIndex,
                  onTap: onTabChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ks = KeepsetTheme.of(context);

    const icons = [
      Iconsax.home,
      Iconsax.note,
      Iconsax.element_3,
      Iconsax.setting_2,
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: ks.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          icons.length,
          (i) => IconButton(
            icon: Icon(
              icons[i],
              color: i == selectedIndex ? ks.textPrimary : ks.textMuted,
            ),
            onPressed: () => onTap(i),
          ),
        ),
      ),
    );
  }
}
