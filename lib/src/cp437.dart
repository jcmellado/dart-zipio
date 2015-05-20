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
// - RFC 1345 - Character Mnemonics & Character Sets:
//   http://tools.ietf.org/html/rfc1345

part of zipio;

///
/// An instance of the default implementation of the [Cp437Codec].
///
/// This instance provides a convenient access to the most common cp437
/// (code page 437) use cases.
///
const Cp437Codec CP437 = const Cp437Codec();

///
/// An [Cp437Codec] allows encoding strings as cp437 bytes and decoding
/// cp437 bytes to strings.
///
class Cp437Codec extends Encoding {
  final bool _allowInvalid;

  ///
  /// Instantiates a new [Cp437Codec].
  ///
  /// If [allowInvalid] is true, the [decode] method and the converter
  /// returned by [decoder] will default to allowing invalid values.
  /// If allowing invalid values, the values will be decoded into the Unicode
  /// Replacement character (U+FFFD). If not, an exception will be thrown.
  /// Calls to the [decode] method can choose to override this default.
  ///
  /// Encoders will not accept invalid (non cp437) characters.
  ///
  const Cp437Codec({bool allowInvalid: false}) : _allowInvalid = allowInvalid;

  /// Name of the encoding.
  @override
  String get name => "cp437";

  /// Returns a fresh instance of [Cp437Encoder].
  @override
  Cp437Encoder get encoder => const Cp437Encoder();

  /// Returns a fresh instance of [Cp437Decoder].
  @override
  Cp437Decoder get decoder => _allowInvalid
      ? const Cp437Decoder(allowInvalid: true)
      : const Cp437Decoder(allowInvalid: false);

  ///
  /// Decodes the cp437 [bytes] (a list of unsigned 8-bit integers) to the
  /// corresponding string.
  ///
  /// If [bytes] contains values that are not in the range 0 .. 255, the decoder
  /// will eventually throw a [FormatException].
  ///
  /// If [allowInvalid] is not provided, it defaults to the value used to create
  /// this [Cp437Codec].
  ///
  @override
  String decode(List<int> bytes, {bool allowInvalid}) {
    if (allowInvalid == null) allowInvalid = _allowInvalid;

    return allowInvalid
        ? const Cp437Decoder(allowInvalid: true).convert(bytes)
        : const Cp437Decoder(allowInvalid: false).convert(bytes);
  }
}

///
/// Converts strings of only cp437 characters to bytes.
///
class Cp437Encoder extends Converter<String, List<int>> {
  const Cp437Encoder();

  ///
  /// Converts the [String] into a list of bytes.
  ///
  /// If [start] and [end] are provided, only the substring
  /// `string.substring(start, end)` is used as input to the conversion.
  ///
  @override
  List<int> convert(String string, [int start = 0, int end]) {
    var length = string.length;
    RangeError.checkValidRange(start, end, length);
    if (end == null) end = length;

    var result = new Uint8List(length);
    for (var i = start; i < end; i++) {
      var codeUnit = string.codeUnitAt(i);
      var code = _unicodeToCp437[codeUnit];
      if (code == null) {
        throw new FormatException(
            "String contains invalid characters with code point: $codeUnit.");
      }
      result[i - start] = code;
    }
    return result;
  }

  ///
  /// Starts a chunked conversion.
  ///
  /// The converter works more efficiently if the given [sink] is a
  /// [ByteConversionSink].
  ///
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _Cp437EncoderSink(sink);
  }
}

///
/// Converts cp437 bytes (lists of unsigned 8-bit integers) to a string.
///
class Cp437Decoder extends Converter<List<int>, String> {
  final bool _allowInvalid;

  ///
  /// Instantiates a new decoder.
  ///
  /// The [_allowInvalid] argument defines how [convert] deals
  /// with invalid bytes.
  ///
  /// If [_allowInvalid] is `true`, [convert] replaces invalid bytes with the
  /// Unicode Replacement character `U+FFFD` (�).
  /// Otherwise it throws a [FormatException].
  ///
  const Cp437Decoder({bool allowInvalid: false}) : _allowInvalid = allowInvalid;

  ///
  /// Converts the [bytes] (a list of unsigned 8-bit integers) to the
  /// corresponding string.
  ///
  /// If [start] and [end] are provided, only the sub-list of bytes from
  /// `start` to `end` (`end` not inclusive) is used as input to the conversion.
  ///
  @override
  String convert(List<int> bytes, [int start = 0, int end]) {
    var length = bytes.length;
    RangeError.checkValidRange(start, end, length);
    if (end == null) end = length;

    var buffer = new StringBuffer();
    for (var i = start; i < end; i++) {
      var code = bytes[i];
      if ((code >= 0) && (code <= 255)) {
        buffer.writeCharCode(_cp437ToUnicode[code]);
      } else {
        if (!_allowInvalid) {
          throw new FormatException("Invalid value in input: $code");
        }
        buffer.writeCharCode(0xFFFD);
      }
    }
    return buffer.toString();
  }

  ///
  /// Starts a chunked conversion.
  ///
  /// The converter works more efficiently if the given [sink] is a
  /// [StringConversionSink].
  ///
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    }
    return new _Cp437DecoderSink(sink, _allowInvalid);
  }
}

///
/// Encodes chunked strings to bytes (unsigned 8-bit integers).
///
class _Cp437EncoderSink extends StringConversionSinkBase {
  final ByteConversionSink _sink;

  _Cp437EncoderSink(this._sink);

  ///
  /// Converts the [String] into a list of bytes and add it to the sink.
  ///
  /// If [isLast] is true, the sink is closed.
  ///
  @override
  void addSlice(String string, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, string.length);

