/*
  Copyright (c) 2015 Juan Mellado

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/

// References:
// - .ZIP File Format Specification:
//   https://www.pkware.com/documents/casestudies/APPNOTE.TXT

///
/// The zipio library can be used to read .ZIP files.
///
library zipio;

// Dart libraries.
import "dart:async"
    show Completer, Future, Stream, StreamController, StreamSubscription;
import "dart:convert"
    show ByteConversionSink, Encoding, StringConversionSink, Utf8Codec;
import "dart:collection" show UnmodifiableListView;
import "dart:io" show File, FileMode, RandomAccessFile, ZLibCodec;
import "dart:math" show min, max;
import "dart:typed_data" show ByteData, Endianness, Uint8List;

// External packages.
import "package:logging/logging.dart" show Level, Logger;

// zipio packages.
import "package:zipio/zipio_extra.dart";

part "src/date.dart";
part "src/debug.dart";
part "src/entity.dart";
part "src/exception.dart";
part "src/mapping.dart";
part "src/reader.dart";
part "src/structure.dart";

///
/// Reads the [path] .ZIP file.
///
/// Returns a stream of {ZipEntity} objects. A {ZipEntity} object can be a
/// {ZipComment} containing the text of the .ZIP file, or a {ZipEntry}
/// describing a entry file.
///
/// zipio uses UTF-8 for text encoding, but a different [enconding] converter
/// can be used.
///
/// An optional [log] can be used to dump debugging information at
/// `Level.FINE`, `Level.FINER` or `Level.FINEST`.
///
Stream<ZipEntity> readZip(String path, {Encoding encoding, Logger log}) async* {
  var reader = log == null
      ? new ZipReader(path, encoding: encoding)
      : new ZipReaderDebug(path, encoding: encoding, log: log);
  try {
    await reader.open();
    yield* reader.process();
  } finally {
    await reader.close();
  }
}

///
/// .ZIP file comment.
///
abstract class ZipComment implements ZipEntity {
  String get text;
}

///
/// .ZIP file entry.
///
abstract class ZipEntry implements ZipEntity {

  /// File name .
  String get name;

  /// Is this entry a directory?
  bool get isDirectory;

  /// Is this entry password protected?
  bool get isProtected;

  /// Compression method.
  ZipMethod get compressionMethod;

  /// Compressed size.
  int get compressedSize;

  /// Uncompresse size.
  int get uncompressedSize;

  /// Uncompressed data.
  Stream<List<int>> content();

  /// Last modification date.
  DateTime get modified;

  /// File comment.
  String get comment;

  /// Raw extra fields.
  List<int> get extra;

  /// Raw local extra fields.
  List<int> get localExtra;
}
