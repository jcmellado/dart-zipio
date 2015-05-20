The zipio library reads zip files.

I wrote this library to analyze the structure of some zip files, it's far from to be complete, but it mainly works, so I released the code to avoid it dies at the bottom of my hard drive.

The library uses the `dart:io` package, so it only can be used on the server side or from the command line. It also uses the new `async` Dart features, so it requires a fresh SDK version.

###Usage
Call the `readZip` function to read a zip file and get a `Stream` of `ZipEntity`:

```
import "package:zipio/zipio.dart";

main() async {
  var path = <<PUT YOUR .zip FILENAME HERE>>;

  await for (ZipEntity entity in readZip(path)) {

...
  }
}
```

A `ZipEntity` can be a `ZipComment` with the zip file comment:
```
    if (entity is ZipComment) {
	    print(entity.text);
    }
```

Or can be a `ZipEntry` with a file entry from the zip file:
```
    if (entity is ZipEntry) {
		print(entity.name);
    }
```

Each `ZipEntry` has attributes that describes that file entry: `name`, `isDirectory`, `uncompressedSize`, `modified`, ...

To get the uncompressed content of a zip file entry use its `content` method:

```
    if (entity is ZipEntry) {
      var content = entity.content();

      // Example: Dump the byte data content to a file:
      var file = new File(entity.name);
      file.createSync(recursive: true);

      var sink = file.openWrite();
      sink.addStream(content).then((_) => sink.close());
    }
```

In the `example` folder of the project you can find a full working `unzip` Dart application.

###Encoding
The zip file format specification states that the IBM Code Page 437 should be used for enconding text string like filenames, but most of the modern zip tools use UTF-8.

zipio uses UTF-8 by default too, but a different [Encoding](https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart:convert.Encoding) can be specifed in the optional `encoding` parameter  of the `readZip` function:

```
  readZip(path, enconding: awesomeEnconding);
```

zipio provides a `CP437` codec ready to use:  

```
  readZip(path, enconding: CP437);
```

###Logging
As stated above, I wrote this library to analyze some zip files, so I dumped a lot of debugging information with the help of the [logging](https://pub.dartlang.org/packages/logging) package. 

The optional `log` parameter of the `readZip` function can be used to get all that debugging information:

```
  readZip(path, log: awesomeLogger);
```
At the `Level.FINE` only the the offset and the main attributes will be logged:

```
2015-05-16 20:01:13.511 FINE    zipio # File Header [Offset: 1568171 (0x17edab)]
2015-05-16 20:01:13.511 FINE    zipio  - File name: test/folder/example.txt
```

At the `Level.FINER` all the attributes will be logged:

```
2015-05-16 20:04:51.739 FINE    zipio # File Header [Offset: 1548020 (0x179ef4)]
2015-05-16 20:04:51.739 FINER   zipio  - Signature: 0x02014b50
2015-05-16 20:04:51.739 FINER   zipio  - Version made by: 0x001e (v3.0) [MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)]
2015-05-16 20:04:51.739 FINER   zipio  - Version needed to extract: 0x0014 (v2.0)
2015-05-16 20:04:51.739 FINER   zipio  - General purpose bit flag: 0x0002
2015-05-16 20:04:51.739 FINER   zipio      b2b1 = 01b [Maximum (-exx/-ex) compression option was used]
2015-05-16 20:04:51.739 FINER   zipio  - Compression method: 8 (0x0008) [The file is Deflated]
2015-05-16 20:04:51.739 FINER   zipio  - Last modification file time: 34049 (0x8501) [16:40:02.000 UTC+1]
2015-05-16 20:04:51.739 FINER   zipio  - Last modification file date: 10843 (0x2a5b) [2001-02-27]
2015-05-16 20:04:51.739 FINER   zipio  - CRC-32: 0x5d41778d
2015-05-16 20:04:51.739 FINER   zipio  - Compressed size: 6018 (0x00001782)
2015-05-16 20:04:51.739 FINER   zipio  - Uncompressed size: 17360 (0x000043d0)
2015-05-16 20:04:51.739 FINER   zipio  - File name length: 25 (0x0019)
2015-05-16 20:04:51.739 FINER   zipio  - Extra field length: 9 (0x0009)
2015-05-16 20:04:51.739 FINER   zipio  - File comment length: 0 (0x0000)
2015-05-16 20:04:51.739 FINER   zipio  - Disk number start: 0 (0x0000)
2015-05-16 20:04:51.739 FINER   zipio  - Internal file attributes: 1 (0x0001)
2015-05-16 20:04:51.739 FINER   zipio      b0 = 1 [The file is apparently an ASCII or text file]
2015-05-16 20:04:51.739 FINER   zipio  - External file attributes: 32 (0x00000020)
2015-05-16 20:04:51.739 FINER   zipio  - Relative offset of local header: 600173 (0x0009286d)
2015-05-16 20:04:51.739 FINE    zipio  - File name: test/folder/example.txt
```

At the `Level.FINEST` the raw data and all the attributes will be logged:

```
2015-05-16 20:07:12.416 FINE    zipio # File Header [Offset: 1571816 (0x17fbe8)]
2015-05-16 20:07:12.416 FINEST  zipio 
2015-05-16 20:07:12.416 FINEST  zipio           00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
2015-05-16 20:07:12.416 FINEST  zipio           -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
2015-05-16 20:07:12.416 FINEST  zipio  0017fbe0 .  .  .  .  .  .  .  .  50 4b 01 02 1e 00 14 00
2015-05-16 20:07:12.416 FINEST  zipio  0017fbf0 02 00 08 00 73 19 7d 38 ff 8e 53 03 0f 61 00 00
2015-05-16 20:07:12.416 FINEST  zipio  0017fc00 e8 e6 01 00 31 00 09 00 00 00 00 00 01 00 20 00
2015-05-16 20:07:12.416 FINEST  zipio  0017fc10 00 00 b1 95 16 00 .  .  .  .  .  .  .  .  .  . 
2015-05-16 20:07:12.416 FINEST  zipio 
2015-05-16 20:07:12.416 FINER   zipio  - Signature: 0x02014b50
2015-05-16 20:07:12.416 FINER   zipio  - Version made by: 0x001e (v3.0) [MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)]
...
```
In the `example` folder of the project you can find a full working `info` Dart application.
