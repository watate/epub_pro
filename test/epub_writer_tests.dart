library epubreadertest;

import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

main() async {
  String fileName = "alicesAdventuresUnderGround.epub";
  String fullPath =
      path.join(io.Directory.current.path, "assets", fileName);
  var targetFile = io.File(fullPath);
  if (!(await targetFile.exists())) {
    throw Exception("Specified epub file not found: $fullPath");
  }

  List<int> bytes = await targetFile.readAsBytes();

  test("Book Round Trip", () async {
    EpubBook book = await EpubReader.readBook(bytes);

    var written = EpubWriter.writeBook(book);
    var bookRoundTrip = await EpubReader.readBook(Future.value(written));

    // The hierarchical structure may change after round-trip due to NCX/spine reconciliation
    // So we check key properties instead of full equality
    expect(bookRoundTrip.title, equals(book.title));
    expect(bookRoundTrip.author, equals(book.author));
    expect(bookRoundTrip.schema?.package?.metadata, equals(book.schema?.package?.metadata));
    
    // Check that all content files are preserved
    expect(bookRoundTrip.content?.html?.keys.toSet(), 
           equals(book.content?.html?.keys.toSet()));
    expect(bookRoundTrip.content?.css?.keys.toSet(), 
           equals(book.content?.css?.keys.toSet()));
    expect(bookRoundTrip.content?.images?.keys.toSet(), 
           equals(book.content?.images?.keys.toSet()));
    
    // Note: Chapter structure may differ due to the improved NCX/spine reconciliation
    // The original book might have a flat structure while the round-trip version
    // properly nests orphaned spine items under their logical parents
  });
}
