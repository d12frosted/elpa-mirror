;;; ini.el --- Converting between INI files and association lists

;; Original author: Daniel Ness <daniel.r.ness@gmail.com>
;; Author of new implementation: Pierre Rouleau <prouleau001@gmail.com>
;; Author of melpa packaging: Esa Laine <pgdad@hotmail.com>
;; Version: 1.0
;; Package-Version: 20220827.2009
;; Package-Commit: d50fe629497d51c6390a56bbded1ad77ce12e5af
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/EsaLaine/ini.el

;;; License
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; --------------------------------------------------------------------------
;;; Commentary:
;;
;; This converts .INI file format into an associated list and vice versa.
;; - The original implementation was done by Daniel Ness.
;; - Pierre Rouleau re-implemented the code, keeping the function names
;;   but with  a different implementation and with an API change.
;;   - `ini-decode':
;;     - Simplified API: its argument is the name of the file,
;;       instead of a string that is the content of the file.
;;       - the new implementation does not create a list of line strings,
;;         which could potentially be quite expensive; instead it uses a
;;         larger regexp to search for syntactic element and a FSM logic to
;;         process matched strings.  The regexp is more complex but described
;;         in comments.
;;     - Supports a wider syntax:
;;       - Comments can now start with # or ;
;;       - Supports multi-line values: values expressed in
;;         multiple line express a compound value that is a list of strings.
;;     - Supports files with key-value pairs without a section: the section
;;       is named after the file base name.
;;  - `ini-encode':
;;    - Supports the more complex data structure with list values.
;;  - `ini-store': a new function that stores the data structure directly into
;;     a file with append and overwrite capability.

;; The code hierarchy follows:
;;
;; - `ini-decode'
;;   - `ini--add-to-alist'
;;     - `ini--add-to-keys'
;;   - `ini--add-extra-value'
;;
;; - `ini-store'
;;   - `ini-encode'

(eval-when-compile (require 'subr-x))   ; use: `string-join'

;;; --------------------------------------------------------------------------
;;; Code:
;;

(defconst ini--regexp "\
^\\(\
\\([#;].*\\)\\|\
\\(\\[\\(.*\\)\\]\\)\\|\
\\(\\([[:alpha:]][^[:blank:]:=]+\\)[[:blank:]]*[:=][[:blank:]]*\\(.+\\)\\)\\|\
\\([[:blank:]]+\\(.+\\)\\)\
\\)$"
  "Regular expression used to extract .INI syntactic elements.")

