;;; highlight-refontification.el --- Visualize font-lock refontification.

;; Copyright (C) 2014-2017 Anders Lindgren

;; Author: Anders Lindgren
;; Keywords: faces, tools
;; Created: 2014-05-15
;; Version: 0.0.3
;; URL: https://github.com/Lindydancer/highlight-refontification

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Minor mode that visualizes how font-lock refontifies a buffer.
;; This is useful when developing or debugging font-lock keywords,
;; especially for keywords that span multiple lines.
;;
;; The background of the buffer is painted in a rainbow of colors,
;; where each band in the rainbow represent a region of the buffer
;; that has been refontified.  When the buffer is modified, the
;; rainbow is updated.

;; Screenshot:
;;
;; ![See doc/demo.png for screenshot](doc/demo.png)

;; Background:
;;
;; When you edit a file, font-lock mode recalculates syntax
;; highlighting as you type.  Clearly, this process must be fast.  If
;; not, Emacs would appear to be slow.  For this reason, as little as
;; possible is refontified, often only the line that was edited.  Once
;; Emacs is idle, a larger section is refontified.
;;
;; Unfortunately, some font-lock keywords doesn't work correctly when
;; applied to region which is too small.

;; Examples:
;;
;; You can use this tool, for example, to:
;;
;; - Investigate when font-lock makes Emacs slow.  If a large region is
;;   refontified for every character typed, could cause this.
;;
;; - Investigate why a font-lock rule sometimes work, sometimes
;;   doesn't.  One cause of this could be that the region starts in
;;   the middle of the language construct that should be highlighted.
;;
;; - Investigate "blinking" syntax highlighting, i.e. the effect where
;;   one color is first applied, and after, say, half a second,
;;   another is applied.

;; The refontification process:
;;
;; When font-lock decides to update a region, it calls the functions
;; in `font-lock-extend-region-functions'.  Each function can extend
;; the region.  For example, when `font-lock-multiline' is enabled,
;; the function `font-lock-extend-region-multiline' is included.  It
;; will extend the region to include all the lines of something that
;; previously was matched in a multiline rule.

;; Usage:
;;
;; - `M-x highlight-refontification-mode RET' -- When this mode is
;;   enabled, any change in the buffer is visualized by a change in
;;   the background color.
;;
;; - `M-x highlight-refontification-list-extend-region-steps RET' --
;;   Print the steps font-lock would take to extend a region.

;; Other Font Lock Tools:
;;
;; This package is part of a suite of font-lock tools.  The other
;; tools in the suite are:
;;
;;
;; Font Lock Studio:
;;
;; Interactive debugger for font-lock keywords (Emacs syntax
;; highlighting rules).
;;
;; Font Lock Studio lets you *single-step* Font Lock keywords --
;; matchers, highlights, and anchored rules, so that you can see what
;; happens when a buffer is fontified.  You can set *breakpoints* on or
;; inside rules and *run* until one has been hit.  When inside a rule,
;; matches are *visualized* using a palette of background colors.  The
;; *explainer* can describe a rule in plain-text English.  Tight
;; integration with *Edebug* allows you to step into Lisp expressions
;; that are part of the Font Lock keywords.
;;
;;
;; Font Lock Profiler:
;;
;; A profiler for font-lock keywords.  This package measures time and
;; counts the number of times each part of a font-lock keyword is
;; used.  For matchers, it counts the total number and the number of
;; successful matches.
;;
;; The result is presented in table that can be sorted by count or
;; time.  The table can be expanded to include each part of the
;; font-lock keyword.
;;
;; In addition, this package can generate a log of all font-lock
;; events.  This can be used to verify font-lock implementations,
;; concretely, this is used for back-to-back tests of the real
;; font-lock engine and Font Lock Studio, an interactive debugger for
;; font-lock keywords.
;;
;;
;; Faceup:
;;
;; Emacs is capable of highlighting buffers based on language-specific
;; `font-lock' rules.  This package makes it possible to perform
;; regression test for packages that provide font-lock rules.
;;
;; The underlying idea is to convert text with highlights ("faces")
;; into a plain text representation using the Faceup markup
;; language.  This language is semi-human readable, for example:
;;
;;     «k:this» is a keyword
;;
;; By comparing the current highlight with a highlight performed with
;; stable versions of a package, it's possible to automatically find
;; problems that otherwise would have been hard to spot.
;;
;; This package is designed to be used in conjunction with Ert, the
;; standard Emacs regression test system.
;;
;; The Faceup markup language is a generic markup language, regression
;; testing is merely one way to use it.
;;
;;
;; Font Lock Regression Suite:
;;
;; A collection of example source files for a large number of
;; programming languages, with ERT tests to ensure that syntax
;; highlighting does not accidentally change.
;;
;; For each source file, font-lock reference files are provided for
;; various Emacs versions.  The reference files contains a plain-text
;; representation of source file with syntax highlighting, using the
;; format "faceup".
;;
;; Of course, the collection source file can be used for other kinds
;; of testing, not limited to font-lock regression testing.

;;; Code:

