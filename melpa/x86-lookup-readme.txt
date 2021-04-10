Requires the following:
* pdftotext command line program from Poppler
* Intel 64 and IA-32 Architecture Software Developer Manual PDF

http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html

Building the index specifically requires Poppler's pdftotext, not
just any PDF to text converter. It has a critical feature over the
others: conventional form feed characters (U+000C) are output
between pages, allowing precise tracking of page numbers. These are
the markers Emacs uses for `forward-page' and `backward-page'.

Your copy of the manual must contain the full instruction set
reference in a single PDF. Set `x86-lookup-pdf' to this file name.
Intel optionally offers the instruction set reference in two
separate volumes, but don't use that.

Choose a PDF viewer by setting `x86-lookup-browse-pdf-function'. If
you provide a custom function, your PDF viewer should support
linking to a specific page (e.g. not supported by xdg-open,
unfortunately). Otherwise there's no reason to use this package.

Once configured, the main entrypoint is `x86-lookup'. You may want
to bind this to a key. The interactive prompt will default to the
mnemonic under the point. Here's a suggestion:

  (global-set-key (kbd "C-h x") #'x86-lookup)

This package pairs well with `nasm-mode'!

; Code
