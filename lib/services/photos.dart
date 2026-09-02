/// The optional photo on a care card. The chosen file is copied into the app's
/// own documents directory so it survives, and it is never uploaded anywhere.
library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> pickCardPhoto() async {
  try {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 82,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/card-photos');
    if (!photos.existsSync()) photos.createSync(recursive: true);
    final name = 'photo-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${photos.path}/$name');
    await dest.writeAsBytes(await picked.readAsBytes());
    return dest.path;
  } catch (_) {
    return null;
  }
}

/// Reads a stored photo, or null if the file has gone. A missing photo falls
/// back to the initial; it never renders as a broken card.
File? photoFile(String? path) {
  if (path == null) return null;
  final file = File(path);
  return file.existsSync() ? file : null;
}

/// Deletes a photo the app copied in, once no card points at it any more —
/// replaced, removed, or on the card's deletion. Every copy is invisible
/// storage the app promised lives only here, so it must not outlive its card.
///
/// Only files inside the app's own `card-photos/` directory are touched; a
/// path from anywhere else is ignored.
Future<void> deleteCardPhoto(String? path) async {
  if (path == null) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final photos = '${dir.path}/card-photos';
    if (!File(path).existsSync()) return;
    if (!path.startsWith('$photos/')) return;
    await File(path).delete();
  } catch (_) {
    // A photo that cannot be deleted right now is re-attempted the next time
    // something replaces it; never worth surfacing.
  }
}
