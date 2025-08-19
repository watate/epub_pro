# 5.6.0
- Added CFI support

# 5.5.1
- Fix duplicates in table of contents due to some books using # in the toc.ncx to refer to headings in chapters

# 5.5.0
- Major performance improvements to EPUB parsing

# 5.4.9
- Downgrade pinned XML dependency

# 5.4.8
- Fixed TOC structure issues with orphaned spine items
  - Orphaned spine items (not in NCX navigation) are now standalone chapters instead of forced sub-chapters
  - Preserves proper NCX hierarchy while ensuring all spine content is accessible
  - Enhanced title extraction for all chapters (both NCX and orphaned) using HTML body content
  - Improved extraction patterns to find first non-empty text content in HTML (handles Japanese content, single characters, etc.)
  - Added intelligent title truncation: texts >10 words are truncated with "..." instead of falling back to filenames
  - Smart fallback logic: use extracted content if available, else NCX title, else filename as last resort

# 5.4.7
- Ran 'dart format' to fix code formatting

# 5.4.6
- Fixed chapter splitting to handle nested divs and more element types including blockquote, h1, h2, section, article, tr, etc.
- Added more test cases for chapter splitting and japanese EPUBs

# 5.4.5
- Update optional chapter splitting to 3000 words instead of 5000 words (20-min reads)

# 5.4.4
- Preserve <head> for all split chapters
- Add filename fallback to chapters without titles

# 5.4.3
- Fix: chapter splitting not working on Japanese EPUBs. Fixed by using word count library

# 5.4.2
- Fix: safely handle files if they're in the root directory instead of a subdirectory

# 5.4.1
- Fixed title inheritance in lazy loading chapter splitting
  - The `splitChapterRef` method now properly applies parent title inheritance for orphaned subchapters
  - Ensures consistent behavior between `splitChapter` and `splitChapterRef` methods
  - Orphaned subchapters now show inherited parent titles instead of "Untitled" in all loading scenarios

# 5.4.0
- Changed chapter splitting title format from "Part X" to "(X/Y)" notation
  - Split chapters now use format: "Chapter Title (1/2)" instead of "Chapter Title - Part 1"
  - Prevents confusion with books that have actual "Part" titles (like Piranesi)
  - Better suited for chapter-based reading apps
- Fixed orphaned subchapters showing as "Untitled"
  - Orphaned spine items that become subchapters now inherit parent chapter titles
  - Applies to both split and non-split chapters for consistency
  - Example: chapter01.xhtml under "PART 1: PIRANESI" now shows as "PART 1: PIRANESI" instead of "Untitled"
- Updated all tests to expect the new (X/Y) format
- Enhanced documentation with cleaner, more readable examples

# 5.3.0
- Improved NCX/spine reconciliation for better handling of malformed EPUBs
  - Smart algorithm that ensures all spine items are accessible even when not in navigation
  - Orphaned spine items are automatically inserted as subchapters under logical parents  
  - Maintains correct reading order while preserving intended navigation hierarchy
  - Matches behavior of major EPUB readers like Apple Books
- Added comprehensive API documentation
  - All major classes now have detailed documentation comments with examples
  - Documentation follows Dart standards for generating API docs with `dart doc`
  - Added clear explanations of all public methods and properties
- Enhanced documentation
  - Updated README.md with better explanation of NCX/spine reconciliation
  - Added code examples for all major features
- Improved test coverage
  - Added tests for EPUBs with section-wrapped content (e.g., piranesi.epub)
  - Added tests for NCX/spine reconciliation functionality
  - Fixed test reliability issues

# 5.2.0
- Added lazy loading support for chapter splitting
  - Added `EpubReader.openBookWithSplitChapters()` - opens book with lazy loading and automatic chapter splitting
  - Added `EpubBookRef.getChapterRefsWithSplitting()` - returns chapter references that split on-demand
  - Added `EpubChapterSplitRef` class - represents a split chapter part with lazy content loading
  - Added `EpubBookSplitRef` class - wrapper for lazy loading books with split chapter support
- Memory efficiency improvements - split chapter content is only loaded when accessed

# 5.1.0
- Added EpubReader.readBookWithSplitChapters to split long chapters (>3000 words) into smaller parts
- Added getChaptersWithSplitting to get a list of chapters while taking into account splitting longer chapters (>3000 words)

