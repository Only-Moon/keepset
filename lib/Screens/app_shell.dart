import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../db/settings_database.dart';
import '../theme/keepset_colors.dart';
import '../theme/keepset_theme.dart';
import '../utils/premium_gate.dart';
import '../widget/customappbar.dart';
import 'home_page.dart';
import 'notes_page.dart';
import 'paywall_page.dart';
import 'settings_page.dart';

class PremiumGatekeeper {
  final bool isSubscribed;

  const PremiumGatekeeper({required this.isSubscribed});

  GateResult gate(PremiumAction action) {
    if (isSubscribed) return const GateAllowed();

    switch (action) {
      case PremiumAction.aiUse:
      case PremiumAction.addWidget:
      case PremiumAction.enableBackup:
      case PremiumAction.restoreBackup:
      case PremiumAction.advancedHomeToggle:
        return const GateBlocked(GateReason.requiresSubscription);
    }
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _TopBarConfig {
  final String title;
  final IconData icon;

  const _TopBarConfig({
    required this.title,
    required this.icon,
  });
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int selectedIndex = 0;

  bool _isSubscribed = false;
  late PremiumGatekeeper _gatekeeper;

  final SettingsDatabase _settings = SettingsDatabase.instance;

  ThemeMode _themeMode = ThemeMode.system;

  // ─────────────────────────────
  // INIT
  // ─────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSubscriptionState();
    _loadTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─────────────────────────────
  // THEME WIRING
  // ─────────────────────────────

  Future<void> _loadTheme() async {
    final raw = await _settings.getString('theme_mode');
    if (!mounted) return;

    final KeepsetThemeMode mode = switch (raw) {
      'light' => KeepsetThemeMode.light,
      'dark' => KeepsetThemeMode.dark,
      _ => KeepsetThemeMode.system,
    };

    KeepsetThemeResolver.setMode(
      mode,
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );

    setState(() {
      _themeMode = mode == KeepsetThemeMode.system
          ? ThemeMode.system
          : mode == KeepsetThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light;
    });
  }

  void _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);

    final KeepsetThemeMode resolved = mode == ThemeMode.system
        ? KeepsetThemeMode.system
        : mode == ThemeMode.dark
            ? KeepsetThemeMode.dark
            : KeepsetThemeMode.light;

    await _settings.setString(
      'theme_mode',
      resolved.name,
    );

    if (!mounted) return;

    KeepsetThemeResolver.setMode(
      resolved,
      MediaQuery.platformBrightnessOf(context),
    );
  }

  @override
  void didChangePlatformBrightness() {
    KeepsetThemeResolver.onSystemBrightnessChanged(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  // ─────────────────────────────
  // SUBSCRIPTION
  // ─────────────────────────────

  Future<void> _loadSubscriptionState() async {
    final isPremium =
        await _settings.getBool('is_premium', defaultValue: false);
    if (!mounted) return;
    setState(() => _isSubscribed = isPremium);
  }

  bool runPremiumAction(
    PremiumAction action, {
    required VoidCallback onAllowed,
  }) {
    final result = _gatekeeper.gate(action);

    if (result is GateAllowed) {
      onAllowed();
      return true;
    }

    if (result is GateBlocked) {
      _openPaywall();
      return false;
    }

    return false;
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallPage(),
      ),
    );
  }

  void _openCreateNote() {
    // handled by NotesPage itself
  }

  // ─────────────────────────────
  // UI CONFIG
  // ─────────────────────────────

  final List<_TopBarConfig> _topBarConfigs = const [
    _TopBarConfig(title: 'Keepset', icon: Iconsax.magicpen),
    _TopBarConfig(title: 'Items', icon: Iconsax.message),
    _TopBarConfig(title: 'Widgets', icon: Iconsax.element_3),
    _TopBarConfig(title: 'Settings', icon: Iconsax.setting_2),
  ];

  late final List<Widget> screens = [
    HomePage(
      onCreateNote: _openCreateNote,
      runPremiumAction: runPremiumAction,
    ),
    NotesPage(
      onCreateNote: _openCreateNote,
      runPremiumAction: runPremiumAction,
    ),
    const _PlaceholderPage(title: 'Widget'),
    SettingsPage(
      currentThemeMode: _themeMode,
      onThemeChanged: _setTheme,
      openPaywall: _openPaywall,
    ),
  ];

  final List<IconData> icons = [
    Icons.home_outlined,
    Iconsax.note,
    Iconsax.element_3,
    Iconsax.setting_2,
  ];

  static const double _topBarHeight = 96;
  static const double _bottomBarHeight = 64;
  static const double _bottomBarPadding = 14;
  static const double _fabOffset = 24;

  // ─────────────────────────────
  // BUILD
  // ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    _gatekeeper = PremiumGatekeeper(isSubscribed: _isSubscribed);

    final media = MediaQuery.of(context);
    final bottomInset = media.viewPadding.bottom;
    final topBar = _topBarConfigs[selectedIndex];

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: KeepsetColors.base,
        systemNavigationBarDividerColor: KeepsetColors.base,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: KeepsetColors.base,
      body: Stack(
        children: [
          Positioned.fill(
            top: _topBarHeight,
            bottom: _bottomBarHeight + _bottomBarPadding * 2 + bottomInset,
            child: IndexedStack(
              index: selectedIndex,
              children: screens,
            ),
          ),
          SafeArea(
            bottom: false,
            child: MyAppBar(
              title: topBar.title,
              iconName: topBar.icon,
              onIconTap: () {
                runPremiumAction(
                  PremiumAction.aiUse,
                  onAllowed: () {},
                );
              },
            ),
          ),
          if (selectedIndex == 0 || selectedIndex == 1)
            Positioned(
              right: _fabOffset,
              bottom:
                  _bottomBarHeight + _bottomBarPadding * 2 + bottomInset + 8,
              child: FloatingActionButton.extended(
                elevation: 10,
                backgroundColor: KeepsetColors.layer2,
                foregroundColor: KeepsetColors.textPrimary,
                icon: const Icon(Icons.add),
                label: const Text(
                  'New item',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  NotesPage.openCreate(context);
                },
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, _bottomBarPadding),
                child: _BottomNavBar(
                  icons: icons,
                  selectedIndex: selectedIndex,
                  onTap: (i) => setState(() => selectedIndex = i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────
// Bottom Navigation
// ─────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.icons,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(26),
      color: KeepsetColors.layer1,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            icons.length,
            (i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Icon(
                icons[i],
                size: 26,
                color: i == selectedIndex
                    ? KeepsetColors.textPrimary
                    : KeepsetColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────
// Placeholder
// ─────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (coming soon)',
        style: TextStyle(
          fontSize: 18,
          color: KeepsetColors.textMuted,
        ),
      ),
    );
  }
}
