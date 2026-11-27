import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Triggers a browser download for a generated report or invoice on Flutter Web.
Future<String?> saveInvoiceBytesOnWeb(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/pdf',
}) async {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(const Duration(seconds: 2), () {
    web.URL.revokeObjectURL(url);
  });
  return fileName;
}
