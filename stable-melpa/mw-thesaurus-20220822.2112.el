;;; mw-thesaurus.el --- Merriam-Webster Thesaurus -*- lexical-binding: t; -*-
;;
;; Author: Ag Ibragimov
;; URL: https://github.com/agzam/mw-thesaurus.el
;; Created: Nov-2017
;; Keywords: wp, matching
;; License: GPL v3
;; Package-Requires: ((emacs "25") (request "0.3.0") (dash "2.16.0"))
;; Version: 1.0.1

;;; Commentary:

;; Thesaurus look up through www.dictionaryapi.com - Merriam-Webster online dictionary
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; For more than 150 years, in print and now online, Merriam-Webster has been America's leading and most-trusted provider of language information.
;; Each month, Merriam-Webster web sites offer guidance to more than 40 million visitors. In print, publications include Merriam-Webster's Collegiate Dictionary (among the best-selling books in American history) and newly published dictionaries for English-language learners.
;; All Merriam-Webster products and services are backed by the largest team of professional dictionary editors and writers in America, and one of the largest in the world.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'request)
(require 'thingatpt)
(require 'xml)
(require 'org)
(require 'dash)

(defgroup mw-thesaurus nil
  "Merriam-Webster Thesaurus"
  :prefix "mw-thesaurus-"
  :group 'applications)

(defvar mw-thesaurus-mode-map (make-sparse-keymap)
  "Keymap for minor mode variable `mw-thesaurus-mode'.")

(defvar mw-thesaurus-buffer-name "* Merriam-Webster Thesaurus *"
  "Default buffer name for Merriam-Webster Thesaurus.")

(define-minor-mode mw-thesaurus-mode
  "Merriam-Webster thesaurus minor mode
\\{mw-thesaurus-mode-map}"
  :group 'mw-thesaurus
  :lighter " Merriam-Webster"
  :init-value nil
  :keymap mw-thesaurus-mode-map
  (read-only-mode 1))

(define-key mw-thesaurus-mode-map [remap org-open-at-point] #'mw-thesaurus-lookup-at-point)
(define-key mw-thesaurus-mode-map (kbd "q") #'mw-thesaurus--quit)

(defcustom mw-thesaurus-api-key
  "67d977d5-790b-412e-a547-9dbcc2bcd525"
  "Merriam-Webster API access key."
  :type 'string)

(defcustom mw-thesaurus--base-url
  "http://www.dictionaryapi.com/api/v1/references/thesaurus/xml/"
  "Merriam-Webster API base URL."
  :type 'string)

(defun mw-thesaurus--get-xml-node (root path)
  "From parsed xml ROOT retrieves a node for given PATH.

Usage: `(mw-thesaurus--get-xml-node html-root '(html head title))`"
  (let ((current-node (xml-get-children root (car path))))
    (if (< 1 (length path))
        (mw-thesaurus--get-xml-node (car current-node) (cdr path))
      current-node)))

(defun mw-thesaurus--italicize (prop)
  "Check for element PROP containing <it> tag, retrieves content, resulting string is placed between '/' and '/'."
  (let ((its (mw-thesaurus--get-xml-node prop '(it))))
    (mapconcat
     (lambda (e)
       (if (member e its)
           (concat "​/" (-> e last car string-trim) "/​")
         (when (stringp e ) e)))
     prop "")))

(defun mw-thesaurus--snd-subs (article)
  "Second level of ARTICLE."
  (let* ((whole-sub (-> article
                        (mw-thesaurus--get-xml-node '(vi)) car))
         (sub-str (mw-thesaurus--italicize whole-sub)))
    (concat "   - " sub-str)))

(defun mw-thesaurus--other-tag (article tag-type)
  "Parse ARTICLE for different TAG-TYPE."
  (let ((content (-> article
                     (mw-thesaurus--get-xml-node `(,tag-type))
                     car
                     mw-thesaurus--italicize))
        (title (cond
                ((eq tag-type 'syn) "Synonyms")
                ((eq tag-type 'rel) "Related words")
                ((eq tag-type 'near) "Near antonyms")
                ((eq tag-type 'ant) "Antonyms")
                (t "Unknown type"))))
    (when (and content (< 0 (length content)))
      (string-join (list "\n*** " title ":\n    " (replace-regexp-in-string ";" "\n   " content t t)) ""))))

(defun mw-thesaurus--third-lvl (article)
  "Third level of ARTICLE."
  (let ((syns (mw-thesaurus--other-tag article 'syn))
        (rels (mw-thesaurus--other-tag article 'rel))
        (nears (mw-thesaurus--other-tag article 'near))
        (ants (mw-thesaurus--other-tag article 'ant)))
    (string-join (list syns rels nears ants) "")))

(defun mw-thesaurus--snd-level (entry)
  "Second level of ENTRY."
  (let ((articles (mw-thesaurus--get-xml-node entry '(sens))))
    (mapconcat
     (lambda (article)
       (let ((desc (-> (mw-thesaurus--get-xml-node article '(mc))
                       car
                       mw-thesaurus--italicize))
             (snd-subs (mw-thesaurus--snd-subs article))
             (third-lvl (mw-thesaurus--third-lvl article)))
         (string-join (list "** " desc "\n" snd-subs third-lvl) "")))
     articles
     "\n")))

(defun mw-thesaurus--get-title (entry)
  "Title for ENTRY."
  (-> (mw-thesaurus--get-xml-node entry '(term hw))
      car (seq-drop 2) car))

(defun mw-thesaurus--get-type (entry)
  "Type of the ENTRY is at <fl> tag."
  (-> (mw-thesaurus--get-xml-node entry '(fl))
      car (seq-drop 2) car))

(defun mw-thesaurus--parse (xml-data)
  "Parse xml returned by Merriam-Webster dictionary API.

Take XML-DATA, Returns multi-line text in ‘org-mode’ format."
  (let* ((entry-list (assq 'entry_list xml-data))
         (entries (xml-get-children entry-list 'entry)))
    (mapconcat
     (lambda (entry)
       (let ((fst-level (concat "* " (mw-thesaurus--get-title entry)
                                " ~" (mw-thesaurus--get-type entry) "~\n"))
             (snd-level (mw-thesaurus--snd-level entry)))
         (string-join (list fst-level snd-level) "")))
     entries "\n")))

(defun mw-thesaurus--create-buffer (word data)
  "Build mw-thesaurus buffer for WORD and the relevant DATA from Merriam-Webster API."
  (let ((dict-str (mw-thesaurus--parse data)))
    (if (< (length dict-str) 1)
        (message "Sadly, Merriam-Webster doesn't seem to have anything for '%s'" word)
      (let ((temp-buf (get-buffer-create mw-thesaurus-buffer-name)))
        ;; (print temp-buf)
        (unless (bound-and-true-p mw-thesaurus-mode)
          (switch-to-buffer-other-window temp-buf))
        (set-buffer temp-buf)
        (with-current-buffer temp-buf
          (let ((inhibit-read-only t))
            (setf (buffer-string) "")
            (setf org-hide-emphasis-markers t)
            (insert (decode-coding-string dict-str 'dos)))
          (org-mode)
          (mw-thesaurus-mode)
          (goto-char (point-min)))))))

(defun mw-thesaurus-get-original-word (beginning end)
  "Get a word to look for from the user.
`BEGINNING' and `END' correspond to the selected text (if selected).
If presented, the selected text will be used.
Otherwise, user must provide additional information."
  (if (use-region-p)
      (buffer-substring-no-properties beginning end)
    (read-string "Word to look up: ")))

(defun mw-thesaurus-is-at-the-beginning-of-word (word-point)
  "Predicate to check whether `WORD-POINT' points to the beginning of the word."
  (save-excursion
    ;; If we are at the beginning of a word
    ;; this will take us to the beginning of the previous word.
    ;; Otherwise, this will take us to the beginning of the current word.
    (backward-word)
    ;; This will take us to the end of the previous word or to the end
    ;; of the current word depending on whether we were at the beginning
    ;; of a word.
    (forward-word)
    ;; Compare our original position with wherever we're now to
    ;; separate those two cases
    (< (point) word-point)))

;;;###autoload
(defun mw-thesaurus-lookup-dwim ()
  "Look up a thesaurus definition on demand using Merriam-Webster online dictionary.
If a region is selected use mw-thesaurus-lookup-word
if a thing at point is not empty use mw-thesaurus-lookup-word-at-point
otherwise as for word using mw-thesaurus-lookup-word"
  (interactive)
  (let (beg end)
    (if (use-region-p)
        (progn
          (setq beg (region-beginning)
                end (region-end))
          (mw-thesaurus-lookup beg end))
      (if (thing-at-point 'word)
          (mw-thesaurus-lookup-at-point (point))
        (mw-thesaurus-lookup)))))

;;;###autoload
(defun mw-thesaurus-lookup-at-point (word-point)
  "Look up a thesaurus definition for word at point using Merriam-Webster online dictionary."
  (interactive (list (point)))
  (save-mark-and-excursion
    (unless (mw-thesaurus-is-at-the-beginning-of-word word-point)
      (backward-word))
    (set-mark (point))
    (forward-word)
    (activate-mark)
    (mw-thesaurus-lookup (region-beginning) (region-end))))

;;;###autoload
(defun mw-thesaurus-lookup (&optional beginning end)
  "Look up a thesaurus definition for word using Merriam-Webster online dictionary.
`BEGINNING' and `END' correspond to the selected text with a word to look up.
If there is no selection provided, additional input will be required."
  (interactive
   ;; it is a simple interactive function instead of interactive "r"
   ;; because it doesn't produce an error in a buffer without a mark
   (if (use-region-p) (list (region-beginning) (region-end))
     (list nil nil)))
  (let* ((word (mw-thesaurus-get-original-word beginning end))
         (url (concat (symbol-value 'mw-thesaurus--base-url)
                      word "?key="
                      (symbol-value 'mw-thesaurus-api-key))))
    (request url
             :parser (lambda () (xml-parse-region (point-min) (point-max)))
             :success (cl-function
                       (lambda (&key data &allow-other-keys)
                         (mw-thesaurus--create-buffer word data))))))

(defun mw-thesaurus--quit ()
  "Kill Merriam-Webster Thesaurus buffer."
  (interactive)
  (when-let* ((buffer (get-buffer mw-thesaurus-buffer-name)))
    (quit-window)
    (kill-buffer buffer)))

(provide 'mw-thesaurus)

;;; mw-thesaurus.el ends here
