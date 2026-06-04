import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:quickbridge/core/theme/theme.dart';
import 'package:quickbridge/core/utils/file_utils.dart';
import 'package:quickbridge/presentation/providers/pairing_provider.dart';
import 'package:quickbridge/presentation/providers/transfer_provider.dart';
import 'package:quickbridge/presentation/widgets/file_transfer_card.dart';
import 'package:quickbridge/presentation/widgets/offline_indicator.dart';
import '../shared/settings_screen.dart';
import 'qr_pair_screen.dart';

class WindowsConnectedScreen extends ConsumerWidget {
  const WindowsConnectedScreen({super.key});

  Future<void> _pickAndSendFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final File file = File(result.files.single.path!);
      await ref.read(transferProvider.notifier).shareFile(file);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingProvider);
    final transferState = ref.watch(transferProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to pairing state to redirect if disconnected
    ref.listen(pairingProvider, (previous, next) {
      if (next.pairing == null || next.pairing?.status == 'disconnected') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QRPairScreen()),
        );
      }
    });

    // Listen to transfer errors to show SnackBar
    ref.listen(transferProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(transferProvider.notifier).clearErrorMessage();
      }
    });

    final pairingModel = pairing.pairing;
    final String partnerDevice = pairingModel?.androidDeviceName ?? 'Android Device';

    return Scaffold(
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkBackgroundGradient) : null,
        child: Row(
          children: [
            // Left Navigation Sidebar (Premium Look)
            Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.swap_calls_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'QuickBridge',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Connection status card
                  Card(
                    elevation: 0,
                    color: (isDark ? Colors.grey.shade900 : Colors.grey.shade100).withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAIRED DEVICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  partnerDevice,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Settings'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                    label: const Text('Disconnect'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Disconnect Device?'),
                          content: Text('Are you sure you want to end pairing session with $partnerDevice?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                              onPressed: () {
                                Navigator.of(context).pop();
                                ref.read(pairingProvider.notifier).disconnect();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Vertical divider
            const VerticalDivider(width: 1, thickness: 1),

            // Main View Area (Responsive details)
            Expanded(
              child: Column(
                children: [
                  const OfflineIndicator(),
                  
                  // Top Title bar
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        const Text(
                          'Transfers Control Panel',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Upload File'),
                          onPressed: () => _pickAndSendFile(context, ref),
                        ),
                      ],
                    ),
                  ),

                  // Content Layout split in two: Active/Send & Shared List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Active Progress card list
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ACTIVE TRANSFERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 12),
                                if (transferState.activeTransfers.isEmpty)
                                  Expanded(
                                    child: Center(
                                      child: Card(
                                        elevation: 0,
                                        color: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, style: BorderStyle.solid),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: InkWell(
                                          onTap: () => _pickAndSendFile(context, ref),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.all(40),
                                            width: double.infinity,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.drive_folder_upload_rounded, size: 48, color: Colors.grey.shade400),
                                                const SizedBox(height: 12),
                                                const Text('No Active Transfers', style: TextStyle(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 4),
                                                const Text('Click here or "Upload File" above to pick a file.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: transferState.activeTransfers.length,
                                      itemBuilder: (context, index) {
                                        final progress = transferState.activeTransfers.values.elementAt(index);
                                        return FileTransferCard(progress: progress);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right side: Shared History list
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SHARED FILES HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: transferState.files.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
                                              const SizedBox(height: 12),
                                              const Text('No files shared in this session yet.', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: transferState.files.length,
                                          itemBuilder: (context, index) {
                                            final file = transferState.files[index];
                                            final bool isLocalUploader = file.uploaderDevice == pairing.localDeviceName;
                                            final String timeStr = '${file.uploadTime.hour.toString().padLeft(2, '0')}:${file.uploadTime.minute.toString().padLeft(2, '0')}';

                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              child: ListTile(
                                                leading: Icon(
                                                  file.fileType == 'pdf'
                                                      ? Icons.picture_as_pdf_rounded
                                                      : (file.fileType == 'doc' || file.fileType == 'docx'
                                                          ? Icons.description_rounded
                                                          : Icons.image_rounded),
                                                  color: file.fileType == 'pdf'
                                                      ? Colors.redAccent
                                                      : (file.fileType == 'doc' || file.fileType == 'docx'
                                                          ? Colors.blueAccent
                                                          : Colors.orangeAccent),
                                                  size: 24,
                                                ),
                                                title: Text(
                                                  file.fileName,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  '${FileUtils.formatBytes(file.fileSize)} • $timeStr • ${isLocalUploader ? 'Sent' : 'Received'}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (!isLocalUploader)
                                                      IconButton(
                                                        icon: const Icon(Icons.download_rounded, color: Colors.indigoAccent),
                                                        onPressed: () => ref.read(transferProvider.notifier).fetchFile(file),
                                                      ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: const Text('Delete File?'),
                                                            content: Text('Permanently delete ${file.fileName} from cloud storage?'),
                                                            actions: [
                                                              TextButton(
                                                                child: const Text('Cancel'),
                                                                onPressed: () => Navigator.of(context).pop(),
                                                              ),
                                                              TextButton(
                                                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                  ref.read(transferProvider.notifier).removeFile(file);
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                onTap: () async {
                                                  // Open downloaded file
                                                  final String userProfile = Platform.environment['USERPROFILE'] ?? '';
                                                  final localFile = File('$userProfile\\Downloads\\${file.fileName}');
                                                  if (localFile.existsSync()) {
                                                    await OpenFilex.open(localFile.path);
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('File not downloaded. Click the download icon first.')),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
