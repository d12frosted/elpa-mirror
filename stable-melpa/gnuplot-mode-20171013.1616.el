;;; gnuplot-mode.el --- Major mode for editing gnuplot scripts

;; Copyright (C) 2010-2013 Mike McCourt
;;
;; Authors: Mike McCourt <mkmcc@astro.berkeley.edu>
;; URL: https://github.com/mkmcc/gnuplot-mode
;; Package-Version: 20171013.1616
;; Package-Commit: 601f6392986f0cba332c87678d31ae0d0a496ce7
;; Version: 1.2.0
;; Keywords: gnuplot, plotting

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Defines a major mode for editing gnuplot scripts.  I wanted to keep
;; it simpler than other modes -- just syntax highlighting, indentation,
;; and a command to plot the file.

;; Some of this code is adapted from a more full-featured version by
;; Bruce Ravel (available here https://github.com/bruceravel/gnuplot-mode;
;; GPLv2).

;; Thanks to everyone, including Christopher Gilbreth and Ralph Möritz,
;; for sending suggestions, improvements, and fixes.

;;; Installation:

;; Use package.el. You'll need to add MELPA to your archives:

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)

;; Alternatively, you can just save this file and do the standard
;; (add-to-list 'load-path "/path/to/gnuplot-mode.el")

;;; Configuration:

;; If you installed this via `package.el', you should take advantage
;; of autoloading.  You can customize features using `defvar' and
;; `eval-after-load', as illustrated below:
;;
;; ;; specify the gnuplot executable (if other than "gnuplot")
;; (defvar gnuplot-program "/sw/bin/gnuplot")
;;
;; ;; set gnuplot arguments (if other than "-persist")
;; (defvar gnuplot-flags "-persist -pointsize 2")
;;
;; ;; if you want, add a mode hook.  e.g., the following turns on
;; ;; spell-checking for strings and comments and automatically cleans
;; ;; up whitespace on save.
;; (eval-after-load 'gnuplot-mode
;;   '(add-hook 'gnuplot-mode-hook
;;              (lambda ()
;;                (flyspell-prog-mode)
;;                (add-hook 'before-save-hook
;;                          'whitespace-cleanup nil t))))

;; If you installed this file manually, you probably don't want to
;; muck around with autoload commands.  Instead, add something like
;; the following to your .emacs:

;; (require 'gnuplot-mode)
;;
;; ;; specify the gnuplot executable (if other than "gnuplot")
;; (setq gnuplot-program "/sw/bin/gnuplot")
;;
;; ;; set gnuplot arguments (if other than "-persist")
;; (setq gnuplot-flags "-persist -pointsize 2")
;;
;; ;; if you want, add a mode hook.  e.g., the following turns on
;; ;; spell-checking for strings and comments and automatically cleans
;; ;; up whitespace on save.
;; (add-hook 'gnuplot-mode-hook
;;           (lambda ()
;;             (flyspell-prog-mode)
;;             (add-hook 'before-save-hook
;;                       'whitespace-cleanup nil t)))

;;; TODO:
;;  1. the indentation commands use regular expressions, which
;;     probably isn't ideal.  is it possible to rework them to use the
;;     syntax table?
;;

;;; Code:

;;; user-settable options:

(defvar gnuplot-program "gnuplot"
  "Command to run gnuplot.")

(defvar gnuplot-flags "-persist"
  "Flags to pass to gnuplot.")

(defvar gnuplot-mode-hook nil
  "Hook to run after `gnuplot-mode'.")

(defvar gnuplot-continued-commands-regexp
  (concat
   (regexp-opt '("splot" "plot" "fit") 'words)
   "\\(\\s-*\\[[^]]+]\\s-*\\)*")        ; optional range commands
  "Regexp which matches all commands which might continue over
multiple lines.  Used in `gnuplot-find-indent-column' and in
`gnuplot-last-line-p'.")

(defvar gnuplot-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x p")   'gnuplot-compile)
    (define-key map (kbd "C-c C-c") 'gnuplot-compile)
    (define-key map (kbd "C-c C-r") 'gnuplot-run-region)
    (define-key map (kbd "C-c C-b") 'gnuplot-run-buffer)
    map)
  "Keymap for `gnuplot-mode'.")

(defvar gnuplot-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?*  "."  st)
    (modify-syntax-entry ?+  "."  st)
    (modify-syntax-entry ?-  "."  st)
    (modify-syntax-entry ?/  "."  st)
    (modify-syntax-entry ?%  "."  st)
    (modify-syntax-entry ?'  "\"" st)
    (modify-syntax-entry ?`  "w"  st)
    (modify-syntax-entry ?_  "w"  st)
    (modify-syntax-entry ?#  "<"  st)
    (modify-syntax-entry ?\n ">"  st)
    st)
  "Syntax table for `gnuplot-mode'.")



;;; font lock.
;; first, define syntax types via explicit lists
(defvar gp-math-functions
  (regexp-opt
   '("abs"     "acos"   "acosh"    "arg"     "asin"
     "asinh"   "atan"   "atan2"    "atanh"   "besj0"
     "besj1"   "besy0"  "besy1"    "ceil"    "cos"
     "cosh"    "erf"    "erfc"     "exp"     "floor"
     "gamma"   "ibeta"  "inverf"   "igamma"  "imag"
     "invnorm" "int"    "lambertw" "lgamma"  "log"
     "log10"   "norm"   "rand"     "real"    "sgn"
     "sin"     "sinh"   "sqrt"     "tan"     "tanh")
   'words)
  "Gnuplot math functions.")

(defvar gp-other-functions
  (regexp-opt
   '("gprintf"      "sprintf"    "strlen"   "strstrr"
     "substr"       "strftime"   "strptime" "system"
     "word"         "words"      "column"   "exists"
     "stringcolumn" "timecolumn" "tm_hour"  "tm_mday"
     "tm_min"       "tm_mon"     "tm_sec"   "tm_wday"
     "tm_yday"      "tm_year"    "valid")
   'words)
  "Gnuplot other functions.")

(defvar gp-reserved-modifiers
  (regexp-opt
   '("axes"   "every" "index"     "title"     "notitle"
     "ps"     "pt"    "pointsize" "pointtype" "linetype"
     "ls"     "lw"    "lt"        "linestyle" "linewidth"
     "smooth" "thru"  "using"     "with")
   'words)
  "Gnuplot reserved words.")

(defvar gp-other-keywords
  (regexp-opt
   '("term" "xrange" "yrange" "logscale" "out" "output")
   'words)
  "Gnuplot keywords")

(defvar gp-term-types
  (regexp-opt
   '("cairolatex" "canvas" "cgm" "context" "corel" "dumb" "dxf"
     "eepic" "emf" "emtex" "epscairo" "epslatex" "fig" "gif"
     "gpic" "hp2623A" "hp2648" "hpgl" "imagen" "jpeg" "latex" "lua"
     "mf" "mif" "mp" "pcl5" "pdfcairo" "png" "pngcairo" "postscript"
     "pslatex" "pstex" "pstricks" "qms" "regis" "svg" "tek40xx"
     "tek410x" "texdraw" "tgif" "tikz" "tkcanvas" "tpic" "unknown"
     "vttek" "wxt" "x11" "xlib" "xterm")
   'words)
  "Gnuplot term types")

(defvar gp-plot-types
  (regexp-opt
   '("lines" "points" "linespoints" "lp" "impulses" "dots" "steps"
     "errorbars" "xerrorbars" "yerrorbars" "xyerrorbars" "boxes"
     "boxerrorbars" "boxxyerrorbars" "candlesticks" "financebars"
     "histeps" "vector")
   'words)
  "Gnuplot plot styles")

(defvar gp-commands
  (regexp-opt
   '("fit"  "set" "unset" "do for" "if" "else" "while")
   'words)
  "Gnuplot commands")

(defvar gp-plot-commands
  (regexp-opt
   '("plot" "splot" "replot")
   'words)
  "Gnuplot plot commands")

(defvar gp-variables
  (regexp-opt
   '("pi" "NaN")
   'words)
  "Gnuplot variables")


;; apply font lock commands
(defvar gnuplot-font-lock-keywords
  `((,gp-commands           . font-lock-constant-face)
    (,gp-plot-commands      . font-lock-keyword-face)
    (,gp-math-functions     . font-lock-function-name-face)
    (,gp-other-functions    . font-lock-function-name-face)
    (,gp-reserved-modifiers . font-lock-type-face)
    (,gp-other-keywords     . font-lock-preprocessor-face)
    (,gp-term-types         . font-lock-reference-face)
    (,gp-plot-types         . font-lock-function-name-face)
    (,gp-variables          . font-lock-variable-name-face)
    ("!"                    . font-lock-negation-char-face)
    ("\\(\\<[a-z]+[a-z_0-9(),]*\\)[ \t]*=" . font-lock-variable-name-face) ; variable declaration
    ("\$[0-9]+"             . font-lock-string-face)   ; columns
    ("\\[\\([^]]+\\)\\]"    1 font-lock-string-face))) ; brackets



;;; indentation
(defun gnuplot-find-indent-column ()
  "Find the column to indent to.

Start with the value `back-to-indentation' gives for the previous
line.  Next, check whether the previous line starts with a plot
command *and* ends with line continuation.  If so, increment the
indent column by the size of the plot command."
  (save-excursion
    ;; start with the indentation of the previous line
    (forward-line -1)
    (back-to-indentation)
    ;; check if there's a plot or fit command and a line
    ;; continuation.  if so, adjust the indentation.
    ;;
    ;; example:
    ;;   plot sin(x) w l,\
    ;;
    ;; we want to indent under "sin", not "plot"
    (let ((indent (current-column))
          (continuation-regexp         ; matches a continued line
           (concat "\\(" gnuplot-continued-commands-regexp "\\s-+" "\\)"
                   ".*" (regexp-quote "\\") "$")))
      (cond
       ((looking-at continuation-regexp)
        (let ((offset (length (match-string 1))))
          (+ indent offset)))
       (t
        indent)))))

(defun gnuplot-last-line-p ()
  "Determine whether we're just after the last line of a
multi-line plot command.  If so, we don't want to indent to the
previous line, but instead to the beginning of the command.  See
comments for details.

Returns nil if nothing needs to be done; otherwise return the
column to indent to."
  (save-excursion
    ;; check that the previous line does *not* end in a continuation,
    ;; and that the line before it *does*.  if so, we just ended a
    ;; multi-line command.  thus, we should not match indentation of
    ;; the previous line (as above), but the indentation of the
    ;; beginning of the command
    ;;
    ;; example:
    ;;   plot sin(x) w l,\
    ;;        cos(x) w l,\
    ;;        tan(x)
    ;;
    ;; we want to indent to under "plot," not "tan".
    ;;
    (end-of-line -1)                    ; go back *two* lines
    (forward-char -1)
    ;; this regexp is horrible.  it means "a \, followed immediately
    ;; by a newline, followed by some whitespace, followed by a single
    ;; line which does not end in a slash."
    (when (looking-at "\\\\\n\\s-+\\([^\n]+\\)[^\\\\\n]\n")
      (when (re-search-backward gnuplot-continued-commands-regexp nil t)
        (current-column)))))

(defun gnuplot-indent-line ()
  "Indent the current line.

See `gnuplot-find-indent-column' for details."
  (interactive)

  (let ((indent
         ; check last-line-p first!
         (or (gnuplot-last-line-p)
             (gnuplot-find-indent-column))))
    (save-excursion
      (unless (= (current-indentation) indent)
        (beginning-of-line)
        (delete-horizontal-space)
        (insert (make-string indent ? ))))

    (when (< (current-column) indent)
      (back-to-indentation))))



;;; define a major mode
;;;###autoload
(define-derived-mode gnuplot-mode prog-mode ; how will pre emacs 24 react to this?
  "Gnuplot"
  "Major mode for editing gnuplot files"
  :syntax-table gnuplot-mode-syntax-table

  ;; indentation
  (set (make-local-variable 'indent-line-function) 'gnuplot-indent-line)

  ;; comment syntax for `newcomment.el'
  (set (make-local-variable 'comment-start)      "# ")
  (set (make-local-variable 'comment-end)        "")
  (set (make-local-variable 'comment-start-skip) "#+\\s-*")

  ;; font lock
  (set (make-local-variable 'font-lock-defaults)
       '(gnuplot-font-lock-keywords))
  (setq show-trailing-whitespace t)

  ;; run user hooks
  (run-mode-hooks 'gnuplot-mode-hook))

;;;###autoload
(dolist (pattern '("\\.gnuplot\\'" "\\.gp\\'"))
  (add-to-list 'auto-mode-alist (cons pattern 'gnuplot-mode)))



;;; functions to run gnuplot
(defun gnuplot-quit ()
  "Close the *gnuplot errors* buffer and restore the previous
window configuration."
  (interactive)
  (kill-buffer)
  (when (get-register :gnuplot-errors)
    (jump-to-register :gnuplot-errors)))

(defun gnuplot-handle-exit-status (exit-status)
  "Display output if gnuplot signals an error.  Otherwise, clean
up our mess."
  (cond
   ((eq exit-status 0)
    (kill-buffer "*gnuplot errors*")
    (message "Running gnuplot... done."))
   (t
    (window-configuration-to-register :gnuplot-errors)
    (switch-to-buffer-other-window "*gnuplot errors*")
    (compilation-mode)
    (local-set-key (kbd "q") 'gnuplot-quit)
    (message "Gnuplot encountered errors."))))

(defun gnuplot-compile-start (file)
  "Set up the compilation buffer.

Clears the buffer, prints some information, and sets local
variables which are used by `compilation-mode'."
  (with-current-buffer (get-buffer-create "*gnuplot errors*")
    (let ((inhibit-read-only t)
          (command (concat gnuplot-program " "
                           gnuplot-flags " "
                           file)))
      (erase-buffer)
      (insert "-*- mode: compilation; default-directory: "
              (prin1-to-string (abbreviate-file-name default-directory))
              " -*-\n\n"
              command "\n\n")
      (setq compile-command command))))

(defun gnuplot-compile-file (file)
  "Runs gnuplot synchronously.

Run gnuplot as `gnuplot-program', operating on FILE, with the
arguments stored in `gnuplot-flags'.  Store the output in the
buffer *gnuplot errors*, and raise it if gnuplot returns an exit
code other than zero.  Hitting 'q' inside the *gnuplot errors*
buffer kills the buffer and restores the previous window
configuration.

The output in *gnuplot errors* should be parsable by
`compilation-mode', so commands like `next-error' and
`previous-error' should work.

This uses `call-process', rather than a shell command, in an
attempt to be portable.  Note that I pass FILE as an argument to
gnuplot, rather than as an input file.  This ensures gnuplot is
run as 'gnuplot -persist FILE', rather than
'gnuplot -persist < FILE'.  The latter doesn't produce useful
output for compilation-mode."
  (interactive)
  (message "Running gnuplot...")
  (gnuplot-compile-start file)
  (let ((exit-status (call-process gnuplot-program nil "*gnuplot errors*"
                                   nil gnuplot-flags file)))
    (gnuplot-handle-exit-status exit-status)))

;;;###autoload
(defun gnuplot-compile ()
  "Runs gnuplot -persist as a synchronous process and passes the
current buffer to it.  Buffer must be visiting a file for it to
work."
  (interactive)
  (if (or (buffer-modified-p) (eq (buffer-file-name) nil))
    (message "buffer isn't saved")
    (gnuplot-compile-file (file-name-nondirectory (buffer-file-name)))))

;;;###autoload
(defun gnuplot-run-region (start end)
  "Send region to gnuplot, ensuring a final newline.  Doesn't
require buffer to be visiting a file."
  (interactive "r")
  (let ((cmd-data
         (buffer-substring-no-properties start end)))
    (with-temp-buffer
      (insert cmd-data "\n")
      (message "Running gnuplot...")
      (let* ((exit-status
              (call-process-region
               (point-min) (point-max)
               gnuplot-program nil "*gnuplot errors*" nil gnuplot-flags)))
        (gnuplot-handle-exit-status exit-status)))))

;;;###autoload
(defun gnuplot-run-buffer ()
  "Send buffer to gnuplot, ensuring a final newline.  Doesn't
require buffer to be visiting a file."
  (interactive)
  (gnuplot-run-region (point-min) (point-max)))

(provide 'gnuplot-mode)

;;; gnuplot-mode.el ends here
