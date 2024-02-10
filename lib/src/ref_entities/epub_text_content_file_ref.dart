import 'dart:async';

import 'epub_content_file_ref.dart';

class EpubTextContentFileRef extends EpubContentFileRef {
  EpubTextContentFileRef(super.epubBookRef);

  Future<String> readContentAsync() => readContentAsText();
}
