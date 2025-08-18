import 'package:xml/xml.dart';

/// Abstract representation of a DOM node for cross-platform compatibility.
///
/// This abstraction allows CFI operations to work consistently across
/// server, web, and Flutter environments without depending on dart:html.
abstract class DOMNode {
  /// The text content of this node (for text nodes).
  String? get nodeValue;

  /// The type of this node.
  DOMNodeType get nodeType;

  /// The parent node, or null if this is the root.
  DOMNode? get parentNode;

  /// List of child nodes.
  List<DOMNode> get childNodes;

  /// The ID attribute of this element (null for non-elements).
  String? get id;

  /// The tag name of this element (null for non-elements).
  String? get tagName;

  /// Gets an attribute value by name.
  String? getAttribute(String name);

  /// Sets an attribute value.
  void setAttribute(String name, String value);

  /// Whether this node has child nodes.
  bool get hasChildNodes => childNodes.isNotEmpty;

  /// Gets the text content of this node and all descendants.
  String get textContent;

  /// Gets the inner HTML content (for elements).
  String get innerHTML;

  /// Gets the outer HTML content including the element itself.
  String get outerHTML;
}

/// Types of DOM nodes.
enum DOMNodeType {
  element,
  text,
  comment,
  document,
  documentType,
  documentFragment,
}

/// Abstract representation of a DOM document.
abstract class DOMDocument extends DOMNode {
  /// The document element (root element).
  DOMElement? get documentElement;

  /// Creates a new element with the given tag name.
  DOMElement createElement(String tagName);

  /// Creates a new text node with the given content.
  DOMText createTextNode(String content);

  /// Finds an element by its ID.
  DOMElement? getElementById(String id);

  /// Finds elements by tag name.
  List<DOMElement> getElementsByTagName(String tagName);

  /// Parses HTML content into a DOM structure.
  static DOMDocument parseHTML(String htmlContent) {
    return XMLDOMDocument.parseHTML(htmlContent);
  }
}

/// Abstract representation of a DOM element.
abstract class DOMElement extends DOMNode {
  /// Gets child elements (excludes text nodes).
  List<DOMElement> get children;

  /// Gets the first child element.
  DOMElement? get firstElementChild;

  /// Gets the last child element.
  DOMElement? get lastElementChild;

  /// Gets the next sibling element.
  DOMElement? get nextElementSibling;

  /// Gets the previous sibling element.
  DOMElement? get previousElementSibling;

  /// Finds the first descendant element matching the selector.
  DOMElement? querySelector(String selector);

  /// Finds all descendant elements matching the selector.
  List<DOMElement> querySelectorAll(String selector);
}

/// Abstract representation of a DOM text node.
abstract class DOMText extends DOMNode {
  /// The text content of this text node.
  String get data;

  /// Sets the text content of this text node.
  set data(String value);

  /// The length of the text content.
  int get length;

  /// Splits this text node at the given offset.
  DOMText splitText(int offset);
}

/// Represents a position within a DOM node.
class DOMPosition {
  /// The container node.
  final DOMNode container;

  /// The offset within the container.
  final int offset;

  /// Whether this position is before the container.
  final bool before;

  /// Whether this position is after the container.
  final bool after;

  const DOMPosition({
    required this.container,
    this.offset = 0,
    this.before = false,
    this.after = false,
  });

  @override
  String toString() {
    if (before) return 'before ${container.tagName ?? 'node'}';
    if (after) return 'after ${container.tagName ?? 'node'}';
    return '${container.tagName ?? 'node'}:$offset';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DOMPosition &&
        container == other.container &&
        offset == other.offset &&
        before == other.before &&
        after == other.after;
  }

  @override
  int get hashCode => Object.hash(container, offset, before, after);
}

/// Represents a range between two positions in the DOM.
class DOMRange {
  /// The start container node.
  final DOMNode startContainer;

  /// The offset within the start container.
  final int startOffset;

  /// The end container node.
  final DOMNode endContainer;

  /// The offset within the end container.
  final int endOffset;

  const DOMRange({
    required this.startContainer,
    required this.startOffset,
    required this.endContainer,
    required this.endOffset,
  });

  /// Whether this range is collapsed (start and end are the same).
  bool get collapsed =>
      startContainer == endContainer && startOffset == endOffset;

  /// Gets the text content of this range.
  String getText() {
    if (collapsed) return '';

    if (startContainer == endContainer &&
        startContainer.nodeType == DOMNodeType.text) {
      // Simple case: range within a single text node
      final text = startContainer.nodeValue ?? '';
      return text.substring(startOffset, endOffset.clamp(0, text.length));
    }

    // Complex case: range spans multiple nodes
    // This would require more sophisticated tree traversal
    return _extractTextFromRange();
  }

