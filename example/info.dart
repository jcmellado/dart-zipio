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

import "package:logging/logging.dart" show Level, Logger;
import "package:zipio/zipio.dart" show readZip;

/// Dump (a lot of) information about a zip file.
main(List<String> args) async {

  // Parameters must be there.
  if (args.length != 1) {
    print(r"Usage: info <file>");
    return;
  }

  // Poor man logger, all the output will be printed to the console.
  Logger.root.onRecord.listen((rec) {
    var level = rec.level.name.padRight(7);
    print("${rec.time} $level ${rec.loggerName} ${rec.message}");
  });

  Logger.root.level = Level.FINEST;

  // Just consume the stream, nothing more to do here.
  var stream = readZip(args[0], log: Logger.root);

  stream.listen((_) => null);
}
