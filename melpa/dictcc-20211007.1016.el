;;; dictcc.el --- Look up translations on dict.cc  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Marten Lienen
;; Copyright (C) 2015 Raimon Grau
;;
;; Author: Marten Lienen <marten.lienen@gmail.com>
;; Version: 1.0.2
;; Package-Version: 20211007.1016
;; Package-Commit: 235841b19567b9c2e17727901ca041a22c096512
;; Keywords: convenience
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5") (ivy "0.10.0"))

;; This file is not part of GNU Emacs.

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

;; Look up translations on dict.cc.  Then you can browse and pick one of them
;; and insert it at point.

;;; Code:

(require 'cl-lib)
(eval-when-compile (require 'subr-x))

(defgroup dictcc ()
  "Look up translations on dict.cc."
  :group 'convenience
  :group 'external
  :prefix "dictcc-")

(defcustom dictcc-completion-backend
  (cond
   ((require 'ivy nil 'noerror) 'ivy)
   ((require 'helm nil 'noerror) 'helm))
  "Completion backend used for choosing a translation to insert."
  :type '(choice (const 'ivy) (const 'helm) (const nil))
  :group 'dictcc)

(defcustom dictcc-candidate-width 30
  "Maximum length of a translation candidate."
  :type 'integer
  :group 'dictcc)

(defcustom dictcc-source-lang "en"
  "Source language."
  :type 'string
  :group 'dictcc)

(defcustom dictcc-destination-lang "de"
  "Destination language."
  :type 'string
  :group 'dictcc)

(defcustom dictcc-languages-alist '(("English" . "en")
                                    ("German" . "de")
                                    ("Swedish" . "sv")
                                    ("Icelandic" . "is")
                                    ("Russian" . "u")
                                    ("Romanian" . "ro")
                                    ("Italian" . "it")
                                    ("French" . "fr")
                                    ("Portuguese" . "pt")
                                    ("Hungarian" . "hu")
                                    ("Dutch" . "nl")
                                    ("Slovak" . "sk")
                                    ("Latin" . "la")
                                    ("Finnish" . "fi")
                                    ("Spanish" . "es")
                                    ("Bulgarian" . "bg")
                                    ("Croation" . "hr")
                                    ("Norwegian" . "no")
                                    ("Czech" . "cs")
                                    ("Danish" . "da")
                                    ("Turkish" . "tr")
                                    ("Polish" . "pl")
                                    ("Serbian" . "sr")
                                    ("Greek" . "el")
                                    ("Esperanto" . "eo")
                                    ("Bosnian" . "bs")
                                    ("Albanian" . "sq"))
  "List of source languages to select from interactively."
  :type 'list
  :group 'dictcc)

(defface dictcc-tag-face
  '((((background dark)) :inherit font-lock-comment-face :foreground "#555555")
    (((background light)) :inherit font-lock-comment-face :foreground "#AAAAAA")
    (default :inherit font-lock-comment-face))
  "Font Lock mode face used to fade tags."
  :group 'dictcc)

(defvar dictcc-tag-face 'dictcc-tag-face
  "Face name to use for tags.")

(cl-defstruct dictcc--translation text tags)

(defun dictcc--translation-from-cell (cell)
  "Create a dictcc--translation from the contents of CELL."
  (let ((words) (tags-nodes))
    ;; Split nodes in words and tag nodes
    (dolist (child (cddr cell))
      (when (listp child)
        (cl-case (car child)
          ('dfn (setq tags-nodes (cons child tags-nodes)))
          ('var (setq tags-nodes (cons child tags-nodes)))
          ('a
           (let ((inner-tag (cl-caddr child)))
             (if (and (listp inner-tag) (eq 'kbd (car inner-tag)))
                 (setq tags-nodes (cons child tags-nodes))
               (setq words (cons (dictcc--tag-to-text child) words))))))))
    (setq words (reverse words)
          tags-nodes (reverse tags-nodes))

    ;; Search for tags in a string form, so that we can more easily find tags,
    ;; that are split across tags (multi-word tags).
    (let* ((tag-strings (mapcar #'dictcc--tag-to-text tags-nodes))
           (tag-string (string-join tag-strings " "))
           (tags (dictcc--tags-from-string tag-string)))
      (make-dictcc--translation :text (string-join words " ")
                                :tags tags))))

(defun dictcc--tags-from-string (string)
  "Extract a list of tags from STRING.

This is implemented as a deterministic finite automaton, because
Emacs does not like my regexps."
  (let ((state 'initial) (pos 0) (start 0) (len (length string))
        (matches))
    (while (< pos len)
      (let ((char (aref string pos)))
        (cl-case state
          ('initial
           (cl-case char
             (?\s (setq pos (1+ pos)))  ; Eat up whitespace
             ((?\[ ?\{)
              (setq state 'pair
                    pos (1+ pos)
                    start pos))
             (t (setq state 'word
                      start pos))))
          ('word
           (cl-case char
             (?\s                       ; Space
              (setq matches (cons (substring string start pos) matches)
                    pos (1+ pos)
                    state 'initial))
             (t (setq pos (1+ pos)))))
          ('pair
           (cl-case char
             ((?\] ?\})
              (setq matches (cons (substring string start pos) matches)
                    pos (1+ pos)
                    state 'initial))
             (t (setq pos (1+ pos))))))))

    ;; Create a last match if the automaton halted in a matching state
    (when (or (eq state 'word) (eq state 'pair))
      (setq matches (cons (substring string start pos) matches)))

    (reverse matches)))

(defun dictcc--translation-to-string (translation)
  "Generate a string representation of TRANSLATION."
  (concat (dictcc--translation-text translation)
          " "
          (propertize
           (string-join (mapcar (lambda (tag) (concat "[" tag "]"))
                                (dictcc--translation-tags translation))
                        " ")
           'face dictcc-tag-face)))

(defun dictcc--request-url (query)
  "Generate a URL for QUERY."
  (format "https://%s%s.dict.cc/?s=%s"
          dictcc-source-lang
          dictcc-destination-lang
          (url-encode-url query)))

(defun dictcc--request (query)
  "Send the request to look up QUERY on dict.cc."
  (let* ((response (url-retrieve-synchronously (dictcc--request-url query)))
         (translations (with-current-buffer response
                         (goto-char (point-min))
                         (dictcc--parse-http-response))))
    (if translations
        (dictcc--select-translation query translations)
      (message "No translations found for '%s'" query))))

(defun dictcc--parse-http-response ()
  "Parse the HTTP response into a list of translation pairs."
  (search-forward "\n\n")
  (let* ((doc (libxml-parse-html-region (point) (point-max)))
         (rows (dictcc--find-translation-rows doc))
         (translations (mapcar #'dictcc--extract-translations rows)))
    translations))

(defun dictcc--find-translation-rows (doc)
  "Find all translation table rows in DOC.

At the moment they are of the form `<tr id='trXXX'></tr>'."
  (let ((rows nil)
        (elements (list doc)))
    (while elements
      (let ((element (pop elements)))
        (when (listp element)
          (let* ((tag (car element))
                 (attributes (cadr element))
                 (children (cddr element))
                 (id (cdr (assq 'id attributes)))
                 (is-translation
                  (and (eq tag 'tr)
                       (stringp id)
                       (string-equal (substring id 0 2) "tr"))))
            (if is-translation
                (push element rows)
              (dolist (child children)
                (push child elements)))))))
    rows))

(defun dictcc--extract-translations (row)
  "Extract translation texts from table ROW."
  (let* ((cells (cddr row)))
    (cons (dictcc--translation-from-cell (nth 1 cells))
          (dictcc--translation-from-cell (nth 2 cells)))))

(defun dictcc--tag-to-text (tag)
  "Concatenate the string contents of TAG and its children."
  (if (stringp tag)
      tag
    (let* ((children (cddr tag))
           (texts (mapcar #'dictcc--tag-to-text children)))
      (string-join texts ""))))

(defun dictcc--insert-source-translation (pair)
  "Insert the source translation of the selected PAIR."
  (insert (dictcc--translation-text (car pair))))

(defun dictcc--insert-destination-translation (pair)
  "Insert the destination translation of the selected PAIR."
  (insert (dictcc--translation-text (cdr pair))))

(defun dictcc--candidate (pair)
  "Generate the candidate pair for a PAIR of translations."
  (let* ((format-string (format "%%-%ds   %%s"
                                dictcc-candidate-width))
         (source (dictcc--cap-string (dictcc--translation-to-string (car pair))))
         (destination (dictcc--cap-string (dictcc--translation-to-string (cdr pair))))
         (text (format format-string source destination)))
    (cons text pair)))

(defun dictcc--cap-string (string)
  "Cut the STRING if it is too long."
  (if (> (length string) dictcc-candidate-width)
      (substring string 0 dictcc-candidate-width)
    string))

(defun dictcc--select-translation (query translations)
  "For QUERY, select one of TRANSLATIONS and insert into buffer."
  (cl-case dictcc-completion-backend
    ('ivy (dictcc--select-translation-ivy query translations))
    ('helm (dictcc--select-translation-helm query translations))
    (t (message "dictcc.el requires ivy or helm."))))

(defun dictcc--insert-candidate (selector)
  "Insert translation text extracted from an ivy/helm item with SELECTOR.
If there is an active region, kill it before insertion."
  (lambda (item)
    (when (use-region-p)
      (kill-region (region-beginning) (region-end)))
    (insert (dictcc--translation-text (funcall selector item)))))

(when (require 'ivy nil 'noerror)
  (ivy-set-actions
   'dictcc--select-translation
   `(("e" ,(dictcc--insert-candidate #'cadr)
      ,(format "Insert %s translation" dictcc-source-lang))
     ("d" ,(dictcc--insert-candidate #'cddr)
      ,(format "Insert %s translation" dictcc-destination-lang)))))

(defun dictcc--select-translation-ivy (query translations)
  "Choose from TRANSLATIONS for QUERY with ivy."
  (ivy-read "Filter: " (mapcar #'dictcc--candidate translations)
            :action (dictcc--insert-candidate #'cadr)
            :require-match t
            :caller 'dictcc--select-translation))

(defun dictcc--select-translation-helm (query translations)
  "Choose from TRANSLATIONS for QUERY with helm."
  (let* ((candidates (mapcar #'dictcc--candidate translations))
         (source `((name . ,(format "Translations for «%s»" query))
                   (candidates . ,candidates)
                   (action . ,(helm-make-actions
                               (format "Insert %s translation" dictcc-source-lang)
                               (dictcc--insert-candidate #'car)
                               (format "Insert %s translation" dictcc-destination-lang)
                               (dictcc--insert-candidate #'cdr))))))
    (helm :prompt "Filter: " :sources (list source))))

(defun dictcc--select-language (prompt)
  "Select language with completing read with prompt PROMPT."
  (let ((lang (completing-read prompt dictcc-languages-alist)))
    (cdr (assoc lang dictcc-languages-alist))))

(defun dictcc--get-query ()
  "Query the user for a word to look up.
If there is a word at point or the region is active, suggest this
as a default option on empty input."
  (cl-flet ((get-completion (default)
             (let ((compl (read-from-minibuffer (concat "Query" " (" default "): "))))
               (if (string-empty-p compl)
                   default
                 compl))))
    (cond ((use-region-p)
           (get-completion (filter-buffer-substring (region-beginning) (region-end))))
          ((word-at-point)
           (get-completion (word-at-point)))
          (t
           (read-from-minibuffer "Query: ")))))

;;;###autoload
(defun dictcc (query &optional source-lang destination-lang)
  "Search dict.cc for QUERY and insert a result at point.

Call it with a prefix argument to replace the source language and
with double prefix argument to replace both."
  (interactive
   (let* ((ask-languages (if current-prefix-arg (car current-prefix-arg) 0))
          (source-lang (when (>= ask-languages 4)
                         (dictcc--select-language
                          (format "Source language (overwriting %s): " dictcc-source-lang))))
          (destination-lang (when (>= ask-languages 16)
                              (dictcc--select-language
                               (format "Destination language (overwriting %s): " dictcc-destination-lang))))
          (query (dictcc--get-query)))
     (list query source-lang destination-lang)))
  (let ((dictcc-source-lang (or source-lang dictcc-source-lang))
        (dictcc-destination-lang (or destination-lang dictcc-destination-lang)))
    (dictcc--request query)))

;;;###autoload
(defun dictcc-at-point ()
  "Run a dict.cc search for the word at point or in an active region."
  (interactive)
  (if (use-region-p)
      (dictcc (filter-buffer-substring (region-beginning) (region-end)))
    (let ((query (word-at-point)))
      (if query (dictcc query)
        (error "No word at point")))))

(provide 'dictcc)
;;; dictcc.el ends here
