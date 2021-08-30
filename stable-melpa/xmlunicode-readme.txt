This file provides a suite of functions designed to make it easier
to enter Unicode into Emacs. It is not, in fact, particularly XML-specific though
it does define an 'xml input-mode and does support the ISO 8879 entity names.

; Usage

1. By default, the entire Unicode character list (as defined in
   xmlunicode-character-list.el) will be loaded. You can tailor
   the selection of characters presented in the list by defining
   xmlunicode-character-list before loading xmlunicode. The
   xmlunicode-character-list is a list of triples of the form:

   (codepoint "unicode name" "iso name") ; iso name can be nil

   e.g.:   (defvar xmlunicode-character-list
            '(
              ;Codept   Unicode name                            ISO Name
              (#x000000 "NULL"                                   nil     )
              (#x000001 "START OF HEADING"                       nil     )
              ...
              (#x0000a0 "NO-BREAK SPACE"                         "nbsp"  )
              (#x0000a1 "INVERTED EXCLAMATION MARK"              "iexcl" )
              (#x0000a2 "CENT SIGN"                              "cent"  )
              ...))


2. Bind the functions defined in this file to keys you find convenient.

   The likely candidates are:

   xmlunicode-character-insert            insert a character by unicode name
                                          (with completion)
   xmlunicode-iso8879-character-insert    insert a character by ISO entity name
                                          (with completion)
   xmlunicode-smart-double-quote          inserts an appropriate double quote
   xmlunicode-smart-single-quote          inserts an appropriate single quote
   xmlunicode-character-menu-insert       choose special character from a popup menu
   xmlunicode-character-shortcut-insert   enter a two-character shortcut for a
                                          unicode character

   Helm integration is provided in `xmlunicode-helm.el`. For helm,
   use the function `xmlunicode-character-insert-helm`.

   You can also create a standard Emacs menu for the character menu list
   (instead of, or in addition to, the popup). To do that:

   (define-key APPROPRIATE-MAP [menu-bar unichar]
     (cons "UniChar" xmlunicode-character-menu-map))

   Where APPROPRIATE-MAP is the name of the Emacs keymap to bind into

3. If you want to use the xml input-mode, which provides automatic replacement for the
   ISO entity names:

   (set-input-method 'xml)

   in the appropriate context. Unlike sgml-input, xml-input only inserts the
   characters for which you have glyphs. It inserts other characters as numeric
   character references. (If you want to insert a literal character even if
   you don't have it in your fonts, use xmlunicode-character-insert or
   xmlunicode-iso8879-character-insert with a prefix.)

; Changes

v1.25 29 Aug 2021
  Added a progress message when loading the xmlunicode-character-alist.
  Fixed a few docstrings.
  Updated to Unicode 14.0.0d13.
v1.24 17 Jul 2021
  Changed the format of the xmlunicode-character-alist so that it's
  more useful for searching by adding the XML entity name and the
  hex codepoint to the displayed string. The performance of
  computing that alist is kind of bad, but I'm not sure how to
  improve it. In the meantime, I've reworked things so that it's
  only computed when it's first used, so you don't pay the cost at
  startup time.
v1.23 23 Aug 2020
  Fixed bug where xmlunicode-smart-hyphen didn't recognize the
  context "<!-" as the beginning of a comment and therefore that
  another "-" should be inserted rather than replacing the hyphen
  with an emdash. This was a consequence of changing
  xmlunicode-in-comment so that a bare "<!" wasn't recognized as
  the start of a comment.
v1.22 11 Aug 2020
  Fixed a bug in xmlunicode-in-comment where it would mistake the
  beginning of a CDATA section for the start of a comment.
  Removed deprecated 'cl package.
v1.21 24 Nov 2019
  Moved the helm-related functions into a separate file. Helm must be
  setup before you can require 'xmlunicode-helm. This avoids an ugly bug
  where (I infer) the byte compiled xmlunicode.el file did not have
  a correct function reference for `helm-build-sync-source` so it didn't
  work reliably.
  I made a few small improvements to `xmlunicode-show-character-list`.
v1.20 23 Nov 2019
  Fixed obvious typo in the name of the xmlunicode-iso8879-character-insert
  function name. (The xmlunicode prefix was repeated.)
v1.19
  Moved defun before defvar (WTF?). *blush*
v1.18
  Fixed bug where I failed to include the provide statement for the
  character list. *blush*
v1.17
  Updated the xmlunicode-character-list.el to Unicode 12.1.0 (from 3.1)
  Added helper scripts so that you can rebuild the list if you wish
  Removed xmlunicode-missing-list.el; whether or not characters are
  displayable is now computed dynamically
  (see xmlunicode-displayable-character).
v1.16
  Fixed the XML character input method so that it will leave
  &gt;, &lt; &amp; &quot; and &apos; alone.
v1.15
  Made the "smart" insert functions a little smarter; they only run
  the XML tests in an XML mode. Makes them easier and safer to use
  more globally.
  Added xmlunicode-default-single-quote so that you can change the
  default apostrophe (in places like contractions) to the rsquo.
v1.14
  Added codepoint to the helm character list
  Improved the xmlunicode-smart-hyphen function; just insert "-" if
  preceded by two "-"s.
v1.13
  Fix all symbol names to have 'xmlunicode-' namespace prefix.
  Added xmlunicode-character-insert-helm to use helm for character prompt
v1.12
  ???
v1.11
  Fix up some compile warnings and deprecations that modern Emacs
  reveals.  Also found a cut-n-paste bug in the ununsed
  unicode-to-codepoints.
v1.7
  Require "cl" because, well, because it's required. Also fiddled with
  the way single quotes are handled; the apostrophe is now part of the
  cycle
v1.6
  Remove debugging code. Embarrassed again. :-(
v1.5
  Fixed bug in unicode-smart-single-quote. It wasn't cycling through all
  three quotes correctly because of a typo in the function definition.
  Make sure smart semicolon insertion only happens if we're right at the
  end of a numeric character reference.
v1.4
  Fixed bug in insert-smart-semicolon. It wasn't careful to tie the search
  to the most recent preceding ampersand.
v1.3
  Fixed bug in (xmlunicode-in-comment)
  Added unicode-smart-semicolon as another convenience for entering Unicode chars
  Added show-unicode-character-list
v1.2
  Added unicode-smart-hyphen for easy insert of mdash and ndash
  Added unicode-smart-period for easy insert of hellip
  Fixed a bug in unicode-smart-single-quote
v1.1
  Fixed a few bugs with respect to how numeric character references are entered.
  Added xml-tag-search-limit and unicode-charref-format
v1.0
  First release. Nearly a complete rewrite from the former xmlchars.el file
