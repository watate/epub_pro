import 'dart:html';
import 'package:http/http.dart' as http;
import 'package:epub_plus/epub_plus.dart' as epub;

void main() async {
  querySelector('#output')?.text = 'Your Dart app is running.';

  var epubRes = await http.get(Uri.parse('alicesAdventuresUnderGround.epub'));
  if (epubRes.statusCode == 200) {
    var book = await epub.EpubReader.openBook(epubRes.bodyBytes);
    querySelector('#title')?.text = book.title;
    querySelector('#author')?.text = book.author;
    var chapters = await book.getChapters();
    querySelector('#nchapters')?.text = chapters.length.toString();
    querySelectorAll('h2').style.visibility = 'visible';
  }
}
