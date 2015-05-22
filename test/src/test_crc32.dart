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

part of zipio_test;

///
/// CRC-32 tests.
///
/// - CRC catalog:
///   http://reveng.sourceforge.net/crc-catalogue/17plus.htm#crc.cat-bits.32
///
class TestCrc32 {

  /// Run all tests.
  static void run() {
    group("CRC-32", () {

      // Compute.
      test("compute", () {
        expect(Crc32.compute([]), equals(0));
        expect(Crc32.compute("123456789".codeUnits), equals(0xcbf43926));

        var crc = Crc32.compute("12345".codeUnits);
        expect(Crc32.compute("6789".codeUnits, crc), equals(0xcbf43926));
      });
    });
  }
}