;; Group number ------------------------------------------------------------>
;; "^\(                                                                      : 1
;;       \([#;].*\)                                                          : 2=comment
;;    \| \(\[\(.*\)\]\)                                                      : 3, 4=section
;;    \| \( \([[:alpha:]][^[:blank:]:=]+\)[[:blank:]]*[:=][[:blank:]]*\(.+\)\) : 5, 6=key, 7=value
;;    \| \([[:blank:]]+\(.+\)\)                                              : 8, 9=extra-value
;; \)$"


(defconst ini--COMMENT     2 "Group for comment.")
(defconst ini--SECTION     4 "Group for section.")
(defconst ini--KEY         6 "Group for key.")
(defconst ini--VALUE       7 "Group for value.")
(defconst ini--EXTRA-VALUE 9 "Group for extra value to append to value list.")

(defun ini--add-extra-value (new-value values)
  "Push NEW-VALUE to what is currently VALUES and return the resulting list.

VALUES may be a single value or a list."
  (unless (listp values)
    (setq values (list values)))
  (push new-value values))

(defun ini--add-to-keys (keys key values)
  "Push (KEY . VALUES) to KEYS and return KEYS list.

KEYS is the previous list of key/values list.
KEY  is the last detected key.
VALUES is the currently accumulated value or values.

The KEY/VALUES cons returned has VALUES in order."
  (push (cons key
              (if (listp values)
                  (reverse values)
                values))
        keys))

(defun ini--add-to-alist (alist section keys key values)
  "Return ALIST with new SECTION entry pushed in front.
Put KEYS in order, each one with one or several VALUES for new KEY."
  (when key
    (setq keys (ini--add-to-keys keys key values)))
  (when section
    (push (cons section (reverse keys))
          alist)))

(defun ini-decode (filename)
  "Read content of .INI formatted FILENAME and return corresponding alist."
  (let ((state nil)                     ; states: nil, in-section, in-key
        (alist nil)
        section
        (keys nil)
        key
        (values nil)
        match)
    (with-temp-buffer
      (insert-file-contents filename)
      (goto-char (point-min))
      (while (re-search-forward ini--regexp nil :noerror)
        (cond
         ;; ----
         ;; skip comment lines, allow comment lines in between value lines.
         ((match-string ini--COMMENT)
          nil)
         ;; ----
         ;; [section]
         ((setq match (match-string ini--SECTION))
          (setq alist (ini--add-to-alist alist section keys key values))
          (setq section match
                keys    nil
                key     nil
                values  nil
                state  'in-section))
         ;; ----
         ;; key = value
         ((setq match (match-string ini--KEY))
          (cond
           ((null state)
            (setq section (file-name-base filename)
                  key     match
                  values (match-string ini--VALUE)
                  state   'in-key))
           ((eq state 'in-section)
            (if key
                (error "FSM: first key/value in section %s already has key %s" section key)
              (setq key    match
                    values (match-string ini--VALUE)
                    state 'in-key)))
           ((eq state 'in-key)
            (setq keys   (ini--add-to-keys keys key values)
                  key    match
                  values (match-string ini--VALUE)
                  state 'in-key))))
         ;; ----
         ;; extra value (on extra line), extending value to a list of values
         ((setq match (match-string ini--EXTRA-VALUE))
          (cond
           ((null state)
            (error "Detect value %s without key and outside section" section))
           ((eq state 'in-section)
            (error "Detect value %s without key in section %s" match section))
           ((eq state 'in-key)
            (setq values (ini--add-extra-value match values)))))))
      (reverse (ini--add-to-alist alist section keys key values)))))

;; --

(defun ini-encode (ini-alist)
  "Convert a INI-ALIST into .INI formatted string."
  (unless (listp ini-alist)
    (error "Ini-alist is not a list"))
  (let ((lines nil)
        (key nil)
        (value nil)
        (separator "")
        (spacer ""))
    (dolist (section ini-alist)
      (push (format "%s[%s]" separator (car section)) lines)
      (setq separator "\n\n")
      (dolist (key.value (cdr section))
        (setq key (car key.value))
        (unless (stringp key)
          (error "In section %s: key %S is not a string!"
                 section key))
        (setq spacer (make-string (+ 3 (length key)) ?\s))
        (setq value (cdr key.value))
        (if (listp value)
            (progn
              (push (format "\n%s = %s" key (car value)) lines)
              (dolist (val (cdr value))
                (push (format "%s%s" spacer val) lines)))
          (push (format "\n%s = %s" key value) lines))))
    (format "%s\n" (string-join (reverse lines) "\n"))))

;; --

(defun ini-store (alist filename &optional header overwrite)
  "Write the ALIST object into the FILENAME as .INI file format.

If HEADER is specified it must be a string.  That string is
inserted at the top of the file.  The HEADER can be anything and
it is inserted verbatim.  If it is meant to be a comment then
ensure you comment each line properly.

By default the new text is appended to the file FILENAME; the
file is created if it does not exists.  However if the OVERWRITE
argument is non-nil then a new file is created and an
existing one is overwritten with the new content.

If you need more file writing control you may want to use the
`write-region' function explicitly instead.

The function returns FILENAME."
  (with-temp-buffer
    (when header
      (unless (stringp header)
        (error "Invalid header: %S" header))
      (insert header))
    (insert (ini-encode alist))
    (if overwrite
        (write-region (point-min) (point-max) filename nil)
      (append-to-file (point-min) (point-max) filename)))
  filename)

;; ---------------------------------------------------------------------------
(provide 'ini)
;;; ini.el ends here
