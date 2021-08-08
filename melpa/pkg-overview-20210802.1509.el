;;; pkg-overview.el --- Make org documentation from elisp source file

;; Copyright © 2020-2021, Boruch Baum <boruch_baum@gmx.com>
;; Available for assignment to the Free Software Foundation, Inc.

;; Author: Boruch Baum <boruch_baum@gmx.com>
;; Maintainer: Boruch Baum <boruch_baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-pkg-overview
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: docs help lisp maint outlines tools
;; Package-Version: 20210802.1509
;; Package-Commit: 9b2e416758a6c107bb8cc670ec4d2627f82d5590
;; Package: pkg-overview
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))
;;
;;   (emacs "24.3") for: read-only-mode

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software.  If not, see <https://www.gnu.org/licenses/>.

;;
;;; Commentary:
;;
;; This package parses an elisp file's comments, definitions,
;; docstrings, and other documentation into a hierarchical `org-mode'
;; buffer. It is intended to facilitate familiarization with a file's
;; contents and organization / structure. The viewer can quickly swoop
;; in and out and across the file structure using standard `org-mode'
;; commands and keybindings.

;;
;;; Dependencies (all are already part of Emacs):
;;
;;   org -- for `org-mode'

;;
;;; Installation:
;;
;; 1) Evaluate or load this file.
;;
;; 2) I don't expect anyone who would want to define a global
;;    keybinding for this kind of function needs me to tell them how
;;    do so, but I'm mindlessly filling out my own template, so:
;;
;;      (global-set-key (kbd "S-M-C F1 M-x butterfly C-c C-h ?") 'pkg-overview)

;;
;;; Operation:
;;
;; Interactive function `pkg-overview' prompts the user for an elisp
;; file, parses it according to generally accepted elisp formatting
;; conventions, and generates a read-only `org-mode' buffer with the
;; results.
;;
;; Note that as of Emacs version 27 and `org-mode' version 9.4.6,
;; `org-mode' takes what some people find to be unbearable entire
;; seconds to load. If you find yourself distressed by this, please:
;; relax; take long, slow, deep breaths, and; be consoled that the
;; gratification-delay only occurs the first time `org-mode' is used
;; for any session.

;;
;;; Feedback:
;;
;; It's best to contact me by opening an 'issue' on the program's github
;; repository (see above) or, distant second-best, by direct e-mail.
;;
;; Code contributions are welcome and github starring is appreciated.

;;
;;; Compatibility
;;
;; This package has been tested under Debian linux Emacs version 27
;; and `org-mode' version 9.4.6.


;;
;;; Code:

(defvar pkg-overview--autoload-label " =autoload="
  "String to identify autoloads.")

;;;###autoload
(defun pkg-overview (file)
  "Create documentation in `org-mode' format from FILE.