    if (start != end) {
      var result = new Uint8List(end - start);
      for (var i = start; i < end; i++) {
        var codeUnit = string.codeUnitAt(i);
        var code = _unicodeToCp437[codeUnit];
        if (code == null) {
          throw new FormatException(
              "String contains invalid characters with code point: $codeUnit.");
        }
        result[i - start] = code;
      }
      _sink.add(result);
    }

    if (isLast) close();
  }

  ///
  /// Closes the sink.
  ///
  @override
  void close() {
    _sink.close();
  }
}

///
/// Encodes chunked list of bytes (unsigned 8-bit integers) to string.
///
class _Cp437DecoderSink extends ByteConversionSinkBase {
  final Sink _sink;

  final bool _allowInvalid;

  _Cp437DecoderSink(this._sink, this._allowInvalid);

  ///
  /// Converts the [List] of bytes into a [String] and add it to the sink.
  ///
  @override
  void add(List<int> source) {
    addSlice(source, 0, source.length, false);
  }

  ///
  /// Converts the [List] of bytes into a [String] and add it to the sink.
  ///
  /// If [isLast] is true, the sink is closed.
  ///
  @override
  void addSlice(List<int> source, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, source.length);

    if (start != end) {
      var buffer = new StringBuffer();
      for (var i = start; i < end; i++) {
        var code = source[i];
        if ((code >= 0) && (code <= 255)) {
          buffer.writeCharCode(_cp437ToUnicode[code]);
        } else {
          if (!_allowInvalid) {
            throw new FormatException("Invalid value in input: $code");
          }
          buffer.writeCharCode(0xFFFD);
        }
      }

      _sink.add(buffer.toString());
    }

    if (isLast) close();
  }

  ///
  /// Closes the sink.
  ///
  @override
  void close() {
    _sink.close();
  }
}

