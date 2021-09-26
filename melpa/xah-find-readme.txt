Provides emacs commands for find/replace text of files in a directory, written entirely in emacs lisp.

This package provides these commands:

xah-find-text
xah-find-text-regex
xah-find-count
xah-find-replace-text
xah-find-replace-text-regex

• Pure emacs lisp. No dependencies on unix/linux grep/sed/find. Especially useful on Windows.

• Output is highlighted and clickable for jumping to occurrence.

• Using emacs regex, not bash/perl etc regex.

These commands treats find/replace string as sequence of chars, not as lines as in grep/sed, so it's easier to find or replace a text containing lots newlines, especially programming language source code.

• Reliably Find/Replace string that contains newline chars.

• Reliably Find/Replace string that contains lots Unicode chars. See http://xahlee.info/comp/unix_uniq_unicode_bug.html and http://ergoemacs.org/emacs/emacs_grep_problem.html

• Reliably Find/Replace string that contains lots escape slashes or backslashes. For example, regex in source code, Microsoft Windows' path.

The result output is also not based on lines. Instead, visual separators are used for easy reading.

For each occurrence or replacement, n chars will be printed before and after. The number of chars to show is defined by `xah-find-context-char-count-before' and `xah-find-context-char-count-after'

Each “block of text” in output is one occurrence.
For example, if a line in a file has 2 occurrences, then the same line will be reported twice, as 2 “blocks”.
so, the number of blocks corresponds exactly to the number of occurrences.

Keys
-----------------------
TAB             xah-find-next-match
<backtab>       xah-find-previous-match

RET             xah-find--jump-to-place
<mouse-1>       xah-find--mouse-jump-to-place

<left>          xah-find-previous-match
<right>         xah-find-next-match

<down>          xah-find-next-file
<up>            xah-find-previous-file

M-n             xah-find-next-file
M-p             xah-find-previous-file

IGNORE DIRECTORIES

By default, .git dir is ignored. You can add to it by adding the following in your init:

(setq
 xah-find-dir-ignore-regex-list
 [
  "\\.git/"
   ; more regex here. regex is matched against file full path
  ])

USE CASE

To give a idea what file size, number of files, are practical, here's my typical use pattern:
• 5 thousand HTML files match file name regex.
• Each HTML file size are usually less than 200k bytes.
• search string length have been up to 13 lines of text.

Homepage: http://ergoemacs.org/emacs/elisp-xah-find-text.html

Like it?
Buy Xah Emacs Tutorial
http://ergoemacs.org/emacs/buy_xah_emacs_tutorial.html
Thank you.

; INSTALL

To install manually, place this file in the directory [~/.emacs.d/lisp/]

Then, place the following code in your emacs init file

(add-to-list 'load-path "~/.emacs.d/lisp/")
(autoload 'xah-find-text "xah-find" "find replace" t)
(autoload 'xah-find-text-regex "xah-find" "find replace" t)
(autoload 'xah-find-replace-text "xah-find" "find replace" t)
(autoload 'xah-find-replace-text-regex "xah-find" "find replace" t)
(autoload 'xah-find-count "xah-find" "find replace" t)

; HISTORY

version 2.1.0, 2015-05-30 Complete rewrite.
version 1.0, 2012-04-02 First version.

; CONTRIBUTOR
2015-12-09 Peter Buckley (dx-pbuckley). defcustom for result highlight color.

HHH___________________________________________________________________
