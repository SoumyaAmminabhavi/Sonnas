import 'dart:typed_data';

/// Minimal platform-neutral stub for File class to support cross-platform builds.
class File {
  final String path;
  File(this.path);

  Future<Uint8List> readAsBytes() async => throw UnsupportedError("PlatformFileStub.readAsBytes is not implemented for the current platform.");
}
