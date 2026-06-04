import 'package:flutter/material.dart';
import '../../utils/file_utils.dart';
import '../../providers/transfer_provider.dart';

class FileTransferCard extends StatelessWidget {
  final TransferProgress progress;

  const FileTransferCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = progress.progressPercent * 100;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Direction icon
                CircleAvatar(
                  radius: 18,
                  backgroundColor: progress.isUpload
                      ? Colors.indigoAccent.withOpacity(0.1)
                      : Colors.tealAccent.withOpacity(0.1),
                  child: Icon(
                    progress.isUpload ? Icons.upload_rounded : Icons.download_rounded,
                    color: progress.isUpload ? Colors.indigoAccent : Colors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // File name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Size: ${FileUtils.formatBytes(progress.totalBytes)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // Progress percent text
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progressPercent,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(
                  progress.isUpload ? const Color(0xFF6366F1) : const Color(0xFF06B6D4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Speed and remaining details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      progress.formattedSpeed,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      progress.formattedRemainingTime,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
