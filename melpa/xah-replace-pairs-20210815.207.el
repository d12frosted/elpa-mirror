;;; xah-replace-pairs.el --- emacs lisp functions for multi-pair find/replace.  -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2010-2020, by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 2.5.20210814190611
;; Package-Version: 20210815.207
;; Package-Commit: b5e4f9ebc9e17916e736af9935bf4e17032edde9
;; Created: 17 Aug 2010
;; Package-Requires: ((emacs "24.1"))
;; Keywords: lisp, tools, find replace
;; License: GPL v3
;; URL: http://ergoemacs.org/emacs/elisp_replace_string_region.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package provides elisp functions that do find/replace with multiple pairs of strings. and guarantees that earlier find/replace pair does not effect later find/replace pairs.

;; The functions are:

;; xah-replace-pairs-region
;; xah-replace-pairs-in-string
;; xah-replace-regexp-pairs-region
;; xah-replace-regexp-pairs-in-string
;; xah-replace-pairs-region-recursive
;; xah-replace-pairs-in-string-recursive

;; Call `describe-function' on them for detail.

;; Or, see home page at
;; http://ergoemacs.org/emacs/elisp_replace_string_region.html

;; If you like it, please support by Buy Xah Emacs Tutorial
;; http://ergoemacs.org/emacs/buy_xah_emacs_tutorial.html
;; Thanks.

;;; History:

;; 2015-04-28 major rewrite. This package was xfrp_find_replace_pairs
;; version 1.0, 2010-08-17. First version.


;;; Code:

(defun xah-replace-pairs-region (@begin @end @pairs &optional @report-p @hilight-p)
  "Replace multiple @pairs of find/replace strings in region @begin @end.

@pairs is a sequence of pairs [[f1 r1] [f2 r2] …] each element or entire argument can be list or vector. f are find string, r are replace string.

Find strings case sensitivity depends on `case-fold-search'. The replacement are literal and case sensitive.

Once a subsring in the buffer is replaced, that part will not change again.  For example, if the buffer content is “abcd”, and the @pairs are a → c and c → d, then, result is “cbdd”, not “dbdd”.

@report-p is t or nil. If t, it prints each replaced pairs, one pair per line.

Returns a list, each element is a vector [position findStr replaceStr].

Version 2020-12-18"
  (let ( ($tempMapPoints nil) ($changeLog nil))
    ;; set $tempMapPoints, to unicode private use area chars
    (dotimes (i (length @pairs)) (push (char-to-string (+ #xe000 i)) $tempMapPoints))
    ;; (message "%s" @pairs)
    ;; (message "%s" $tempMapPoints)
    (save-excursion
      (save-restriction
        (narrow-to-region @begin @end)
        (dotimes (i (length @pairs))
          (goto-char (point-min))
          (while (search-forward (elt (elt @pairs i) 0) nil t)
            (replace-match (elt $tempMapPoints i) t t)))
        (dotimes (i (length @pairs))
          (goto-char (point-min))
          (while (search-forward (elt $tempMapPoints i) nil t)
            (push (vector (point)
                          (elt (elt @pairs i) 0)
                          (elt (elt @pairs i) 1)) $changeLog)
            (replace-match (elt (elt @pairs i) 1) t t)
            (when @hilight-p
              (overlay-put (make-overlay (match-beginning 0) (match-end 0)) 'face 'highlight))))))
    (when (and @report-p (> (length $changeLog) 0))
      (mapc
       (lambda ($x)
         (princ $x)
         (terpri))
       (reverse $changeLog)))
    $changeLog
    ))

(defun xah-replace-pairs-in-string (@str @pairs)
  "Replace string @str by find/replace @pairs sequence.
Returns the new string.
This function is a wrapper of `xah-replace-pairs-region'. See there for detail."
  (with-temp-buffer
    (insert @str)
    (xah-replace-pairs-region (point-min) (point-max) @pairs)
    (buffer-string)))

(defun xah-replace-regexp-pairs-region (@begin @end @pairs &optional @fixedcase-p @literal-p @hilight-p)
  "Replace regex string find/replace @pairs in region.

@begin @end are the region boundaries.

@pairs is
 [[regexStr1 replaceStr1] [regexStr2 replaceStr2] …]
It can be list or vector, for the elements or the entire argument.

The optional arguments @fixedcase-p and @literal-p is the same as in `replace-match'.
If @hilight-p is true, highlight the changed region.

Find strings case sensitivity depends on `case-fold-search'. You can set it locally, like this: (let ((case-fold-search nil)) …)
Version 2017-02-21 2021-08-14"
  (save-excursion
    (save-restriction
      (narrow-to-region @begin @end)
      (mapc
       (lambda ($x)
         (goto-char (point-min))
         (while (re-search-forward (elt $x 0) (point-max) t)
           (replace-match (elt $x 1) @fixedcase-p @literal-p)
           (when @hilight-p
             (overlay-put (make-overlay (match-beginning 0) (match-end 0)) 'face 'highlight))))
       @pairs))))

(defun xah-replace-regexp-pairs-in-string (@str @pairs &optional @fixedcase-p @literal-p)
  "Replace string @str recursively by regex find/replace pairs @pairs sequence.

This function is a wrapper of `xah-replace-regexp-pairs-region'. See there for detail.

See also `xah-replace-pairs-in-string'."
  (with-temp-buffer
    (insert @str)
    (goto-char (point-min))
    (xah-replace-regexp-pairs-region (point-min) (point-max) @pairs @fixedcase-p @literal-p)
    (buffer-string)))

(defun xah-replace-pairs-region-recursive (@begin @end @pairs)
  "Replace multiple @pairs of find/replace strings in region @begin @end.

This function is similar to `xah-replace-pairs-region', except that the replacement is done recursively after each find/replace pair.  Earlier replaced value may be replaced again.

For example, if the input string is “abcd”, and the pairs are a → c and c → d, then, the result is “dbdd”, not “cbdd”.

Find strings case sensitivity depends on `case-fold-search'. You can set it locally, like this: (let ((case-fold-search nil)) …)

The replacement are literal and case sensitive.
Version 2017-02-21 2021-08-14"
  (save-excursion
    (save-restriction
      (narrow-to-region @begin @end)
      (mapc
       (lambda (x)
         (goto-char (point-min))
         (while (search-forward (elt x 0) (point-max) t)
           (replace-match (elt x 1) t t)))
       @pairs))))

(defun xah-replace-pairs-in-string-recursive (@str @pairs)
  "Replace string @str recursively by find/replace pairs @pairs sequence.

This function is is a wrapper of `xah-replace-pairs-region-recursive'. See there for detail."
  (with-temp-buffer
    (insert @str)
    (goto-char (point-min))
    (xah-replace-pairs-region-recursive (point-min) (point-max) @pairs)
    (buffer-string)))

(provide 'xah-replace-pairs)

;;; xah-replace-pairs.el ends here
