import 'dart:async';

import 'package:archive/archive.dart';

import '../entities/epub_schema.dart';
import '../utils/zip_path_utils.dart';
import 'navigation_reader.dart';
import 'package_reader.dart';
import 'root_file_path_reader.dart';

class SchemaReader {
  static Future<EpubSchema> readSchema(Archive epubArchive) async {
    final rootFilePath =
        (await RootFilePathReader.getRootFilePath(epubArchive))!;
    final contentDirectoryPath = ZipPathUtils.getDirectoryPath(rootFilePath);

    final package = await PackageReader.readPackage(epubArchive, rootFilePath);

    final navigation = await NavigationReader.readNavigation(
      epubArchive,
      contentDirectoryPath,
      package,
    );

    return EpubSchema(
      package: package,
      navigation: navigation,
      contentDirectoryPath: contentDirectoryPath,
    );
  }
}
