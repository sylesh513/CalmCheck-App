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
