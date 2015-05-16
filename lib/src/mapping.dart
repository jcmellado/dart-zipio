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
/// Size of the buffer used to read a .ZIP file.
///
const int blockSize = 65536;

///
/// Maps a file in memory.
///
/// A buffer of `blockSize` bytes is used to read the file in memory.
///
class FileMapping {

  /// File path.
  final String _path;

  /// Mapped file.
  RandomAccessFile _file;

  /// File length.
  int _length;

  /// File offset.
  int _position;

  /// Memory buffer.
  Uint8List _buffer;

  /// Buffer "synonym".
  ByteData _view;

  /// Real buffer size.
  int _available;

  ///
  /// Maps a file in memory.
  ///
  FileMapping(this._path);

  /// File length.
  int get length => _length;

  /// File path.
  String get path => _path;

  ///
  /// Opens the file and builds the buffer.
  ///
  Future open() async {
    _file = await new File(_path).open(mode: FileMode.READ);
    _length = await _file.length();
    _position = 0;

    _buffer = new Uint8List(blockSize);
    _view = _buffer.buffer.asByteData();
    _available = 0;
  }

  ///
  /// Closes the file.
  ///
  Future close() => _file == null ? null : _file.close();

  ///
  /// Reads a block of [size] bytes from [offset].
  ///
  Future<int> read(int offset, int size) async {
    if ((offset < 0) || (offset >= _length)) {
      throw new RangeError.range(offset, 0, _length - 1, "offset");
    }
    if ((size <= 0) || (size > blockSize) || (size > _length - offset)) {
      throw new RangeError.range(
          size, 1, min(blockSize, _length - offset), "size");
    }

    if ((offset >= _position) && (offset + size <= _position + _available)) {
      return size;
    }

    _position = offset;
    await _file.setPosition(_position);

    _available = min(blockSize, _length - _position);
    return await _file.readInto(_buffer, 0, _available);
  }

  ///
  /// Reads a unsigned byte from [offset].
  ///
  int getUint8(int offset) => _view.getUint8(offset - _position);

  ///
  /// Reads a (little endian) unsigned 16 bits word from [offset].
  ///
  int getUint16(int offset) =>
      _view.getUint16(offset - _position, Endianness.LITTLE_ENDIAN);

  ///
  /// Reads a (little endian) unsigned 32 bits word from [offset].
  ///
  int getUint32(int offset) =>
      _view.getUint32(offset - _position, Endianness.LITTLE_ENDIAN);

  ///
  /// Reads a (little endian) unsigned 64 bits word from [offset].
  ///
  int getUint64(int offset) =>
      _view.getUint64(offset - _position, Endianness.LITTLE_ENDIAN);

  ///
  /// Adds the [chunkSize] bytes from [offset] to [input].
  ///
  void addSlice(ByteConversionSink input, int offset, int chunkSize) {
    input.addSlice(
        _buffer, offset - _position, offset - _position + chunkSize, false);
  }

  ///
  /// Copies [chunkSize] bytes from [offset] to [bytes] starting at [position].
  ///
  void setRange(List<int> bytes, int position, int offset, int chunkSize) {
    bytes.setRange(position, position + chunkSize,
        _buffer.getRange(offset - _position, offset - _position + chunkSize));
  }
}
