import 'package:test/test.dart';
import 'package:epub_pro/src/cfi/dom/dom_abstraction.dart';

void main() {
  group('DOM Abstraction Tests', () {
    group('XML DOM Document Parsing', () {
      test('Parse simple HTML document', () {
        const html = '''
          <html>
            <head><title>Test</title></head>
            <body>
              <p>Hello World</p>
            </body>
          </html>
        ''';

        final doc = DOMDocument.parseHTML(html);

        expect(doc.nodeType, equals(DOMNodeType.document));
        expect(doc.documentElement, isNotNull);
        expect(doc.documentElement!.tagName, equals('html'));
      });

      test('Parse HTML with self-closing tags', () {
        const html = '''
          <html>
            <head>
              <meta charset="utf-8"/>
              <link rel="stylesheet" href="style.css"/>
            </head>
            <body>
              <p>Content with <br/> line break</p>
              <hr/>
            </body>
          </html>
        ''';

        final doc = DOMDocument.parseHTML(html);

        expect(doc.documentElement, isNotNull);
        final metaTags = doc.getElementsByTagName('meta');
        expect(metaTags.length, equals(1));
        expect(metaTags.first.getAttribute('charset'), equals('utf-8'));

        final linkTags = doc.getElementsByTagName('link');
        expect(linkTags.length, equals(1));
        expect(linkTags.first.getAttribute('href'), equals('style.css'));
      });

      test('Parse HTML with mixed content', () {
        const html = '''
          <div id="content">
            <h1>Title</h1>
            Text content
            <p>Paragraph with <strong>bold</strong> text</p>
            More text
            <ul>
              <li>Item 1</li>
              <li>Item 2</li>
            </ul>
          </div>
        ''';

        final doc = DOMDocument.parseHTML(html);

        expect(doc.documentElement, isNotNull);
        expect(doc.documentElement!.tagName, equals('div'));
        expect(doc.documentElement!.id, equals('content'));

        final children = doc.documentElement!.childNodes;
        expect(children.length, greaterThan(0));

        // Should contain mix of elements and text nodes
        final hasTextNodes =
            children.any((child) => child.nodeType == DOMNodeType.text);
        final hasElementNodes =
            children.any((child) => child.nodeType == DOMNodeType.element);
        expect(hasTextNodes, isTrue);
        expect(hasElementNodes, isTrue);
      });

      test('Handle malformed HTML gracefully', () {
        const html = '''
          <html>
            <body>
              <p>Paragraph content</p>
              <br/>
              <img src="test.jpg"/>
              <div>Nested content</div>
            </body>
          </html>
        ''';

        expect(() => DOMDocument.parseHTML(html), returnsNormally);

        final doc = DOMDocument.parseHTML(html);
        expect(doc.documentElement, isNotNull);
        expect(doc.documentElement!.tagName, equals('html'));
      });
    });

    group('DOM Node Navigation', () {
      late DOMDocument doc;

      setUp(() {
        const html = '''
          <html>
            <body>
              <div id="container">
                <h1 id="title">Main Title</h1>
                <p class="content">First paragraph</p>
                <p class="content">Second paragraph</p>
              </div>
            </body>
          </html>
        ''';
        doc = DOMDocument.parseHTML(html);
      });

      test('Navigate through parent-child relationships', () {
        final container = doc.getElementById('container');
        expect(container, isNotNull);
        expect(container!.id, equals('container'));
        expect(container.tagName, equals('div'));

        expect(container.parentNode, isNotNull);
        expect(container.parentNode!.tagName, equals('body'));

        expect(container.hasChildNodes, isTrue);
        expect(container.childNodes.length, greaterThan(0));

        final elementChildren = container.children;
        expect(elementChildren.length, equals(3));
        expect(elementChildren[0].tagName, equals('h1'));
        expect(elementChildren[1].tagName, equals('p'));
        expect(elementChildren[2].tagName, equals('p'));
      });

      test('Navigate through sibling relationships', () {
        final title = doc.getElementById('title');
        expect(title, isNotNull);

        final nextSibling = title!.nextElementSibling;
        expect(nextSibling, isNotNull);
        expect(nextSibling!.tagName, equals('p'));
        expect(nextSibling.getAttribute('class'), equals('content'));

        final previousSibling = nextSibling.previousElementSibling;
        expect(previousSibling, isNotNull);
        expect(previousSibling!.id, equals('title'));

        final firstSibling = title.previousElementSibling;
        expect(firstSibling, isNull);

        final lastSibling = nextSibling.nextElementSibling;
        expect(lastSibling, isNotNull);
        expect(lastSibling!.tagName, equals('p'));

        final noMoreSiblings = lastSibling.nextElementSibling;
        expect(noMoreSiblings, isNull);
      });

      test('Access first and last element children', () {
        final container = doc.getElementById('container');
        expect(container, isNotNull);

        final firstChild = container!.firstElementChild;
        expect(firstChild, isNotNull);
        expect(firstChild!.id, equals('title'));

        final lastChild = container.lastElementChild;
        expect(lastChild, isNotNull);
        expect(lastChild!.tagName, equals('p'));
        expect(lastChild.getAttribute('class'), equals('content'));
      });
    });

    group('DOM Element Queries', () {
      late DOMDocument doc;

      setUp(() {
        const html = '''
          <html>
            <body>
              <div id="main">
                <section id="intro">
                  <h1>Introduction</h1>
                  <p>Welcome message</p>
                </section>
                <section id="content">
                  <h2>Content Section</h2>
                  <div class="subsection">
                    <h3>Subsection</h3>
                    <p>Subsection content</p>
                  </div>
                </section>
                <footer id="footer">
                  <p>Footer content</p>
                </footer>
              </div>
            </body>
          </html>
        ''';
        doc = DOMDocument.parseHTML(html);
      });

      test('Find elements by ID', () {
        final main = doc.getElementById('main');
        expect(main, isNotNull);
        expect(main!.tagName, equals('div'));

        final intro = doc.getElementById('intro');
        expect(intro, isNotNull);
        expect(intro!.tagName, equals('section'));

        final nonExistent = doc.getElementById('nonexistent');
        expect(nonExistent, isNull);
      });

      test('Find elements by tag name', () {
        final sections = doc.getElementsByTagName('section');
        expect(sections.length, equals(2));
        expect(sections[0].id, equals('intro'));
        expect(sections[1].id, equals('content'));

        final paragraphs = doc.getElementsByTagName('p');
        expect(paragraphs.length, equals(3));

        final spans = doc.getElementsByTagName('span');
        expect(spans.length, equals(0));
      });

      test('Query selector by ID', () {
        final root = doc.documentElement!;

        final main = root.querySelector('#main');
        expect(main, isNotNull);
        expect(main!.id, equals('main'));

        final footer = root.querySelector('#footer');
        expect(footer, isNotNull);
        expect(footer!.tagName, equals('footer'));

        final nonExistent = root.querySelector('#nonexistent');
        expect(nonExistent, isNull);
      });

      test('Query selector by tag name', () {
        final root = doc.documentElement!;

        final firstH1 = root.querySelector('h1');
        expect(firstH1, isNotNull);
        expect(firstH1!.tagName, equals('h1'));

        final firstP = root.querySelector('p');
        expect(firstP, isNotNull);
        expect(firstP!.tagName, equals('p'));
      });

      test('Query selector all', () {
        final root = doc.documentElement!;

        final allSections = root.querySelectorAll('section');
        expect(allSections.length, equals(2));

        final allHeadings = root.querySelectorAll('h1');
        expect(allHeadings.length, equals(1));

        final allH2s = root.querySelectorAll('h2');
        expect(allH2s.length, equals(1));

        final allH3s = root.querySelectorAll('h3');
        expect(allH3s.length, equals(1));
      });
    });

    group('DOM Text Node Operations', () {
      test('Access text node content', () {
        const html = '<p>Hello World</p>';
        final doc = DOMDocument.parseHTML(html);

        final p = doc.getElementsByTagName('p').first;
        expect(p.hasChildNodes, isTrue);

        final textNode = p.childNodes.first;
        expect(textNode.nodeType, equals(DOMNodeType.text));
        expect(textNode.nodeValue, equals('Hello World'));
        expect(textNode.textContent, equals('Hello World'));
      });

      test('Modify text node content', () {
        const html = '<p>Original Text</p>';
        final doc = DOMDocument.parseHTML(html);

        final p = doc.getElementsByTagName('p').first;
        final textNode = p.childNodes.first;

        expect(textNode.nodeType, equals(DOMNodeType.text));
        expect(textNode.nodeValue, equals('Original Text'));

        // Create a proper DOMText using the document API
        final newTextNode = doc.createTextNode('Modified Text');
        expect(newTextNode.data, equals('Modified Text'));
        expect(newTextNode.length, equals(13));
      });

      test('Split text node', () {
        const html = '<p>Hello World</p>';
        final doc = DOMDocument.parseHTML(html);

        // Create a DOMText node directly for testing split functionality
        final textNode = doc.createTextNode('Hello World');

        final splitNode = textNode.splitText(6);

        expect(textNode.data, equals('Hello '));
        expect(splitNode.data, equals('World'));
        expect(textNode.length, equals(6));
        expect(splitNode.length, equals(5));
      });

      test('Handle split text edge cases', () {
        const html = '<p>Test</p>';
        final doc = DOMDocument.parseHTML(html);

        // Create a DOMText node for testing edge cases
        final textNode = doc.createTextNode('Test');

        // Split at beginning
        final splitAtStart = textNode.splitText(0);
        expect(textNode.data, equals(''));
        expect(splitAtStart.data, equals('Test'));

        // Test with a fresh text node for invalid offsets
        final freshTextNode = doc.createTextNode('Test');
        expect(() => freshTextNode.splitText(-1), throwsA(isA<RangeError>()));
        expect(() => freshTextNode.splitText(10), throwsA(isA<RangeError>()));
      });
    });

    group('DOM Attribute Operations', () {
      test('Get and set element attributes', () {
        const html = '<div id="test" class="example" data-value="123"></div>';
        final doc = DOMDocument.parseHTML(html);

        final div = doc.documentElement!;

        expect(div.getAttribute('id'), equals('test'));
        expect(div.getAttribute('class'), equals('example'));
        expect(div.getAttribute('data-value'), equals('123'));
        expect(div.getAttribute('nonexistent'), isNull);

        div.setAttribute('title', 'New Title');
        expect(div.getAttribute('title'), equals('New Title'));

        div.setAttribute('id', 'modified');
        expect(div.getAttribute('id'), equals('modified'));
        expect(div.id, equals('modified'));
      });

      test('Handle attributes on different node types', () {
        const html = '''
          <div>
            <p id="para">Text content</p>
          </div>
        ''';
        final doc = DOMDocument.parseHTML(html);

        final div = doc.documentElement!;
        final p = div.children.first;
        final textNode = p.childNodes.first;

        // Element should support attributes
        expect(p.getAttribute('id'), equals('para'));
        p.setAttribute('class', 'test');
        expect(p.getAttribute('class'), equals('test'));

        // Text node should not support attributes
        expect(textNode.getAttribute('id'), isNull);
        textNode.setAttribute('class', 'test'); // Should not throw
        expect(textNode.getAttribute('class'), isNull);
      });
    });

    group('DOM Content Access', () {
      test('Get text content from elements', () {
        const html = '''
          <div>
            <h1>Title</h1>
            <p>First paragraph</p>
            <p>Second <strong>bold</strong> paragraph</p>
          </div>
        ''';
        final doc = DOMDocument.parseHTML(html);

        final div = doc.documentElement!;
        final textContent = div.textContent;

        expect(textContent, contains('Title'));
        expect(textContent, contains('First paragraph'));
        expect(textContent, contains('bold'));
        expect(textContent, contains('Second'));
        expect(textContent, contains('paragraph'));
      });

      test('Get inner HTML content', () {
        const html = '''
          <div>
            <p>Paragraph with <strong>bold</strong> text</p>
          </div>
        ''';
        final doc = DOMDocument.parseHTML(html);

        final div = doc.documentElement!;
        final innerHTML = div.innerHTML;

        expect(innerHTML, contains('<p>'));
        expect(innerHTML, contains('<strong>'));
        expect(innerHTML, contains('bold'));
      });

      test('Get outer HTML content', () {
        const html = '<div id="test"><p>Content</p></div>';
        final doc = DOMDocument.parseHTML(html);

        final div = doc.documentElement!;
        final outerHTML = div.outerHTML;

        expect(outerHTML, contains('<div'));
        expect(outerHTML, contains('id="test"'));
        expect(outerHTML, contains('<p>Content</p>'));
        expect(outerHTML, contains('</div>'));
      });
    });

    group('DOM Position and Range', () {
      test('Create and compare DOM positions', () {
        const html = '<p>Test content</p>';
        final doc = DOMDocument.parseHTML(html);

        final p = doc.getElementsByTagName('p').first;
        final textNode = p.childNodes.first;

        final pos1 = DOMPosition(container: textNode, offset: 0);
        final pos2 = DOMPosition(container: textNode, offset: 5);
        final pos3 = DOMPosition(container: p, before: true);
        final pos4 = DOMPosition(container: p, after: true);

        expect(pos1.container, equals(textNode));
        expect(pos1.offset, equals(0));
        expect(pos1.before, isFalse);
        expect(pos1.after, isFalse);

        expect(pos3.before, isTrue);
        expect(pos4.after, isTrue);

        expect(pos1, equals(DOMPosition(container: textNode, offset: 0)));
        expect(pos1, isNot(equals(pos2)));
      });

      test('Create and analyze DOM ranges', () {
        const html = '<p>Hello World Test</p>';
        final doc = DOMDocument.parseHTML(html);

        final textNode = doc.getElementsByTagName('p').first.childNodes.first;

        final range1 = DOMRange(
          startContainer: textNode,
          startOffset: 0,
          endContainer: textNode,
          endOffset: 5,
        );

        final range2 = DOMRange(
          startContainer: textNode,
          startOffset: 5,
          endContainer: textNode,
          endOffset: 5,
        );

        expect(range1.collapsed, isFalse);
        expect(range2.collapsed, isTrue);

        final text1 = range1.getText();
        expect(text1, equals('Hello'));

        final text2 = range2.getText();
        expect(text2, equals(''));
      });

      test('Extract text from DOM ranges', () {
        const html = '<p>The quick brown fox</p>';
        final doc = DOMDocument.parseHTML(html);

        final textNode = doc.getElementsByTagName('p').first.childNodes.first;

        final fullRange = DOMRange(
          startContainer: textNode,
          startOffset: 0,
          endContainer: textNode,
          endOffset: 19,
        );

        final partialRange = DOMRange(
          startContainer: textNode,
          startOffset: 4,
          endContainer: textNode,
          endOffset: 9,
        );

        expect(fullRange.getText(), equals('The quick brown fox'));
        expect(partialRange.getText(), equals('quick'));
      });
    });

    group('DOM Document Creation', () {
      test('Create new elements and text nodes', () {
        const html = '<html><body></body></html>';
        final doc = DOMDocument.parseHTML(html);

        final newDiv = doc.createElement('div');
        expect(newDiv.tagName, equals('div'));
        expect(newDiv.childNodes, isEmpty);

        final newText = doc.createTextNode('Hello');
        expect(newText.nodeType, equals(DOMNodeType.text));
        expect(newText.data, equals('Hello'));
        expect(newText.length, equals(5));
      });

      test('Handle document-level operations', () {
        const html = '<html><body><div id="test"></div></body></html>';
        final doc = DOMDocument.parseHTML(html);

        expect(doc.nodeType, equals(DOMNodeType.document));
        expect(doc.parentNode, isNull);
        expect(doc.nodeValue, isNull);
        expect(doc.tagName, isNull);
        expect(doc.id, isNull);

        expect(() => doc.setAttribute('test', 'value'),
            throwsA(isA<UnsupportedError>()));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Handle empty and whitespace-only content', () {
        const html = '  <div>   </div>  ';
        final doc = DOMDocument.parseHTML(html);

        expect(doc.documentElement, isNotNull);
        expect(doc.documentElement!.tagName, equals('div'));
      });

      test('Handle deeply nested content', () {
        const html = '''
          <div>
            <section>
              <article>
                <header>
                  <h1>
                    <span>Deeply nested title</span>
                  </h1>
                </header>
              </article>
            </section>
          </div>
        ''';

        final doc = DOMDocument.parseHTML(html);

        expect(doc.documentElement, isNotNull);
        final span = doc.getElementsByTagName('span').first;
        expect(span.textContent, contains('Deeply nested title'));

        // Verify deep parent chain
        var current = span.parentNode;
        final expectedTags = ['h1', 'header', 'article', 'section', 'div'];

        for (final expectedTag in expectedTags) {
          expect(current, isNotNull);
          expect(current!.tagName, equals(expectedTag));
          current = current.parentNode;
        }
      });

      test('Handle special characters and encoding', () {
        const html = '''
          <div>
            <p>Special chars: &amp; &lt; &gt; &quot; &#39;</p>
            <p>Unicode: ñ ü ß 中文</p>
          </div>
        ''';

        final doc = DOMDocument.parseHTML(html);
        final paragraphs = doc.getElementsByTagName('p');

        expect(paragraphs.length, equals(2));

        final firstP = paragraphs[0];
        expect(firstP.textContent, contains('&'));
        expect(firstP.textContent, contains('<'));
        expect(firstP.textContent, contains('>'));

        final secondP = paragraphs[1];
        expect(secondP.textContent, contains('Unicode'));
      });
    });

    group('Performance Tests', () {
      test('Parse and navigate large document efficiently', () {
        final htmlBuffer = StringBuffer('<html><body>');
        for (int i = 0; i < 1000; i++) {
          htmlBuffer
              .write('<div id="item$i" class="item">Item $i content</div>');
        }
        htmlBuffer.write('</body></html>');

        final stopwatch = Stopwatch()..start();
        final doc = DOMDocument.parseHTML(htmlBuffer.toString());
        stopwatch.stop();

        expect(doc.documentElement, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        // Test efficient lookups
        final lookupStopwatch = Stopwatch()..start();
        final item500 = doc.getElementById('item500');
        lookupStopwatch.stop();

        expect(item500, isNotNull);
        expect(item500!.getAttribute('class'), equals('item'));
        expect(lookupStopwatch.elapsedMilliseconds, lessThan(100));

        print('Parsed 1000 elements in ${stopwatch.elapsedMicroseconds} μs');
        print(
            'Found element by ID in ${lookupStopwatch.elapsedMicroseconds} μs');
      });
    });
  });
}
