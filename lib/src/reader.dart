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

class ZipReader {
  FileMapping _file;

  Encoding _encoding;

  final Encoding _utf8Codec = const Utf8Codec(allowMalformed: true);

  ZipReader(String path, {Encoding encoding}) {
    _file = new FileMapping(path);
    _encoding = encoding == null ? _utf8Codec : encoding;
  }

  Future open() => _file.open();

  Future close() => _file.close();

  Stream<ZipEntity> process() async* {
    var zip = await readZip();

    if (zip.comment != null) yield new ZipCommentImpl(zip.comment);

    yield* readDirectory(zip.directory);
  }

  ///
  /// Extracts the ZIP and Zip64 structures from the mapped [_file].
  ///
  Future<ZipStructure> readZip() async {
    var zip = new ZipStructure();

    // Reads the basic ZIP structures.
    var offset = await findEndRecord();
    zip.endRecord = readEndRecord(offset);
    zip.comment = await readComment(
        offset + endRecordLength, zip.endRecord.commentLength);

    // Reads the Zip64 structures.
    var zip64Offset = await findZip64Locator(offset - zip64LocatorLength);
    if (zip64Offset != null) {
      zip.zip64Locator = readZip64Locator(zip64Offset);
      if (await isValidZip64Locator(zip64Offset, zip)) {
        zip.zip64EndRecord = readZip64EndRecord(zip.zip64Locator.zip64Offset);
        if (isValidZip64EndRecord(zip)) {
          zip.isZip64 = true;
        }
      }
    }

    //  Takes the correct directory values.
    zip.directory = buildDirectory(zip, offset);

    return zip;
  }

  ///
  /// Tries to find the end record signature reading backward from the end
  /// of the ZIP file.
  ///
  Future<int> findEndRecord() async {
    var position = _file.length;
    var offset = _file.length - endRecordLength;

    var size = min(endRecordLength + maxCommentLength, _file.length);
    var chunkSize = min(size, blockSize);

    while (chunkSize >= endRecordLength) {
      position -= chunkSize;

      await _file.read(position, chunkSize);

      for (; offset >= position; offset--) {
        if (_file.getUint32(offset) == endRecordSignature) return offset;
      }

      position += endRecordLength - 1;
      size -= chunkSize - (endRecordLength - 1);

      chunkSize = min(size, blockSize);
    }

    throw new ZipException("End of Central Directory record signature not"
        " found. This does not seem to be a valid ZIP file.");
  }

  ///
  /// Reads the end record from [offset].
  ///
  ZipEndRecord readEndRecord(int offset) => new ZipEndRecord()
    ..disk = _file.getUint16(offset + 4)
    ..directoryDisk = _file.getUint16(offset + 6)
    ..diskEntryCount = _file.getUint16(offset + 8)
    ..entryCount = _file.getUint16(offset + 10)
    ..directorySize = _file.getUint32(offset + 12)
    ..directoryOffset = _file.getUint32(offset + 16)
    ..commentLength = _file.getUint16(offset + 20);

  ///
  /// Reads the ZIP file comment from [offset].
  ///
  /// Returns `null` if the [length] of the comment is `0`.
  ///
  Future<String> readComment(int offset, int length) async {
    if (offset + length > _file.length) {
      throw new ZipException("The .ZIP File Comment ends (${offset + length})"
          " after the end of the file (${_file.length}).");
    }

    return await readString(offset, length);
  }

  ///
  /// Tries to find the Zip64 end record locator from [offset].
  ///
  /// Returns `null` if the locator could not be found.
  ///
  Future<int> findZip64Locator(int offset) async {
    if (offset < 0) return null;

    await _file.read(offset, zip64LocatorLength);

    if (_file.getUint32(offset) != zip64LocatorSignature) return null;

    return offset;
  }

  ///
  /// Reads the Zip64 end record locator from [offset].
  ///
  Zip64Locator readZip64Locator(int offset) => new Zip64Locator()
    ..zip64Disk = _file.getUint32(offset + 4)
    ..zip64Offset = _file.getUint64(offset + 8)
    ..diskCount = _file.getUint32(offset + 16);

