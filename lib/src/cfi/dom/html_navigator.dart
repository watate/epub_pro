import '../core/cfi_structure.dart';
import 'dom_abstraction.dart';

/// Navigator for traversing HTML DOM trees using CFI indexing rules.
/// 
/// The HTML navigator implements the CFI specification for DOM traversal,
/// including the specific indexing scheme where child nodes are organized
/// as alternating elements and text nodes with virtual positions.
class HTMLNavigator {
  /// Navigates to a DOM position using CFI path components.
  /// 
  /// Follows the CFI specification for DOM indexing:
  /// - Even indices (0, 2, 4...) represent elements
  /// - Odd indices (1, 3, 5...) represent text nodes or virtual positions
  /// - Index 0 and final+1 are virtual "before" and "after" positions
  /// 
  /// Returns the DOM position, or null if navigation fails.
  static DOMPosition? navigateToPosition(DOMNode root, CFIPath path) {
    var currentNode = root;
    
    for (int i = 0; i < path.parts.length; i++) {
      final part = path.parts[i];
      
      // Handle ID assertion first (allows direct lookup)
      if (part.id != null) {
        final elementById = _findElementById(root, part.id!);
        if (elementById == null) return null;
        currentNode = elementById;
        continue;
      }
      
      // Get indexed child nodes according to CFI rules
      final indexedNodes = _getIndexedChildNodes(currentNode);
      
      if (part.index >= indexedNodes.length) {
        return null; // Index out of bounds
      }
      
      final targetNode = indexedNodes[part.index];
      
      // Handle virtual positions
      if (targetNode is _VirtualPosition) {
        return DOMPosition(
          container: currentNode,
          before: targetNode.type == _VirtualPositionType.before,
          after: targetNode.type == _VirtualPositionType.after,
        );
      }
      
      // Handle regular nodes
      if (targetNode is DOMNode) {
        // If this is the last part, apply character offset if present
        if (i == path.parts.length - 1 && part.offset != null) {
          return DOMPosition(
            container: targetNode,
            offset: part.offset!,
          );
        }
        
        currentNode = targetNode;
      } else {
        return null; // Unexpected node type
      }
    }
    
    // If we completed the path without offsets, return position at the node
    return DOMPosition(container: currentNode);
  }

  /// Creates a CFI path from a DOM position.
  /// 
  /// Builds a CFI path by traversing up the DOM tree from the target
  /// position to the root, calculating indices according to CFI rules.
  static CFIPath createPathFromPosition(DOMPosition position) {
    final parts = <CFIPart>[];
    var currentNode = position.container;
    var offset = position.offset;
    
    // Handle virtual positions
    if (position.before || position.after) {
      final parent = currentNode.parentNode;
      if (parent != null) {
        final indexedNodes = _getIndexedChildNodes(parent);
        final virtualIndex = position.before ? 0 : indexedNodes.length - 1;
        
        parts.insert(0, CFIPart(index: virtualIndex));
        currentNode = parent;
      }
    }
    
    // Traverse up the DOM tree
    while (currentNode.parentNode != null) {
      final parent = currentNode.parentNode!;
      final indexedNodes = _getIndexedChildNodes(parent);
      
      // Find the index of currentNode in the indexed list
      int nodeIndex = -1;
      int? adjustedOffset = offset;
      
      for (int i = 0; i < indexedNodes.length; i++) {
        final node = indexedNodes[i];
        if (node == currentNode) {
          nodeIndex = i;
          break;
        } else if (node is List && node.contains(currentNode)) {
          // Handle grouped text nodes
          nodeIndex = i;
          adjustedOffset = _calculateOffsetInTextGroup(node.cast<DOMNode>(), currentNode, offset);
          break;
        }
      }
      
      if (nodeIndex == -1) {
        break; // Node not found in parent's children
      }
      
      // Create CFI part
      final part = CFIPart(
        index: nodeIndex,
        id: currentNode.id,
        offset: currentNode.nodeType == DOMNodeType.text ? adjustedOffset : null,
      );
      
      parts.insert(0, part);
      
      currentNode = parent;
      offset = 0; // Only apply offset to the target node
    }
    
    return CFIPath(parts: parts);
  }

  /// Gets indexed child nodes according to CFI specification.
  /// 
  /// CFI uses a specific indexing scheme:
  /// - Virtual "before" position (index 0)
  /// - Alternating elements and text nodes/virtual positions
  /// - Consecutive text nodes are grouped together
  /// - Virtual "after" position (final index)
  static List<dynamic> _getIndexedChildNodes(DOMNode node) {
    final children = node.childNodes
        .where((child) => 
            child.nodeType == DOMNodeType.element || 
            child.nodeType == DOMNodeType.text)
        .toList();
    
    final indexed = <dynamic>[];
    
    // Virtual "before" position
    indexed.add(_VirtualPosition(_VirtualPositionType.before));
    
    // Process actual child nodes
    List<DOMNode>? currentTextGroup;
    
    for (final child in children) {
      if (child.nodeType == DOMNodeType.text) {
        // Group consecutive text nodes
        currentTextGroup ??= <DOMNode>[];
        currentTextGroup.add(child);
      } else {
        // Element node - first close any text group
        if (currentTextGroup != null) {
          if (currentTextGroup.length == 1) {
            indexed.add(currentTextGroup.first);
          } else {
            indexed.add(currentTextGroup);
          }
          currentTextGroup = null;
        }
        
        // Add virtual text position before element if needed
        if (indexed.length > 1 && indexed.last is! _VirtualPosition) {
          final lastNode = indexed.last;
          if (lastNode is DOMNode && lastNode.nodeType == DOMNodeType.element) {
            indexed.add(_VirtualPosition(_VirtualPositionType.text));
          }
        }
        
        indexed.add(child);
      }
    }
    
    // Close any remaining text group
    if (currentTextGroup != null) {
      if (currentTextGroup.length == 1) {
        indexed.add(currentTextGroup.first);
      } else {
        indexed.add(currentTextGroup);
      }
    }
    
    // Virtual "after" position
    indexed.add(_VirtualPosition(_VirtualPositionType.after));
    
    return indexed;
  }