;; ------------------------------------------------------------
;; The minor mode.
;;

(defvar highlight-refontification-keywords
  '((highlight-refontification-matcher))
  "Font-lock keywords for `highlight-refontification-mode'.")

(defvar highlight-refontification-index nil
  "Current index into `highlight-refontification-colors'.

This variable is incremented for each refontification.  When
larger than the length of `highlight-refontification-colors', it
is set to 0.")
(make-variable-buffer-local 'highlight-refontification-index)

(defvar highlight-refontification-colors '("chartreuse1"
                                           "tan1"
                                           "PaleTurquoise2"
                                           "gold1"
                                           "grey85"
                                           "OliveDrab2"
                                           "Yellow")
  "List of colors `highlight-refontification-mode' cycles through.")

(defun highlight-refontification-matcher (limit)
  "Font-lock matcher for `highlight-refontification-mode'.

As a side effect, this colors the background between point and
LIMIT in a rainbow of colors, one color each time font-lock
refontifies a region."
  (remove-overlays (point) limit 'highlight-refontification t)
  (let ((o (make-overlay (point) limit (current-buffer)))
        (color (highlight-refontification-next-color)))
    ;; Exclude colors of neighbouring regions.
    (while (member color (list
                          (highlight-refontification-color-at (- (point) 1))
                          (highlight-refontification-color-at (+ limit 1))))
      (setq color (highlight-refontification-next-color)))
    (overlay-put o 'highlight-refontification t)
    (overlay-put o
                 'face
                 (list :background color)))
  ;; Always "fail" to find anything.
  nil)


(defun highlight-refontification-next-color ()
  "The next color to be used to highlight the background."
  (prog1
      (nth highlight-refontification-index
           highlight-refontification-colors)
    (setq highlight-refontification-index
          (mod (+ 1 highlight-refontification-index)
               (length highlight-refontification-colors)))))


(defun highlight-refontification-color-at (pos)
  "The previous background color at POS, or nil."
  (let ((res nil))
    (dolist (o (overlays-at pos))
      (when (overlay-get o 'highlight-refontification)
        (setq res (nth 1 (overlay-get o 'face)))))
    res))

;;;###autoload
(define-minor-mode highlight-refontification-mode
  "Minor mode that highlight bad whitespace and out-of-place characters."
  nil
  nil
  nil
  :group 'highlight-refontification
  (if highlight-refontification-mode
      (highlight-refontification-font-lock-add-keywords)
    (highlight-refontification-font-lock-remove-keywords))
  (when font-lock-mode
    ;; As of Emacs 25, `font-lock-fontify-buffer' is not legal to
    ;; call, instead `font-lock-flush' should be used.
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (when font-lock-mode
        (with-no-warnings
          (font-lock-fontify-buffer))))))


(defun highlight-refontification-font-lock-add-keywords ()
  "Install Highlight Refontification mode keywords into current buffer."
  (setq highlight-refontification-index 0)
  (font-lock-add-keywords nil highlight-refontification-keywords t))


(defun highlight-refontification-font-lock-remove-keywords ()
  "Remove Highlight Refontification mode keywords in current buffer."
  (font-lock-remove-keywords nil highlight-refontification-keywords)
  (remove-overlays (point-min) (point-max) 'highlight-refontification t))


;; ------------------------------------------------------------
;; List extend region operations.
;;


(defun highlight-refontification-list-extend-region-steps (&optional
                                                           beg end)
  "List how font-lock would extend the region between BEG and END.

BEG and END is the start and end of the area.  When nil or
omitted, the current line is used.

When called interactively, the region is used if visible and the
current line otherwise."
  (interactive (if (use-region-p)
                   (list (region-beginning)
                         (region-end))
                 (list nil nil)))
  (unless beg
    (setq beg (line-beginning-position)))
  (unless end
    (setq end (+ (line-end-position) 1)))
  (with-output-to-temp-buffer "*ExtendRegion*"
      (let ((funs font-lock-extend-region-functions)
            (font-lock-beg beg)
            (font-lock-end end))
        (princ (format "Initial: (beg=%d end=%d)\n"
                       font-lock-beg
                       font-lock-end))
        (while funs
          (princ (format "Calling `%s' (beg=%d end=%d)\n"
                         (car funs)
                         font-lock-beg
                         font-lock-end))
          (let ((res (funcall (car funs))))
            (when res
              (princ (format "  Changed region to (beg=%d end=%d)\n"
                             font-lock-beg
                             font-lock-end)))
            (setq funs (if (or (not res)
                               (eq funs font-lock-extend-region-functions))
                           (cdr funs)
                         ;; If there's been a change, we should go through
                         ;; the list again since this new position may
                         ;; warrant a different answer from one of the fun
                         ;; we've already seen.
                         font-lock-extend-region-functions))))
        (princ (format "Final: (beg=%d end=%d)\n"
                       font-lock-beg
                       font-lock-end)))))


;; -------------------------------------------------------------------
;; The end
;;

(provide 'highlight-refontification)

;;; highlight-refontification.el ends here