  ///
  /// Validates the Zip64 end record locator found at [offset].
  ///
  Future<bool> isValidZip64Locator(int offset, ZipStructure zip) async {
    var zip64Locator = zip.zip64Locator;

    // There must be only one disk.
    if (zip64Locator.diskCount != 1) {
      throw new ZipException("Unsupported multi-disk ZIP file detected."
          " The Zip64 End of Central Directory Locator claims that there are"
          " ${zip64Locator.diskCount} disks.");
    }

    // There must be only one disk.
    if (zip64Locator.zip64Disk != 0) {
      throw new ZipException("Unsupported multi-disk ZIP file detected."
          " The Zip64 End of Central Directory starts in the disk number"
          " ${zip64Locator.zip64Disk}.");
    }

    // The Zip64 end record must be located before the Zip64 locator.
    if (zip64Locator.zip64Offset + zip64EndRecordLength > offset) {
      throw new ZipException("The Zip64 End of Central Directory record ends"
          " (${zip64Locator.zip64Offset + zip64EndRecordLength}) after the"
          " Zip64 End of Central Directory Locator ($offset).");
    }

    await _file.read(zip64Locator.zip64Offset, zip64EndRecordLength);

    // The Zip64 end record signature must be there.
    if (_file.getUint32(zip64Locator.zip64Offset) != zip64EndRecordSignature) {
      throw new ZipException("Zip64 End of Central Directory record signature"
          " not found at ${zip64Locator.zip64Offset}.");
    }

    return true;
  }

  ///
  /// Reads the Zip64 end record from [offset].
  ///
  /// The Zip64 extensible data sector is ignored because is "PKWARE
  /// Proprietary Technology".
  ///
  Zip64EndRecord readZip64EndRecord(int offset) => new Zip64EndRecord()
    ..size = _file.getUint64(offset + 4)
    ..versionMadeBy = _file.getUint16(offset + 12)
    ..versionNeeded = _file.getUint16(offset + 14)
    ..disk = _file.getUint32(offset + 16)
    ..directoryDisk = _file.getUint32(offset + 20)
    ..diskEntryCount = _file.getUint64(offset + 24)
    ..entryCount = _file.getUint64(offset + 32)
    ..directorySize = _file.getUint64(offset + 40)
    ..directoryOffset = _file.getUint64(offset + 48);

