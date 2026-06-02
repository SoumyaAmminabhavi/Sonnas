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

    int width = img.naturalWidth;
    int height = img.naturalHeight;
    if (width == 0 || height == 0) {
      html.window.console.warn('Image loaded but natural dimensions are 0');
      return bytes;
    }

    // Downscale if image exceeds max dimension (e.g. 1024px) to optimize payload sizes
    const double maxDimension = 1024.0;
    if (width > maxDimension || height > maxDimension) {
      if (width > height) {
        height = ((height * maxDimension) / width).round();
        width = maxDimension.round();
      } else {
        width = ((width * maxDimension) / height).round();
        height = maxDimension.round();
      }
    }

    final canvas = html.CanvasElement()
      ..width = width
      ..height = height;
    canvas.context2D.drawImageScaled(img, 0, 0, width, height);

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

    int width = img.naturalWidth;
    int height = img.naturalHeight;
    if (width == 0 || height == 0) {
      html.window.console.warn('Image loaded but natural dimensions are 0');
      return bytes;
    }

    // Downscale if image exceeds max dimension (e.g. 1024px) to optimize payload sizes
    const double maxDimension = 1024.0;
    if (width > maxDimension || height > maxDimension) {
      if (width > height) {
        height = ((height * maxDimension) / width).round();
        width = maxDimension.round();
      } else {
        width = ((width * maxDimension) / height).round();
        height = maxDimension.round();
      }
    }

    final canvas = html.CanvasElement()
      ..width = width
      ..height = height;
    canvas.context2D.drawImageScaled(img, 0, 0, width, height);

    // Use 0.8 quality parameter for WebP to get excellent compression and high fidelity
    final dataUrl = canvas.toDataUrl('image/webp', 0.8);
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
