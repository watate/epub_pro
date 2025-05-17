import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:image/image.dart' as images;

import '../ref_entities/epub_book_ref.dart';
// import '../ref_entities/epub_byte_content_file_ref.dart';

class BookCoverReader {
  static Future<images.Image?> readBookCover(EpubBookRef bookRef) async {
    // Try to find explicit cover first
    final metaItems = bookRef.schema?.package?.metadata?.metaItems;
    if (metaItems != null && metaItems.isNotEmpty) {
      final coverMetaItem = metaItems.firstWhereOrNull((metaItem) =>
          metaItem.name != null && metaItem.name!.toLowerCase() == 'cover');
      
      if (coverMetaItem?.content != null && coverMetaItem!.content!.isNotEmpty) {
        var coverManifestItem = bookRef.schema?.package?.manifest?.items
            .firstWhereOrNull((manifestItem) =>
                manifestItem.id?.toLowerCase() ==
                coverMetaItem.content?.toLowerCase());
                
        if (coverManifestItem != null && 
            bookRef.content?.images.containsKey(coverManifestItem.href) == true) {
          var coverImageContentFileRef = bookRef.content!.images[coverManifestItem.href];
          var coverImageContent = await coverImageContentFileRef!.readContentAsBytes();
          return images.decodeImage(Uint8List.fromList(coverImageContent));
        }
      }
    }

    // Fall back to first image if no explicit cover found
    if (bookRef.content?.images.isNotEmpty == true) {
      var firstImage = bookRef.content!.images.values.first;
      var imageContent = await firstImage.readContentAsBytes();
      return images.decodeImage(Uint8List.fromList(imageContent));
    }

    return null;
  }
}
