import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../shared/widgets/rydar_screen_chrome.dart';
import '../../shared/widgets/rydar_stitch_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceFeedback = true;

  @override
  Widget build(BuildContext context) {
    final tokenAdded = AppConfig.hasMapboxToken;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const RydarTaskHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  RydarSettingsRow(
                    icon: Icons.map_rounded,
                    label: 'Map style',
                    value: 'Dark',
                    onTap: () => _showMessage('Dark map style is active.'),
                  ),
                  RydarSettingsRow(
                    icon: Icons.straighten_rounded,
                    label: 'Units',
                    value: 'Kilometers',
                    onTap: () => _showMessage('Kilometers are active.'),
                  ),
                  RydarSettingsRow(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Voice feedback',
                    trailing: _OrangeSwitch(
                      value: _voiceFeedback,
                      onChanged: (value) {
                        setState(() => _voiceFeedback = value);
                        _showMessage(
                          value
                              ? 'Voice feedback enabled for this session.'
                              : 'Voice feedback muted for this session.',
                        );
                      },
                    ),
                  ),
                  const RydarSettingsRow(
                    icon: Icons.palette_rounded,
                    label: 'App theme',
                    value: 'Dark',
                    locked: true,
                  ),
                  RydarSettingsRow(
                    icon: Icons.key_rounded,
                    label: 'Mapbox',
                    value: tokenAdded ? 'Token added' : 'Token missing',
                    onTap: () => _showMessage(
                      tokenAdded
                          ? 'Mapbox maps and route planning are enabled.'
                          : 'Add MAPBOX_ACCESS_TOKEN in your local .env file.',
                    ),
                  ),
                  RydarSettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About Rydar',
                    value: 'v0.1.0',
                    onTap: () => _showMessage(
                      'Rydar tracks guest rides locally on this device.',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'GUEST MODE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Some settings require an account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.25),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          _showMessage('Accounts are coming soon.'),
                      child: Text(
                        'CREATE AN ACCOUNT',
                        style: TextStyle(
                          color: AppColors.orange.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OrangeSwitch extends StatelessWidget {
  const _OrangeSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.orange,
      inactiveThumbColor: AppColors.secondary,
      inactiveTrackColor: AppColors.surfaceContainerHigh,
      onChanged: onChanged,
    );
  }
}
