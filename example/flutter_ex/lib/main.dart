import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:epub_plus/epub_plus.dart' as epub;
import 'package:image/image.dart' as image;

void main() => runApp(const EpubWidget());

class EpubWidget extends StatefulWidget {
  const EpubWidget({super.key});

  @override
  State<StatefulWidget> createState() => EpubState();
}

class EpubState extends State<EpubWidget> {
  Future<epub.EpubBookRef>? book;

  final _urlController = TextEditingController();

  void fetchBookButton() {
    setState(() {
      book = fetchBook(_urlController.text);
    });
  }

  void fetchBookPresets(String link) {
    setState(() {
      book = fetchBook(link);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Fetch Epub Example",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 16.0)),
                const Text(
                  'Epub Inspector',
                  style: TextStyle(fontSize: 25.0),
                ),
                const Padding(padding: EdgeInsets.only(top: 50.0)),
                const Text(
                  'Enter the Url of an Epub to view some of it\'s metadata.',
                  style: TextStyle(fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
                const Padding(padding: EdgeInsets.only(top: 20.0)),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Enter Url",
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(),
                    ),
                  ),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Url cannot be empty";
                    } else {
                      return null;
                    }
                  },
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                ),
                ElevatedButton(
                  onPressed: fetchBookButton,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(8.0)),
                    textStyle:
                        MaterialStateProperty.all<TextStyle>(const TextStyle(
                      color: Colors.white,
                    )),
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                  ),
                  child: const Text("Inspect Book"),
                ),
                const Padding(padding: EdgeInsets.only(top: 25.0)),
                const Text(
                  'Or select available links:',
                  style: TextStyle(fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
                const Padding(padding: EdgeInsets.only(top: 12.0)),
                Column(
                  children: [
                    ...[
                      'https://filesamples.com/samples/ebook/epub/Around%20the%20World%20in%2028%20Languages.epub',
                      'https://filesamples.com/samples/ebook/epub/Sway.epub',
                      'https://filesamples.com/samples/ebook/epub/Alices%20Adventures%20in%20Wonderland.epub',
                      'https://filesamples.com/samples/ebook/epub/sample1.epub',
                    ]
                        .map((link) => TextButton(
                              child: Text(link),
                              onPressed: () => fetchBookPresets(link),
                            ))
                        .cast<Widget>(),
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: 25.0)),
                Center(
                  child: FutureBuilder<epub.EpubBookRef>(
                    future: book,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Material(
                          color: Colors.white,
                          child: buildEpubWidget(snapshot.data!),
                        );
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      // By default, show a loading spinner
                      // return CircularProgressIndicator();

                      // By default, show just empty.
                      return Container();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildEpubWidget(epub.EpubBookRef book) {
  var cover = book.readCover();
  return Column(
    children: <Widget>[
      const Text(
        "Title",
        style: TextStyle(fontSize: 20.0),
      ),
      Text(
        book.title!,
        style: const TextStyle(fontSize: 15.0),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 15.0),
      ),
      const Text(
        "Author",
        style: TextStyle(fontSize: 20.0),
      ),
      Text(
        book.author!,
        style: const TextStyle(fontSize: 15.0),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 15.0),
      ),
      Column(
        children: <Widget>[
          const Text("Chapters", style: TextStyle(fontSize: 20.0)),
          Text(
            book.getChapters().length.toString(),
            style: const TextStyle(fontSize: 15.0),
          )
        ],
      ),
      const Padding(
        padding: EdgeInsets.only(top: 15.0),
      ),
      FutureBuilder<epub.Image?>(
        future: cover,
        builder: (context, AsyncSnapshot<epub.Image?> snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: <Widget>[
                const Text("Cover", style: TextStyle(fontSize: 20.0)),
                Image.memory(
                    Uint8List.fromList(image.encodePng(snapshot.data!))),
              ],
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return Container();
        },
      ),
    ],
  );
}

// Needs a url to a valid url to an epub such as
// https://www.gutenberg.org/ebooks/11.epub.images
// or
// https://www.gutenberg.org/ebooks/19002.epub.images
Future<epub.EpubBookRef> fetchBook(String url) async {
  // Hard coded to Alice Adventures In Wonderland in Project Gutenberb
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the EPUB
    return epub.EpubReader.openBook(response.bodyBytes);
  } else {
    // If that response was not OK, throw an error.
    throw Exception('Failed to load epub');
  }
}
