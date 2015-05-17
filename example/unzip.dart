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

import "dart:io" show Directory, File, Platform;
import "package:path/path.dart" as path show absolute, normalize;
import "package:zipio/zipio.dart" show readZip, ZipEntity, ZipEntry, ZipMethod;

/// Unzip a file into a directory.
main(List<String> args) async {

  // Parameters must be there.
  if (args.length != 2) {
    print(r"Usage: unzip <file> <directory>");
    return;
  }

  // Target directory.
  var target = path.normalize(path.absolute(args[1]));

  // Process the zip entries.
  await for (ZipEntity entity in readZip(args[0])) {

    // Only file entries.
    if (entity is! ZipEntry) continue;

    var entry = entity as ZipEntry;

    // Password protected files can't be extracted.
    if (entry.isProtected) {
      print("${entry.name}: Password protected");
      continue;
    }

    // Only deflated and stored compression methods are supported.
    if (entry.compressionMethod != ZipMethod.DEFLATED &&
        entry.compressionMethod != ZipMethod.STORED) {
      print("${entry.name}: Unsupported compression method");
      continue;
    }

    // Files without a valid name are ignored.
    if ((entry.name == null) || entry.name.trim().isEmpty) {
      print("Invalid or empty filename");
      continue;
    }

    // Absolute file name.
    var name = path
        .normalize(path.absolute(target + Platform.pathSeparator + entry.name));

    // Avoid to create files outside the target directory.
    if (!name.startsWith(target)) {
      print("${entry.name}: Invalid target directory");
      continue;
    }

    // Directory entry.
    if (entry.isDirectory) {
      var dir = new Directory(name);

      // Avoid to overwrite existing directories.
      if (dir.existsSync()) {
        print("${dir.path}: Directory already exists");
        continue;
      }

      // Creates the directory.
      dir.createSync(recursive: true);
      continue;
    }

    // File entry.
    var file = new File(name);

    // Avoid to overwrite existing files.
    if (file.existsSync()) {
      print("${file.path}: File already exists");
      continue;
    }

    // Creates the file.
    file.createSync(recursive: true);

    var sink = file.openWrite();

    sink.addStream(entry.content()).then((_) => sink.close());
  }
}
