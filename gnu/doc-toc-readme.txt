1 Doc Tools TOC
═══════════════

  [https://img.shields.io/badge/license-GPLv3-blue.svg]

  Create, cleanup, add and manage Table Of Contents (TOC) of pdf and
  djvu documents with Emacs


[https://img.shields.io/badge/license-GPLv3-blue.svg]
<https://www.gnu.org/licenses/gpl-3.0.en.html>


2 Introduction
══════════════

  Doc Tools TOC is a package for creating, cleaning, adding and managing
  the Table Of Contents (TOC) of pdf and djvu documents.

  This package is also provided by the [toc-layer for Spacemacs]


[toc-layer for Spacemacs] <https://github.com/dalanicolai/toc-layer>

2.1 Features:
─────────────

  • Extract Table of Contents from documents via text layer or via
    Tesseract OCR
  • Auto detect indentation levels from leading spaces or by selecting
    level separater
  • Quickly adjust pagenumbers while viewing the document
  • Add Table of Contents to document


3 Installation
══════════════

  For Spacemacs use the [toc-layer for Spacemacs]. Installation
  instruction are found on that page.

  For regular Emacs users, well… you probably know how to install
  packages.


[toc-layer for Spacemacs] <https://github.com/dalanicolai/toc-layer>

3.1 Requirements
────────────────

  To use the pdf.tocgen functionality that software has to be installed
  (see <https://krasjet.com/voice/pdf.tocgen/>). For the other remaining
  functionality the package requires `pdftotext' (part of
  poppler-utils), `pdfoutline' (part of [fntsample]) and `djvused' (part
  of [http://djvu.sourceforge.net/]) command line utilities to be
  available. Extraction with OCR requires the `tesseract' command line
  utility to be available.


[fntsample] <https://launchpad.net/ubuntu/bionic/+package/fntsample>

[http://djvu.sourceforge.net/] <http://djvu.sourceforge.net/>


4 Usage
═══════

4.1 pdf-tocgen (software generated PDF's)
─────────────────────────────────────────

  <https://krasjet.com/voice/pdf.tocgen/>

  For 'software-generated' (i.e. PDF's not created from scans) PDF-files
  it is recommend to use `doc-toc-extract-with-pdf-tocgen'. To use this
  function you first have to provide the font properties for the
  different headline levels. For that select the word in a headline of a
  certain level and then type `M-x doc-toc-gen-set-level'. This function
  will ask which level you are setting, the highest level should be
  level 1. After you have set the various levels (1,2, etc.) then it is
  time to run `M-x doc-toc-extract-with-pdf-tocgen'. If a TOC is
  extracted succesfully, then in the pdftocgen-mode buffer simply press
  C-c C-c to add the contents to the PDF. The contents will be added to
  a copy of the original PDF with the filename output.pdf and this copy
  will be opened in a new buffer. If the pdf-tocgen option does not work
  well then continue with the steps below.


4.2 toc-mode
────────────

  In each step below, check out available shortcuts using `C-h
  m'. Additionally you can find available functions by typing the M-x
  mode-name (e.g. `M-x doc-toc-cleanup'), or with two dashes in the mode
  name (e.g. `M-x doc-toc--cleanup'). Of course if you use packages like
  Ivy or Helm you just use the fuzzy search functionality.

  Extraction and adding contents to a document is done in 4 steps:
  1. extraction
  2. cleanup
  3. adjust/correct pagenumbers
  4. add TOC to document

  In each step below, check out available shortcuts using `C-h
  m'. Additionally you can find available functions by typing the `M-x
  mode-name' (e.g. `M-x doc-toc-cleanup'), or with two dashes in the
  mode name (e.g. `M-x doc-toc--cleanup'). Of course if you use packages
  like Ivy or Helm you just use the fuzzy search functionality.


4.2.1 1. Extraction
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  For PDFs without TOC pages, with a very complicated TOC (i.e. that
  require much cleanup work) or with headlines well fitted for automatic
  extraction (you will have to decide for yourself by trying it),
  consider to use the [pdf.tocgen] functionality described below.

  Otherwise, start with opening some pdf or djvu file in Emacs
  (pdf-tools and djvu package recommended). Find the pagenumbers for the
  TOC. Then type `M-x doc-toc-extract-pages', or `M-x
  doc-toc-extract-pages-ocr' if doc has no text layer or the text layer
  is bad, and answer the subsequent prompts by entering the pagenumbers
  for the first and the last page each followed by `RET'. *For PDF
  extraction with OCR, currently it is required* *to view all contents
  pages once before extraction* (doc-toc uses the cached file data). For
  TOC's that are formatted as two columns per page, prepend the
  `doc-toc-extract-pages-ocr' command with two universal arguments. Then
  after you are asked for the start and finish pagenumbers, a third
  question asks you to set the tesseract psm code. For the double column
  layout it is best (as far as I know) to use psm code `1'. Also the
  languages used for tesseract OCR can be customized via the
  `doc-toc-ocr-languages' variable.



  A buffer with the, somewhat cleaned up, extracted text will open in
  TOC-cleanup mode. Prefix command with the universal argument (`C-u')
  to omit cleanup and get the raw text. If the extracted text is of too
  low quality you either can hack/extend the [doc-toc-extract-pages-ocr]
  definition, or alternatively you can try to extract the text with the
  [python document-contents-extractor script], which is more
  configurable (you are also welcome to hack on and improve that
  script). For this the [tesseract] documentation might be useful.

  If you merely want to extract text without further processing then you
  can use the command [doc-toc-extract-only].


[pdf.tocgen] <https://krasjet.com/voice/pdf.tocgen/>

[doc-toc-extract-pages-ocr] <help:doc-toc-extract-pages-ocr>

[python document-contents-extractor script]
<https://pypi.org/project/document-contents-extractor/>

[tesseract]
<https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html>

[doc-toc-extract-only] <help:doc-toc-extract-only>


4.2.2 2. TOC-Cleanup
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In this mode you can further cleanup the contents to create a list
  where each line has the structure:

  TITLE (SOME) PAGENUMBER

  There can be any number of spaces between TITLE and PAGE. The correct
  pagenumbers can be edited in the next step. A document outline
  supports different levels and levels are automatically assigned in
  order of increasing number of preceding spaces, i.e. the lines with
  the least amount of preceding spaces are assigned level 0 etc., and
  lines with equal number of spaces get assigned the same levels.
  ┌────
  │ Contents   1
  │ Chapter 1      2
  │  Section 1 3
  │   Section 1.1     4
  │ Chapter 2      5
  └────
  There are some handy functions to assist in the cleanup. `C-c C-j'
  jumps automatically to the next line not ending with a number and
  joins it with the next line. If the indentation structure of the
  different lines does not correspond with the levels, then the levels
  can be set automatically from the number of seperators in the indices
  with `M-x doc-toc-cleanup-set-level-by-index'. The default seperator
  is a `.' but a different seperator can be entered by preceding the
  function invocation with the universal argument (`C-u'). Some
  documents contain a structure like
  ┌────
  │ 1 Chapter 1    1
  │ Section 1      2
  └────
  Here the indentation can be set with `M-x replace-regexp' `^[^0-9]' ->
  `\&' (where there is a space character before the `\&').

  Type `C-c C-c' when finished


4.2.3 3. TOC-tabular (adjust pagenumbers)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This mode provides the functionality for easy adjustment of
  pagenmumbers. The buffer can be navigated with the arrow `up/down'
  keys. The `left' and `right' arrow keys will shift `down/up' all the
  page numbers from the current line and below (combine with `SHIFT' for
  setting individual pagenumbers).

  The `TAB' key jumps to the pagenumber of the current line, while
  `C-right/C-left' will shift all remaining page numbers up/down while
  jumping/scrolling to the line its page in the document window. Because
  the numbering of scanned books often breaks at sections of a certain
  level, `C-j' will let jo jump quickly to the next entry of a certain
  level (e.g. you can quickly check if the page numbers of all level 0
  sections correspond to the page numbers in the document). The
  `S-up/S-down' in the tablist window will just scroll page up/down in
  the document window and, `C-up/C-down' will scroll smoothly in that
  window.

  If you discover some small error in some field, then you put the
  cursor on that field and press `r' to correct the text in that field.

  Type `C-c C-c' when done.


4.2.4 4. TOC-mode (add outline to document)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The text of this buffer should have the right structure for adding the
  contents to (for pdf's a copy of) the original document. Final
  adjustments can be done but should not be necessary. Type `C-c C-c'
  for adding the contents to the document.

  By default, the TOC is simply added to the original file. (ONLY FOR
  PDF's, if the (customizable) variable [doc-toc-replace-original-file]
  is `nil', then the TOC is added to a copy of the original pdf file
  with the path as defined by the variable
  `doc-toc-destination-file-name'. Either a relative path to the
  original file directory or an absolute path can be given.)

  Sometimes the `pdfoutline/djvused' application is not able to add the
  TOC to the document. In that case you can either debug the problem by
  copying the used terminal command from the `*messages*' buffer and run
  it manually in the document's folder iside the terminal, or you can
  delete the outline source buffer and run
  `doc-toc--tablist-to-handyoutliner' from the tablist buffer to get an
  outline source file that can be used with [HandyOutliner]
  (unfortunately the handyoutliner command does not take arguments, but
  if you customize the [doc-toc-handyoutliner-path] and
  [doc-toc-file-browser-command] variables, then Emacs will try to open
  HandyOutliner and the file browser so that you can drag the file
  `contents.txt' directly into HandyOutliner).


[doc-toc-replace-original-file] <help:doc-toc-replace-original-file>

[HandyOutliner] <http://handyoutlinerfo.sourceforge.net/>

[doc-toc-handyoutliner-path] <help:doc-toc-handyoutliner-path>

[doc-toc-file-browser-command] <help:doc-toc-file-browser-command>


5 Key bindings
══════════════

  all-modes (i.e. all steps)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key Binding  Description          
  ───────────────────────────────────
   `C-c C-c'    dispatch (next step) 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  doc-toc-cleanup-mode
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `C-c C-j'  doc-toc-join-next-unnumbered-lines 
   `C-c C-s'  doc-toc–roman-to-arabic            
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  doc-toc-mode (tablist)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `TAB'             preview/jump-to-page                                                 
   `right/left'      doc-toc-in/decrease-remaining                                        
   `C-right/C-left'  doc-toc-in/decrease-remaining and view page                          
   `S-right/S-left'  in/decrease pagenumber current entry                                 
   `C-down/C-up'     scroll document other window (only when other buffer shows document) 
   `S-down/S-up'     full page scroll document other window ( idem )                      
   `C-j'             doc-toc–jump-to-next-entry-by-level                                  
   `r'               doc-toc–replace-input                                                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


6 Alternatives
══════════════

  • For TOC extraction: [documents-contents-extractor]
  • For adding TOC to document (pdf and djvu): [HandyOutliner]


[documents-contents-extractor]
<https://pypi.org/project/document-contents-extractor/>

[HandyOutliner] <http://handyoutlinerfo.sourceforge.net/>

6.0.1 Donate
╌╌╌╌╌╌╌╌╌╌╌╌

  [Buy me a coffee (PayPal donate)]


[Buy me a coffee (PayPal donate)]
<https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6BHLS7H9ARJXE&source=url>
