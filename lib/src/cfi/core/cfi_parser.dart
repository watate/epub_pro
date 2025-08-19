import 'cfi_structure.dart';

/// Parser for EPUB CFI strings into structured components.
class CFIParser {
  /// Parses a CFI string into a structured representation.
  ///
  /// Throws [FormatException] if the CFI string is malformed.
  static CFIStructure parse(String cfi) {
    if (!cfi.startsWith('epubcfi(') || !cfi.endsWith(')')) {
      throw FormatException(
          'Invalid CFI format: must start with "epubcfi(" and end with ")"');
    }

    // Extract the content between epubcfi( and )
    final content = cfi.substring(8, cfi.length - 1);

    // Check for empty content
    if (content.isEmpty) {
      throw FormatException('CFI content cannot be empty');
    }

    // Check if this is a range CFI (contains commas not inside brackets)
    if (_isRangeCFI(content)) {
      return _parseRangeCFI(content);
    } else {
      return _parsePointCFI(content);
    }
  }

  /// Determines if a CFI content string represents a range.
  static bool _isRangeCFI(String content) {
    int bracketDepth = 0;
    bool inSplitNotation = false;
    
    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      
      // Handle bracket depth for parameters
      if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        bracketDepth--;
      }
      
      // Check for split notation start
      if (i + 6 < content.length && content.substring(i, i + 6) == 'split=') {
        inSplitNotation = true;
        continue;
      }
      
      // Check for split notation end (next '/')
      if (inSplitNotation && char == '/') {
        inSplitNotation = false;
        continue;
      }
      
