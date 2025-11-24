/// Stub implementation for non-web platforms
void downloadFile(List<int> bytes, String fileName) {
  // Not supported on mobile - do nothing
  throw UnsupportedError('Download is only supported on web platform');
}