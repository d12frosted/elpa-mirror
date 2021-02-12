Provides a function `bibslurp-query-ads', which reads a search
string from the minibuffer, sends the query to NASA ADS
(http://adswww.harvard.edu/), and displays the results in a new
buffer called "ADS Search Results".

The "ADS Search Results" buffer opens in `bibslurp-mode', which
provides a few handy functions.  Typing the number preceding an
abstract and hitting RET calls `bibslurp-slurp-bibtex', which
fetches the bibtex entry corresponding to the abstract and saves it
to the kill ring.  Typing 'a' instead pulls up the abstract page.
At anytime, you can hit 'q' to quit bibslurp-mode and restore the
previous window configuration.

; Example usage:

add an entry to a bibtex buffer:
  M-x bibslurp-query-ads RET ^Quataert 2008 RET
Move to the abstract you want to cite with n and p keys, or search
in the buffer with s or r, and then press
  RET
  q
  C-y

If you want to select a different abstract, just type the
corresponding number before pressing RET:
  15 RET
  q
  C-y

For more examples and information see the project page at
http://astro.berkeley.edu/~mkmcc/software/bibslurp.html

; Advanced search
You can turn to the ADS advanced search interface, akin to
http://adsabs.harvard.edu/abstract_service.html, either by pressing
C-c C-c after having issued `bibslurp-query-ads', or directly with
  M-x `bibslurp-query-ads-advanced-search' RET
Here you can fill the wanted search fields (authors, publication
date, objects, title, abstract) and specify combination logics, and
then send the query either with C-c C-c or by pressing the button
"Send Query".  Use TAB to move through fields, and q outside an
input field to quit the search interface.

; Other features
In the ADS search result buffer you can also visit some useful
pages related to each entry:
 - on-line data at other data centers, with d
 - on-line version of the selected article, with e
 - on-line articles in PDF or Postscript, with f
 - lists of objects for the selected abstract in the NED database,
   with N
 - lists of objects for the selected abstract in the SIMBAD
   database, with S
 - on-line pre-print version of the article in the arXiv database,
   with x
For each of these commands, BibSlurp will use by default the
abstract point is currenly on, but you can specify a different
abstract by prefixing the command with a number.  For example,
  7 x
will fire up your browser to the arXiv version of the seventh
abstract in the list.

; Notes about the implementation:

1. As far as I know, ADS doesn't have an API for searching its
  database, and emacs doesn't have functionality to parse html.
  Since I don't want to implement a browser in emacs lisp, that
  leaves me parsing the html pages with regexps.  While that would
  be a terrible idea under ordinary circumstances, the ADS pages
  are all automatically generated, so they should conform to a
  pretty regular format.  That gives me some hope...

2. There are many ways you can customize the behaviour of biblurp.
   I define font-lock faces at the beginning of the file so you can
   add these to your color theme.  I also run a mode hook at the
   end of `bibslurp-mode', so you can inject your own code at that
   point.

; Installation:

Use package.el. You'll need to add MELPA to your archives:

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

Alternatively, you can just save this file and do the standard
(add-to-list 'load-path "/path/to/bibslurp.el")
(require 'bibslurp)