FILE is an elisp source file formatted according to the Emacs
style. Result is an org mode buffer containing the file's
documentary comments and docstrings."
  (interactive "f")
  (switch-to-buffer (get-buffer-create (concat (file-name-nondirectory file) ".org")))
  (insert-file-contents file nil nil nil 'replace)
  ;; Remove sets of parentheses that aren't argument lists
  (goto-char (point-min))
  (let (beg)
    (while (setq beg (re-search-forward "^(\\(defcustom\\|defvar\\) [^ ]+" nil t))
      (forward-sexp)
      (delete-region beg (point))))
  ;; Comment-out docstrings
  (goto-char (point-min))
  (let (p0 p1 p2)
    (while (setq p0 (re-search-forward "^(def" nil t))
      (when (not (re-search-forward "^ +\"" nil t))
        (error "Badly formatted file, near %d" p0))
      (setq p1 (match-beginning 0))
      (replace-match "")
      (when (not (re-search-forward "\")?$" nil t))
        (error "Badly formatted file, near %d" p0))
      (setq p2 (match-beginning 0))
      (replace-match "")
      (goto-char p1)
      (narrow-to-region p1 p2) ; because p2 moves with every replacement
      (while (re-search-forward "^" nil t)
        (replace-match ";;"))
      (widen)))
  ;; Merge multi-line arg-lists into a single line
  (goto-char (point-min))
  (while (re-search-forward "^(def[^ ]+ +[^ ]+ ([^)]+" nil t)
    (replace-match
      (replace-regexp-in-string "[\n \t]+" " " (match-string 0))))
  ;; Comment-out def* and adjust pre-existing comments
  (dolist (repl '(("^;;; " ";;;; ")
                  ("^$"    ";;")
                  ("^(def" ";;; (def")))
    (goto-char (point-min))
    (while (re-search-forward (car repl) nil t)
      (replace-match (cadr repl))))
  ;; Remove everything else
  (goto-char (point-min))
  (delete-non-matching-lines  "^;" (point-min) (point-max))
  ;; Substitute command keys
  (goto-char (point-min))
  (let (keys)
    (while (re-search-forward (rx (+? (?? (seq "\\\\<" (+ (not ">")) ">"))
                                      (+? (seq "\\\\[" (+ (not "]")) "]"))))
                               nil t)
      (save-match-data
        (setq keys (replace-regexp-in-string
                     "\\\\" ""
                     (substitute-command-keys (match-string 0))
                     nil t)))
      (replace-match keys nil t)))
  ;; Create org headings and remove extra blank lines
  (dolist
      (repl '(("^;;;###autoload\n"  ";\\&")
              ("^;;;;" "**")
              ("^;;; (def\\([^ ]+\\) +\\('\\)?\\([^ \n]+\\)\\( ([^)]*)\\)?[^\n]*" "*** def\\1\t\\3\\4")
              ("^;;;" "***")
              ("^;;" " ")
              ("^ +$" "")
              ("\n\n+" "\n\n")))
    (goto-char (point-min))
    (while (re-search-forward (car repl) nil t)
      (replace-match (cadr repl))))
  ;; Place autoload information in nice place
  (goto-char (point-min))
  (while (re-search-forward "^**###autoload\n" nil t)
    (replace-match "")
    (end-of-line)
    (insert pkg-overview--autoload-label))
  (align-regexp (point-min) (point-max)
                (concat "\\(\\s-*\\)" pkg-overview--autoload-label "$"))
  ;; Move a definition's preface commentary into its heading
  ;; + For example, in the following quotation, line (1) should
  ;;   be moved after line (2)
  ;;
  ;;        #+begin_quote
  ;;  (1)   ;; Foo is a great function
  ;;        (defun foo ()
  ;;  (2)     "Foo does stuff."
  ;;        #+end_quote
  (goto-char (point-max))
  (let (beg end comment)
    (while (re-search-backward "^[^*\n][^\n]+\n\\*+ def" nil t)
      (when (re-search-backward "\n\n" nil t)
        (goto-char (setq beg (match-end 0)))
        (when (re-search-forward "^*" nil t)
          (setq end (match-beginning 0))
          (setq comment (buffer-substring-no-properties beg end))
          (delete-region beg end)
          (if (re-search-forward "^*" nil t)
            (backward-char)
           (goto-char (point-max)))
          (insert comment)))))
  ;; Create top heading
  (goto-char (point-min))
  (delete-char 1)
  ;; Create colophon heading
  (forward-line 1)
  (insert "** Colophon:\n")
  ;; Ta-da!
  (goto-char (point-min))
  (org-mode)
  (read-only-mode)
  (org-cycle) ; open up first-level headings
  (when (re-search-forward "^\\*\\* Commentary:" nil t)
    (goto-char (match-beginning 0))
    ;; open up content of anny commentary text
    (org-cycle)))


;;
;;; Conclusion:

(provide 'pkg-overview)

;;
;;; Emacs-core integration notes
;;
;; This package was originally proposed on the `emacs-devel' mailing
;; list as a new feature for emacs-core[1]. See there for the 30
;; messages of the thread. Here's a summary of the demands made in
;; that thread as a pre-requisite for it to be considered for
;; inclusion:
;;
;; + Use `outline-minor-mode' instead of `org-mode'
;;   + org-mode takes an "excessive" time to load. (Stefan Monnier)
;;   + At the time, `outline-minor-mode' wasn't available to the public,
;;     but when it was released I did implement this and found it very
;;     confusing and burdensome because of all the different keybindings
;;     it needed to perform what `org-mode' does with a single keybinding
;;     (<TAB>).
;;   + Initially, and until I hear complaints, I'm willing to wave my
;;     hands and baselessly claim that people who want to use this kind
;;     of feature already have `org-mode' loaded, so it's not an issue.
;;     + If it becomes a deal-breaker, I could add a defcustom to
;;       optionally select the mode to be used.
;;     + It `outline-minor-mode' becomes as easy to use as `org-mode',
;;       and with compatible keybindings, I'd be happy to make it the
;;       exclusive presentation mode.
;;
;; + This feature should not be a stand-alone feature
;;   + It should be integrated into the output produced by function
;;     `describe-package' (Eli Zaretskii, Stefan Monnier, Stefan Kangas)
;;   + I'm open to the idea of integrating the feature, but not at the
;;     expense of being independently discoverable.
;;     + The feature is intended to be useful for elisp files even if
;;       they aren't loaded packages.
;;
;; + Formatting demands (Stefan Kangas)
;;   + Don't show obsolete aliases.
;;   + DONE: Improve representation of autoload cookies
;;   + DONE: Apply function `substitute-command-keys' to doc strings
;;   + Re-arrange the author's organization of the file
;;     + eg. Move the license to the end, or omit it.
;;
;; [1] 2020-10-15 https://lists.gnu.org/archive/html/emacs-devel/2020-10/msg01265.html


;;; TODO:
;;
;; + The single \t inserted into "(def[^ ]+" headings in insufficient
;;   to vertically align symbol names when the "(def[^ ]+" is
;;   `define-derived-mode' or `define-obsolete-function-alias'

;;
;;; pkg-overview.el ends here
