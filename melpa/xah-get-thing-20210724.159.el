;;; xah-get-thing.el --- get thing or selection at point. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2011-2021 by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 2.2.20210723185706
;; Package-Version: 20210724.159
;; Package-Commit: 4f9041e7231108bc86ce722c623884146973343b
;; Created: 22 May 2015
;; Package-Requires: ((emacs "24.1"))
;; Keywords: extensions, lisp, tools
;; License: GPL v3
;; URL: http://ergoemacs.org/emacs/elisp_get-selection-or-unit.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package provides functions similar to `thing-at-point' of `thingatpt.el'.

;; The functions are:

;; xah-get-bounds-of-thing
;; xah-get-bounds-of-thing-or-region
;; xah-get-thing-at-point

;; They are useful for writing commands that act on text selection if there's one, or current {symbol, block, …} under cursor.

;; This package is similar to emac's builtin thing-at-point package thingatpt.el.

;; The main differences are:

;; • Is not based on syntax table. So, the “thing” are predicable in any major mode.
;; • provides the 'block, which is similar to emacs's 'paragraph, but strictly defined by between blank lines.
;; • xah-get-bounds-of-thing-or-region Returns the boundary of region, if active. This saves you few lines of code.
;; • Thing 'url and 'filepath, are rather different from how thingatpt.el determines them, and, again, is not based on syntax table, but based on regex of likely characters. Also, result is never modified version of what's in the buffer. For example, if 'url, the http prefix is not automatically added if it doesn't exist in buffer.
;; • Thing 'line never includes newline character. This avoid inconsistency when line is last line.

;; The return values of these functions is the same format as emacs's thingatpt.el, so you can just drop-in replace by changing the function names in your code.

;; Home page: http://ergoemacs.org/emacs/elisp_get-selection-or-unit.html

;;; Install:

;; To install manually, place this file in the directory 〔~/.emacs.d/lisp/〕.
;; Then, add the following in your emacs lisp init:
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; Then, in elisp code where you want to use it, add
;; (require 'xah-get-thing)

;;; HISTORY

;; xah-get-thing-at-cursor (deprecated), xah-get-thing-or-selection (deprecated)
;; 2015-05-22 changes won't be logged here anymore, unless incompatible ones.
;; version 1.0, 2015-05-22 was {unit-at-cursor, get-selection-or-unit} from xeu_elisp_util.el


;;; Code:

(defun xah-get-bounds-of-thing (@unit )
  "Return the boundary of @UNIT under cursor.
Return a cons cell (START . END).
@UNIT can be:
• 'word — sequence of 0 to 9, A to Z, a to z, and hyphen.
• 'glyphs — sequence of visible glyphs. Useful for file name, URL, …, anything doesn't have white spaces in it.
• 'line — delimited by “\\n”. (captured text does not include “\\n”.)
• 'block — delimited by empty lines or beginning/end of buffer. Lines with just spaces or tabs are also considered empty line. (captured text does not include a ending “\\n”.)
• 'buffer — whole buffer. (respects `narrow-to-region')
• 'filepath — delimited by chars that's USUALLY not part of filepath.
• 'url — delimited by chars that's USUALLY not part of URL.
• 'inDoubleQuote — between double quote chars.
• 'inSingleQuote — between single quote chars.
• a vector [beginRegex endRegex] — The elements are regex strings used to determine the beginning/end of boundary chars. They are passed to `skip-chars-backward' and `skip-chars-forward'. For example, if you want paren as delimiter, use [\"^(\" \"^)\"]

This function is similar to `bounds-of-thing-at-point'.
The main difference are:

• This function's behavior does not depend on syntax table. e.g. for @units 「'word」, 「'block」, etc.
• 'line always returns the line without end of line character, avoiding inconsistency when the line is at end of buffer.
• Support certain “thing” such as 'glyphs that's a sequence of chars. Useful as file path or url in html links, but do not know which before hand.
• Some “thing” such 'url and 'filepath considers strings that at USUALLY used for such. The algorithm that determines this is different from thing-at-point.

Version 2017-05-27 2021-07-23"
  (let ((p0 (point)) p1 p2)
    (save-excursion
      (cond
       ( (eq @unit 'word)
         (let ((wordcharset "-A-Za-z0-9ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"))
           (skip-chars-backward wordcharset)
           (setq p1 (point))
           (skip-chars-forward wordcharset)
           (setq p2 (point))))
       ( (eq @unit 'glyphs)
         (progn
           (skip-chars-backward "[:graph:]")
           (setq p1 (point))
           (skip-chars-forward "[:graph:]")
           (setq p2 (point))))
       ((eq @unit 'buffer)
        (progn
          (setq p1 (point-min))
          (setq p2 (point-max))))
       ((eq @unit 'line)
        (progn
          (setq p1 (line-beginning-position))
          (setq p2 (line-end-position))))
       ((eq @unit 'block)
        (progn
          (if (re-search-backward "\n[ \t]*\n" nil "move")
              (progn (re-search-forward "\n[ \t]*\n")
                     (setq p1 (point)))
            (setq p1 (point)))
          (if (re-search-forward "\n[ \t]*\n" nil "move")
              (progn (re-search-backward "\n[ \t]*\n")
                     (setq p2 (point)))
            (setq p2 (point)))))
       ((eq @unit 'filepath)
        (let (($delimitors "^  \"\t\n'|()[]{}<>〔〕“”〈〉《》【】〖〗«»‹›·。\\`"))
          ;; chars that are likely to be delimiters of full path, e.g. space, tabs, brakets.
          (skip-chars-backward $delimitors)
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward $delimitors)
          (setq p2 (point))))
       ((eq @unit 'url)
        (let ( ($delimitors "!\"#$%&'*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"))
          (setq p0 (point))
          (skip-chars-backward $delimitors) ;"^ \t\n,([{<>〔“\""
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward $delimitors) ;"^ \t\n,)]}<>〕\"”"
          (setq p2 (point))))
       ;; • 'filepath-or-url — either file path or URL, with heuristics to detect which sequences of chars to grab. They cannot be distinguished correctly by just lexical form. For example, URL usually contains the colon, but file path not. Sometimes you need this, for example, the value of “href” attribute, which can be just a file path (e.g. relative path) or URL (e.g. http://example.com/)
       ;; ((eq @unit 'filepath-or-url)
       ;;  (let ( $input
       ;;        (case-fold-search nil)
       ;;        ($delimitors "!\"#$%&'*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"))
       ;;    (setq p0 (point))
       ;;    (skip-chars-backward $delimitors) ;"^ \t\n,([{<>〔“\""
       ;;    (setq p1 (point))
       ;;    (goto-char p0)
       ;;    (skip-chars-forward $delimitors) ;"^ \t\n,)]}<>〕\"”"
       ;;    (setq p2 (point))
       ;;    (setq $input (buffer-substring-no-properties p1 p2))
       ;;    (if (string-match "`http\\|`file" $input &optional START)
       ;;        (progn )
       ;;      (progn ))))
       ((eq @unit 'inDoubleQuote)
        (progn
          (skip-chars-backward "^\"")
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward "^\"")
          (setq p2 (point))))
       ((eq @unit 'inSingleQuote)
        (progn
          (skip-chars-backward "^\"")
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward "^\"")
          (setq p2 (point))))
       ((vectorp @unit)
        (progn
          (skip-chars-backward (elt @unit 0))
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward (elt @unit 1))
          (setq p2 (point))))))
    (cons p1 p2 )))

