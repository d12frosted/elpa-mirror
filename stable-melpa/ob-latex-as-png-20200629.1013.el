;;; ob-latex-as-png.el --- Org-babel functions for latex-as-png evaluation  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Musa Al-hassy

;; Author: Musa Al-hassy <alhassy@gmail.com>
;; Version: 1.0
;; Package-Version: 20200629.1013
;; Package-Commit: a20e3fedbac4034de4ab01436673a0f8845de1df
;; Package-Requires: ((emacs "26.1") (org "9.1"))
;; Keywords: literate programming, reproducible research, org, convenience
;; URL: https://github.com/alhassy/ob-latex-as-png

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; An Org-babel “language” whose execution produces PNGs from LaTeX snippets;
;; useful for shipping *arbitrary* LaTeX results in HTML.
;;
;; Below is an example of producing a nice diagram;
;; type it in and C-c C-c to obtain the png.
;; Then C-c C-x C-v to inline the resulting image.
;;
;;    #+PROPERTY: header-args:latex-as-png :results raw value replace
;;    #+begin_src latex-as-png :file example :resolution 150
;;    \smartdiagram[bubble diagram]{Emacs,Org-mode, \LaTeX, Pretty Images, HTML}
;;    #+end_src
;;
;;  Hint: Add the following lines to your init to *always* re-display inline images.
;;
;;    ;; Always redisplay images after C-c C-c (org-ctrl-c-ctrl-c)
;;    (add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

;;; Requirements:

;; Users must have PDFLATEX and PDFTOPPM command line tools.

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 'ox-latex)

;; Treat (colour) this “language” as LaTeX
(add-to-list 'org-src-lang-modes '("latex-as-png" . latex))

;; Default header arguments
(defvar org-babel-default-header-args:latex-as-png
  '((:results . "raw value replace")))

(defvar ob-latex-as-png-header '("\\usepackage{smartdiagram}")
  "The LaTeX preamble used for executing latex-as-png source blocks.

This is generally any LaTeX matter that may appear before \\begin{document}.")

(defvar ob-latex-as-png-header-separator "% in"
  "A literal expression that separates local LaTeX header matter from the body.

Everything before the separator is matter that is necessary
to produce a PNG from the primary LaTeX.")

;; This is the main function which is called to evaluate a code
;; block.
(defun org-babel-execute:latex-as-png (contents params)
  "Execute a block of latex-as-png code with org-babel.
This function is called by `org-babel-execute-src-block'

Such blocks have two notable header arguments, PARAMS, both optional:
:file       ⇒ The name of the resulting PNG; any extensions are ignored.
:resolution ⇒ The resolution; by default 150.

Argument CONTENTS is the source text of the block."
  (message "executing latex-as-png source code block")
  (let* ((processed-params (org-babel-process-params params))

         (pieces (split-string contents (regexp-quote ob-latex-as-png-header-separator)))
         (headers (if (< 1 (length pieces)) (car pieces) ""))
         (body    (if (< 1 (length pieces)) (cadr pieces) (car pieces)))
         ;; Augment usepackage declarations and front-matter for LaTeX
         (full-contents (concat "\n\\documentclass[varwidth,crop]{standalone}\n\n"
                                headers
                                "\n"
                                (mapconcat #'identity ob-latex-as-png-header "\n ")
                                "\n\n\n\\begin{document}\n\n\n"
                                body
                                "\n\n\n\\end{document}\n"))

         ;; Get resolution argument
         (resolution (or (cdr (assoc :resolution processed-params)) "150"))

         ;; The target file
         (file.ext (or (cdr (assoc :file processed-params)) "ob-latex-as-png.pdf"))
         (file (car (split-string file.ext "\\.")))

         ;; ⟨4⟩ Handle filenames with spaces or other characters that the shell
         ;; might get caught on; then actually send everything to the shell
         (sq-file (shell-quote-argument file))
         (sq-resolution (shell-quote-argument resolution))

         ;; temporarily override for speed gains
         (org-latex-pdf-process
           '("pdflatex -shell-escape -output-directory %o %f"))
            ;; (org-latex-classes
            ;;  '(("article"
            ;;     "\\documentclass[varwidth,crop]{standalone}")))
         )

    ;; ⟨0⟩ Generate the PDF
    ;; (let ((pdflatex (format "pdflatex -shell-escape -jobname=%s" file)))
    ;; (org-babel-eval pdflatex full-contents))
    ;; This does not show a helpful errors log when LaTeX is malformed.
    ;; Let's use the org-export back-end instead.
    (with-temp-file (format "%s.tex" file)
      (insert full-contents))

    (unless (ignore-errors (org-latex-compile (format "%s.tex" file)))
            (message "ob-latex-as-png: There seems to be a LaTeX error!")
            (switch-to-buffer "*Org PDF LaTeX Output*")
            (goto-char (point-max)))

    ;; Now to get the PNG and cleanup.
    (dolist (cmd (list
                 ;; ⟨1⟩ Transform it to a PNG
                  (format "pdftoppm %s.pdf -png %s -r %s"
                          sq-file
                          sq-file
                          sq-resolution)
                 ;; ⟨2⟩ for some reason pdftoppm produces “OUTPUTNAME-1.png”
                 ;; so I rename away the extra “-1”.
                 (format "mv %s-1.png %s.png" file file)
                 ;; ⟨3⟩ Remove the new PDF
                 ; (format "rm %s.pdf" file)
                 ))
      (shell-command cmd))

    ;; ⟨5⟩ Return the a raw link to the PNG
    (format "[[file:%s.png]]" file)))

(provide 'ob-latex-as-png)
;;; ob-latex-as-png.el ends here
