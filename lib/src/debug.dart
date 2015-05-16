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

/// OS names.
const Map<int, String> osNames = const {
  0: "MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)",
  1: "Amiga",
  2: "OpenVMS",
  3: "UNIX",
  4: "VM/CMS",
  5: "Atari ST",
  6: "OS/2 H.P.F.S.",
  7: "Macintosh",
  8: "Z-System",
  9: "CP/M",
  10: "Windows NTFS",
  11: "MVS (OS/390 - Z/OS)",
  12: "VSE",
  13: "Acorn Risc",
  14: "VFAT",
  15: "Alternate MVS",
  16: "BeOS",
  17: "Tandem",
  18: "OS/400",
  19: "OS X (Darwin)"
};

/// Compression method names.
const Map<int, String> methodNames = const {
  storedMethod: "The file is stored (no compression)",
  shrunkMethod: "The file is Shrunk",
  reduced1Method: "The file is Reduced with compression factor 1",
  reduced2Method: "The file is Reduced with compression factor 2",
  reduced3Method: "The file is Reduced with compression factor 3",
  reduced4Method: "The file is Reduced with compression factor 4",
  implodedMethod: "The file is Imploded",
  tokenizedMethod: "Reserved for Tokenizing compression algorithm",
  deflatedMethod: "The file is Deflated",
  deflated64Method: "Enhanced Deflating using Deflate64(tm)",
  ibmTerseOldMethod:
      "PKWARE Data Compression Library Imploding (old IBM TERSE)",
  reserved11Method: "Reserved by PKWARE",
  bzip2Method: "File is compressed using BZIP2 algorithm",
  reserved13Method: "Reserved by PKWARE",
  lzmaMethod: "LZMA (EFS)",
  reserved15Method: "Reserved by PKWARE",
  reserved16Method: "Reserved by PKWARE",
  reserved17Method: "Reserved by PKWARE",
  ibmTerseNewMethod: "File is compressed using IBM TERSE (new)",
  lz77Method: "IBM LZ77 z Architecture (PFS)",
  wavPackMethod: "WavPack compressed data",
  ppmdMethod: "PPMd version I, Rev 1"
};

///
/// Reads a zip file and dumps to the log a lot of information about it.
///
class ZipReaderDebug extends ZipReader {

  /// Logger.
  Logger _log;

  /// Builds the zip reader.
  ZipReaderDebug(String path, {Encoding encoding, Logger log})
      : super(path, encoding: encoding) {
    _log = log == null ? Logger.root : log;
  }