  /// Extracts text content from a complex range.
  String _extractTextFromRange() {
    // Simplified implementation - in a full implementation,
    // this would perform tree traversal to extract text
    final buffer = StringBuffer();

    // This is a placeholder - real implementation would traverse
    // the DOM tree between start and end positions
    if (startContainer.nodeType == DOMNodeType.text) {
      final text = startContainer.nodeValue ?? '';
      buffer.write(text.substring(startOffset));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'Range(${startContainer.tagName ?? 'node'}:$startOffset -> ${endContainer.tagName ?? 'node'}:$endOffset)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DOMRange &&
        startContainer == other.startContainer &&
        startOffset == other.startOffset &&
        endContainer == other.endContainer &&
        endOffset == other.endOffset;
  }

  @override
  int get hashCode =>
      Object.hash(startContainer, startOffset, endContainer, endOffset);
}

/// XML-based implementation of the DOM abstraction using the xml package.
class XMLDOMDocument extends DOMDocument {
  final XmlDocument _xmlDoc;

  XMLDOMDocument._(this._xmlDoc);

  /// Parses HTML content into an XML DOM document.
  static XMLDOMDocument parseHTML(String htmlContent) {
    try {
      // Parse as XML (more strict)
      final xmlDoc = XmlDocument.parse(htmlContent);
      return XMLDOMDocument._(xmlDoc);
    } catch (e) {
      // If XML parsing fails, try to clean up the HTML and parse again
      final cleanedHtml = _cleanHTML(htmlContent);
      final xmlDoc = XmlDocument.parse(cleanedHtml);
      return XMLDOMDocument._(xmlDoc);
    }
  }

  /// Cleans HTML to make it more XML-compatible.
  static String _cleanHTML(String html) {
    // Basic HTML cleanup for XML parsing
    return html
        .replaceAll(RegExp(r'<br\s*>', caseSensitive: false), '<br/>')
        .replaceAll(RegExp(r'<hr\s*>', caseSensitive: false), '<hr/>')
        .replaceAll(
            RegExp(r'<img([^>]*[^/])>', caseSensitive: false), '<img\$1/>')
        .replaceAll(
            RegExp(r'<meta([^>]*[^/])>', caseSensitive: false), '<meta\$1/>')
        .replaceAll(
            RegExp(r'<link([^>]*[^/])>', caseSensitive: false), '<link\$1/>');
  }

  @override
  DOMNodeType get nodeType => DOMNodeType.document;

  @override
  String? get nodeValue => null;

  @override
  DOMNode? get parentNode => null;

  @override
  List<DOMNode> get childNodes =>
      _xmlDoc.children.map((child) => XMLDOMNode._(child)).toList();

  @override
  String? get id => null;

  @override
  String? get tagName => null;

  @override
  String? getAttribute(String name) => null;

  @override
  void setAttribute(String name, String value) {
    throw UnsupportedError('Cannot set attributes on document');
  }

  @override
  String get textContent => _xmlDoc.innerText;

  @override
  String get innerHTML => _xmlDoc.children.map((e) => e.toString()).join();

  @override
  String get outerHTML => _xmlDoc.toString();

  @override
  DOMElement? get documentElement {
    final rootElement = _xmlDoc.rootElement;
    return XMLDOMElement._(rootElement);
  }

  @override
  DOMElement createElement(String tagName) {
    final element = XmlElement(XmlName(tagName));
    return XMLDOMElement._(element);
  }

  @override
  DOMText createTextNode(String content) {
    final textNode = XmlText(content);
    return XMLDOMText._(textNode);
  }

  @override
  DOMElement? getElementById(String id) {
    return _findElementById(_xmlDoc.rootElement, id);
  }

  DOMElement? _findElementById(XmlNode? node, String id) {
    if (node is XmlElement) {
      if (node.getAttribute('id') == id) {
        return XMLDOMElement._(node);
      }

      for (final child in node.children) {
        final found = _findElementById(child, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  List<DOMElement> getElementsByTagName(String tagName) {
    final elements = <DOMElement>[];
    _collectElementsByTagName(
        _xmlDoc.rootElement, tagName.toLowerCase(), elements);
    return elements;
  }

  void _collectElementsByTagName(
      XmlNode? node, String tagName, List<DOMElement> results) {
    if (node is XmlElement) {
      if (node.name.local.toLowerCase() == tagName) {
        results.add(XMLDOMElement._(node));
      }

      for (final child in node.children) {
        _collectElementsByTagName(child, tagName, results);
      }
    }
  }
}

/// XML-based implementation of DOMNode.
class XMLDOMNode extends DOMNode {
  final XmlNode _xmlNode;

  XMLDOMNode._(this._xmlNode);

  @override
  String? get nodeValue {
    if (_xmlNode is XmlText) {
      return (_xmlNode as XmlText).value;
    }
    return null;
  }

  @override
  DOMNodeType get nodeType {
    if (_xmlNode is XmlElement) return DOMNodeType.element;
    if (_xmlNode is XmlText) return DOMNodeType.text;
    if (_xmlNode is XmlComment) return DOMNodeType.comment;
    if (_xmlNode is XmlDocument) return DOMNodeType.document;
    return DOMNodeType.element; // Default
  }

  @override
  DOMNode? get parentNode {
    final parent = _xmlNode.parent;
    return parent != null ? XMLDOMNode._(parent) : null;
  }

  @override
  List<DOMNode> get childNodes {
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement)
          .children
          .map((child) => XMLDOMNode._(child))
          .toList();
    }
    if (_xmlNode is XmlDocument) {
      return (_xmlNode as XmlDocument)
          .children
          .map((child) => XMLDOMNode._(child))
          .toList();
    }
    return [];
  }

  @override
  String? get id {
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement).getAttribute('id');
    }
    return null;
  }

