;;; transient-extras-a2ps.el --- A transient interface to a2ps -*- lexical-binding: t -*-

;; Author: Samuel W. Flint <swflint@flintfam.org>
;; URL: https://git.sr.ht/~swflint/transient-extras-a2ps
;; Package-Version: 20230303.1511
;; Package-Commit: e91a1cddb1f0cb8b99d2bd30db64d467e5fa7ea8
;; Version: 1.0.0
;; Package-Requires: ((emacs "28.1") (transient-extras "1.0.0"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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
;; This package provites a transient menu with common options for a2ps.

(require 'transient)
(require 'transient-extras)

;;; Code:

;; Options

(transient-define-argument transient-extras-a2ps-printer ()
  :class 'transient-extras-option-dynamic-choices
  :description "Printer"
  :key "P"
  :argument "-P"
  :choices-function (transient-extras-make-command-filter-function
                     "a2ps" '("--list=printers")
                     (lambda (line)
                       (when (and (string-match-p "^-" line)
                                  (not (string-match-p "Default" line))
                                  (not (string-match-p "Unknown" line)))
                         (substring line 2))))
  :prompt "Printer? ")

(transient-define-argument transient-extras-a2ps-sidedness ()
  :description "Sidedness"
  :class 'transient-extras-exclusive-switch
  :key "s"
  :argument-format "--sides=%s"
  :argument-regexp "\\(--sides=\\(simplex\\|duplex\\|tumble\\)\\)"
  :choices '("simplex" "duplex" "tumble"))

(transient-define-argument transient-extras-a2ps-medium ()
  :class 'transient-extras-option-dynamic-choices
  :description "Medium"
  :key "M"
  :argument "--medium="
  :choices-function (transient-extras-make-command-filter-function
                     "a2ps" '("--list=media")
                     (lambda (line)
                       (when (and (string-match-p "^  " line)
                                  (not (string-match-p "^  Name" line)))
                         (let* ((line (substring line 2))
                                (end (string-match "[[:space:]]" line)))
                           (substring line nil end)))))
  :prompt "Medium? ")

(transient-define-argument transient-extras-a2ps-alignment ()
  :description "File Alignment"
  :class 'transient-extras-exclusive-switch
  :key "a"
  :argument-format "--file-align=%s"
  :argument-regexp "\\(--file-align=\\(fill\\|rank\\|page\\|sheet\\)\\)"
  :choices '("fill" "rank" "page" "sheet"))

(transient-define-argument transient-extras-a2ps-highlight-level ()
  :description "Highlight Level"
  :class 'transient-extras-exclusive-switch
  :key "H"
  :argument-format "--highlight-level=%s"
  :argument-regexp "\\(--highlight-level=\\(none\\|normal\\|heavy\\)\\)"
  :choices '("none" "normal" "heavy"))

(transient-define-argument transient-extras-a2ps-pretty-printer ()
  :class 'transient-extras-option-dynamic-choices
  :description "Pretty Printer"
  :key "E"
  :argument "--pretty-print="
  :choices-function (transient-extras-make-command-filter-function
                     "a2ps" '("--list=style-sheets")
                     (lambda (line)
                       (when (string-match-p "\\.ssh" line)
                         (when-let ((start (string-match "(" line))
                                    (end (string-match "\\.ssh" line)))
                           (substring line (1+ start) end)))))
  :prompt "Pretty Printer? ")

(transient-define-argument transient-extras-a2ps-user-option ()
  :class 'transient-extras-option-dynamic-choices
  :description "User Shortcut"
  :key "="
  :argument "-="
  :choices-function (transient-extras-make-command-filter-function
                     "a2ps" '("--list=user-options")
                     (lambda (line)
                       (when (string-match-p "=" line)
                         (substring line nil (string-match "[[:space:]]" line)))))
  :prompt "Shortcut? ")

(transient-define-argument transient-extras-a2ps-prologue ()
  :class 'transient-extras-option-dynamic-choices
  :description "PostScript Prologue"
  :key "C-p"
  :argument "--prologue="
  :choices-function (transient-extras-make-command-filter-function
                     "a2ps" '("--list=prologues")
                     (lambda (line)
                       (when (string-match-p "Prologue " line)
                         (substring line 10 (string-match "\":" line)))))
  :prompt "Prologue?")


;; Run Program

(defun transient-extras-a2ps-run (files &optional args)
  "Call `a2ps' with files/buffer.

FILES is a buffer or list of files.  ARGS are other arguments
passed to `a2ps'."
  (interactive (list (transient-extras--get-default-file-list-or-buffer)))
  (unless (or (bufferp files)
              (listp files))
    (user-error "`files' must be a buffer or list"))
  (if-let ((program (executable-find "a2ps")))
      (let* ((cmd (nconc (list program)
                         args
                         (and (listp files)
                              files)))
             (buffer (generate-new-buffer "*a2ps-out-buffer*"))
             (process (make-process
                       :name "a2ps-print"
                       :buffer buffer
                       :stderr buffer
                       :connection-type 'pipe
                       :command cmd)))
        (message "Started print job: %s"
                 (mapconcat #'identity cmd " "))
        (when (bufferp files)
          (process-send-string process (with-current-buffer files (buffer-string)))
          (process-send-eof process))
        (while (accept-process-output process))
        (let ((output (with-current-buffer buffer (buffer-string))))
          (kill-buffer buffer)
          (message "%s" (string-trim output))))
    (error "No `a2ps' executable available")))

(defun transient-extras-a2ps-do-run (arguments)
  "Call `transient-extras-a2ps-run-a2ps' with `transient' ARGUMENTS."
  (interactive (list (transient-args 'transient-extras-a2ps-menu)))
  (transient-extras-a2ps-run (car arguments) (cdr arguments)))

(defun transient-extras-a2ps ()
  "Start the a2ps transient menu."
  (interactive)
  (call-interactively #'transient-extras-a2ps-menu))


;; Build the Transient

(transient-define-prefix transient-extras-a2ps-menu (filename)
  "Call `a2ps' with various arguments and options."
  :man-page "a2ps"
  :info-manual "a2ps"

  [(transient-extras-file-list-or-buffer)]

  [["General"
    (transient-extras-a2ps-user-option)
    (transient-extras-a2ps-printer)
    ("p" "Pages" "--pages="
     :prompt "Pages? "
     :class transient-option
     :reader read-string)
    ("t" "Job Title" "--title="
     :prompt "Job Title? "
     :class transient-option
     :reader read-string)
    ("n" "Number of Copies" "--copies="
     :prompt "Number of Copies? "
     :class transient-option
     :reader transient-read-number-N+)
    (transient-extras-a2ps-sidedness)
    (transient-extras-a2ps-prologue)]

   ["Sheets"
    (transient-extras-a2ps-medium)
    ("r" "Portrait?" ("-R" "--portrait"))
    ("C" "Columns" "--columns="
     :prompt "Columns? "
     :class transient-option
     :reader transient-read-number-N+)
    ("R" "Rows" "--rows="
     :prompt "Rows? "
     :class transient-option
     :reader transient-read-number-N+)
    (transient-extras-a2ps-alignment)]
   ["Pages"
    ("C-l" "Line Numbers" "--line-numbers="
     :prompt "Line Numbers? "
     :class transient-option
     :reader transient-read-number-N+)
    ("f" "Font Size" "--font-size="
     :prompt "Font Size? "
     :class transient-option
     :reader transient-read-number-N+)
    ("L" "Lines per Page" "--lines-per-page="
     :prompt "Lines per Page? "
     :class transient-option
     :reader transient-read-number-N+)
    ("l" "Characters per Line" "--chars-per-line="
     :prompt "Characters per Line? "
     :class transient-option
     :reader transient-read-number-N+)
    ("T" "Tab Size" "--tab-size="
     :prompt "Tab Size? "
     :class transient-option
     :reader transient-read-number-N+)]]

  [["Headings"
    ("B" "No Header" ("-B" "--no-header"))
    ("b" "Header" "--header="
     :prompt "Header? "
     :class transient-option
     :reader read-string)
    ("u" "Underlay" "--underlay="
     :prompt "Underlay? "
     :class transient-option
     :reader read-string)]
   [""
    ("hc" "Centered Heading" "--center-title="
     :prompt "Centered Title? "
     :class transient-option
     :reader read-string)
    ("hl" "Left Title" "--left-title="
     :prompt "Left Title? "
     :class transient-option
     :reader read-string)
    ("hr" "Right Title" "--right-title="
     :prompt "Right Title? "
     :class transient-option
     :reader read-string)]
   [""
    ("Fc" "Centered Footer" "--center-footer="
     :prompt "Centered Footer? "
     :class transient-option
     :reader read-string)
    ("Fl" "Left Footer" "--left-footer="
     :prompt "Left Footer? "
     :class transient-option
     :reader read-string)
    ("Fr" "Right Footer" "--right-footer="
     :prompt "Right Footer? "
     :class transient-option
     :reader read-string)]]

  [["Pretty Printing"
    (transient-extras-a2ps-pretty-printer)]
   [""
    (transient-extras-a2ps-highlight-level)]]

  [[("C-c C-c" "Run"
     transient-extras-a2ps-do-run
     :transient nil)]])

(provide 'transient-extras-a2ps)

;;; transient-extras-a2ps.el ends here
