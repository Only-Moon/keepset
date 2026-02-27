import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/settings_database.dart';
import '../theme/keepset_colors.dart';
import '../theme/keepset_theme.dart';
import '../utils/notification_service.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback openPaywall;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
    required this.openPaywall,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _db = SettingsDatabase.instance;
  final _notifs = NotificationService.instance;

  bool _ai = false;
  bool _backup = false;
  bool _notifsEnabled = false;

  bool _loggedIn = false;
  String _authProvider = 'none';
  String? _displayName;

  String _subStatus = 'none';
  String? _subPlan;

  PackageInfo? _pkg;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _notifs.init();

    final results = await Future.wait([
      _db.isAiEnabled(),
      _db.isBackupEnabled(),
      _db.isLoggedIn(),
      _db.getAuthProvider(),
      _db.getDisplayName(),
      _db.getSubscriptionStatus(),
      _db.getSubscriptionPlan(),
      Permission.notification.status,
      PackageInfo.fromPlatform(),
    ]);

    if (!mounted) return;

    setState(() {
      _ai = results[0] as bool;
      _backup = results[1] as bool;
      _loggedIn = results[2] as bool;
      _authProvider = results[3] as String;
      _displayName = results[4] as String?;
      _subStatus = results[5] as String;
      _subPlan = results[6] as String?;
      _notifsEnabled = (results[7] as PermissionStatus).isGranted;
      _pkg = results[8] as PackageInfo;
    });
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KeepsetColors.base,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _group([
            _row(
              icon: Iconsax.profile_circle,
              iconColor: KeepsetColors.layer3,
              title: _loggedIn ? (_displayName ?? 'Account') : 'Not signed in',
              value: _loggedIn ? _authProvider : 'Sign in',
              onTap: _sheetSignIn,
            ),
          ]),
          const SizedBox(height: 16),
          _group([
            _row(
              icon: Iconsax.magicpen,
              iconColor: KeepsetColors.layer3,
              title: 'AI',
              value: _ai ? 'On' : 'Off',
              active: _ai,
              onTap: () => _sheetBinary(
                title: 'AI suggestions',
                current: _ai,
                onChange: (v) async {
                  await _db.setAiEnabled(v);
                  if (!mounted) return;
                  setState(() => _ai = v);
                },
              ),
            ),
            _divider(),
            _row(
              icon: Iconsax.shield_tick,
              iconColor: KeepsetColors.layer2,
              title: 'Data',
              value: _backup ? 'Backup' : 'Local only',
              active: _backup,
              onTap: () => _sheetBinary(
                title: 'Backup',
                current: _backup,
                onChange: (v) async {
                  await _db.setBackupEnabled(v);
                  if (!mounted) return;
                  setState(() => _backup = v);
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _group([
            _row(
              icon: Iconsax.colorfilter,
              iconColor: KeepsetColors.layer3,
              title: 'Theme',
              value: _themeLabel(widget.currentThemeMode),
              onTap: _sheetTheme,
            ),
            _divider(),
            _row(
              icon: Iconsax.notification,
              iconColor: KeepsetColors.layer2,
              title: 'Notifications',
              value: _notifsEnabled ? 'Enabled' : 'Disabled',
              active: _notifsEnabled,
              onTap: _sheetNotifications,
            ),
            _divider(),
            _row(
              icon: Iconsax.wallet,
              iconColor: KeepsetColors.layer3,
              title: 'Restore purchases',
              value: _subStatus == 'active'
                  ? (_subPlan ?? 'Active')
                  : 'No subscription',
              onTap: _sheetRestore,
            ),
          ]),
          const SizedBox(height: 16),
          _group([
            _row(
              icon: Iconsax.info_circle,
              iconColor: KeepsetColors.textSecondary,
              title: 'About Keepset',
              value: 'Info',
              onTap: _sheetAbout,
            ),
          ]),
        ],
      ),
    );
  }

  // ───────────────────────── Core Widgets ─────────────────────────

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: KeepsetColors.layer1,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: children),
      );

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool active = false,
    VoidCallback? onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: KeepsetColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color:
                      active ? KeepsetColors.layer3 : KeepsetColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: KeepsetColors.textMuted),
            ],
          ),
        ),
      );

  Widget _divider() => Divider(
        height: 12,
        thickness: 0.5,
        color: KeepsetColors.divider,
      );

  // ───────────────────────── Unified Sheet ─────────────────────────

  void _sheet({
    required String title,
    required Widget body,
    List<Widget>? actions,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: KeepsetColors.layer1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: KeepsetColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              body,
              if (actions != null) ...[
                const SizedBox(height: 20),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Sheets ─────────────────────────

  void _sheetSignIn() => _sheet(
        title: 'Sign in',
        body: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Sign in to enable backup and restore across devices.',
            style: TextStyle(color: KeepsetColors.textSecondary),
          ),
        ),
      );

  void _sheetRestore() => _sheet(
        title: 'Restore purchases',
        body: Text(
          'Previous purchases will be restored automatically when available.',
          style: TextStyle(color: KeepsetColors.textSecondary),
        ),
      );

  void _sheetBinary({
    required String title,
    required bool current,
    required Future<void> Function(bool) onChange,
  }) =>
      _sheet(
        title: title,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _binary('Enable', current, () => onChange(true)),
            _binary('Disable', !current, () => onChange(false)),
          ],
        ),
      );

  Widget _binary(
    String label,
    bool selected,
    Future<void> Function() action,
  ) =>
      ListTile(
        title: Text(
          label,
          style: TextStyle(
            color: selected ? KeepsetColors.layer3 : KeepsetColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing:
            selected ? Icon(Icons.check, color: KeepsetColors.layer3) : null,
        onTap: () async {
          await action();
          if (!mounted) return;
          Navigator.pop(context);
        },
      );

  void _sheetTheme() => _sheet(
        title: 'Theme',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((m) {
            final selected = widget.currentThemeMode == m;
            return ListTile(
              title: Text(
                _themeLabel(m),
                style: TextStyle(
                  color:
                      selected ? KeepsetColors.layer3 : KeepsetColors.textMuted,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check, color: KeepsetColors.layer3)
                  : null,
              onTap: () {
                widget.onThemeChanged(m);

                KeepsetThemeResolver.setMode(
                  m == ThemeMode.system
                      ? KeepsetThemeMode.system
                      : m == ThemeMode.dark
                          ? KeepsetThemeMode.dark
                          : KeepsetThemeMode.light,
                  MediaQuery.platformBrightnessOf(context),
                );

                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      );

  void _sheetNotifications() async {
    final status = await Permission.notification.status;
    if (!mounted) return;

    if (status.isGranted) {
      _sheet(
        title: 'Notifications',
        body: Text(
          'Notifications are enabled for Keepset.',
          style: TextStyle(color: KeepsetColors.textSecondary),
        ),
        actions: [_action('Manage in system settings', openAppSettings)],
      );
    } else if (status.isPermanentlyDenied) {
      _sheet(
        title: 'Notifications disabled',
        body: Text(
          'Notifications are disabled at the system level.',
          style: TextStyle(color: KeepsetColors.textSecondary),
        ),
        actions: [_action('Open system settings', openAppSettings)],
      );
    } else {
      _sheet(
        title: 'Notifications',
        body: Text(
          'Keepset sends notifications only for reminders you create.',
          style: TextStyle(color: KeepsetColors.textSecondary),
        ),
        actions: [
          _action(
            'Enable notifications',
            () async {
              final granted = await _notifs.requestPermission();
              if (!mounted) return;
              if (granted) setState(() => _notifsEnabled = true);
            },
          ),
        ],
      );
    }
  }

  void _sheetAbout() => _sheet(
        title: 'About Keepset',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _aboutRow('Version', _pkg?.version ?? '—'),
            _aboutLink(
              'Privacy policy',
              'https://onlymoon.github.io/keepset/privacy',
            ),
            _aboutLink(
              'Terms of service',
              'https://onlymoon.github.io/keepset/terms',
            ),
            _aboutLink(
              'GitHub',
              'https://github.com/OnlyMoon/keepset',
            ),
          ],
        ),
      );

  // ───────────────────────── Helpers ─────────────────────────

  Widget _action(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KeepsetColors.layer2,
            foregroundColor: KeepsetColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            onTap();
            Navigator.pop(context);
          },
          child: Text(label),
        ),
      );

  Widget _aboutRow(String t, String v) =>
      ListTile(title: Text(t), subtitle: Text(v));

  Widget _aboutLink(String t, String u) => ListTile(
        title: Text(t),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => launchUrl(
          Uri.parse(u),
          mode: LaunchMode.inAppBrowserView,
        ),
      );

  String _themeLabel(ThemeMode m) => m == ThemeMode.dark
      ? 'Dark'
      : m == ThemeMode.light
          ? 'Light'
          : 'System';
}
