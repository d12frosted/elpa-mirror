;;; xah-get-thing.el --- get thing or selection at point. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2011-2021 by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 2.4.20210828120308
;; Package-Version: 20210828.1913
;; Package-Commit: 849683fa055afc982af4811f89998281ffe99315
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
;; xah-get-thing-or-region

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

;; To install manually, place this file in the directory ~/.emacs.d/lisp/
;; Then, add the following in your emacs lisp init:
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; Then, in elisp code where you want to use it, add
;; (require 'xah-get-thing)

;;; HISTORY

;; xah-get-thing-at-cursor (deprecated), xah-get-thing-or-selection (deprecated)
;; 2015-05-22 changes won't be logged here anymore, unless incompatible ones.
;; version 1.0, 2015-05-22 was {unit-at-cursor, get-selection-or-unit} from xeu_elisp_util.el


;;; Code:

(defun xah-get-bounds-of-thing (Unit)
  "Return the boundary of Unit under cursor.
Return a cons cell (START . END).
Unit can be:
• 'word → sequence of 0 to 9, A to Z, a to z, and hyphen.
• 'glyphs → sequence of visible glyphs. Useful for file name, URL, …, anything doesn't have white spaces in it.
• 'line → delimited by “\\n”. (captured text does not include “\\n”.)
• 'block → delimited by empty lines or beginning/end of buffer. Lines with just spaces or tabs are also considered empty line. (captured text does not include a ending “\\n”.)
• 'buffer → whole buffer. (respects `narrow-to-region')
• 'filepath → delimited by chars that's usually not part of filepath.
• 'url → delimited by chars that's usually not part of URL.
• 'inDoubleQuote → between double quote chars.
• 'inSingleQuote → between single quote chars.
• a vector [beginRegex endRegex] → The elements are regex strings used to determine the beginning/end of boundary chars. They are passed to `skip-chars-backward' and `skip-chars-forward'. For example, if you want paren as delimiter, use [\"^(\" \"^)\"]

This function is similar to `bounds-of-thing-at-point'.
The main difference are:

• This function's behavior does not depend on syntax table. e.g. for Units 「'word」, 「'block」, etc.
• 'line always returns the line without end of line character, avoiding inconsistency when the line is at end of buffer.
• Support certain “thing” such as 'glyphs that's a sequence of chars. Useful as file path or url in html links, but do not know which before hand.
• Some “thing” such 'url and 'filepath considers strings that at usually used for such. The algorithm that determines this is different from thing-at-point.

Version 2017-05-27 2021-07-23 2021-08-11"
  (let (($p0 (point)) $p1 $p2)
    (save-excursion
      (cond
       ((eq Unit 'block)
        (progn
          (setq $p1 (if (re-search-backward "\n[ \t]*\n" nil "move")
                        (goto-char (match-end 0))
                      (point)))
          (setq $p2 (if (re-search-forward "\n[ \t]*\n" nil "move")
                        (match-beginning 0)
                      (point)))))

       ((eq Unit 'filepath)
        (let (($delimitors "^  \"\t\n'|()[]{}<>〔〕“”〈〉《》【】〖〗«»‹›·。\\`"))
          (skip-chars-backward $delimitors)
          (setq $p1 (point))
          (goto-char $p0)
          (skip-chars-forward $delimitors)
          (setq $p2 (point))))

       ((eq Unit 'url)
        (let ( ($delimitors "^  \t\n\"`'‘’“”|[]{}<>。\\"))
          (skip-chars-backward $delimitors)
          (setq $p1 (point))
          (goto-char $p0)
          (skip-chars-forward $delimitors)
          (setq $p2 (point))))

       ((eq Unit 'inDoubleQuote)
        (progn
          (skip-chars-backward "^\"")
          (setq $p1 (point))
          (goto-char $p0)
          (skip-chars-forward "^\"")
          (setq $p2 (point))))

       ((eq Unit 'inSingleQuote)
        (progn
          (skip-chars-backward "^\"")
          (setq $p1 (point))
          (goto-char $p0)
          (skip-chars-forward "^\"")
          (setq $p2 (point))))

       ((vectorp Unit)
        (progn
          (skip-chars-backward (elt Unit 0))
          (setq $p1 (point))
          (goto-char $p0)
          (skip-chars-forward (elt Unit 1))
          (setq $p2 (point))))

       ( (eq Unit 'word)
         (let ((wordcharset "-A-Za-z0-9ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"))
           (skip-chars-backward wordcharset)
           (setq $p1 (point))
           (skip-chars-forward wordcharset)
           (setq $p2 (point))))
       ( (eq Unit 'glyphs)
         (progn
           (skip-chars-backward "[:graph:]")
           (setq $p1 (point))
           (skip-chars-forward "[:graph:]")
           (setq $p2 (point))))
       ((eq Unit 'buffer)
        (progn
          (setq $p1 (point-min))
          (setq $p2 (point-max))))
       ((eq Unit 'line)
        (progn
          (setq $p1 (line-beginning-position))
          (setq $p2 (line-end-position))))))
    (cons $p1 $p2 )))

(defun xah-get-bounds-of-thing-or-region (Unit)
  "If region is active, return its boundary, else same as `xah-get-bounds-of-thing'.
Version 2016-10-18 2021-08-11"
  (if (region-active-p)
      (cons (region-beginning) (region-end))
    (xah-get-bounds-of-thing Unit)))

(defun xah-get-thing-or-region (Unit)
  "If region is active, return its boundary, else return the thing at point.
See `xah-get-bounds-of-thing' for Unit.
Version 2021-08-11"
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (let (($bds (xah-get-bounds-of-thing Unit)))
      (buffer-substring-no-properties (car $bds) (cdr $bds)))))

(defun xah-get-thing-at-point (Unit)
  "Return the thing at point.
See `xah-get-bounds-of-thing' for Unit.
Version 2016-10-18 2021-08-11"
  (let ( ($bds (xah-get-bounds-of-thing Unit)) )
    (buffer-substring-no-properties (car $bds) (cdr $bds))))

(provide 'xah-get-thing)

;;; xah-get-thing.el ends here
