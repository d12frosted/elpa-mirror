Raffael Stocker


Table of Contents
─────────────────

1. Scanner: scan documents and images with Emacs
2. Configuration
3. Bugs


1 Scanner: scan documents and images with Emacs
═══════════════════════════════════════════════

  Scan documents and images using `scanimage(1)' from the SANE
  distribution and `tesseract(1)' for OCR and PDF export.  Additionally,
  `unpaper(1)' can now be used for post-processing the scans obtained
  from `scanimage' before feeding them into `tesseract'.  This is
  optional, but highly recommended.  The source to unpaper is available
  at <https://github.com/unpaper/unpaper>.

  The scanner package uses two sets of customizations for image mode and
  document mode, with the former usually configured to use high
  resolution and an image file format, like JPEG, and the latter to use
  lower resolution and a document format, like PDF or text.  The
  available file formats are provided by `scanimage(1)' for image mode
  and `tesseract(1)' for document mode.  The scanner package uses
  `tesseract(1)' to provide optical character recognition (OCR).  You
  can select the language plugins with `scanner-tesseract-languages'.
  See also the remark about the data directories below.

  In document mode, you can scan one or multiple pages that are then
  written in a customizable output format, e.g. (searchable) PDF or
  text, or whatever tesseract provides.  You can also customize
  resolution, intermediate image format, and paper size.  The command
  `scanner-scan-document' starts a document scan.  Without a prefix
  argument, it scans one page.  With a non-numeric argument, it asks the
  user after each scanned page for confirmation to scan another page.
  With a numeric argument, it scans that many pages.  In the latter
  case, it observes a delay between scans that is customizable using
  `scanner-scan-delay'.

  The `scanner-scan-image' command performs one scan or multiple scans
  in image mode.  This function tries to guess the file format from the
  chosen file name or falls back to the configured default, see
  `scanner-image-format'.  The prefix argument works as in document
  mode.

  The scanning commands are also available in the Tools->Scanner menu.

  For both images and documents, you can customize the scan mode
  (e.g. "Color" or "Gray") if your scanning device supports it.

  You can pass additional options to the backends using the
  customization variables `scanner-scanimage-switches' and
  `scanner-tesseract-switches'.  The former variable is helpful for
  tuning brightness and contrast, for instance.

  Finally, the customization options `scanner-tessdata-dir' and
  `scanner-tessdata-configdir' must be set to point to tesseract's data
  directory containing the language definitions (usually something like
  `/usr/share/tessdata/') and tesseract's configs directory containing
  the output configurations (usually something like
  `/usr/share/tessdata/configs/').


2 Configuration
═══════════════

  To use `unpaper', set the customization option `scanner-use-unpaper'
  to t.

  Scanner defines a keymap that is best bound to some convenient key,
  for example with `(keymap-global-set "s-s" scanner-map)' or when using
  `use-package' with `:bind-keymap ("s-s" . scanner-map)' in the
  use-package specification.

  Most package options are customizations and can but configured in the
  usual ways.


3 Bugs
══════

  • This package doesn't support document feeders yet.
  • This package doesn't support authentication.
  • If a new document scan is started while another is still running,
    the log will be messed up a bit.
