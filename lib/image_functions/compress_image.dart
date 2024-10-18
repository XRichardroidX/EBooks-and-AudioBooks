import 'dart:typed_data';

int estimateCompressedFileSize(Uint8List image) {
  final imageSizeInBytes = image.lengthInBytes;

  if (imageSizeInBytes >= 12 * 1024 * 1024) {
    // 10MB or more
    return (imageSizeInBytes * 0.10).round();
  } else if (imageSizeInBytes >= 8 * 1024 * 1024) {
    // 8MB to 10MB
    return (imageSizeInBytes * 0.12).round();
  } else if (imageSizeInBytes >= 6 * 1024 * 1024) {
    // 6MB to 8MB
    return (imageSizeInBytes * 0.14).round();
  } else if (imageSizeInBytes >= 4 * 1024 * 1024) {
    // 4MB to 6MB
    return (imageSizeInBytes * 0.18).round();
  } else if (imageSizeInBytes >= 2 * 1024 * 1024) {
    // 2MB to 4MB
    return (imageSizeInBytes * 0.22).round();
  } else if (imageSizeInBytes >= 512 * 1024) {
    // 1MB to 2MB
    return (imageSizeInBytes * 0.26).round();
  } else {
    // Less than 1MB (500kB or less)
    return (imageSizeInBytes * 0.30)
        .round(); // Adjust factor for smaller images
  }
}

// Function to determine whether compression is needed based on image quality
bool shouldCompress(Uint8List imageBytes) {
  // Replace these thresholds with your own criteria

  int maxAllowedFileSize = 999 * 1024; // 500 KB

  // Check file size
  bool fileSizeExceedThreshold =
  imageBytes.length > maxAllowedFileSize ? true : false;

  return fileSizeExceedThreshold;
}