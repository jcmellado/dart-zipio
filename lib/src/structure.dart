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

// Signatures.

/// End record signature.
const int endRecordSignature = 0x06054b50;

/// Zip64 end record locator signature.
const int zip64LocatorSignature = 0x07064b50;

/// Zip64 end record signature.
const int zip64EndRecordSignature = 0x06064b50;

/// File header signature.
const int fileHeaderSignature = 0x02014b50;

/// Local file header signature.
const int localFileHeaderSignature = 0x04034b50;

/// Spanned/Split file signature.
const int spanSignature = 0x08074b50;

/// Single spanned/Split file signature.
const int singleSpanSignature = 0x30304b50;

// Structure lengths.

/// Signature length.
const int signatureLength = 4;

/// End record length.
const int endRecordLength = 22;

/// Maximum ZIP file comment length.
const int maxCommentLength = 65535;

/// Zip64 end record locator length.
const int zip64LocatorLength = 20;

/// Zip64 end record length.
const int zip64EndRecordLength = 56;

/// File header length.
const int fileHeaderLength = 46;

/// Local file header length.
const int localFileHeaderLength = 30;

/// Encryption header length.
const int encryptionHeaderLength = 12;

/// Extra field length.
const int extraFieldLength = 4;

// Magic numbers.

/// Magic disk number.
const int magicDisk = 0xffff;

/// Magic offset.
const int magicOffset = 0xffffffff;

/// Magic size.
const int magicSize = 0xffffffff;

/// Magic entry count.
const int magicEntryCount = 0xffff;

// Compression methods.

/// The file is stored (no compression).
const int storedMethod = 0;

/// The file is Shrunk.
const int shrunkMethod = 1;

/// The file is Reduced with compression factor 1.
const int reduced1Method = 2;

/// The file is Reduced with compression factor 2.
const int reduced2Method = 3;

/// The file is Reduced with compression factor 3.
const int reduced3Method = 4;

/// The file is Reduced with compression factor 4.
const int reduced4Method = 5;

/// The file is Imploded.
const int implodedMethod = 6;

/// Reserved for Tokenizing compression algorithm.
const int tokenizedMethod = 7;

/// The file is Deflated.
const int deflatedMethod = 8;

/// Enhanced Deflating using Deflate64(tm).
const int deflated64Method = 9;

/// PKWARE Data Compression Library Imploding (old IBM TERSE).
const int ibmTerseOldMethod = 10;

/// Reserved by PKWARE.
const int reserved11Method = 11;

/// File is compressed using BZIP2 algorithm.
const int bzip2Method = 12;

/// Reserved by PKWARE.
const int reserved13Method = 13;

/// LZMA (EFS).
const int lzmaMethod = 14;

/// Reserved by PKWARE.
const int reserved15Method = 15;

/// Reserved by PKWARE.
const int reserved16Method = 16;

/// Reserved by PKWARE.
const int reserved17Method = 17;

/// File is compressed using IBM TERSE (new).
const int ibmTerseNewMethod = 18;

/// IBM LZ77 z Architecture (PFS).
const int lz77Method = 19;

/// WavPack compressed data.
const int wavPackMethod = 97;

/// PPMd version I, Rev 1.
const int ppmdMethod = 98;

/// Compression methods.
enum ZipMethod {
  STORED,
  SHRUNK,
  REDUCED_1,
  REDUCED_2,
  REDUCED_3,
  REDUCED_4,
  IMPLODED,
  TOKENIZED,
  DEFLATED,
  DEFLATED64,
  IBM_TERSE_OLD,
  RESERVED_11,
  BZIP2,
  RESERVED_13,
  LZMA,
  RESERVED_15,
  RESERVER_16,
  RESERVED_17,
  IBM_TERSE_NEW,
  LZ77,
  WAVPACK,
  PPMD,
  UNKNOWN
}

/// Compression methods by id.
const Map<int, ZipMethod> methods = const {
  storedMethod: ZipMethod.STORED,
  shrunkMethod: ZipMethod.SHRUNK,
  reduced1Method: ZipMethod.REDUCED_1,
  reduced2Method: ZipMethod.REDUCED_2,
  reduced3Method: ZipMethod.REDUCED_3,
  reduced4Method: ZipMethod.REDUCED_4,
  implodedMethod: ZipMethod.IMPLODED,
  tokenizedMethod: ZipMethod.TOKENIZED,
  deflatedMethod: ZipMethod.DEFLATED,
  deflated64Method: ZipMethod.DEFLATED64,
  ibmTerseOldMethod: ZipMethod.IBM_TERSE_OLD,
  reserved11Method: ZipMethod.RESERVED_11,
  bzip2Method: ZipMethod.BZIP2,
  reserved13Method: ZipMethod.RESERVED_13,
  lzmaMethod: ZipMethod.LZMA,
  reserved15Method: ZipMethod.RESERVED_15,
  reserved16Method: ZipMethod.RESERVER_16,
  reserved17Method: ZipMethod.RESERVED_17,
  ibmTerseNewMethod: ZipMethod.IBM_TERSE_NEW,
  lz77Method: ZipMethod.LZ77,
  wavPackMethod: ZipMethod.WAVPACK,
  ppmdMethod: ZipMethod.PPMD
};

