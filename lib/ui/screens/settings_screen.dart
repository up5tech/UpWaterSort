import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';

/// Sound, haptics, color-blind mode, theme and language, plus "Reset data"
/// (PLAN.md §12.2, §21 Phase 5). Every option is persisted immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final strings = stringsFor(settings.locale);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(strings.sound),
            value: settings.sound,
            onChanged: settings.setSound,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(strings.vibration),
            value: settings.vibration,
            onChanged: settings.setVibration,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: Text(strings.colorBlindMode),
            value: settings.colorBlind,
            onChanged: settings.setColorBlind,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(strings.darkMode),
            value: settings.darkMode,
            onChanged: settings.setDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(strings.language),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('English'),
                    selected: settings.locale == 'en',
                    onSelected: (_) => settings.setLocale('en'),
                  ),
                  ChoiceChip(
                    label: const Text('Tiếng Việt'),
                    selected: settings.locale == 'vi',
                    onSelected: (_) => settings.setLocale('vi'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              strings.resetData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmReset(context, settings, strings),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    SettingsController settings,
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.resetConfirmTitle),
        content: Text(strings.resetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.reset),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await settings.resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(stringsFor(settings.locale).resetDone)),
      );
  }
}
