import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbridge/presentation/providers/settings_provider.dart';
import 'package:quickbridge/presentation/providers/pairing_provider.dart';
import 'package:quickbridge/core/theme/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final pairing = ref.watch(pairingProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<int?, String> dropdownOptions = {
      24: '24 Hours',
      72: '3 Days',
      168: '7 Days',
      null: 'Never',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkBackgroundGradient) : null,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Device Information Section
            _buildSectionHeader(context, 'Device Info'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.devices_rounded, color: Color(0xFF6366F1)),
                title: const Text('Local Device Name'),
                subtitle: Text(pairing.localDeviceName),
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader(context, 'Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_rounded, color: Color(0xFF8B5CF6)),
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Enable dark mode UI styling'),
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleTheme(val);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  
                  // Auto-Delete/Cleanup schedule dropdown
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF06B6D4)),
                    title: const Text('Auto-Delete Files'),
                    subtitle: const Text('Permanent server cleanup schedule'),
                    trailing: DropdownButton<int?>(
                      value: settings.cleanupHours,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      underline: const SizedBox(),
                      items: dropdownOptions.entries.map((entry) {
                        return DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (hours) {
                        if (pairing.activePairId != null) {
                          // Update Firestore and settings provider
                          ref.read(pairingProvider.notifier).changeCleanupConfig(hours);
                        } else {
                          // Update local settings provider only
                          ref.read(settingsProvider.notifier).updateCleanupHours(hours);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            _buildSectionHeader(context, 'About'),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6)),
                    title: Text('QuickBridge'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Colors.green),
                    title: const Text('Security'),
                    subtitle: const Text('Encrypted HTTPS/TLS transfers & automatic cleanup'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Security Policy'),
                          content: const Text(
                            'QuickBridge is built for safety and privacy:\n\n'
                            '• No account tracking or logins.\n'
                            '• Pairing is secured locally via QR verification.\n'
                            '• All transfers run over TLS.\n'
                            '• Files are automatically deleted based on your cleanup setting.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