  @override
  String? get tagName {
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement).name.local;
    }
    return null;
  }

  @override
  String? getAttribute(String name) {
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement).getAttribute(name);
    }
    return null;
  }

  @override
  void setAttribute(String name, String value) {
    if (_xmlNode is XmlElement) {
      (_xmlNode as XmlElement).setAttribute(name, value);
    }
  }

  @override
  String get textContent {
    if (_xmlNode is XmlText) {
      return (_xmlNode as XmlText).value;
    }
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement).innerText;
    }
    return '';
  }

  @override
  String get innerHTML {
    if (_xmlNode is XmlElement) {
      return (_xmlNode as XmlElement).children.map((e) => e.toString()).join();
    }
    return '';
  }

  @override
  String get outerHTML => _xmlNode.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is XMLDOMNode && _xmlNode == other._xmlNode;
  }

  @override
  int get hashCode => _xmlNode.hashCode;
}

/// XML-based implementation of DOMElement.
class XMLDOMElement extends XMLDOMNode implements DOMElement {
  XMLDOMElement._(XmlElement xmlElement) : super._(xmlElement);

  XmlElement get _xmlElement => _xmlNode as XmlElement;

  @override
  List<DOMElement> get children {
    return _xmlElement.children
        .whereType<XmlElement>()
        .map((child) => XMLDOMElement._(child))
        .toList();
  }

  @override
  DOMElement? get firstElementChild {
    final firstElement =
        _xmlElement.children.whereType<XmlElement>().firstOrNull;
    return firstElement != null ? XMLDOMElement._(firstElement) : null;
  }

  @override
  DOMElement? get lastElementChild {
    final lastElement = _xmlElement.children.whereType<XmlElement>().lastOrNull;
    return lastElement != null ? XMLDOMElement._(lastElement) : null;
  }

  @override
  DOMElement? get nextElementSibling {
    final parent = _xmlElement.parent;
    if (parent == null) return null;

    final siblings = parent.children.whereType<XmlElement>().toList();
    final currentIndex = siblings.indexOf(_xmlElement);

    if (currentIndex >= 0 && currentIndex < siblings.length - 1) {
      return XMLDOMElement._(siblings[currentIndex + 1]);
    }

    return null;
  }

  @override
  DOMElement? get previousElementSibling {
    final parent = _xmlElement.parent;
    if (parent == null) return null;

    final siblings = parent.children.whereType<XmlElement>().toList();
    final currentIndex = siblings.indexOf(_xmlElement);

    if (currentIndex > 0) {
      return XMLDOMElement._(siblings[currentIndex - 1]);
    }

    return null;
  }

  @override
  DOMElement? querySelector(String selector) {
    // Simple selector support - just by tag name for now
    if (selector.startsWith('#')) {
      // ID selector
      final id = selector.substring(1);
      return _findElementById(_xmlElement, id);
    } else {
      // Tag name selector
      final element = _xmlElement.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local.toLowerCase() == selector.toLowerCase())
          .firstOrNull;
      return element != null ? XMLDOMElement._(element) : null;
    }
  }

  @override
  List<DOMElement> querySelectorAll(String selector) {
    if (selector.startsWith('#')) {
      // ID selector - should return at most one element
      final element = querySelector(selector);
      return element != null ? [element] : [];
    } else {
      // Tag name selector
      return _xmlElement.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local.toLowerCase() == selector.toLowerCase())
          .map((e) => XMLDOMElement._(e))
          .toList();
    }
  }

  DOMElement? _findElementById(XmlElement element, String id) {
    if (element.getAttribute('id') == id) {
      return XMLDOMElement._(element);
    }

    for (final child in element.children.whereType<XmlElement>()) {
      final found = _findElementById(child, id);
      if (found != null) return found;
    }

    return null;
  }
}

/// XML-based implementation of DOMText.
class XMLDOMText extends XMLDOMNode implements DOMText {
  XMLDOMText._(XmlText xmlText) : super._(xmlText);

  XmlText get _xmlText => _xmlNode as XmlText;

  @override
  String get data => _xmlText.value;

  @override
  set data(String value) {
    _xmlText.value = value;
  }

  @override
  int get length => _xmlText.value.length;

  @override
  DOMText splitText(int offset) {
    final originalText = _xmlText.value;
    if (offset < 0 || offset > originalText.length) {
      throw RangeError('Offset out of range: $offset');
    }

    final beforeText = originalText.substring(0, offset);
    final afterText = originalText.substring(offset);

    // Update this text node
    _xmlText.value = beforeText;

    // Create new text node
    final newTextNode = XmlText(afterText);

    // Insert after this node
    final parent = _xmlText.parent;
    if (parent != null) {
      final index = parent.children.indexOf(_xmlText);
      parent.children.insert(index + 1, newTextNode);
    }

    return XMLDOMText._(newTextNode);
  }
}
