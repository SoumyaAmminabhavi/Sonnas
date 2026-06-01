// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<Uint8List> convertToPng(Uint8List bytes, String fileName) async {
  final ext = fileName.split('.').last.toLowerCase();
  if (ext == 'gif') return bytes;

  try {
    final img = html.ImageElement();
    img.src = html.Url.createObjectUrl(html.Blob([bytes]));
    await img.onLoad.first.timeout(const Duration(seconds: 10));
    html.Url.revokeObjectUrl(img.src!);

    final int width = img.naturalWidth;
    final int height = img.naturalHeight;
    if (width == 0 || height == 0) {
      html.window.console.warn('Image loaded but natural dimensions are 0');
      return bytes;
    }

    final canvas = html.CanvasElement()
      ..width = width
      ..height = height;
    canvas.context2D.drawImage(img, 0, 0);

    final dataUrl = canvas.toDataUrl('image/png');
    if (!dataUrl.startsWith('data:image/png')) {
      html.window.console.warn('Canvas toDataURL returned non-png data url');
      return bytes;
    }

    return base64Decode(dataUrl.split(',').last);
  } catch (e) {
    html.window.console.error('PNG conversion failed: $e');
    return bytes;
  }
}

Future<Uint8List> convertToWebP(Uint8List bytes, String fileName) async {
  final ext = fileName.split('.').last.toLowerCase();
  if (ext == 'webp' || ext == 'gif') return bytes;

  try {
    final img = html.ImageElement();
    img.src = html.Url.createObjectUrl(html.Blob([bytes]));
    await img.onLoad.first.timeout(const Duration(seconds: 10));
    html.Url.revokeObjectUrl(img.src!);

    final int width = img.naturalWidth;
    final int height = img.naturalHeight;
    if (width == 0 || height == 0) {
      html.window.console.warn('Image loaded but natural dimensions are 0');
      return bytes;
    }

    final canvas = html.CanvasElement()
      ..width = width
      ..height = height;
    canvas.context2D.drawImage(img, 0, 0);

    final dataUrl = canvas.toDataUrl('image/webp');
    if (!dataUrl.startsWith('data:image/webp')) {
      html.window.console.warn('Canvas toDataURL returned non-webp data url');
      return bytes;
    }

    return base64Decode(dataUrl.split(',').last);
  } catch (e) {
    html.window.console.error('WebP conversion failed: $e');
    return bytes;
  }
}
