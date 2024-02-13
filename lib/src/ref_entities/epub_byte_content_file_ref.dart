import 'dart:async';

import 'epub_content_file_ref.dart';

class EpubByteContentFileRef extends EpubContentFileRef {
  EpubByteContentFileRef({
    required super.epubBookRef,
    super.fileName,
    super.contentMimeType,
    super.contentType,
  });

  Future<List<int>> readContent() => readContentAsBytes();
}
