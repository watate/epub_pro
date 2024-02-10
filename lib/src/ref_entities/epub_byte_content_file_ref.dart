import 'dart:async';

import 'epub_content_file_ref.dart';

class EpubByteContentFileRef extends EpubContentFileRef {
  EpubByteContentFileRef(super.epubBookRef);

  Future<List<int>> readContent() => readContentAsBytes();
}
