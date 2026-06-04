class SpeedCalculator {
  final int totalBytes;
  final DateTime startTime;
  
  SpeedCalculator({required this.totalBytes}) : startTime = DateTime.now();

  /// Calculates the current speed in bytes per second.
  double getBytesPerSecond(int bytesTransferred) {
    final now = DateTime.now();
    final duration = now.difference(startTime).inMilliseconds;
    if (duration <= 0) return 0.0;
    return (bytesTransferred / duration) * 1000.0;
  }

  /// Formats the transfer speed into a human-readable string (e.g. "2.5 MB/s").
  String getFormattedSpeed(int bytesTransferred) {
    final double bytesPerSecond = getBytesPerSecond(bytesTransferred);
    if (bytesPerSecond <= 0) return '0 B/s';
    
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = 0;
    double speed = bytesPerSecond;
    while (speed >= 1024 && i < suffixes.length - 1) {
      speed /= 1024;
      i++;
    }
    return '${speed.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Estimates the remaining time in seconds.
  int? getRemainingSeconds(int bytesTransferred) {
    final double bytesPerSecond = getBytesPerSecond(bytesTransferred);
    if (bytesPerSecond <= 0) return null;
    
    final int remainingBytes = totalBytes - bytesTransferred;
    if (remainingBytes <= 0) return 0;
    
    return (remainingBytes / bytesPerSecond).round();
  }

  /// Formats the remaining time into a human-readable string (e.g., "01:23 remaining" or "Calculating...").
  String getFormattedRemainingTime(int bytesTransferred) {
    final remainingSeconds = getRemainingSeconds(bytesTransferred);
    if (remainingSeconds == null) return 'Calculating...';
    if (remainingSeconds == 0) return 'Completed';

    final int minutes = remainingSeconds ~/ 60;
    final int seconds = remainingSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    } else {
      return '${seconds}s remaining';
    }
  }
}
