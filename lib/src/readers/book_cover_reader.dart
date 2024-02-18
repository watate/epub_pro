import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:image/image.dart' as images;

import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';

class BookCoverReader {
  static Future<images.Image?> readBookCover(EpubBookRef bookRef) async {
    final metaItems = bookRef.schema?.package?.metadata?.metaItems;
    if (metaItems == null || metaItems.isEmpty) return null;

    final coverMetaItem = metaItems.firstWhereOrNull((metaItem) =>
        metaItem.name != null && metaItem.name!.toLowerCase() == 'cover');
    if (coverMetaItem == null) return null;
    if (coverMetaItem.content == null || coverMetaItem.content!.isEmpty) {
      throw Exception(
        'Incorrect EPUB metadata: cover item content is missing.',
      );
    }

    var coverManifestItem = bookRef.schema?.package?.manifest?.items
        .firstWhereOrNull((manifestItem) =>
            manifestItem.id?.toLowerCase() ==
            coverMetaItem.content?.toLowerCase());
    if (coverManifestItem == null) {
      throw Exception(
        'Incorrect EPUB manifest: item with ID = "${coverMetaItem.content}" is missing.',
      );
    }

    EpubByteContentFileRef? coverImageContentFileRef;
    if (!bookRef.content!.images.containsKey(coverManifestItem.href)) {
      throw Exception(
        'Incorrect EPUB manifest: item with href = "${coverManifestItem.href}" is missing.',
      );
    }

    coverImageContentFileRef = bookRef.content!.images[coverManifestItem.href];
    var coverImageContent =
        await coverImageContentFileRef!.readContentAsBytes();
    var retval = images.decodeImage(Uint8List.fromList(coverImageContent));
    return retval;
  }
}
