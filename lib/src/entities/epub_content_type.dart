enum EpubContentType {
  xhtml11,
  dtbook,
  dtbookNCX,
  oeb1Document,
  xml,
  css,
  oeb1CSS,
  imageGIF,
  imageJPEG,
  imagePNG,
  imageSVG,
  imageBMP,
  fontTrueType,
  fontOpenType,
  other;

  factory EpubContentType.fromMimeType(String contentMimeType) =>
      switch (contentMimeType.toLowerCase()) {
        'application/xhtml+xml' || 'text/html' => xhtml11,
        'application/x-dtbook+xml' => dtbook,
        'application/x-dtbncx+xml' => dtbookNCX,
        'text/x-oeb1-document' => oeb1Document,
        'application/xml' => xml,
        'text/css' => css,
        'text/x-oeb1-css' => oeb1CSS,
        'image/gif' => imageGIF,
        'image/jpeg' => imageJPEG,
        'image/png' => imagePNG,
        'image/svg+xml' => imageSVG,
        'image/bmp' => imageBMP,
        'font/truetype' => fontTrueType,
        'font/opentype' || 'application/vnd.ms-opentype' => fontOpenType,
        _ => other,
      };
}