///
/// Zip file structure.
///
class ZipStructure {

  /// End record.
  ZipEndRecord endRecord;

  /// ZIP file comment.
  String comment;

  /// Zip64 end record locator.
  Zip64Locator zip64Locator;

  /// Zip64 end record.
  Zip64EndRecord zip64EndRecord;

  /// Central directory.
  ZipDirectory directory;

  /// Is this a Zip64 file?
  bool isZip64 = false;
}

///
/// End record.
///
class ZipEndRecord {

  /// Number of the disk which contains the end record.
  int disk;

  /// Number of the disk with the start of the central directory.
  int directoryDisk;

  /// Number of entries in the disk which contains the end record.
  int diskEntryCount;

  /// Total number of entries in the central directory.
  int entryCount;

  /// Size of the entire central directory.
  int directorySize;

  /// Relative offset to the start of the central directory.
  int directoryOffset;

  /// ZIP file comment length.
  int commentLength;
}

///
/// Zip64 end record locator.
///
class Zip64Locator {

  /// Number of the disk which contains the Zip64 end record.
  int zip64Disk;

  /// Relative offset to the start of the Zip64 end record.
  int zip64Offset;

  /// Total number of disks.
  int diskCount;
}

///
/// Zip64 end record.
///
class Zip64EndRecord {

  /// Size of the Zip64 end record.
  int size;

  /// Version made by.
  int versionMadeBy;

  /// Version needed to extract.
  int versionNeeded;

  /// Number of the disk which contains the Zip64 end record.
  int disk;

  /// Number of the disk with the start of the central directory.
  int directoryDisk;

  /// Number of entries in the disk which contains the Zip64 end record.
  int diskEntryCount;

  /// Total number of entries in the central directory.
  int entryCount;

  /// Size of the entire central directory.
  int directorySize;

  /// Relative offset to the start of the central directory.
  int directoryOffset;
}

///
/// File header.
///
class ZipFileHeader {

  /// Version made by.
  int versionMadeBy;

  /// Version needed to extract.
  int versionNeeded;

  /// General purpose bit flags.
  int flags;

  /// Compression method.
  int compressionMethod;

  /// Last modification time.
  int time;

  /// Last modification date.
  int date;

  /// CRC-32.
  int crc32;

  /// Compressed size.
  int compressedSize;

  /// Uncompressed size.
  int uncompressedSize;

  /// File name length.
  int nameLength;

  /// Extra field length.
  int extraLength;

  /// File comment length.
  int commentLength;

  /// Number of the disk which contains the local header.
  int localDisk;

  /// Internal file attributes.
  int internalAttr;

  /// External file attributes.
  int externalAttr;

  /// Relative offset to the local header.
  int localOffset;

  /// File name.
  String name;

  /// Extra field.
  List<int> extra;

  /// File comment.
  String comment;
}

///
/// Local file header.
///
class ZipLocalFileHeader {

  /// Version needed to extract.
  int versionNeeded;

  /// General purpose bit flags.
  int flags;

  /// Compression method.
  int compressionMethod;

  /// Last modification time.
  int time;

  /// Last modification date.
  int date;

  /// CRC-32.
  int crc32;

  /// Compressed size.
  int compressedSize;

  /// Uncompressed size.
  int uncompressedSize;

  /// File name length.
  int nameLength;

  /// Extra field length.
  int extraLength;

  /// File name.
  String name;

  /// Extra field.
  List<int> extra;
}

///
/// Extensible data field.
///
class ZipExtraField {

  /// Header id.
  int id;

  /// Size.
  int size;

  /// Data.
  List<int> data;
}

///
/// Zip64 Extended Information Extra Field.
///
class Zip64ExtraField {

  /// Header id.
  int id;

  /// Size.
  int size;

  /// Uncompressed size.
  int uncompressedSize;

  /// Compressed size.
  int compressedSize;

  /// Relative offset to the local header.
  int localOffset;

  /// Number of the disk which contains the local header.
  int localDisk;
}

///
/// Central directory.
///
class ZipDirectory {

  /// Number of the disk with the start of the central directory.
  int disk;

  /// Relative offset to the start of the central directory.
  int offset;

  /// Size of the entire central directory.
  int size;

  /// Total number of entries in the central directory.
  int entryCount;
}