  /// Calculates character offset within a group of text nodes.
  static int? _calculateOffsetInTextGroup(List<DOMNode> textGroup, DOMNode targetNode, int? targetOffset) {
    int totalOffset = 0;
    
    for (final node in textGroup) {
      if (node == targetNode) {
        return totalOffset + (targetOffset ?? 0);
      }
      totalOffset += node.nodeValue?.length ?? 0;
    }
    
    return totalOffset;
  }

  /// Finds an element by ID in the DOM tree.
  static DOMElement? _findElementById(DOMNode root, String id) {
    if (root is DOMDocument) {
      return root.getElementById(id);
    }
    
    if (root is DOMElement && root.id == id) {
      return root;
    }
    
    for (final child in root.childNodes) {
      if (child is DOMElement) {
        final found = _findElementById(child, id);
        if (found != null) return found;
      }
    }
    
    return null;
  }

  /// Resolves a CFI path to a DOM range.
  /// 
  /// Used for range CFIs that specify start and end positions.
  static DOMRange? createRangeFromPaths(
    DOMNode root,
    CFIPath? parentPath,
    CFIPath startPath,
    CFIPath endPath,
  ) {
    DOMNode baseNode = root;
    
    // Navigate to parent path if specified
    if (parentPath != null) {
      final parentPosition = navigateToPosition(root, parentPath);
      if (parentPosition == null) return null;
      baseNode = parentPosition.container;
    }
    
    // Navigate to start and end positions
    final startPosition = navigateToPosition(baseNode, startPath);
    final endPosition = navigateToPosition(baseNode, endPath);
    
    if (startPosition == null || endPosition == null) return null;
    
    return DOMRange(
      startContainer: startPosition.container,
      startOffset: startPosition.offset,
      endContainer: endPosition.container,
      endOffset: endPosition.offset,
    );
  }

  /// Creates a CFI path from a DOM range.
  /// 
  /// Builds start and end paths and finds their common parent.
  static CFIStructure createStructureFromRange(DOMRange range) {
    final startPosition = DOMPosition(
      container: range.startContainer,
      offset: range.startOffset,
    );
    final endPosition = DOMPosition(
      container: range.endContainer,
      offset: range.endOffset,
    );
    
    final startPath = createPathFromPosition(startPosition);
    final endPath = createPathFromPosition(endPosition);
    
    // Find common parent path
    final commonParentParts = <CFIPart>[];
    final minLength = startPath.parts.length < endPath.parts.length
        ? startPath.parts.length
        : endPath.parts.length;
    
    for (int i = 0; i < minLength - 1; i++) { // -1 to exclude final positioning
      final startPart = startPath.parts[i];
      final endPart = endPath.parts[i];
      
      if (startPart.index == endPart.index && startPart.id == endPart.id) {
        commonParentParts.add(startPart);
      } else {
        break;
      }
    }
    
    // Create relative paths
    final startRelativeParts = startPath.parts.skip(commonParentParts.length).toList();
    final endRelativeParts = endPath.parts.skip(commonParentParts.length).toList();
    
    return CFIStructure(
      parent: commonParentParts.isNotEmpty ? CFIPath(parts: commonParentParts) : null,
      start: CFIPath(parts: startRelativeParts),
      end: CFIPath(parts: endRelativeParts),
    );
  }

  /// Validates that a CFI path can be resolved in the given DOM tree.
  static bool validatePath(DOMNode root, CFIPath path) {
    return navigateToPosition(root, path) != null;
  }

  /// Gets text content between two positions in the DOM.
  static String extractTextBetweenPositions(DOMPosition start, DOMPosition end) {
    if (start.container == end.container && 
        start.container.nodeType == DOMNodeType.text) {
      // Simple case: same text node
      final text = start.container.nodeValue ?? '';
      final startOffset = start.offset.clamp(0, text.length);
      final endOffset = end.offset.clamp(startOffset, text.length);
      return text.substring(startOffset, endOffset);
    }
    
    // Complex case: multiple nodes
    // This would require tree traversal to collect text
    return _extractTextFromComplexRange(start, end);
  }

  /// Extracts text from a range spanning multiple nodes.
  /// 
  /// This is a simplified implementation. A full implementation would
  /// perform proper tree traversal to collect all text content.
  static String _extractTextFromComplexRange(DOMPosition start, DOMPosition end) {
    final buffer = StringBuffer();
    
    // Start with text from the starting node
    if (start.container.nodeType == DOMNodeType.text) {
      final text = start.container.nodeValue ?? '';
      buffer.write(text.substring(start.offset.clamp(0, text.length)));
    }
    
    // TODO: Implement proper tree traversal to collect intermediate text
    // This would involve walking the DOM tree from start to end position
    
    // End with text from the ending node (if different)
    if (end.container != start.container && 
        end.container.nodeType == DOMNodeType.text) {
      final text = end.container.nodeValue ?? '';
      buffer.write(text.substring(0, end.offset.clamp(0, text.length)));
    }
    
    return buffer.toString();
  }
}

/// Represents virtual positions in the CFI indexing scheme.
class _VirtualPosition {
  final _VirtualPositionType type;
  
  const _VirtualPosition(this.type);
  
  @override
  String toString() => type.name;
}

/// Types of virtual positions.
enum _VirtualPositionType {
  before,  // Virtual position before all content
  text,    // Virtual text position between elements
  after,   // Virtual position after all content
}