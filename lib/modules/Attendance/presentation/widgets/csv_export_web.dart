import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> exportCsv(String csv, String fileName) async {
  // Convert CSV string to bytes
  final Uint8List bytes = Uint8List.fromList(csv.codeUnits);

  // Convert Dart bytes → JS Uint8Array
  final jsBytes = bytes.toJS;

  final blob = web.Blob(
    [jsBytes].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