///
/// cp437 to Unicode table.
///
const List<int> _cp437ToUnicode = const <int>[
  0x0000, // 0x00 NU NULL
  0x0001, // 0x01 SH START OF HEADING
  0x0002, // 0x02 SX START OF TEXT
  0x0003, // 0x03 EX END OF TEXT
  0x0004, // 0x04 ET END OF TRANSMISSION
  0x0005, // 0x05 EQ ENQUIRY
  0x0006, // 0x06 AK ACKNOWLEDGE
  0x0007, // 0x07 BL BELL
  0x0008, // 0x08 BS BACKSPACE
  0x0009, // 0x09 HT HORIZONTAL TABULATION
  0x000a, // 0x0a LF LINE FEED
  0x000b, // 0x0b VT VERTICAL TABULATION
  0x000c, // 0x0c FF FORM FEED
  0x000d, // 0x0d CR CARRIAGE RETURN
  0x000e, // 0x0e SO SHIFT OUT
  0x000f, // 0x0f SI SHIFT IN
  0x0010, // 0x10 DL DATA LINK ESCAPE
  0x0011, // 0x11 D1 DEVICE CONTROL ONE
  0x0012, // 0x12 D2 DEVICE CONTROL TWO
  0x0013, // 0x13 D3 DEVICE CONTROL THREE
  0x0014, // 0x14 D4 DEVICE CONTROL FOUR
  0x0015, // 0x15 NK NEGATIVE ACKNOWLEDGE
  0x0016, // 0x16 SY SYNCHRONOUS IDLE
  0x0017, // 0x17 EB END OF TRANSMISSION BLOCK
  0x0018, // 0x18 CN CANCEL
  0x0019, // 0x19 EM END OF MEDIUM
  0x001a, // 0x1a SB SUBSTITUTE
  0x001b, // 0x1b EC ESCAPE
  0x001c, // 0x1c FS FILE SEPARATOR
  0x001d, // 0x1d GS GROUP SEPARATOR
  0x001e, // 0x1e RS RECORD SEPARATOR
  0x001f, // 0x1f US UNIT SEPARATOR
  0x0020, // 0x20 SP SPACE
  0x0021, // 0x21 !  EXCLAMATION MARK
  0x0022, // 0x22 "  QUOTATION MARK
  0x0023, // 0x23 Nb NUMBER SIGN
  0x0024, // 0x24 DO DOLLAR SIGN
  0x0025, // 0x25 %  PERCENT SIGN
  0x0026, // 0x26 &  AMPERSAND
  0x0027, // 0x27 '  APOSTROPHE
  0x0028, // 0x28 (  LEFT PARENTHESIS
  0x0029, // 0x29 )  RIGHT PARENTHESIS
  0x002a, // 0x2a *  ASTERISK
  0x002b, // 0x2b +  PLUS SIGN
  0x002c, // 0x2c ,  COMMA
  0x002d, // 0x2d -  HYPHEN-MINUS
  0x002e, // 0x2e .  FULL STOP
  0x002f, // 0x2f /  SOLIDUS
  0x0030, // 0x30 0  DIGIT ZERO
  0x0031, // 0x31 1  DIGIT ONE
  0x0032, // 0x32 2  DIGIT TWO
  0x0033, // 0x33 3  DIGIT THREE
  0x0034, // 0x34 4  DIGIT FOUR
  0x0035, // 0x35 5  DIGIT FIVE
  0x0036, // 0x36 6  DIGIT SIX
  0x0037, // 0x37 7  DIGIT SEVEN
  0x0038, // 0x38 8  DIGIT EIGHT
  0x0039, // 0x39 9  DIGIT NINE
  0x003a, // 0x3a :  COLON
  0x003b, // 0x3b ;  SEMICOLON
  0x003c, // 0x3c <  LESS-THAN SIGN
  0x003d, // 0x3d =  EQUALS SIGN
  0x003e, // 0x3e >  GREATER-THAN SIGN
  0x003f, // 0x3f ?  QUESTION MARK
  0x0040, // 0x40 At COMMERCIAL AT
  0x0041, // 0x41 A  LATIN CAPITAL LETTER A
  0x0042, // 0x42 B  LATIN CAPITAL LETTER B
  0x0043, // 0x43 C  LATIN CAPITAL LETTER C
  0x0044, // 0x44 D  LATIN CAPITAL LETTER D
  0x0045, // 0x45 E  LATIN CAPITAL LETTER E
  0x0046, // 0x46 F  LATIN CAPITAL LETTER F
  0x0047, // 0x47 G  LATIN CAPITAL LETTER G
  0x0048, // 0x48 H  LATIN CAPITAL LETTER H
  0x0049, // 0x49 I  LATIN CAPITAL LETTER I
  0x004a, // 0x4a J  LATIN CAPITAL LETTER J
  0x004b, // 0x4b K  LATIN CAPITAL LETTER K
  0x004c, // 0x4c L  LATIN CAPITAL LETTER L
  0x004d, // 0x4d M  LATIN CAPITAL LETTER M
  0x004e, // 0x4e N  LATIN CAPITAL LETTER N
  0x004f, // 0x4f O  LATIN CAPITAL LETTER O
  0x0050, // 0x50 P  LATIN CAPITAL LETTER P
  0x0051, // 0x51 Q  LATIN CAPITAL LETTER Q
  0x0052, // 0x52 R  LATIN CAPITAL LETTER R
  0x0053, // 0x53 S  LATIN CAPITAL LETTER S
  0x0054, // 0x54 T  LATIN CAPITAL LETTER T
  0x0055, // 0x55 U  LATIN CAPITAL LETTER U
  0x0056, // 0x56 V  LATIN CAPITAL LETTER V
  0x0057, // 0x57 W  LATIN CAPITAL LETTER W
  0x0058, // 0x58 X  LATIN CAPITAL LETTER X
  0x0059, // 0x59 Y  LATIN CAPITAL LETTER Y
  0x005a, // 0x5a Z  LATIN CAPITAL LETTER Z
  0x005b, // 0x5b <( LEFT SQUARE BRACKET
  0x005c, // 0x5c // REVERSE SOLIDUS
  0x005d, // 0x5d )> RIGHT SQUARE BRACKET
  0x005e, // 0x5e '> CIRCUMFLEX ACCENT
  0x005f, // 0x5f _  LOW LINE
  0x0060, // 0x60 '! GRAVE ACCENT
  0x0061, // 0x61 a  LATIN SMALL LETTER A
  0x0062, // 0x62 b  LATIN SMALL LETTER B
  0x0063, // 0x63 c  LATIN SMALL LETTER C
  0x0064, // 0x64 d  LATIN SMALL LETTER D
  0x0065, // 0x65 e  LATIN SMALL LETTER E
  0x0066, // 0x66 f  LATIN SMALL LETTER F
  0x0067, // 0x67 g  LATIN SMALL LETTER G
  0x0068, // 0x68 h  LATIN SMALL LETTER H
  0x0069, // 0x69 i  LATIN SMALL LETTER I
  0x006a, // 0x6a j  LATIN SMALL LETTER J
  0x006b, // 0x6b k  LATIN SMALL LETTER K
  0x006c, // 0x6c l  LATIN SMALL LETTER L
  0x006d, // 0x6d m  LATIN SMALL LETTER M
  0x006e, // 0x6e n  LATIN SMALL LETTER N
  0x006f, // 0x6f o  LATIN SMALL LETTER O
  0x0070, // 0x70 p  LATIN SMALL LETTER P
  0x0071, // 0x71 q  LATIN SMALL LETTER Q
  0x0072, // 0x72 r  LATIN SMALL LETTER R
  0x0073, // 0x73 s  LATIN SMALL LETTER S
  0x0074, // 0x74 t  LATIN SMALL LETTER T
  0x0075, // 0x75 u  LATIN SMALL LETTER U
  0x0076, // 0x76 v  LATIN SMALL LETTER V
  0x0077, // 0x77 w  LATIN SMALL LETTER W
  0x0078, // 0x78 x  LATIN SMALL LETTER X
  0x0079, // 0x79 y  LATIN SMALL LETTER Y
  0x007a, // 0x7a z  LATIN SMALL LETTER Z
  0x007b, // 0x7b (! LEFT CURLY BRACKET
  0x007c, // 0x7c !! VERTICAL LINE
  0x007d, // 0x7d !) RIGHT CURLY BRACKET
  0x007e, // 0x7e '? TILDE
  0x007f, // 0x7f DT DELETE
  0x00c7, // 0x80 C, LATIN CAPITAL LETTER C WITH CEDILLA
  0x00fc, // 0x81 u: LATIN SMALL LETTER U WITH DIAERESIS
  0x00e9, // 0x82 e' LATIN SMALL LETTER E WITH ACUTE
  0x00e2, // 0x83 a> LATIN SMALL LETTER A WITH CIRCUMFLEX
  0x00e4, // 0x84 a: LATIN SMALL LETTER A WITH DIAERESIS
  0x00e0, // 0x85 a! LATIN SMALL LETTER A WITH GRAVE
  0x00e5, // 0x86 aa LATIN SMALL LETTER A WITH RING ABOVE
  0x00e7, // 0x87 c, LATIN SMALL LETTER C WITH CEDILLA
  0x00ea, // 0x88 e> LATIN SMALL LETTER E WITH CIRCUMFLEX
  0x00eb, // 0x89 e: LATIN SMALL LETTER E WITH DIAERESIS
  0x00e8, // 0x8a e! LATIN SMALL LETTER E WITH GRAVE
  0x00ef, // 0x8b i: LATIN SMALL LETTER I WITH DIAERESIS
  0x00ee, // 0x8c i> LATIN SMALL LETTER I WITH CIRCUMFLEX
  0x00ec, // 0x8d i! LATIN SMALL LETTER I WITH GRAVE
  0x00c4, // 0x8e A: LATIN CAPITAL LETTER A WITH DIAERESIS
  0x00c5, // 0x8f AA LATIN CAPITAL LETTER A WITH RING ABOVE
  0x00c9, // 0x90 E' LATIN CAPITAL LETTER E WITH ACUTE
  0x00e6, // 0x91 ae LATIN SMALL LIGATURE AE
  0x00c6, // 0x92 AE LATIN CAPITAL LIGATURE AE
  0x00f4, // 0x93 o> LATIN SMALL LETTER O WITH CIRCUMFLEX
  0x00f6, // 0x94 o: LATIN SMALL LETTER O WITH DIAERESIS
  0x00f2, // 0x95 o! LATIN SMALL LETTER O WITH GRAVE
  0x00fb, // 0x96 u> LATIN SMALL LETTER U WITH CIRCUMFLEX
  0x00f9, // 0x97 u! LATIN SMALL LETTER U WITH GRAVE
  0x00ff, // 0x98 y: LATIN SMALL LETTER Y WITH DIAERESIS
  0x00d6, // 0x99 O: LATIN CAPITAL LETTER O WITH DIAERESIS
  0x00dc, // 0x9a U: LATIN CAPITAL LETTER U WITH DIAERESIS
  0x00a2, // 0x9b Ct CENT SIGN
  0x00a3, // 0x9c Pd POUND SIGN
  0x00a5, // 0x9d Ye YEN SIGN
  0x20a7, // 0x9e Pt PESETA SIGN
  0x0192, // 0x9f Fl LATIN SMALL LETTER F WITH HOOK
  0x00e1, // 0xa0 a' LATIN SMALL LETTER A WITH ACUTE
  0x00ed, // 0xa1 i' LATIN SMALL LETTER I WITH ACUTE
  0x00f3, // 0xa2 o' LATIN SMALL LETTER O WITH ACUTE
  0x00fa, // 0xa3 u' LATIN SMALL LETTER U WITH ACUTE
  0x00f1, // 0xa4 n? LATIN SMALL LETTER N WITH TILDE
  0x00d1, // 0xa5 N? LATIN CAPITAL LETTER N WITH TILDE
  0x00aa, // 0xa6 -a FEMININE ORDINAL INDICATOR
  0x00ba, // 0xa7 -o MASCULINE ORDINAL INDICATOR
  0x00bf, // 0xa8 ?I INVERTED QUESTION MARK
  0x2310, // 0xa9 NI REVERSED NOT SIGN
  0x00ac, // 0xaa NO NOT SIGN
  0x00bd, // 0xab 12 VULGAR FRACTION ONE HALF
  0x00bc, // 0xac 14 VULGAR FRACTION ONE QUARTER
  0x00a1, // 0xad !I INVERTED EXCLAMATION MARK
  0x00ab, // 0xae << LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
  0x00bb, // 0xaf >> RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
  0x2591, // 0xb0 .S LIGHT SHADE
  0x2592, // 0xb1 :S MEDIUM SHADE
  0x2593, // 0xb2 ?S DARK SHADE
  0x2502, // 0xb3 vv BOX DRAWINGS LIGHT VERTICAL
  0x2524, // 0xb4 vl BOX DRAWINGS LIGHT VERTICAL AND LEFT
  0x2561, // 0xb5 vL BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE
  0x2562, // 0xb6 Vl BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE
  0x2556, // 0xb7 Dl BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE
  0x2555, // 0xb8 dL BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE
  0x2563, // 0xb9 VL BOX DRAWINGS DOUBLE VERTICAL AND LEFT
  0x2551, // 0xba VV BOX DRAWINGS DOUBLE VERTICAL
  0x2557, // 0xbb LD BOX DRAWINGS DOUBLE DOWN AND LEFT
  0x255d, // 0xbc UL BOX DRAWINGS DOUBLE UP AND LEFT
  0x255c, // 0xbd Ul BOX DRAWINGS UP DOUBLE AND LEFT SINGLE
  0x255b, // 0xbe uL BOX DRAWINGS UP SINGLE AND LEFT DOUBLE
  0x2510, // 0xbf dl BOX DRAWINGS LIGHT DOWN AND LEFT
  0x2514, // 0xc0 ur BOX DRAWINGS LIGHT UP AND RIGHT
  0x2534, // 0xc1 uh BOX DRAWINGS LIGHT UP AND HORIZONTAL
  0x252c, // 0xc2 dh BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
  0x251c, // 0xc3 vr BOX DRAWINGS LIGHT VERTICAL AND RIGHT
  0x2500, // 0xc4 hh BOX DRAWINGS LIGHT HORIZONTAL
  0x253c, // 0xc5 vh BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
  0x255e, // 0xc6 vR BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
  0x255f, // 0xc7 Vr BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE
  0x255a, // 0xc8 UR BOX DRAWINGS DOUBLE UP AND RIGHT
  0x2554, // 0xc9 DR BOX DRAWINGS DOUBLE DOWN AND RIGHT
  0x2569, // 0xca UH BOX DRAWINGS DOUBLE UP AND HORIZONTAL
  0x2566, // 0xcb DH BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
  0x2560, // 0xcc VR BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
  0x2550, // 0xcd HH BOX DRAWINGS DOUBLE HORIZONTAL
  0x256c, // 0xce VH BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
  0x2567, // 0xcf uH BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE
  0x2568, // 0xd0 Uh BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
  0x2564, // 0xd1 dH BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
  0x2565, // 0xd2 Dh BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE
  0x2559, // 0xd3 Ur BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
  0x2558, // 0xd4 uR BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE
  0x2552, // 0xd5 dR BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE
  0x2553, // 0xd6 Dr BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE
  0x256b, // 0xd7 Vh BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
  0x256a, // 0xd8 vH BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
  0x2518, // 0xd9 ul BOX DRAWINGS LIGHT UP AND LEFT
  0x250c, // 0xda dr BOX DRAWINGS LIGHT DOWN AND RIGHT
  0x2588, // 0xdb FB FULL BLOCK
  0x2584, // 0xdc LB LOWER HALF BLOCK
  0x258c, // 0xdd lB LEFT HALF BLOCK
  0x2590, // 0xde RB RIGHT HALF BLOCK
  0x2580, // 0xdf TB UPPER HALF BLOCK
  0x03b1, // 0xe0 a* GREEK SMALL LETTER ALPHA
  0x00df, // 0xe1 b* LATIN SMALL LETTER SHARP S
  0x0393, // 0xe2 G* GREEK CAPITAL LETTER GAMMA
  0x03c0, // 0xe3 p* GREEK SMALL LETTER PI
  0x03a3, // 0xe4 S* GREEK CAPITAL LETTER SIGMA
  0x03c3, // 0xe5 s* GREEK SMALL LETTER SIGMA
  0x00b5, // 0xe6 m* MICRO SIGN
  0x03c4, // 0xe7 t* GREEK SMALL LETTER TAU
  0x03a6, // 0xe8 F* GREEK CAPITAL LETTER PHI
  0x0398, // 0xe9 H* GREEK CAPITAL LETTER THETA
  0x03a9, // 0xea W* GREEK CAPITAL LETTER OMEGA
  0x03b4, // 0xeb d* GREEK SMALL LETTER DELTA
  0x221e, // 0xec 00 INFINITY
  0x03c6, // 0xed /0 GREEK SMALL LETTER PHI
  0x03b5, // 0xee e* GREEK SMALL LETTER EPSILON
  0x2229, // 0xef (U INTERSECTION
  0x2261, // 0xf0 =3 IDENTICAL TO
  0x00b1, // 0xf1 +- PLUS-MINUS SIGN
  0x2265, // 0xf2 >= GREATER-THAN OR EQUAL TO
  0x2264, // 0xf3 =< LESS-THAN OR EQUAL TO
  0x2320, // 0xf4 Iu TOP HALF INTEGRAL
  0x2321, // 0xf5 Il BOTTOM HALF INTEGRAL
  0x00f7, // 0xf6 -: DIVISION SIGN
  0x2248, // 0xf7 ?2 ALMOST EQUAL TO
  0x00b0, // 0xf8 Ob DEGREE SIGN
  0x2219, // 0xf9 .M BULLET OPERATOR
  0x00b7, // 0xfa Sb MIDDLE DOT
  0x221a, // 0xfb RT SQUARE ROOT
  0x207f, // 0xfc nS SUPERSCRIPT LATIN SMALL LETTER N
  0x00b2, // 0xfd 2S SUPERSCRIPT TWO
  0x25a0, // 0xfe fS BLACK SQUARE
  0x00a0 // 0xff NS NO-BREAK SPACE
];

