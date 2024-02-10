import 'package:quiver/core.dart';

import '../schema/navigation/epub_navigation.dart';
import '../schema/opf/epub_package.dart';

class EpubSchema {
  EpubPackage? package;
  EpubNavigation? navigation;
  String? contentDirectoryPath;

  @override
  int get hashCode => hash3(
      package.hashCode, navigation.hashCode, contentDirectoryPath.hashCode);

  @override
  bool operator ==(other) {
    if (other is! EpubSchema) {
      return false;
    }

    return package == other.package &&
        navigation == other.navigation &&
        contentDirectoryPath == other.contentDirectoryPath;
  }
}