(defun xah-get-bounds-of-thing-or-region (@unit)
  "Same as `xah-get-bounds-of-thing', except when (use-region-p) is t, return the region boundary instead.
Version 2016-10-18"
  (if (use-region-p)
      (cons (region-beginning) (region-end))
    (xah-get-bounds-of-thing @unit)))

(defun xah-get-thing-at-point (@unit)
  "Same as `xah-get-bounds-of-thing', but return the string.
Version 2016-10-18T02:31:36-07:00"
  (let ( ($bds (xah-get-bounds-of-thing @unit)) )
    (buffer-substring-no-properties (car $bds) (cdr $bds))))

(defun xah-get-thing-at-cursor (@unit)
  "Same as `xah-get-bounds-of-thing', except this returns a vector [text a b], where text is the string and a b are its boundary.

Version 2016-10-18T00:23:52-07:00"
  (let* (
         ($bds (xah-get-bounds-of-thing @unit))
         ($p1 (car $bds)) ($p2 (cdr $bds)))
    (vector (buffer-substring-no-properties $p1 $p2) $p1 $p2 )))

(make-obsolete 'xah-get-thing-at-cursor 'xah-get-thing-at-point "2016-10-18")

(defun xah-get-thing-or-selection (@unit)
  "Same as `xah-get-bounds-of-thing-or-region', except returns a vector [text a b], where text is the string and a b are its boundary."
  (interactive)
  (let* (
         ($bds (xah-get-bounds-of-thing-or-region @unit))
         ($p1 (car $bds)) ($p2 (cdr $bds)))
    (vector (buffer-substring-no-properties $p1 $p2) $p1 $p2 )))

(make-obsolete 'xah-get-thing-or-selection 'xah-get-bounds-of-thing-or-region "2016-10-18")

(provide 'xah-get-thing)

;;; xah-get-thing.el ends here
