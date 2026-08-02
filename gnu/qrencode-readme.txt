1 QREncode EL
═════════════

  QR Code encoder written in pure Emacs Lisp.

  For example the self-link (<https://github.com/ruediger/qrencode-el>)
  below was generated using this code:

  <file:qr-self.png>


1.1 Usage
─────────

  This package provides two user facing interactive functions, that will
  encode text into a QR Code and show it in a separate buffer.

  `qrencode-region'
        Shows the current selection as a QR Code.
  `qrencode-url-at-point'
        Encode URL at point as QR Code.

  Some customizations are provided using `M-x customize-group RET
    qrencode RET'.

  QR Codes are rendered as Unicode text, but there is an option to
  export them as bitmap (NetPBM format).  There are also some public
  elisp library functions to generate QR Codes for use in other elisp
  code.


1.1.1 Converting different bitmaps
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This package only supports exporting to NetPBM format due to the
  simplicity of the format.  If PNG or other bitmap formats are desired
  this can be achieved by using `qrencode-post-export-functions' to run
  a conversion after the export.  For example using `convert(1)' from
  [ImageMagick]:

  ┌────
  │ (add-hook 'qrencode-post-export-functions
  │         #'(lambda (filename)
  │             (call-process "convert" nil nil nil
  │                           filename
  │                           (file-name-with-extension filename "png"))))
  └────


[ImageMagick] <https://www.imagemagick.org/script/convert.php>


1.2 Installation
────────────────

  [file:https://melpa.org/packages/qrencode-badge.svg]
  [file:https://stable.melpa.org/packages/qrencode-badge.svg]

  QREncode is available via [MELPA] and [el-get].


[file:https://melpa.org/packages/qrencode-badge.svg]
<https://melpa.org/#/qrencode>

[file:https://stable.melpa.org/packages/qrencode-badge.svg]
<https://stable.melpa.org/#/qrencode>

[MELPA] <https://melpa.org/#/qrencode>

[el-get]
<https://github.com/dimitri/el-get/blob/master/recipes/qrencode.rcp>


1.3 Background
──────────────

  <file:https://github.com/ruediger/qrencode-el/actions/workflows/test.yml/badge.svg>

  The code is written in pure Emacs Lisp on GNU Emacs 27.  It should be
  backwards compatible to GNU Emacs 25.1 and potentially even earlier
  with `seq' and `cl-lib' compat libraries.

  There are unit tests and an integration test using [zbar.sf.net]
  (Debian/Ubuntu package `zbar-tools') to verify that generated QR Codes
  can be decoded.  <https://qrlogo.kaarposoft.dk/qrdecode.html> is
  another good way to test the generated codes, since the decoder
  supports debug output.

  The encoder is written for the ISO/IEC 18004:2015 standard.  It only
  supports regular QR Codes (Model 2) and byte encoding (#11).  I
  believe this is sufficient for use-cases in GNU Emacs.  The word "QR
  Code" is registered trademark of DENSO WAVE INCORPORATED in Japan and
  other countries.


[zbar.sf.net] <https://zbar.sf.net>
