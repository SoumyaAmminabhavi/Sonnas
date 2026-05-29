// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<Uint8List> convertToWebP(Uint8List bytes, String fileName) async {
  final ext = fileName.split('.').last.toLowerCase();
  if (ext == 'webp' || ext == 'gif') return bytes;

  try {
    final img = html.ImageElement();
    img.src = html.Url.createObjectUrl(html.Blob([bytes]));
    await img.onLoad.first.timeout(const Duration(seconds: 10));
    html.Url.revokeObjectUrl(img.src!);

    final canvas = html.CanvasElement()
      ..width = img.width!
      ..height = img.height!;
    canvas.context2D.drawImage(img, 0, 0);

    final dataUrl = (canvas as dynamic).toDataURL('image/webp') as String;
    if (!dataUrl.startsWith('data:image/webp')) return bytes;

    return base64Decode(dataUrl.split(',').last);
  } catch (_) {
    return bytes;
  }
}
