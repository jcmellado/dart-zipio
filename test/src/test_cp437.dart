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
/// cp437 tests.
///
class TestCp437 {

  /// Run all tests.
  static void run() {
    group("cp437", () {

      // Encode.
      test("encode", () {
        expect(CP437.encode(""), equals([]));
        expect(CP437.encode("\u0007\u0008\u0009"), equals([7, 8, 9]));
        expect(CP437.encode("ABC"), equals([65, 66, 67]));
        expect(CP437.encode("πΣσ"), equals([227, 228, 229]));

        expect(() => CP437.encode("\u0500"), throwsFormatException);
        expect(() => CP437.encode("Aπ\u0500C"), throwsFormatException);
      });

      // Decode.
      test("decode", () {
        expect(CP437.decode([]), equals(""));
        expect(CP437.decode([7, 8, 9]), equals("\u0007\u0008\u0009"));
        expect(CP437.decode([65, 66, 67]), equals("ABC"));
        expect(CP437.decode([227, 228, 229]), equals("πΣσ"));

        expect(() => CP437.decode([999]), throwsFormatException);
        expect(() => CP437.decode([65, 227, 999, 67]), throwsFormatException);
      });

      // Decode - Allow invalid.
      test("decode - allow invalid", () {
        var codec = const Cp437Codec(allowInvalid: true);

        expect(codec.decode([999]), equals("\ufffd"));
        expect(codec.decode([65, 227, 999, 67]), equals("Aπ\ufffdC"));
      });

      // Encode chunks.
      test("encode - chunks", () {
        var result = new List<int>();
        var sink = new ByteConversionSink.withCallback((bytes) {
          result.addAll(bytes);
        });

        var output = CP437.encoder.startChunkedConversion(sink);
        output.add("\u0007\u0008\u0009");
        output.addSlice("ABC", 1, 3, false);
        output.add("πΣσ");
        output.close();

        expect(result, equals([7, 8, 9, 66, 67, 227, 228, 229]));
      });

      // Decode chunks.
      test("decode - chunks", () {
        var result = "";
        var sink = new StringConversionSink.withCallback((string) {
          result += string;
        });

        var output = CP437.decoder.startChunkedConversion(sink);
        output.add([7, 8, 9]);
        output.addSlice([65, 66, 67], 1, 3, false);
        output.add([227, 228, 229]);
        output.close();

        expect(result, equals("\u0007\u0008\u0009BCπΣσ"));
      });
    });
  }
}