# 5.0.5
- Ran dart formatter to improve package score

# 5.0.4
- Fixed chapter retrieval logic for EPUB2. Spine might contain additional split files that aren't in the NCX. We modify ChapterReader to create chapters for all spine items, even if they're not in the NCX. Basically this helps you handle unreliable "toc.ncx" in your EPUBs

# 5.0.3
- Fixed readBook crashing when cover image not found

# 5.0.2
- Updated dependencies

# 5.0.1
- Remove deprecated examples
- Remove unused dependencies
- Fix bugs

## 5.0.0
- Migrate to Dart code-style and null-safety

## 4.0.0

- Merge all pull requests

## 3.0.0
### Changed
- `metadata` file now saves as `mimetype` [pull#1](https://github.com/rbcprolabs/epubx.dart/pull/1) 
### Added
- Epub v3 support [dart-epub | pull#76](https://github.com/orthros/dart-epub/pull/76) 
- Doc comment [dart-epub | pull#80](https://github.com/orthros/dart-epub/pull/80) 

## 3.0.0-dev.3
### Changed
- At `EpubReader.{openBook, readBook}` first argument can be future (not before) 

## 3.0.0-dev.2
### Fixed
- Fixed null-safety bug

## 3.0.0-dev.1
### Added
- Null-safety migration
### Changed
- Upgrade all dependencies

## 2.1.0
### Fixed
- Version 3 EPUB's can have a null Table of Contents
- Updated `pedantic` analysis options

## 2.0.7
### Added
- Added example of using `epub` in a web page: `examples/web_ex`
### Fixed
- Fixed errors from pedantic analysis
### Changed
- Added pedantic analysis options

## 2.0.6
### Fixed
- Fixed Issue #35: File cannot be opened if its path is url-encoded in the manifest
- Updated `examples/dart_ex` to have a README as well as use a locally stored file.

## 2.0.5
### Changed
- Exposed `EpubChapterRef` to consumers.

## 2.0.4
### Fixed
- Merged pull request #45
    - Fixes pana hits to make code more readable

## 2.0.3
### Changed
- Raised `sdk` version constraint to 2.0.0
- Raised constraint on `async` to 3.0.0
### Fixed
- Merged pull request #40 by vblago. 
    - Fixes Undefined class 'XmlBuilder'

## 2.0.2
### Changed
- Lowered sdk version constraint to 2.0.0-dev.61.0

## 2.0.1
### Changed
- Formatted documents

## 2.0.0
### Added
- Added support for writing Epubs back to Byte Arrays
- Tests for writing Epubs

### Changed
- Epub Readers and Writers now have their == operator and hashCode get-er overridden

### Fixed
- Fixed an issue when reading EpubContentFileRef

## 1.3.2
### Changed
- Updates to Travis configuration and publishing

## 1.3.1
### Changed
- Updates to Travis configuration and publishing
### Removed
- Removed unused variable `FilePath` from `EpubBook` and `EpubBookRef`

## 1.3.0
### Added
- Package now supports Dart 2!
### Removed
- Removed support for Dart 1.2.21

## 1.2.10
### Fixed
- Merged pull request #15 from ShadowJonathan/dev. 
    - Fixes issue with parsing schema by removing `opf:` namespace

## 1.2.9
### Changed
- Ran code through `dartfmt` as per analysis by `pana`

## 1.2.8
### Added
- Added unit tests for Images
### Changed
- Updated dependencies

## 1.2.7
### Added
- Added upper limit of Dart version to 2.0.1

## 1.2.6
### Added
- Added Support for Dart 2.0

## 1.2.5
### Added
- A publish step in the travis deploy

## 1.2.4
### Changed
- EnumFromString no longer uses the `mirrors` package to make this Flutter compatible by @MostafaAyesh 

## 1.2.3
### Added
- This Changelog!

### Changed
- Author email

## 1.2.2
### Changed
- Dependencies were updated to more permissive versions by @jarontai

### Added
- Example by @jarontai
- More Entities and types are exported by @jarontai

### Fixed
- Issue with case sensitivity in switch statements from @jarontai
- Issue with Async Loops from @jarontai

## 1.2.1
### Fixed
- Made code in line with Dart styleguide

## 1.0.0
- Initial release of epub_pro
- Forked from epub_plus with updated dependencies
- Fixed equality comparison in EpubContentFileRef
- Removed unnecessary library name
