unicad.el is an Elisp program port from Mozilla universal charset
auto detector. After loading unicad in GNU Emacs, it can automatically
detect multiple charsets, and you will never encounter garbled files
in the future.

Put this file into your load-path and the following into your ~/.emacs:
  (require 'unicad)

You can toggle unicad by M-x `unicad-mode'.

It may take a few seconds to detect some large latin-1 or latin-2 files,
you can byte-compile this file to speed up detecting process.

Following coding systems can be auto detected:
 * (BOM detect)
 * (ascii)
 * multibyte coding systems:
   - gb18030 (gb2312)
   - big5
   - sjis
   - euc-jp
   - euc-kr
   - euc-tw
   - utf-8
   - utf-16le (also without signature)
   - utf-16be (also without signature)
 * singlebyte coding systems:
   - greek
     > iso-8859-7
     > windows-1253
   - russian
     > koi8-r
     > windows-1251
     > iso-8859-5
     > ibm855
 - bulgarian
     > iso-8859-5
     > windows-1251
 - sjis (singlebyte only)
 * latin-1
 * latin-2