///
/// Unicode to cp437 table.
///
const Map<int, int> _unicodeToCp437 = const <int, int>{
  0x0000: 0x00, // NU NULL
  0x0001: 0x01, // SH START OF HEADING
  0x0002: 0x02, // SX START OF TEXT
  0x0003: 0x03, // EX END OF TEXT
  0x0004: 0x04, // ET END OF TRANSMISSION
  0x0005: 0x05, // EQ ENQUIRY
  0x0006: 0x06, // AK ACKNOWLEDGE
  0x0007: 0x07, // BL BELL
  0x0008: 0x08, // BS BACKSPACE
  0x0009: 0x09, // HT HORIZONTAL TABULATION
  0x000a: 0x0a, // LF LINE FEED
  0x000b: 0x0b, // VT VERTICAL TABULATION
  0x000c: 0x0c, // FF FORM FEED
  0x000d: 0x0d, // CR CARRIAGE RETURN
  0x000e: 0x0e, // SO SHIFT OUT
  0x000f: 0x0f, // SI SHIFT IN
  0x0010: 0x10, // DL DATA LINK ESCAPE
  0x0011: 0x11, // D1 DEVICE CONTROL ONE
  0x0012: 0x12, // D2 DEVICE CONTROL TWO
  0x0013: 0x13, // D3 DEVICE CONTROL THREE
  0x0014: 0x14, // D4 DEVICE CONTROL FOUR
  0x0015: 0x15, // NK NEGATIVE ACKNOWLEDGE
  0x0016: 0x16, // SY SYNCHRONOUS IDLE
  0x0017: 0x17, // EB END OF TRANSMISSION BLOCK
  0x0018: 0x18, // CN CANCEL
  0x0019: 0x19, // EM END OF MEDIUM
  0x001a: 0x1a, // SB SUBSTITUTE
  0x001b: 0x1b, // EC ESCAPE
  0x001c: 0x1c, // FS FILE SEPARATOR
  0x001d: 0x1d, // GS GROUP SEPARATOR
  0x001e: 0x1e, // RS RECORD SEPARATOR
  0x001f: 0x1f, // US UNIT SEPARATOR
  0x0020: 0x20, // SP SPACE
  0x0021: 0x21, // !  EXCLAMATION MARK
  0x0022: 0x22, // "  QUOTATION MARK
  0x0023: 0x23, // Nb NUMBER SIGN
  0x0024: 0x24, // DO DOLLAR SIGN
  0x0025: 0x25, // %  PERCENT SIGN
  0x0026: 0x26, // &  AMPERSAND
  0x0027: 0x27, // '  APOSTROPHE
  0x0028: 0x28, // (  LEFT PARENTHESIS
  0x0029: 0x29, // )  RIGHT PARENTHESIS
  0x002a: 0x2a, // *  ASTERISK
  0x002b: 0x2b, // +  PLUS SIGN
  0x002c: 0x2c, // ,  COMMA
  0x002d: 0x2d, // -  HYPHEN-MINUS
  0x002e: 0x2e, // .  FULL STOP
  0x002f: 0x2f, // /  SOLIDUS
  0x0030: 0x30, // 0  DIGIT ZERO
  0x0031: 0x31, // 1  DIGIT ONE
  0x0032: 0x32, // 2  DIGIT TWO
  0x0033: 0x33, // 3  DIGIT THREE
  0x0034: 0x34, // 4  DIGIT FOUR
  0x0035: 0x35, // 5  DIGIT FIVE
  0x0036: 0x36, // 6  DIGIT SIX
  0x0037: 0x37, // 7  DIGIT SEVEN
  0x0038: 0x38, // 8  DIGIT EIGHT
  0x0039: 0x39, // 9  DIGIT NINE
  0x003a: 0x3a, // :  COLON
  0x003b: 0x3b, // ;  SEMICOLON
  0x003c: 0x3c, // <  LESS-THAN SIGN
  0x003d: 0x3d, // =  EQUALS SIGN
  0x003e: 0x3e, // >  GREATER-THAN SIGN
  0x003f: 0x3f, // ?  QUESTION MARK
  0x0040: 0x40, // At COMMERCIAL AT
  0x0041: 0x41, // A  LATIN CAPITAL LETTER A
  0x0042: 0x42, // B  LATIN CAPITAL LETTER B
  0x0043: 0x43, // C  LATIN CAPITAL LETTER C
  0x0044: 0x44, // D  LATIN CAPITAL LETTER D
  0x0045: 0x45, // E  LATIN CAPITAL LETTER E
  0x0046: 0x46, // F  LATIN CAPITAL LETTER F
  0x0047: 0x47, // G  LATIN CAPITAL LETTER G
  0x0048: 0x48, // H  LATIN CAPITAL LETTER H
  0x0049: 0x49, // I  LATIN CAPITAL LETTER I
  0x004a: 0x4a, // J  LATIN CAPITAL LETTER J
  0x004b: 0x4b, // K  LATIN CAPITAL LETTER K
  0x004c: 0x4c, // L  LATIN CAPITAL LETTER L
  0x004d: 0x4d, // M  LATIN CAPITAL LETTER M
  0x004e: 0x4e, // N  LATIN CAPITAL LETTER N
  0x004f: 0x4f, // O  LATIN CAPITAL LETTER O
  0x0050: 0x50, // P  LATIN CAPITAL LETTER P
  0x0051: 0x51, // Q  LATIN CAPITAL LETTER Q
  0x0052: 0x52, // R  LATIN CAPITAL LETTER R
  0x0053: 0x53, // S  LATIN CAPITAL LETTER S
  0x0054: 0x54, // T  LATIN CAPITAL LETTER T
  0x0055: 0x55, // U  LATIN CAPITAL LETTER U
  0x0056: 0x56, // V  LATIN CAPITAL LETTER V
  0x0057: 0x57, // W  LATIN CAPITAL LETTER W
  0x0058: 0x58, // X  LATIN CAPITAL LETTER X
  0x0059: 0x59, // Y  LATIN CAPITAL LETTER Y
  0x005a: 0x5a, // Z  LATIN CAPITAL LETTER Z
  0x005b: 0x5b, // <( LEFT SQUARE BRACKET
  0x005c: 0x5c, // // REVERSE SOLIDUS
  0x005d: 0x5d, // )> RIGHT SQUARE BRACKET
  0x005e: 0x5e, // '> CIRCUMFLEX ACCENT
  0x005f: 0x5f, // _  LOW LINE
  0x0060: 0x60, // '! GRAVE ACCENT
  0x0061: 0x61, // a  LATIN SMALL LETTER A
  0x0062: 0x62, // b  LATIN SMALL LETTER B
  0x0063: 0x63, // c  LATIN SMALL LETTER C
  0x0064: 0x64, // d  LATIN SMALL LETTER D
  0x0065: 0x65, // e  LATIN SMALL LETTER E
  0x0066: 0x66, // f  LATIN SMALL LETTER F
  0x0067: 0x67, // g  LATIN SMALL LETTER G
  0x0068: 0x68, // h  LATIN SMALL LETTER H
  0x0069: 0x69, // i  LATIN SMALL LETTER I
  0x006a: 0x6a, // j  LATIN SMALL LETTER J
  0x006b: 0x6b, // k  LATIN SMALL LETTER K
  0x006c: 0x6c, // l  LATIN SMALL LETTER L
  0x006d: 0x6d, // m  LATIN SMALL LETTER M
  0x006e: 0x6e, // n  LATIN SMALL LETTER N
  0x006f: 0x6f, // o  LATIN SMALL LETTER O
  0x0070: 0x70, // p  LATIN SMALL LETTER P
  0x0071: 0x71, // q  LATIN SMALL LETTER Q
  0x0072: 0x72, // r  LATIN SMALL LETTER R
  0x0073: 0x73, // s  LATIN SMALL LETTER S
  0x0074: 0x74, // t  LATIN SMALL LETTER T
  0x0075: 0x75, // u  LATIN SMALL LETTER U
  0x0076: 0x76, // v  LATIN SMALL LETTER V
  0x0077: 0x77, // w  LATIN SMALL LETTER W
  0x0078: 0x78, // x  LATIN SMALL LETTER X
  0x0079: 0x79, // y  LATIN SMALL LETTER Y
  0x007a: 0x7a, // z  LATIN SMALL LETTER Z
  0x007b: 0x7b, // (! LEFT CURLY BRACKET
  0x007c: 0x7c, // !! VERTICAL LINE
  0x007d: 0x7d, // !) RIGHT CURLY BRACKET
  0x007e: 0x7e, // '? TILDE
  0x007f: 0x7f, // DT DELETE
  0x00c7: 0x80, // C, LATIN CAPITAL LETTER C WITH CEDILLA
  0x00fc: 0x81, // u: LATIN SMALL LETTER U WITH DIAERESIS
  0x00e9: 0x82, // e' LATIN SMALL LETTER E WITH ACUTE
  0x00e2: 0x83, // a> LATIN SMALL LETTER A WITH CIRCUMFLEX
  0x00e4: 0x84, // a: LATIN SMALL LETTER A WITH DIAERESIS
  0x00e0: 0x85, // a! LATIN SMALL LETTER A WITH GRAVE
  0x00e5: 0x86, // aa LATIN SMALL LETTER A WITH RING ABOVE
  0x00e7: 0x87, // c, LATIN SMALL LETTER C WITH CEDILLA
  0x00ea: 0x88, // e> LATIN SMALL LETTER E WITH CIRCUMFLEX
  0x00eb: 0x89, // e: LATIN SMALL LETTER E WITH DIAERESIS
  0x00e8: 0x8a, // e! LATIN SMALL LETTER E WITH GRAVE
  0x00ef: 0x8b, // i: LATIN SMALL LETTER I WITH DIAERESIS
  0x00ee: 0x8c, // i> LATIN SMALL LETTER I WITH CIRCUMFLEX
  0x00ec: 0x8d, // i! LATIN SMALL LETTER I WITH GRAVE
  0x00c4: 0x8e, // A: LATIN CAPITAL LETTER A WITH DIAERESIS
  0x00c5: 0x8f, // AA LATIN CAPITAL LETTER A WITH RING ABOVE
  0x00c9: 0x90, // E' LATIN CAPITAL LETTER E WITH ACUTE
  0x00e6: 0x91, // ae LATIN SMALL LIGATURE AE
  0x00c6: 0x92, // AE LATIN CAPITAL LIGATURE AE
  0x00f4: 0x93, // o> LATIN SMALL LETTER O WITH CIRCUMFLEX
  0x00f6: 0x94, // o: LATIN SMALL LETTER O WITH DIAERESIS
  0x00f2: 0x95, // o! LATIN SMALL LETTER O WITH GRAVE
  0x00fb: 0x96, // u> LATIN SMALL LETTER U WITH CIRCUMFLEX
  0x00f9: 0x97, // u! LATIN SMALL LETTER U WITH GRAVE
  0x00ff: 0x98, // y: LATIN SMALL LETTER Y WITH DIAERESIS
  0x00d6: 0x99, // O: LATIN CAPITAL LETTER O WITH DIAERESIS
  0x00dc: 0x9a, // U: LATIN CAPITAL LETTER U WITH DIAERESIS
  0x00a2: 0x9b, // Ct CENT SIGN
  0x00a3: 0x9c, // Pd POUND SIGN
  0x00a5: 0x9d, // Ye YEN SIGN
  0x20a7: 0x9e, // Pt PESETA SIGN
  0x0192: 0x9f, // Fl LATIN SMALL LETTER F WITH HOOK
  0x00e1: 0xa0, // a' LATIN SMALL LETTER A WITH ACUTE
  0x00ed: 0xa1, // i' LATIN SMALL LETTER I WITH ACUTE
  0x00f3: 0xa2, // o' LATIN SMALL LETTER O WITH ACUTE
  0x00fa: 0xa3, // u' LATIN SMALL LETTER U WITH ACUTE
  0x00f1: 0xa4, // n? LATIN SMALL LETTER N WITH TILDE
  0x00d1: 0xa5, // N? LATIN CAPITAL LETTER N WITH TILDE
  0x00aa: 0xa6, // -a FEMININE ORDINAL INDICATOR
  0x00ba: 0xa7, // -o MASCULINE ORDINAL INDICATOR
  0x00bf: 0xa8, // ?I INVERTED QUESTION MARK
  0x2310: 0xa9, // NI REVERSED NOT SIGN
  0x00ac: 0xaa, // NO NOT SIGN
  0x00bd: 0xab, // 12 VULGAR FRACTION ONE HALF
  0x00bc: 0xac, // 14 VULGAR FRACTION ONE QUARTER
  0x00a1: 0xad, // !I INVERTED EXCLAMATION MARK
  0x00ab: 0xae, // << LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
  0x00bb: 0xaf, // >> RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
  0x2591: 0xb0, // .S LIGHT SHADE
  0x2592: 0xb1, // :S MEDIUM SHADE
  0x2593: 0xb2, // ?S DARK SHADE
  0x2502: 0xb3, // vv BOX DRAWINGS LIGHT VERTICAL
  0x2524: 0xb4, // vl BOX DRAWINGS LIGHT VERTICAL AND LEFT
  0x2561: 0xb5, // vL BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE
  0x2562: 0xb6, // Vl BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE
  0x2556: 0xb7, // Dl BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE
  0x2555: 0xb8, // dL BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE
  0x2563: 0xb9, // VL BOX DRAWINGS DOUBLE VERTICAL AND LEFT
  0x2551: 0xba, // VV BOX DRAWINGS DOUBLE VERTICAL
  0x2557: 0xbb, // LD BOX DRAWINGS DOUBLE DOWN AND LEFT
  0x255d: 0xbc, // UL BOX DRAWINGS DOUBLE UP AND LEFT
  0x255c: 0xbd, // Ul BOX DRAWINGS UP DOUBLE AND LEFT SINGLE
  0x255b: 0xbe, // uL BOX DRAWINGS UP SINGLE AND LEFT DOUBLE
  0x2510: 0xbf, // dl BOX DRAWINGS LIGHT DOWN AND LEFT
  0x2514: 0xc0, // ur BOX DRAWINGS LIGHT UP AND RIGHT
  0x2534: 0xc1, // uh BOX DRAWINGS LIGHT UP AND HORIZONTAL
  0x252c: 0xc2, // dh BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
  0x251c: 0xc3, // vr BOX DRAWINGS LIGHT VERTICAL AND RIGHT
  0x2500: 0xc4, // hh BOX DRAWINGS LIGHT HORIZONTAL
  0x253c: 0xc5, // vh BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
  0x255e: 0xc6, // vR BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
  0x255f: 0xc7, // Vr BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE
  0x255a: 0xc8, // UR BOX DRAWINGS DOUBLE UP AND RIGHT
  0x2554: 0xc9, // DR BOX DRAWINGS DOUBLE DOWN AND RIGHT
  0x2569: 0xca, // UH BOX DRAWINGS DOUBLE UP AND HORIZONTAL
  0x2566: 0xcb, // DH BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
  0x2560: 0xcc, // VR BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
  0x2550: 0xcd, // HH BOX DRAWINGS DOUBLE HORIZONTAL
  0x256c: 0xce, // VH BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
  0x2567: 0xcf, // uH BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE
  0x2568: 0xd0, // Uh BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
  0x2564: 0xd1, // dH BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
  0x2565: 0xd2, // Dh BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE
  0x2559: 0xd3, // Ur BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
  0x2558: 0xd4, // uR BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE
  0x2552: 0xd5, // dR BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE
  0x2553: 0xd6, // Dr BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE
  0x256b: 0xd7, // Vh BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
  0x256a: 0xd8, // vH BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
  0x2518: 0xd9, // ul BOX DRAWINGS LIGHT UP AND LEFT
  0x250c: 0xda, // dr BOX DRAWINGS LIGHT DOWN AND RIGHT
  0x2588: 0xdb, // FB FULL BLOCK
  0x2584: 0xdc, // LB LOWER HALF BLOCK
  0x258c: 0xdd, // lB LEFT HALF BLOCK
  0x2590: 0xde, // RB RIGHT HALF BLOCK
  0x2580: 0xdf, // TB UPPER HALF BLOCK
  0x03b1: 0xe0, // a* GREEK SMALL LETTER ALPHA
  0x00df: 0xe1, // b* LATIN SMALL LETTER SHARP S
  0x0393: 0xe2, // G* GREEK CAPITAL LETTER GAMMA
  0x03c0: 0xe3, // p* GREEK SMALL LETTER PI
  0x03a3: 0xe4, // S* GREEK CAPITAL LETTER SIGMA
  0x03c3: 0xe5, // s* GREEK SMALL LETTER SIGMA
  0x00b5: 0xe6, // m* MICRO SIGN
  0x03c4: 0xe7, // t* GREEK SMALL LETTER TAU
  0x03a6: 0xe8, // F* GREEK CAPITAL LETTER PHI
  0x0398: 0xe9, // H* GREEK CAPITAL LETTER THETA
  0x03a9: 0xea, // W* GREEK CAPITAL LETTER OMEGA
  0x03b4: 0xeb, // d* GREEK SMALL LETTER DELTA
  0x221e: 0xec, // 00 INFINITY
  0x03c6: 0xed, // /0 GREEK SMALL LETTER PHI
  0x03b5: 0xee, // e* GREEK SMALL LETTER EPSILON
  0x2229: 0xef, // (U INTERSECTION
  0x2261: 0xf0, // =3 IDENTICAL TO
  0x00b1: 0xf1, // +- PLUS-MINUS SIGN
  0x2265: 0xf2, // >= GREATER-THAN OR EQUAL TO
  0x2264: 0xf3, // =< LESS-THAN OR EQUAL TO
  0x2320: 0xf4, // Iu TOP HALF INTEGRAL
  0x2321: 0xf5, // Il BOTTOM HALF INTEGRAL
  0x00f7: 0xf6, // -: DIVISION SIGN
  0x2248: 0xf7, // ?2 ALMOST EQUAL TO
  0x00b0: 0xf8, // Ob DEGREE SIGN
  0x2219: 0xf9, // .M BULLET OPERATOR
  0x00b7: 0xfa, // Sb MIDDLE DOT
  0x221a: 0xfb, // RT SQUARE ROOT
  0x207f: 0xfc, // nS SUPERSCRIPT LATIN SMALL LETTER N
  0x00b2: 0xfd, // 2S SUPERSCRIPT TWO
  0x25a0: 0xfe, // fS BLACK SQUARE
  0x00a0: 0xff // NS NO-BREAK SPACE
};