  ///
  /// Reads and dumps to the log the end record.
  ///
  @override
  ZipEndRecord readEndRecord(int offset) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine("End of Central Directory Record"
          " [Offset: ${_number(offset)}]");
    }

    var record = super.readEndRecord(offset);

    if (_log.isLoggable(Level.FINEST)) _dump(offset, endRecordLength);

    if (_log.isLoggable(Level.FINER)) {
      _finer("Signature:"
          " ${_hex(endRecordSignature, 4)}");
      _finer("Number of this disk:"
          " ${_number(record.disk, 2)}");
      _finer("Number of the disk with the start of the central"
          " directory: ${_number(record.directoryDisk, 2)}");
      _finer("Total number of entries in the central directory on"
          " this disk: ${_number(record.diskEntryCount, 2)}");
      _finer("Total number of entries in the central directory:"
          " ${_number(record.entryCount, 2)}");
      _finer("Size of the central directory:"
          " ${_number(record.directorySize, 4)}");
      _finer("Offset of start of central directory with respect to the"
          " starting disk number: ${_number(record.directoryOffset, 4)}");
      _finer(".ZIP file comment length:"
          " ${_number(record.commentLength, 2)}");
    }

    return record;
  }

  ///
  /// Reads and dumps to the log the ZIP file comment.
  ///
  @override
  Future<String> readComment(int offset, int length) async {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine(".ZIP File Comment [Offset: ${_number(offset)}]");
    }

    var comment = await super.readComment(offset, length);

    if (comment != null) {
      if (_log.isLoggable(Level.FINER)) _finer("Comment: $comment");
    }

    return comment;
  }

  ///
  /// Reads and dumps to the log the Zip64 end record locator.
  ///
  @override
  Zip64Locator readZip64Locator(int offset) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine("Zip64 End of Central Directory Locator"
          " [Offset: ${_number(offset)}]");
    }

    var locator = super.readZip64Locator(offset);

    if (_log.isLoggable(Level.FINEST)) _dump(offset, zip64LocatorLength);

    if (_log.isLoggable(Level.FINER)) {
      _finer("Signature:"
          " ${_hex(zip64LocatorSignature, 4)}");
      _finer("Number of the disk with the start of the zip64 end of"
          " central directory: ${_number(locator.zip64Disk, 4)}");
      _finer("Relative offset of the zip64 end of central directory record:"
          " ${_number(locator.zip64Offset, 8)}");
      _finer("Total number of disks:"
          " ${_number(locator.diskCount, 4)}");
    }

    return locator;
  }

  ///
  /// Reads and dumps to the log the Zip64 end record.
  ///
  @override
  Zip64EndRecord readZip64EndRecord(int offset) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine("Zip64 End of Central Directory Record"
          " [Offset: ${_number(offset)}]");
    }

    var record = super.readZip64EndRecord(offset);

    if (_log.isLoggable(Level.FINEST)) _dump(offset, zip64EndRecordLength);

    if (_log.isLoggable(Level.FINER)) {
      _finer("Signature:"
          " ${_hex(zip64EndRecordSignature, 4)}");
      _finer("Size of zip64 end of central directory record:"
          " ${_number(record.size, 8)}");
      _finer("Version made by:"
          " ${_madeBy(record.versionMadeBy)}");
      _finer("Version needed to extract:"
          " ${_version(record.versionNeeded)}");
      _finer("Number of this disk:"
          " ${_number(record.disk, 4)}");
      _finer("Number of the disk with the start of the central directory:"
          " ${_number(record.directoryDisk, 4)}");
      _finer("Total number of entries in the central directory on"
          " this disk: ${_number(record.diskEntryCount, 8)}");
      _finer("Total number of entries in the central directory:"
          " ${_number(record.entryCount, 8)}");
      _finer("Size of the central directory:"
          " ${_number(record.directorySize, 8)}");
      _finer("Offset of start of central directory with respect to the"
          " starting disk number: ${_number(record.directoryOffset, 8)}");
    }

    return record;
  }

  ///
  /// Reads and dumps to the log a file header.
  ///
  @override
  ZipFileHeader readFileHeader(int offset) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine("File Header [Offset: ${_number(offset)}]");
    }

    var header = super.readFileHeader(offset);

    if (_log.isLoggable(Level.FINEST)) _dump(offset, fileHeaderLength);

    if (_log.isLoggable(Level.FINER)) {
      var date = new DosDateTime(header.date, header.time);

      _finer("Signature: ${_hex(fileHeaderSignature, 4)}");
      _finer("Version made by: ${_madeBy(header.versionMadeBy)}");
      _finer("Version needed to extract: ${_version(header.versionNeeded)}");
      _finer("General purpose bit flag: ${_hex(header.flags, 2)}");
      _flags(header.flags, header.compressionMethod);
      _finer("Compression method: ${_method(header.compressionMethod)}");
      _finer("Last modification file time: ${_time(header.time, date)}");
      _finer("Last modification file date: ${_date(header.date, date)}");
      _finer("CRC-32: ${_hex(header.crc32, 4)}");
      _finer("Compressed size: ${_number(header.compressedSize, 4)}");
      _finer("Uncompressed size: ${_number(header.uncompressedSize, 4)}");
      _finer("File name length: ${_number(header.nameLength, 2)}");
      _finer("Extra field length: ${_number(header.extraLength, 2)}");
      _finer("File comment length: ${_number(header.commentLength, 2)}");
      _finer("Disk number start: ${_number(header.localDisk, 2)}");
      _finer("Internal file attributes: ${_number(header.internalAttr, 2)}");
      _internalAttr(header.internalAttr);
      _finer("External file attributes: ${_number(header.externalAttr, 4)}");
      _finer(
          "Relative offset of local header: ${_number(header.localOffset, 4)}");
    }

    return header;
  }

  ///
  /// Reads and dumps to the log a local file header.
  @override
  ZipLocalFileHeader readLocalFileHeader(int offset) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine("");
      _fine("Local File Header [Offset: ${_number(offset)}]");
    }

    var header = super.readLocalFileHeader(offset);

    if (_log.isLoggable(Level.FINEST)) _dump(offset, localFileHeaderLength);

    if (_log.isLoggable(Level.FINER)) {
      var date = new DosDateTime(header.date, header.time);

      _finer("Signature: ${_hex(localFileHeaderSignature, 4)}");
      _finer("Version needed to extract: ${_version(header.versionNeeded)}");
      _finer("General purpose bit flag: ${_hex(header.flags, 2)}");
      _flags(header.flags, header.compressionMethod);
      _finer("Compression method: ${_method(header.compressionMethod)}");
      _finer("Last modification file time: ${_time(header.time, date)}");
      _finer("Last modification file date: ${_date(header.date, date)}");
      _finer("CRC-32: ${_hex(header.crc32, 4)}");
      _finer("Compressed size: ${_number(header.compressedSize, 4)}");
      _finer("Uncompressed size: ${_number(header.uncompressedSize, 4)}");
      _finer("File name length: ${_number(header.nameLength, 2)}");
      _finer("Extra field length: ${_number(header.extraLength, 2)}");
    }

    return header;
  }

  ///
  /// Reads and dumps to the log an entry file name.
  ///
  @override
  Future<String> readEntryFilename(int offset, int length, bool utf8) async {
    var filename = await super.readEntryFilename(offset, length, utf8);

    if (filename != null) {
      if (_log.isLoggable(Level.FINE)) _fine2("File name: $filename");
    }

    return filename;
  }

  ///
  /// Reads and dumps to the log an extra field.
  ///
  @override
  Future<List<int>> readExtraField(int offset, int length) async {
    var extra = await super.readExtraField(offset, length);

    if (extra != null) {
      if (_log.isLoggable(Level.FINEST)) {
        _finer("Extra field (dump):");
        _dump(offset, length, extra);
      }
    }

    return extra;
  }

  ///
  /// Reads and dumps to the log an entry comment.
  ///
  @override
  Future<String> readEntryComment(int offset, int length, bool utf8) async {
    var comment = await super.readEntryComment(offset, length, utf8);

    if (comment != null) {
      if (_log.isLoggable(Level.FINER)) _finer("Comment: $comment");
    }

    return comment;
  }

  ///
  /// Reads and dumps to the log a Zip64 extra field.
  ///
  @override
  Zip64ExtraField readZip64Extra(List<int> bytes, ZipFileHeader header) {
    var extra = super.readZip64Extra(bytes, header);

    if (extra != null) {
      if (_log.isLoggable(Level.FINER)) {
        _finer("Extra field (ID: ${_extra(extra.id)})");
        _finer2("Data Size: ${_number(extra.size, 2)}");
        if (extra.uncompressedSize != null) {
          _finer2("Original uncompressed file size:"
              " ${_number(extra.uncompressedSize, 8)}");
        }
        if (extra.compressedSize != null) {
          _finer2("Size of compressed data):"
              " ${_number(extra.compressedSize, 8)}");
        }
        if (extra.localOffset != null) {
          _finer2("Offset of local header record:"
              " ${_number(extra.localOffset, 8)}");
        }
        if (extra.localDisk != null) {
          _finer2("Number of the disk on which this file starts:"
              " ${_number(extra.localDisk, 4)}");
        }
      }
    }

    return extra;
  }

  ///
  /// Dumps to the log the flags that [value] represents.
  ///
  void _flags(int value, int method) {
    if ((value & 0x0001) != 0) {
      _finer2("b0 = 1 [The file is encripted]");
    }

    // Imploding.
    if (method == 6) {
      if ((value & 0x0002) == 0) {
        _finer2("b1 = 0 [An 4K sliding dictionary was used]");
      } else {
        _finer2("b1 = 1 [An 8K sliding dictionary was used]");
      }
      if ((value & 0x0004) == 0) {
        _finer2("b2 = 0 [2 Shannon-Fano trees were used]");
      } else {
        _finer2("b2 = 1 [3 Shannon-Fano trees were used]");
      }
    }

    // Deflating.
    if ((method == 8) || (method == 9)) {
      switch ((value & 0x0006) >> 1) {
        case 0:
          _finer2("b2b1 = 00b [Normal (-en) compression option was used]");
          break;
        case 1:
          _finer2(
              "b2b1 = 01b [Maximum (-exx/-ex) compression option was used]");
          break;
        case 2:
          _finer2("b2b1 = 10b [Fast (-ef) compression option was used]");
          break;
        case 3:
          _finer2("b2b1 = 11b [Super Fast (-es) compression option was used]");
          break;
      }
    }

    // LZMA.
    if (method == 14) {
      if ((value & 0x0002) != 0) {
        _finer2("b1 = 1 [an end-of-stream (EOS) marker is used]");
      }
    }

    if ((value & 0x0008) != 0) {
      _finer2("b3 = 1 [CRC-32, compressed size and uncompressed size are set"
          " to zero in the local header]");
    }
    if ((value & 0x0020) != 0) {
      _finer2("b5 = 1 [The file is compressed patched data]");
    }
    if ((value & 0x0040) != 0) {
      _finer2("b6 = 1 [Strong encryption]");
    }
    if ((value & 0x0800) != 0) {
      _finer2(
          "b11 = 1 [The filename and comment fields are encoded using UTF-8]");
    }
    if ((value & 0x2000) != 0) {
      _finer2("b13 = 1 [Selected data values in the Local Header are masked to"
          "hide their actual values]");
    }
  }

  ///
  /// Dumps to the log the internal attributes that [value] represents.
  ///
  void _internalAttr(int value) {
    if ((value & 0x0001) != 0) {
      _finer2("b0 = 1 [The file is apparently an ASCII or text file]");
    }
  }

  ///
  /// Returns a string containing the hexadecimal representation of [value].
  ///
  ///     _hex(10); // => "0xa"
  ///     _hex(1024); // => "0x400"
  ///
  /// If [bytes] is given, the output string will have [bytes] * 2 digits.
  ///
  ///     _hex(10, 1); // => "0x0a"
  ///     _hex(1024, 4); // => "0x00000400"
  ///
  String _hex(int value, [int bytes = 0]) =>
      "0x${value.toRadixString(16).padLeft(bytes * 2, "0")}";

  ///
  /// Returns a string containing the decimal representation of [value]
  /// followed by its hexadecimal representation between parentheses.
  ///
  ///     _number(10) // => "10 (0xa)"
  ///     _number(1024) // => "1024 (0x400)"
  ///
  /// If [bytes] is given, the hexadecimal part will have [bytes] * 2 digits.
  ///
  ///     _number(10, 1); // => "10 (0x0a)"
  ///     _number(1024, 4); // => "1024 (0x00000400)"
  ///
  String _number(int value, [int bytes = 0]) =>
      "$value (${_hex(value, bytes)})";

  ///
  /// Returns a string containing the hexadecimal representation of [value]
  /// followed by the ZIP specification version that [value] represents
  /// between parentheses.
  ///
  /// The lower byte indicates the ZIP specification version. [value]/10 is
  /// the major version number, and [value] mod 10 is the minor version.
  ///
  ///     _version(20); // => "0x0014 (v2.0)"
  ///
  String _version(int value) =>
      "${_hex(value, 2)} (v${(value & 0xff) ~/ 10}.${(value & 0xff) % 10})";

  ///
  /// Returns a string containing the hexadecimal representation of [value]
  /// followed by the ZIP specification version between parentheses and
  /// the compatibility of the file attribute information that [value]
  /// represents between square brackets.
  ///
  /// The upper byte indicates the compatibility of the file attribute
  /// information. The lower byte indicates the ZIP specification version.
  ///
  ///     _madeBy(63) // => "0x003f (v6.3) [MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)]"
  ///
  String _madeBy(int value) => "${_version(value)} [${_osName(value >> 8)}]";

  ///
  /// Returns a string with the name of the OS that [value] represents.
  ///
  String _osName(int value) {
    var name = osNames[value];
    return name == null ? "Unknown" : name;
  }

  ///
  /// Returns a string containing the decimal representation of [value]
  /// followed by its hexadecimal representation between parentheses and the
  /// compression method that [value] represents between square brackets.
  ///
  ///     _method(8); // => "8 (0x0008) [The file is Deflated]"
  ///
  String _method(int value) => "${_number(value, 2)} [${_methodName(value)}]";

  ///
  /// Returns a string with the name of the algorithm that [value] represents.
  ///
  String _methodName(int value) {
    var name = methodNames[value];
    return name == null ? "Unknown" : name;
  }

  ///
  /// Returns a string containing the decimal representation of [value]
  /// followed by its hexadecimal representation between parentheses and the
  /// time format representation between square brackets of [date].
  ///
  ///     _time(23274); // => "23274 (0x5aea) [11:23:20]"
  ///
  String _time(int value, DosDateTime date) =>
      "${_number(value, 2)} [${date.toTimeString()}]";

  ///
  /// Returns a string containing the decimal representation of [value]
  /// followed by its hexadecimal representation between parentheses and the
  /// date format representation between square brackets of [date].
  ///
  ///     _date(18023); // => "18023 (0x4667) [2015-03-07]"
  ///
  String _date(int value, DosDateTime date) =>
      "${_number(value, 2)} [${date.toDateString()}]";

  ///
  /// Returns a string containing the hexadecimal representation of [value]
  /// followed by the extra header name that [value] represents between
  /// square brackets.
  ///
  ///     _extra(1); // => "0x0001 [Zip64 extended information]"
  ///
  String _extra(int value) => "${_hex(value, 2)} [${_extraName(value)}]";

  ///
  /// Returns the extra header name that [value] represents.
  ///
  String _extraName(int value) {
    var name = extraNames[value];
    return name == null ? "Unknown" : name;
  }

  ///
  /// Dumps to the log [length] bytes from [offset] of the current mapped
  /// [_file] or from [data].
  ///
  /// IMPORTANT NOTE: The [_file] (or [data]) buffer must have at least
  /// [length] bytes from [offset].
  ///
  void _dump(int offset, int length, [List<int> data]) {
    var start = offset - (offset % 16);
    var end = offset + length;

    var nibbles = max((end.bitLength / 4).ceil(), 8);
    var tab = "".padRight(nibbles);

    _finest("");
    _finest(" $tab 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f");
    _finest(" $tab -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --");

    for (var i = start; i < end; i += 16) {
      var buffer =
          new StringBuffer(" ${i.toRadixString(16).padLeft(nibbles, "0")}");

      for (var j = i; j < i + 16; j++) {
        if ((j < offset) || (j >= end)) {
          buffer.write(" . ");
        } else {
          var byte = data == null ? _file.getUint8(j) : data[j - offset];
          buffer.write(" ${byte.toRadixString(16).padLeft(2, "0")}");
        }
      }

      _finest(buffer.toString());
    }

    _finest("");
  }

  ///
  /// Log [message] at level [Level.FINE].
  ///
  void _fine(String message) {
    _log.fine("# $message");
  }

  ///
  /// Log [message] at second level of [Level.FINE].
  ///
  void _fine2(String message) {
    _log.fine(" - $message");
  }

  ///
  /// Log [message] at level [Level.FINER].
  ///
  void _finer(String message) {
    _log.finer(" - $message");
  }

  ///
  /// Log [message] at the second level of [Level.FINER].
  ///
  void _finer2(String message) {
    _log.finer("     $message");
  }

  ///
  /// Log [message] at level [Level.FINEST].
  ///
  void _finest(String message) {
    _log.finest("$message");
  }
}
