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
// - .ZIP File Format Specification:
//   https://www.pkware.com/documents/casestudies/APPNOTE.TXT

///
/// The zipio_extra library can be used to process ZIP extra fields.
///
library zipio_extra;

// Extra field header ids.

/// Zip64 extended information extra field header id.
const int zip64HeaderId = 0x0001;

/// AV Info extra field header id.
const int avInfoHeaderId = 0x0007;

/// Extended language encoding data (PFS) extra field header id.
const int pfsHeaderId = 0x0008;

/// OS/2 extra field header id.
const int os2HeaderId = 0x0009;

/// NTFS extra field header id.
const int ntfsHeaderId = 0x000a;

/// OpenVMS extra field header id.
const int openVmsHeaderId = 0x000c;

/// UNIX extra field header id.
const int unixHeaderId = 0x000d;

/// File stream and fork descriptors extra field header id.
const int fileStreamHeaderId = 0x000e;

/// Patch descriptor extra field header id.
const int patchDescriptorHeaderId = 0x000f;

/// PKCS#7 Store for X.509 Certificates extra field header id.
const int pkcs7StoreHeaderId = 0x0014;

/// X.509 Certificate ID and Signature for individual file extra field
/// header id.
const int x509FileHeaderId = 0x0015;

/// X.509 Certificate ID and Signature for Central Directory extra field header id.
const int x509DirectoryHeaderId = 0x0016;

/// Strong Encryption Header extra field header id.
const int encryptionHeaderId = 0x0017;

/// Record Management Controls extra field header id.
const int managementHeaderId = 0x0018;

/// PKCS#7 Encryption Recipient Certificate List extra field header id.
const int pkcs72HeaderdId = 0x0019;

/// IBM S/390 (Z390), AS/400 (I400) attributes (uncompressed) extra field
/// header id.
const int as400UncompressedHeaderId = 0x0065;

/// IBM S/390 (Z390), AS/400 (I400) attributes (compressed) extra field
/// header id.
const int os400CompressedHeaderId = 0x0066;

/// POSZIP 4690 extra field header id.
const int poszip4690HeaderId = 0x4690;

/// Macintosh extra field header id.
const int macintoshHeaderId = 0x07c8;

/// ZipIt Macintosh (long) extra field header id.
const int zipItMacintosh1HeaderId = 0x2605;

/// ZipIt Macintosh (short, for files) extra field header id.
const int zipItMacintosh2HeaderId = 0x2705;

/// ZipIt Macintosh (short, for directories) extra field header id.
const int zipItMacintosh3HeaderId = 0x2805;

/// Info-ZIP Macintosh extra field header id.
const int infoZipMacintoshHeaderId = 0x334d;

/// Acorn/SparkFS extra field header id.
const int acornHeaderId = 0x4341;

/// Windows NT security descriptor (binary ACL) extra field header id.
const int windowsNtHeaderId = 0x4453;

/// VM/CMS extra field header id.
const int vmCmsHeaderId = 0x4704;

/// MVS extra field header id.
const int mvsHeaderId = 0x470f;

/// FWKCS MD5 extra field header id.
const int fwkcsMd5HeaderId = 0x4b46;

/// OS/2 access control list (text ACL) extra field header id.
const int os2AclHeaderId = 0x4c41;

/// Info-ZIP OpenVMS extra field header id.
const int infoZipOpenVmsHeaderId = 0x4d49;

/// Xceed original location extra field header id.
const int xceedHeaderId = 0x4f4c;

/// AOS/VS (ACL) extra field header id.
const int aosVsHeaderId = 0x5356;

/// Extended timestamp extra field header id.
const int timestampHeaderId = 0x5455;

/// Xceed unicode extra field header id.
const int xceedUnicodeHeaderId = 0x554e;

/// Info-ZIP UNIX (original, also OS/2, NT, etc) extra field header id.
const int infoZipHeaderId = 0x5855;

/// Info-ZIP Unicode Comment extra field header id.
const int infoZipCommentHeaderId = 0x6375;

/// BeOS/BeBox extra field header id.
const int beOsHeaderId = 0x6542;

/// Info-ZIP Unicode Path extra field header id.
const int infoZipUnicodeHeaderId = 0x7075;

/// ASi UNIX extra field header id.
const int asiHeaderId = 0x756e;

/// Info-ZIP UNIX (new) extra field header id.
const int infoZip2HeaderId = 0x7855;

/// Microsoft Open Packaging Growth Hint extra field header id.
const int opcHeaderId = 0xa220;

/// SMS/QDOS extra field header id.
const int smsQdosHeaderId = 0xfd4a;

/// Extra header names.
const Map<int, String> extraNames = const {
  zip64HeaderId: "Zip64 extended information",
  avInfoHeaderId: "AV Info",
  pfsHeaderId: "Extended language encoding data (PFS)",
  os2HeaderId: "OS/2",
  ntfsHeaderId: "NTFS",
  openVmsHeaderId: "OpenVMS",
  unixHeaderId: "UNIX",
  fileStreamHeaderId: "File stream and fork descriptors",
  patchDescriptorHeaderId: "Patch descriptor",
  pkcs7StoreHeaderId: "PKCS#7 Store for X.509 Certificates",
  x509FileHeaderId: "X.509 Certificate ID and Signature for individual file",
  x509DirectoryHeaderId:
      "X.509 Certificate ID and Signature for Central Directory",
  encryptionHeaderId: "Strong Encryption Header",
  managementHeaderId: "Record Management Controls",
  pkcs72HeaderdId: "PKCS#7 Encryption Recipient Certificate List",
  as400UncompressedHeaderId:
      "IBM S/390 (Z390), AS/400 (I400) attributes (uncompressed)",
  os400CompressedHeaderId:
      "IBM S/390 (Z390), AS/400 (I400) attributes (compressed)",
  poszip4690HeaderId: "POSZIP 4690",
  macintoshHeaderId: "Macintosh",
  zipItMacintosh1HeaderId: "ZipIt Macintosh (long)",
  zipItMacintosh2HeaderId: "ZipIt Macintosh (short, for files)",
  zipItMacintosh3HeaderId: "ZipIt Macintosh (short, for directories)",
  infoZipMacintoshHeaderId: "Info-ZIP Macintosh",
  acornHeaderId: "Acorn/SparkFS",
  windowsNtHeaderId: "Windows NT security descriptor (binary ACL)",
  vmCmsHeaderId: "VM/CMS",
  mvsHeaderId: "MVS",
  fwkcsMd5HeaderId: "FWKCS MD5",
  os2AclHeaderId: "OS/2 access control list (text ACL)",
  infoZipOpenVmsHeaderId: "Info-ZIP OpenVMS",
  xceedHeaderId: "Xceed original location",
  aosVsHeaderId: "AOS/VS (ACL)",
  timestampHeaderId: "Extended timestamp",
  xceedUnicodeHeaderId: "Xceed unicode",
  infoZipHeaderId: "Info-ZIP UNIX (original, also OS/2, NT, etc)",
  infoZipCommentHeaderId: "Info-ZIP Unicode Comment",
  beOsHeaderId: "BeOS/BeBox",
  infoZipUnicodeHeaderId: "Info-ZIP Unicode Path",
  asiHeaderId: "ASi UNIX",
  infoZip2HeaderId: "Info-ZIP UNIX (new)",
  opcHeaderId: "Microsoft Open Packaging Growth Hint",
  smsQdosHeaderId: "SMS/QDOS"
};