  ///
  /// Validates the Zip64 end record.
  ///
  /// The [zip.zip64Locator] is used to validated the disk number claimed
  /// in the [zip.zip64EndRecord].
  ///
  /// The [zip.endRecord] is used to validated the field values claimed
  /// in the [zip.zip64EndRecord].
  ///
  bool isValidZip64EndRecord(ZipStructure zip) {
    var endRecord = zip.endRecord;
    var zip64Locator = zip.zip64Locator;
    var zip64EndRecord = zip.zip64EndRecord;

    // The disk number in the Zip64 end record must be the same that the
    // one in the Zip64 end record locator.
    if (zip64EndRecord.disk != zip64Locator.zip64Disk) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that the current disk number is ${zip64EndRecord.disk}"
          " instead of ${zip64Locator.zip64Disk}.");
    }

    // The fields in the Zip64 end record must have the same value that the
    // corresponding valid fields in the end record.
    if ((endRecord.directoryDisk != magicDisk) &&
        (endRecord.directoryDisk != zip64EndRecord.directoryDisk)) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that theCentral Directory disk number is"
          " ${zip64EndRecord.directoryDisk} instead of"
          " ${endRecord.directoryDisk}.");
    }
    if ((endRecord.diskEntryCount != magicEntryCount) &&
        (endRecord.diskEntryCount != zip64EndRecord.diskEntryCount)) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that the number of entries on the current disk is"
          " ${zip64EndRecord.diskEntryCount} instead of"
          " ${endRecord.diskEntryCount}.");
    }
    if ((endRecord.entryCount != magicEntryCount) &&
        (endRecord.entryCount != zip64EndRecord.entryCount)) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that the  total number of entries is"
          " ${zip64EndRecord.entryCount} instead of ${endRecord.entryCount}.");
    }
    if ((endRecord.directorySize != magicSize) &&
        (endRecord.directorySize != zip64EndRecord.directorySize)) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that the size of the Central Directory is"
          " ${zip64EndRecord.directorySize} instead of"
          " ${endRecord.directorySize}.");
    }
    if ((endRecord.directoryOffset != magicOffset) &&
        (endRecord.directoryOffset != zip64EndRecord.directoryOffset)) {
      throw new ZipException("The Zip64 End of Central Directory record"
          " claims that the  offset to the Central Directory is"
          " ${zip64EndRecord.directoryOffset} instead of"
          " ${endRecord.directoryOffset}.");
    }

    return true;
  }

  ///
  /// Takes the correct directory values.
  ///
  /// The [zip.isZip64] and [zip.endRecord] values are used to take (or not)
  /// the values claimed in the [zip.zip64EndRecord].
  ///
  /// The [endRecordOffset] is used to validate that the whole central
  /// directory is before the end record (or the Zip64 end record).
  ///
  ZipDirectory buildDirectory(ZipStructure zip, int endRecordOffset) {
    var directory = new ZipDirectory();

    var endRecord = zip.endRecord;
    var isZip64 = zip.isZip64;
    var zip64Locator = zip.zip64Locator;
    var zip64EndRecord = zip.zip64EndRecord;

    directory.disk = isZip64 && (endRecord.directoryDisk == magicDisk)
        ? zip64EndRecord.directoryDisk
        : endRecord.directoryDisk;

    directory.offset = isZip64 && (endRecord.directoryOffset == magicOffset)
        ? zip64EndRecord.directoryOffset
        : endRecord.directoryOffset;

    directory.size = isZip64 && (endRecord.directorySize == magicSize)
        ? zip64EndRecord.directorySize
        : endRecord.directorySize;

    directory.entryCount = isZip64 && (endRecord.entryCount == magicEntryCount)
        ? zip64EndRecord.entryCount
        : endRecord.entryCount;

    // Al values must be valid now.
    if (!isZip64) {
      if ((directory.disk == magicDisk) ||
          (directory.offset == magicOffset) ||
          (directory.size == magicSize) ||
          (directory.entryCount == magicEntryCount)) {
        throw new ZipException("The Zip64 End of Central Directory record was"
            " not found, but it is necessary to get the real values of some"
            " of the fields in the End of Central Directory record.");
      }
    }

    // There must be only one disk.
    if (directory.disk != 0) {
      throw new ZipException("Unsupported multi-disk ZIP file detected."
          " Central Directory starts in the disk number ${directory.disk}.");
    }

    // The central directory must be located before the end record.
    var offset = isZip64 ? zip64Locator.zip64Offset : endRecordOffset;

    if ((directory.offset + directory.size) > offset) {
      throw new ZipException("The Central Directory ends"
          " (${directory.offset + directory.size}) after the"
          " ${isZip64 ? 'Zip64' : ''} End of Central Directory record"
          " ($offset).");
    }

    return directory;
  }

  ///
  /// Reads the central [directory] entries. Emits an entity for each entry found.
  ///
  Stream<ZipEntity> readDirectory(ZipDirectory directory) async* {
    var offset = directory.offset;
    var size = directory.size;

    // Empty file?
    if ((offset == 0) && (size == 0)) return;

    // Iterates over all the entries, one block first, then another one, and so on.
    var headers = new List<ZipFileHeader>();
    var chunkSize = 0;

    for (var i = 0; i < directory.entryCount; i++) {
      if (chunkSize < fileHeaderLength) {
        size += chunkSize;
        chunkSize = min(size, blockSize);

        if (chunkSize < fileHeaderLength) {
          throw new ZipException("File Header too short at $offset, it must be"
              " $fileHeaderLength bytes long at least, but only $chunkSize"
              " were found instead.");
        }

        await _file.read(offset, chunkSize);
        size -= chunkSize;
      }

      // The file header signature must be there.
      if (_file.getUint32(offset) != fileHeaderSignature) {
        throw new ZipException("File Header signature not found at $offset.");
      }

      var header = readFileHeader(offset);
      offset += fileHeaderLength;

      // File name, extra field and comment.
      var payload =
          header.nameLength + header.extraLength + header.commentLength;

      if ((offset + payload) > (directory.offset + directory.size)) {
        throw new ZipException("File Header ends"
            " (${offset + fileHeaderLength + payload}) after the end of the"
            " Central Directory (${directory.offset + directory.size}).");
      }

      // If b11 is set then the file name and comment are enconded using UTF-8.
      var utf8 = (header.flags & 0x0800) != 0;

      header.name = await readEntryFilename(offset, header.nameLength, utf8);
      offset += header.nameLength;

      header.extra = await readExtraField(offset, header.extraLength);
      offset += header.extraLength;

      // Extra Zip64 field?
      if (header.extra != null) {
        readZip64Extra(header.extra, header);
      }

      header.comment =
          await readEntryComment(offset, header.commentLength, utf8);
      offset += header.commentLength;

      // There must be only one disk.
      if (header.localDisk != 0) {
        throw new ZipException("Unsupported multi-disk ZIP file detected. The"
            " entry number $i starts in the disk number ${header.localDisk}.");
      }

      // All done with this header.
      headers.add(header);

      chunkSize -= fileHeaderLength + payload;

      // Is the current block fully processed?
      if ((chunkSize < fileHeaderLength) || (i == (directory.entryCount - 1))) {

        // Reads the corresponding local headers and emits an entity for each entry.
        yield* readEntries(headers);
      }
    }
  }

  ///
  /// Reads a file header from [offset].
  ///
  ZipFileHeader readFileHeader(int offset) => new ZipFileHeader()
    ..versionMadeBy = _file.getUint16(offset + 4)
    ..versionNeeded = _file.getUint16(offset + 6)
    ..flags = _file.getUint16(offset + 8)
    ..compressionMethod = _file.getUint16(offset + 10)
    ..time = _file.getUint16(offset + 12)
    ..date = _file.getUint16(offset + 14)
    ..crc32 = _file.getUint32(offset + 16)
    ..compressedSize = _file.getUint32(offset + 20)
    ..uncompressedSize = _file.getUint32(offset + 24)
    ..nameLength = _file.getUint16(offset + 28)
    ..extraLength = _file.getUint16(offset + 30)
    ..commentLength = _file.getUint16(offset + 32)
    ..localDisk = _file.getUint16(offset + 34)
    ..internalAttr = _file.getUint16(offset + 36)
    ..externalAttr = _file.getUint32(offset + 38)
    ..localOffset = _file.getUint32(offset + 42);

  ///
  /// Read the corresponding entry (aka local file header) for each file
  /// header in [headers] and emits an entity for each entry.
  ///
  Stream<ZipEntity> readEntries(List<ZipFileHeader> headers) async* {
    for (var header in headers) {
      var entry = await readEntry(header.localOffset, header);

      // Calculates the offset to the file content data.
      var dataOffset = header.localOffset +
          localFileHeaderLength +
          entry.nameLength +
          entry.extraLength;

      // If b0 is set then the file is encrypted.
      if ((header.flags & 0x0001) != 0) {
        dataOffset += encryptionHeaderLength;
      }

      if (dataOffset + header.compressedSize > _file.length) {
        throw new ZipException("Content data file ends"
            " (${dataOffset + header.compressedSize}) after the end of the"
            " file (${_file.length}).");
      }

      yield new ZipEntryImpl.fromCentral(_file.path, header, entry);
    }
  }

  ///
  /// Reads an entry (aka local file header) from [offset].
  ///
  /// If the local file header has a Zip64 extra field then [header] is
  /// updated with the new values. The rest of the values of the local
  /// file header are read but ignored.
  ///
  Future<ZipLocalFileHeader> readEntry(int offset, ZipFileHeader header) async {
    if (offset + localFileHeaderLength > _file.length) {
      throw new ZipException("Local File Header ends"
          " (${offset + localFileHeaderLength}) after the end of the file"
          " (${_file.length}).");
    }

    await _file.read(offset, localFileHeaderLength);

    // The local file header signature must be there.
    if (_file.getUint32(offset) != localFileHeaderSignature) {
      throw new ZipException(
          "Local File Header signature not found at $offset.");
    }

    var entry = readLocalFileHeader(offset);
    offset += localFileHeaderLength;

    // File name and extra field.
    var payload = entry.nameLength + entry.extraLength;

    // If b0 is set then the file is encrypted.
    if ((header.flags & 0x0001) != 0) {
      payload += encryptionHeaderLength;
    }

    if ((offset + payload) > _file.length) {
      throw new ZipException("Local File Header ends (${offset + payload})"
          " after the end of the file (${_file.length}).");
    }

    // The file name is ignored, but the extra field is inspected.
    entry.extra =
        await readExtraField(offset + entry.nameLength, entry.extraLength);

    // Extra Zip64 field?
    if (entry.extra != null) {
      readZip64Extra(entry.extra, header);
    }

    return entry;
  }

  ///
  /// Reads a local file header from [offset].
  ///
  ZipLocalFileHeader readLocalFileHeader(int offset) => new ZipLocalFileHeader()
    ..versionNeeded = _file.getUint16(offset + 4)
    ..flags = _file.getUint16(offset + 6)
    ..compressionMethod = _file.getUint16(offset + 8)
    ..time = _file.getUint16(offset + 10)
    ..date = _file.getUint16(offset + 12)
    ..crc32 = _file.getUint32(offset + 14)
    ..compressedSize = _file.getUint32(offset + 18)
    ..uncompressedSize = _file.getUint32(offset + 22)
    ..nameLength = _file.getUint16(offset + 26)
    ..extraLength = _file.getUint16(offset + 28);

  ///
  /// Reads an entry file name from [offset] of [length] bytes length.
  ///
  Future<String> readEntryFilename(int offset, int length, bool utf8) async =>
      await readString(offset, length, utf8: utf8);

  ///
  /// Reads an entry extra field from [offset] of [length] bytes length.
  ///
  Future<List<int>> readExtraField(int offset, int length) async =>
      await readBytes(offset, length);

  ///
  /// Reads an entry comment from [offset] of [length] bytes length.
  ///
  Future<String> readEntryComment(int offset, int length, bool utf8) async =>
      await readString(offset, length, utf8: utf8);

  ///
  /// Tries to find and process the Zip64 extra field in [bytes].
  ///
  /// If the field is found then the invalid uncompressed size, compressed
  /// size, offset to the local header, and disk number in the [header] are
  /// replaced with the values extracted from it.
  ///
  Zip64ExtraField readZip64Extra(List<int> bytes, ZipFileHeader header) {
    var required = 0;
    if (header.uncompressedSize == magicSize) required += 8;
    if (header.compressedSize == magicSize) required += 8;
    if (header.localOffset == magicOffset) required += 8;
    if (header.localDisk == magicDisk) required += 4;

    // Are all the values already valid?
    if (required == 0) return null;

    // Inspect the extra field, it should be pairs of <id, size>, but it could
    // also contains any random data.
    var data = (bytes as Uint8List).buffer.asByteData();
    var offset = 0;
    var available = data.lengthInBytes;

    while (available >= extraFieldLength) {
      var id = data.getUint16(offset, Endianness.LITTLE_ENDIAN);
      var size = data.getUint16(offset + 2, Endianness.LITTLE_ENDIAN);

      // Zip64 extra field detected?
      if ((id == zip64HeaderId) && (size <= (available - extraFieldLength))) {

        // Is this a valid Zip64 extra field?
        if (size < required) break;

        // Reads the Zip64 extra field.
        var extra = new Zip64ExtraField()
          ..id = id
          ..size = size;

        offset += extraFieldLength;

        // Set the correct values in the header.
        if (header.uncompressedSize == magicSize) {
          header.uncompressedSize = extra.uncompressedSize =
              data.getUint64(offset, Endianness.LITTLE_ENDIAN);
          offset += 8;
        }
        if (header.compressedSize == magicSize) {
          header.compressedSize = extra.compressedSize =
              data.getUint64(offset, Endianness.LITTLE_ENDIAN);
          offset += 8;
        }
        if (header.localOffset == magicOffset) {
          header.localOffset = extra.localOffset =
              data.getUint64(offset, Endianness.LITTLE_ENDIAN);
          offset += 8;
        }
        if (header.localDisk == magicDisk) {
          header.localDisk = extra.localDisk =
              data.getUint32(offset, Endianness.LITTLE_ENDIAN);
          offset += 4;
        }

        return extra;
      }

      offset += extraFieldLength + size;
      available -= extraFieldLength + size;
    }

    return null;
  }

  ///
  /// Reads [size] bytes from [offset].
  ///
  /// Returns `null` if the [size] is `0`.
  ///
  Future<List<int>> readBytes(int offset, int size) async {
    if (size == 0) return null;

    var result = new Uint8List(size);
    var position = 0;

    while (size > 0) {
      var chunkSize = min(size, blockSize);
      await _file.read(offset, chunkSize);

      _file.setRange(result, position, offset, chunkSize);

      position += chunkSize;
      offset += chunkSize;
      size -= chunkSize;
    }

    return result;
  }

  ///
  /// Reads [size] bytes from [offset] and returns the result as a string.
  ///
  /// This method will use the default UTF8 decoder, the decoder passed as
  /// parameter in the constructor, or the UTF-8 decoder is [utf8] is `true`.
  ///
  /// Returns `null` if the [size] is `0`.
  ///
  Future<String> readString(int offset, int size, {bool utf8: false}) async {
    if (size == 0) return null;

    var result = new StringBuffer();

    var output = new StringConversionSink.withCallback((String data) {
      result.write(data);
    });

    var input = (utf8 ? _utf8Codec.decoder : _encoding.decoder)
        .startChunkedConversion(output);

    while (size > 0) {
      var chunkSize = min(size, blockSize);
      await _file.read(offset, chunkSize);

      _file.addSlice(input, offset, chunkSize);

      offset += chunkSize;
      size -= chunkSize;
    }

    input.close();

    return result.toString();
  }
}
