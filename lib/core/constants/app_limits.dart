abstract final class AppLimits {
  /// Files above this size are rejected to protect memory.
  static const int maxFileBytes = 500 * 1024 * 1024;

  /// Longest side of the in-editor preview; export always uses full resolution.
  static const int previewMaxSide = 1024;

  static const int historyLimit = 200;
}
