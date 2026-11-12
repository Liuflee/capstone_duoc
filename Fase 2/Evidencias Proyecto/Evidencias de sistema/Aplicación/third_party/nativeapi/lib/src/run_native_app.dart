/// Runs a desktop application without Flutter.
///
/// This functionality is unavailable when using Dart 3.14.
void runNativeApp(void Function() main) {
  throw UnsupportedError(
    'runNativeApp is not supported with Dart 3.14.',
  );
}
