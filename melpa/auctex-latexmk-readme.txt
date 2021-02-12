This library adds LatexMk support to AUCTeX.

Requirements:
  * AUCTeX
  * LatexMk
  * TeXLive (2011 or later if you write TeX source in Japanese)

To use this package, add the following line to your .emacs file:
    (require 'auctex-latexmk)
    (auctex-latexmk-setup)
And add the following line to your .latexmkrc file:
    # .latexmkrc starts
    $pdf_mode = 1;
    # .latexmkrc ends
After that, by using M-x TeX-command-master (or C-c C-c), you can use
LatexMk command to compile TeX source.

For Japanese users:

LatexMk command automatically stores the encoding of a source file
and passes it to latexmk via an environment variable named "LATEXENC".
Here is the example of .latexmkrc to use "LATEXENC":
    # .latexmkrc starts
    $kanji    = "-kanji=$ENV{\"LATEXENC\"}" if defined $ENV{"LATEXENC"};
    $latex    = "platex $kanji";
    $bibtex   = "pbibtex $kanji";
    $dvipdf   = 'dvipdfmx -o %D %S';
    $pdf_mode = 3;
    # .latexmkrc ends
