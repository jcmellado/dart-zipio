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
/// MS-DOS date time:
/// - https://msdn.microsoft.com/en-us/library/ms724247(v=vs.85).aspx
///
class DosDateTime {

  ///
  /// MS-DOS date.
  ///
  /// The date is a packed value with the following format:
  /// - Bits 0-4: Day of the month (1-31)
  /// - Bits 5-8: Month (1 = January, 2 = February, and so on)
  /// - Bits 9-15: Year offset from 1980 (add 1980 to get actual year)
  ///
  final int date;

  ///
  /// MS-DOS time.
  ///
  /// The time is a packed value with the following format:
  /// - Bits 0-4: Second divided by 2
  /// - Bits 5-10: Minute (0-59)
  /// - Bits 11-15: Hour (0-23 on a 24-hour clock)
  ///
  final int time;

  ///
  /// Backed DateTime.
  ///
  final DateTime dateTime;

  ///
  /// Constructs a [DosDateTime] based on MS-DOS [date] and [time].
  ///
  factory DosDateTime(int date, int time) {
    var day = date & 0x001f;
    var month = (date & 0x01e0) >> 5;
    var year = 1980 + ((date & 0xfe00) >> 9);

    var second = (time & 0x001f) * 2;
    var minute = (time & 0x007e0) >> 5;
    var hour = (time & 0xf800) >> 11;

    var dateTime = new DateTime(year, month, day, hour, minute, second);

    return new DosDateTime._internal(date, time, dateTime);
  }

  ///
  /// Constructs a [DosDateTime] based on [dateTime].
  ///
  /// Milliseconds are set to 0 in the backed dateTime.
  ///
  factory DosDateTime.fromDateTime(DateTime dateTime) {
    dateTime = new DateTime(dateTime.year, dateTime.month, dateTime.day,
        dateTime.hour, dateTime.minute, dateTime.second);

    var day = dateTime.day;
    var month = (dateTime.month << 5) & 0xffff;
    var year = ((dateTime.year - 1980) << 9) & 0xffff;

    var date = day + month + year;

    var second = dateTime.second >> 1;
    var minute = (dateTime.minute << 5) & 0xffff;
    var hour = (dateTime.hour << 11) & 0xffff;

    var time = second + minute + hour;

    return new DosDateTime._internal(date, time, dateTime);
  }

  ///
  /// Constructs a [DosDateTime].
  ///
  const DosDateTime._internal(this.date, this.time, this.dateTime);

  ///
  /// Returns the date part of the ISO-8601 format representation.
  ///
  String toDateString() => dateTime.toIso8601String().split("T")[0];

  ///
  /// Returns the time part of the ISO-8601 format representation plus
  /// the time zone offset.
  ///
  String toTimeString() => "${dateTime.toIso8601String().split("T")[1]}"
      " ${_timeZoneOffset()}";

  ///
  /// Returns a string with the time offset using this pattern: "UTC{(+|-)h{:m}}".
  ///
  String _timeZoneOffset() {
    var offset = dateTime.timeZoneOffset.inMinutes;

    if (offset == 0) return "UTC";

    var hours = (offset ~/ 60).abs();
    var minutes = (offset.remainder(60)).abs();

    return "UTC${offset < 0 ? "-" : "+"}$hours${minutes == 0 ? "" : ":$minutes"}";
  }
}