      // Only count commas outside brackets and outside split notation
      if (char == ',' && bracketDepth == 0 && !inSplitNotation) {
        return true;
      }
    }
    return false;
  }

  /// Parses a range CFI with format: parent,start,end
  static CFIStructure _parseRangeCFI(String content) {
    final parts = _splitRangeParts(content);

    if (parts.length != 3) {
      throw FormatException(
          'Range CFI must have exactly 3 parts separated by commas');
    }

    final parentPath = parts[0].isNotEmpty ? _parsePath(parts[0]) : null;
    final startPath = _parsePath(parts[1]);
    final endPath = _parsePath(parts[2]);

    return CFIStructure(
      parent: parentPath,
      start: startPath,
      end: endPath,
    );
  }

  /// Parses a point CFI with a single path.
  static CFIStructure _parsePointCFI(String content) {
    final path = _parsePath(content);
    return CFIStructure(start: path);
  }

  /// Splits range CFI content into parent, start, and end parts.
  static List<String> _splitRangeParts(String content) {
    final parts = <String>[];
    int bracketDepth = 0;
    bool inSplitNotation = false;
    int startIndex = 0;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      
      if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        bracketDepth--;
      }
      
      // Check for split notation start
      if (i + 6 < content.length && content.substring(i, i + 6) == 'split=') {
        inSplitNotation = true;
        continue;
      }
      
      // Check for split notation end (next '/')
      if (inSplitNotation && char == '/') {
        inSplitNotation = false;
        continue;
      }
      
      // Only split on commas outside brackets and outside split notation
      if (char == ',' && bracketDepth == 0 && !inSplitNotation) {
        parts.add(content.substring(startIndex, i));
        startIndex = i + 1;
      }
    }

    // Add the last part
    parts.add(content.substring(startIndex));

    return parts;
  }

  /// Parses a CFI path into structured parts.
  static CFIPath _parsePath(String pathStr) {
    final tokens = _tokenize(pathStr);
    final parts = <CFIPart>[];

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token.type == CFITokenType.indirection) {
        // Handle step indirection - affects the next step
        i++;
        if (i < tokens.length && tokens[i].type == CFITokenType.step) {
          final part = _parsePartFromTokens(tokens, i, hasIndirection: true);
          parts.add(part);
          i = _skipPartTokens(tokens, i);
        } else {
          throw FormatException(
              'Step indirection (!) must be followed by a step');
        }
      } else if (token.type == CFITokenType.step) {
        final part = _parsePartFromTokens(tokens, i);
        parts.add(part);
        i = _skipPartTokens(tokens, i);
      } else {
        throw FormatException('Unexpected token: ${token.value}');
      }
    }

    return CFIPath(parts: parts);
  }

  /// Parses a CFI part from tokens starting at the given index.
  static CFIPart _parsePartFromTokens(List<CFIToken> tokens, int startIndex,
      {bool hasIndirection = false}) {
    if (tokens[startIndex].type != CFITokenType.step) {
      throw FormatException('Expected step token');
    }

    final index = tokens[startIndex].value as int;
    String? id;
    int? offset;
    double? temporal;
    List<double>? spatial;
    List<String>? text;
    String? side;

    int i = startIndex + 1;
    while (i < tokens.length &&
        tokens[i].type != CFITokenType.step &&
        tokens[i].type != CFITokenType.indirection) {
      final token = tokens[i];

      switch (token.type) {
        case CFITokenType.assertion:
          final value = token.value as String;
          if (value.startsWith(',')) {
            // Text assertion: [,text1,text2,...]
            text = value.substring(1).split(',');
          } else if (value == 'before' || value == 'after') {
            // Side bias
            side = value;
          } else {
            // ID assertion
            id = _unescapeCFI(value);
          }
          break;
        case CFITokenType.offset:
          offset = token.value as int;
          break;
        case CFITokenType.temporal:
          temporal = token.value as double;
          break;
        case CFITokenType.spatial:
          spatial = (token.value as List).cast<double>();
          break;
        default:
          throw FormatException('Unexpected token in part: ${token.value}');
      }
      i++;
    }

    return CFIPart(
      index: index,
      id: id,
      offset: offset,
      temporal: temporal,
      spatial: spatial,
      text: text,
      side: side,
      hasIndirection: hasIndirection,
    );
  }

  /// Skips all tokens belonging to the current part.
  static int _skipPartTokens(List<CFIToken> tokens, int startIndex) {
    int i = startIndex + 1;
    while (i < tokens.length &&
        tokens[i].type != CFITokenType.step &&
        tokens[i].type != CFITokenType.indirection) {
      i++;
    }
    return i;
  }

  /// Tokenizes a CFI path string.
  static List<CFIToken> _tokenize(String pathStr) {
    final tokens = <CFIToken>[];

    int i = 0;
    while (i < pathStr.length) {
      final char = pathStr[i];

      switch (char) {
        case '/':
          // Step reference or split notation
          i++;
          
          // Check if this is split notation
          if (i + 5 < pathStr.length && pathStr.substring(i, i + 5) == 'split') {
            // Skip split notation: split=X,total=Y
            final nextSlash = pathStr.indexOf('/', i);
            if (nextSlash == -1) {
              throw FormatException('Split notation must be followed by /');
            }
            i = nextSlash; // Skip to next slash, will be processed in next iteration
            continue;
          }
          
          final numberStr = _readNumber(pathStr, i);
          if (numberStr.isEmpty) {
            throw FormatException(
                'Step reference must be followed by a number');
          }
          tokens.add(CFIToken(CFITokenType.step, int.parse(numberStr)));
          i += numberStr.length;
          break;

        case ':':
          // Character offset
          i++;
          final numberStr = _readNumber(pathStr, i);
          if (numberStr.isEmpty) {
            throw FormatException(
                'Character offset must be followed by a number');
          }
          tokens.add(CFIToken(CFITokenType.offset, int.parse(numberStr)));
          i += numberStr.length;
          break;

        case '~':
          // Temporal offset
          i++;
          final numberStr = _readFloat(pathStr, i);
          if (numberStr.isEmpty) {
            throw FormatException(
                'Temporal offset must be followed by a number');
          }
          tokens.add(CFIToken(CFITokenType.temporal, double.parse(numberStr)));
          i += numberStr.length;
          break;

        case '@':
          // Spatial coordinates
          i++;
          final coordsStr = _readUntil(pathStr, i, RegExp(r'[:/\[\]!,]'));
          final coords = coordsStr.split(':').map(double.parse).toList();
          tokens.add(CFIToken(CFITokenType.spatial, coords));
          i += coordsStr.length;
          break;

        case '[':
          // Assertion
          i++;
          final assertion = _readAssertion(pathStr, i);
          tokens.add(CFIToken(CFITokenType.assertion, assertion));
          i += assertion.length + 1; // +1 for closing ]
          break;

        case '!':
          // Step indirection
          tokens.add(CFIToken(CFITokenType.indirection, null));
          i++;
          break;

        default:
          throw FormatException('Unexpected character in CFI: $char');
      }
    }

    return tokens;
  }

  /// Reads a number from the string starting at the given index.
  static String _readNumber(String str, int startIndex) {
    int i = startIndex;
    while (i < str.length && RegExp(r'\d').hasMatch(str[i])) {
      i++;
    }
    return str.substring(startIndex, i);
  }

  /// Reads a floating-point number from the string starting at the given index.
  static String _readFloat(String str, int startIndex) {
    int i = startIndex;
    bool hasDot = false;
    while (i < str.length) {
      final char = str[i];
      if (RegExp(r'\d').hasMatch(char)) {
        i++;
      } else if (char == '.' && !hasDot) {
        hasDot = true;
        i++;
      } else {
        break;
      }
    }
    return str.substring(startIndex, i);
  }

  /// Reads until a pattern is matched.
  static String _readUntil(String str, int startIndex, RegExp pattern) {
    int i = startIndex;
    while (i < str.length && !pattern.hasMatch(str[i])) {
      i++;
    }
    return str.substring(startIndex, i);
  }

  /// Reads an assertion (content between brackets).
  static String _readAssertion(String str, int startIndex) {
    final buffer = StringBuffer();
    int i = startIndex;

    while (i < str.length && str[i] != ']') {
      if (str[i] == '^' && i + 1 < str.length) {
        // Escape sequence
        i++; // Skip the ^
        buffer.write(str[i]);
      } else {
        buffer.write(str[i]);
      }
      i++;
    }

    if (i >= str.length) {
      throw FormatException('Unclosed assertion bracket');
    }

    return buffer.toString();
  }

  /// Unescapes CFI special characters.
  static String _unescapeCFI(String text) {
    return text.replaceAllMapped(
      RegExp(r'\^(.)'),
      (match) => match.group(1)!,
    );
  }
}

/// Represents a token in CFI parsing.
class CFIToken {
  final CFITokenType type;
  final dynamic value;

  const CFIToken(this.type, this.value);

  @override
  String toString() => '$type: $value';
}

/// Types of CFI tokens.
enum CFITokenType {
  step, // /N - step reference
  offset, // :N - character offset
  temporal, // ~N - temporal offset
  spatial, // @X:Y - spatial coordinates
  assertion, // [text] - ID or text assertion
  indirection, // ! - step indirection
}
