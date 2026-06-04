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
import 'scan_qr_screen.dart';

class AndroidConnectedScreen extends ConsumerWidget {
  const AndroidConnectedScreen({super.key});

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
      if (next.pairing == null || next.pairing!.status == 'disconnected') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScanQRScreen()),
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
    final String partnerDevice = pairingModel?.desktopDeviceName ?? 'Windows PC';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickBridge Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Disconnect?'),
                  content: Text('Are you sure you want to end pairing with $partnerDevice?'),
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
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkBackgroundGradient) : null,
        child: Column(
          children: [
            // Offline warning
            const OfflineIndicator(),

            // Connection Card header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.phonelink_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connected to Desktop',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              partnerDevice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent, width: 1),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Active Transfers Section
            if (transferState.activeTransfers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Active Transfers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: transferState.activeTransfers.length,
                  itemBuilder: (context, index) {
                    final progress = transferState.activeTransfers.values.elementAt(index);
                    return FileTransferCard(progress: progress);
                  },
                ),
              ),
            ],

            // Transferred Files Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transferred Files',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: transferState.files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No files shared yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                              size: 28,
                            ),
                            title: Text(
                              file.fileName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${FileUtils.formatBytes(file.fileSize)} • $timeStr • ${isLocalUploader ? 'Sent' : 'Received'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                        content: Text('Are you sure you want to permanently delete ${file.fileName} from server storage?'),
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
                              // Verify if file has been downloaded locally
                              final userProfile = Platform.isAndroid ? '/storage/emulated/0/Download' : '';
                              final localFile = File('$userProfile/${file.fileName}');
                              if (localFile.existsSync()) {
                                await OpenFilex.open(localFile.path);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('File not downloaded yet. Press download button first.')),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
            
            // Bottom Send Action panel
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Send File'),
                onPressed: () => _pickAndSendFile(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
