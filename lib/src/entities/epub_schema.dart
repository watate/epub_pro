import '../schema/navigation/epub_navigation.dart';
import '../schema/opf/epub_package.dart';

class EpubSchema {
  final EpubPackage? package;
  final EpubNavigation? navigation;
  final String? contentDirectoryPath;

  const EpubSchema({
    this.package,
    this.navigation,
    this.contentDirectoryPath,
  });

  @override
  int get hashCode =>
      package.hashCode ^ navigation.hashCode ^ contentDirectoryPath.hashCode;

  @override
  bool operator ==(covariant EpubSchema other) {
    if (identical(this, other)) return true;

    return other.package == package &&
        other.navigation == navigation &&
        other.contentDirectoryPath == contentDirectoryPath;
  }
}
