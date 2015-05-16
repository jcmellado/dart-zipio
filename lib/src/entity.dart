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

part of zipio;

///
/// Class used as base for all the entities.
///
abstract class ZipEntity {}

///
/// .ZIP file comment.
///
class ZipCommentImpl implements ZipComment {
  final String _text;

  ZipCommentImpl(this._text);

  String get text => _text;
}

///
/// .ZIP entry file.
///
class ZipEntryImpl implements ZipEntry {
  final String _name;

  final bool _isDirectory;

  final bool _isProtected;

  final ZipMethod _compressionMethod;

  final int _compressedSize;

  final int _uncompressedSize;

  final DateTime _modified;

  final String _comment;

  final List<int> _extra;

  final List<int> _localExtra;

  final String _path;

  final int _dataOffset;

  ///
  /// Builds a .ZIP entry file from the Central Directory.
  ///
  factory ZipEntryImpl.fromCentral(
      String path, ZipFileHeader header, ZipLocalFileHeader local) {
    var name = header.name;
    var isDirectory = (header.name != null) && header.name.endsWith("/");
    var isProtected = (header.flags & 0x0001) != 0;

    var compressionMethod = methods[header.compressionMethod];
    if (compressionMethod == null) {
      compressionMethod = ZipMethod.UNKNOWN;
    }
    var compressedSize = header.compressedSize;
    var uncompressedSize = header.uncompressedSize;

    var modified = new DosDateTime(header.date, header.time).dateTime;
    var comment = header.comment;

    var extra = header.extra;
    if (extra != null) {
      extra = new UnmodifiableListView(extra);
    }
    var localExtra = local.extra;
    if (localExtra != null) {
      localExtra = new UnmodifiableListView(local.extra);
    }

    // Calculates the offset to the file content data.
    var dataOffset = header.localOffset +
        localFileHeaderLength +
        local.nameLength +
        local.extraLength;

    if (isProtected) {
      dataOffset += encryptionHeaderLength;
    }

    return new ZipEntryImpl._internal(name, isDirectory, isProtected,
        compressionMethod, compressedSize, uncompressedSize, modified, comment,
        extra, localExtra, path, dataOffset);
  }

  const ZipEntryImpl._internal(this._name, this._isDirectory, this._isProtected,
      this._compressionMethod, this._compressedSize, this._uncompressedSize,
      this._modified, this._comment, this._extra, this._localExtra, this._path,
      this._dataOffset);

  String get name => _name;

  bool get isDirectory => _isDirectory;

  bool get isProtected => _isProtected;

  ZipMethod get compressionMethod => _compressionMethod;

  int get compressedSize => _compressedSize;

  int get uncompressedSize => _uncompressedSize;

  DateTime get modified => _modified;

  String get comment => _comment;

  List<int> get extra => _extra;

  List<int> get localExtra => _localExtra;

  ///
  /// Get the uncompressed content of the entry.
  ///
  Stream<List<int>> content() async* {
    if (isProtected) {
      throw new ZipException("Unsupported encrypted file detected.");
    }
    if (compressionMethod == ZipMethod.UNKNOWN) {
      throw new ZipException("This entry uses an unknown compression method.");
    }
    if ((compressionMethod != ZipMethod.STORED) &&
        (compressionMethod != ZipMethod.DEFLATED)) {
      throw new ZipException("Unsupported compression method detected. Only"
          " stored and deflated methods are supported.");
    }

    // Reads the file.
    var stream = await new File(_path).openRead(
        _dataOffset, _dataOffset + compressedSize);

    yield* (compressionMethod == ZipMethod.STORED
        ? stream
        : new ZLibCodec(raw: true).decoder.bind(stream));
  }
}
