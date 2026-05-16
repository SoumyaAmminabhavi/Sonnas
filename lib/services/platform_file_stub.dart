/// Minimal platform-neutral stub for File class to support cross-platform builds.
class File {
  final String path;
  File(this.path);

  Future<List<int>> readAsBytes() async => throw UnsupportedError("PlatformFileStub.readAsBytes is not implemented for the current platform.");
}
