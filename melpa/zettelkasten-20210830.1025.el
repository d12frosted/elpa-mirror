;;; zettelkasten.el --- Helper functions to organise notes in a Zettelkasten style  -*- lexical-binding: t; -*-

;; Author: Yann Herklotz <yann@ymhg.org>
;; URL: https://github.com/ymherklotz/emacs-zettelkasten
;; Package-Version: 20210830.1025
;; Package-Commit: 4048bf9e1be7ab759696a9541eec8f435359bcf3
;; Version: 0.3.0
;; Package-Requires: ((emacs "25.1") (s "1.10.0"))
;; Keywords: files, hypermedia, notes

;;; Commentary:

;; Used to organise notes using the Zettelkasten method.

;;; License:

;; Copyright (C) 2020-2021  Yann Herklotz
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'cl-lib)
(require 's)

(defgroup zettelkasten nil
  "Helper to work with zettelkasten notes."
  :group 'applications)

(defcustom zettelkasten-prefix [(control ?c) ?k]
  "Prefix key to use for Zettelkasten commands in Zettelkasten minor mode.
The value of this variable is checked as part of loading Zettelkasten mode.
After that, changing the prefix key requires manipulating keymaps."
  :type 'key-sequence
  :group 'zettelkasten)

(defcustom zettelkasten-directory (expand-file-name "~/zettelkasten")
  "Main zettelkasten directory."
  :type 'string
  :group 'zettelkasten)

(defcustom zettelkasten-file-format "%y%W%u%%02d"
  "Format for new zettelkasten files.

For supported options, please consult `format-time-string'."
  :type 'string
  :group 'zettelkasten)

(defcustom zettelkasten-link-format "[[./%2$s.%3$s][%1$s]]"
  "Zettelkasten link format."
  :type 'string
  :group 'zettelkasten)

(defcustom zettelkasten-extension "org"
  "Default extension for notes."
  :type 'string
  :group 'zettelkasten)

;;; -----------------------------
;;; HELPER FUNCTIONS FOR NOTE IDs
;;; -----------------------------

(defun zettelkasten--make-filename (note)
  "Make a filename using the default directory and the NOTE passed to it."
  (expand-file-name (concat zettelkasten-directory "/"
                            note "." zettelkasten-extension)))

(defun zettelkasten--filename-to-id (filename)
  "Convert FILENAME to id."
  (string-match (format "\\([0-9]*\\)\\.%s\\'" zettelkasten-extension) filename)
  (match-string 1 filename))

(defun zettelkasten--display-for-search (note)
  "Dispaly the NOTE's title and id.

Meant for displaying when searching."
  (format "%s: %s" note (zettelkasten--get-note-title note)))

(defun zettelkasten--get-id (note)
  "Return the id for a NOTE.

The note may be formatted with some title, which this function
aims to remove."
  (string-match "[^0-9]*\\([0-9]+\\)" note)
  (match-string 1 note))

(defun zettelkasten--format-link (note &optional link-text)
  "Format a LINK-TEXT to a NOTE."
  (format zettelkasten-link-format
          (or link-text (zettelkasten--get-note-title note))
          (zettelkasten--get-id note)
          zettelkasten-extension))

;;; ---------------------------
;;; LISTING AND SEARCHING NOTES
;;; ---------------------------

(defun zettelkasten--note-regexp (note regexp &optional num)
  "Return the REGEXP first match in the NOTE.

Return the NUMth match.  If NUM is nil, return the 0th match."
  (with-temp-buffer
    (insert-file-contents-literally
     (zettelkasten--make-filename note))
    (when (re-search-forward regexp nil t)
      (match-string (if num num 0)))))

(defun zettelkasten--note-regexp-multiple (note regexp &optional num)
  "Return the REGEXP matched in the NOTE.

Return the NUMth match.  If NUM is nil, return the 0th match."
  (with-temp-buffer
    (insert-file-contents-literally
     (zettelkasten--make-filename note))
    (let (match-list)
      (while (re-search-forward regexp nil t)
        (setq match-list (append match-list (list (match-string (if num num 0))))))
      match-list)))

(defun zettelkasten--match-link (current note)
  "Return the note if the link to CURRENT is in the NOTE."
  (when (zettelkasten--note-regexp
         note
         (let ((zk-link-format (replace-regexp-in-string
                                "\\\\\\$" "$"
                                (regexp-quote zettelkasten-link-format))))
           (format zk-link-format
                   ".*" current
                   zettelkasten-extension)))
    note))

(defun zettelkasten--list-notes-by-id ()
  "Return all the ids that are currently available."
  (mapcar #'zettelkasten--filename-to-id
          (directory-files
           (expand-file-name zettelkasten-directory) nil
           (format "[0-9]+\\.%s$" zettelkasten-extension) t)))

(defun zettelkasten--list-notes-grep ()
  "Return all the ids and titles of notes in the `zettelkasten-directory'.

This is deprecated in favour for `zettelkasten-list-notes'."
  (shell-command (concat "grep -i \"#+TITLE:\" " zettelkasten-directory "/*"))
  (let (match-list morelines current-string matched-string)
    (with-current-buffer "*Shell Command Output*"
      (set-buffer "*Shell Command Output*")
      (setq morelines t)
      (goto-char 1)
      (while morelines
        (setq current-string
              (buffer-substring-no-properties
               (line-beginning-position)
               (line-end-position)))
        (when (string-match
               (format "\\([0-9]*\\)\\.%s:#\\+TITLE: \\(.*\\)"
                       zettelkasten-extension)
               current-string)
          (setq matched-string (concat (match-string 1 current-string) ": "
                                       (match-string 2 current-string)))
          (setq match-list (append match-list (list matched-string))))
        (setq morelines (= 0 (forward-line 1)))))
    (kill-buffer "*Shell Command Output*")
    match-list))

(defun zettelkasten--list-notes ()
  "Return all the ids and titles of notes in the `zettelkasten-directory'."
  (mapcar #'zettelkasten--display-for-search
          (zettelkasten--list-notes-by-id)))

(defun zettelkasten--list-links (note)
  "List all notes that the current NOTE links to."
  (sort
   (cl-remove-duplicates
    (mapcar #'zettelkasten--get-id
            (zettelkasten--note-regexp-multiple
             note
             (let ((zk-link-format (replace-regexp-in-string
                                    "\\\\\\$" "$"
                                    (regexp-quote zettelkasten-link-format))))
               (format zk-link-format
                       ".*" ".*"
                       zettelkasten-extension))))) #'string<))

;;; ------------------
;;; CREATING NEW NOTES
;;; ------------------

(defun zettelkasten--find-new-note-name (note)
  "Iterate on ITERATION until a usable file based on NOTE is found."
  (let ((iteration 0)
        (maxcount 10000))
    (while (and (< iteration maxcount)
                (file-exists-p
                 (zettelkasten--make-filename (format note iteration))))
      (setq iteration (+ iteration 1)))
    (format note iteration)))

(defun zettelkasten--add-link-to-parent (note parent)
  "Add a link to NOTE from a PARENT."
  (with-temp-file (zettelkasten--make-filename parent)
    (insert-file-contents-literally (zettelkasten--make-filename parent))
    (goto-char (point-max))
    (insert "\n" (zettelkasten--format-link note))))

(defun zettelkasten--create-new-note-ni (title &optional parent)
  "Create a new note based on the TITLE and it's optional PARENT note.

If PARENT is nil, it will not add a link from a PARENT."
  (let* ((note (zettelkasten--find-new-note-name
                (format-time-string zettelkasten-file-format)))
         (filename (zettelkasten--make-filename note)))
    (with-temp-buffer
      (set-visited-file-name filename)
      (set-buffer-file-coding-system 'utf-8)
      (insert "#+TITLE: " title
              (format-time-string "\n#+DATE: %c\n#+TAGS:\n\n"))
      (save-buffer))
    (when parent
      (zettelkasten--add-link-to-parent note (zettelkasten--get-id parent)))
    (find-file filename)))

(defun zettelkasten--find-parents (note)
  "Find the parents of the NOTE."
  (delete
   nil
   (mapcar (lambda (el) (zettelkasten--match-link
                         note el))
           (zettelkasten--list-notes-by-id))))

(defun zettelkasten--get-note-title (note)
  "Return the title of the NOTE."
  (zettelkasten--note-regexp note "#\\+TITLE: \\(.*\\)" 1))

;;; -----------------
;;; DEALING WITH TAGS
;;; -----------------

(defun zettelkasten--get-tags (note)
  "Get all the tags for a specific NOTE."
  (let ((tags (zettelkasten--note-regexp
               note "#\\+TAGS: \\(.*\\)" 1)))
    (when tags
      (mapcar #'s-trim (s-split "," tags)))))

(defun zettelkasten--get-tags-and-ids ()
  "Return a mapping from TAGS to ids for NOTE."
  (let ((tags nil)
        (onlytags nil))
    (mapc
     (lambda (note)
       (mapc
        (lambda (el)
          (when el
            (let* ((ismember (member el tags))
                   (currlist (cdr ismember)))
              (if ismember
                  (setcar currlist (append (car currlist) (list note)))
                (progn
                  (setq tags (append (list el (list note)) tags))
                  (push el onlytags))))))
        (zettelkasten--get-tags note)))
     (zettelkasten--list-notes-by-id))
    (append (list onlytags) tags)))

;;; -------------------------------
;;; HELPER FUNCTIONS FOR `org-mode'
;;; -------------------------------

(defun zettelkasten--indent (amount str-list)
  "Indent STR-LIST by some AMOUNT."
  (mapcar (lambda (n) (concat (make-string amount ?\s) n)) str-list))

(defun zettelkasten--generate-list-for-note-nc (notes)
  "Generate a list of NOTES."
  (if notes
      (apply #'append
             (mapcar (lambda (n)
                       (cons (concat "- " (zettelkasten--format-link n) "\n")
                             (zettelkasten--indent
                              2 (zettelkasten--generate-list-for-note-nc
                                 (zettelkasten--list-links n)))))
                     notes)) ""))

(defun zettelkasten--generate-list-for-note (note)
  "Generate a list of links for NOTE."
  (zettelkasten--generate-list-for-note-nc (zettelkasten--list-links note)))

(defun zettelkasten--list-notes-without-parents ()
  "List all the notes that do not have any parents."
  (delete nil (mapcar (lambda (n)
                        (if (zettelkasten--find-parents n) nil n))
                      (zettelkasten--list-notes-by-id))))

(defun zettelkasten-generate-site-map (title _)
  "Generate the site map for the Zettelkasten using TITLE."
  (let* ((ti (zettelkasten--get-tags-and-ids))
         (tags (sort (car ti) #'string<)))
    (concat
     "#+TITLE: " title "\n\n"
     (apply
      #'concat
      (mapcar
       (lambda (tag)
         (concat "[[#" tag "][" tag "]] \| "))
       tags))
     "\n\n* Index\n\n"
     (apply
      #'concat
      (zettelkasten--generate-list-for-note-nc (sort (zettelkasten--list-notes-without-parents) #'string>)))
     "\n* Tags\n\n"
     (apply
      #'concat
      (mapcar
       (lambda (tag)
         (let* ((ismember (member tag ti))
                (currlist (car (cdr ismember))))
           (with-temp-buffer
             (set-visited-file-name (concat tag ".org"))
             (set-buffer-file-coding-system 'utf-8)
             (insert "#+TITLE: " (capitalize tag) "\n\n"
                     (apply
                      #'concat
                      (mapcar
                       (lambda (note)
                         (concat "- " (zettelkasten--format-link note) "\n"))
                       currlist)))
             (save-buffer))
           (concat "** " (capitalize tag) "\n  :PROPERTIES:\n  :CUSTOM_ID: " tag "\n  :END:\n\n"
                   (apply
                    #'concat
                    (mapcar
                     (lambda (note)
                       (concat "- " (zettelkasten--format-link note) "\n"))
                     currlist))
                   "\n")))
       tags)))))

(defun zettelkasten-org-export-preprocessor (_)
  "A preprocessor for Zettelkasten directories.

Adds information such as backlinks to the `org-mode' files before
publishing."
  (unless (string= (zettelkasten--filename-to-id (buffer-file-name)) "")
    (let ((notes (zettelkasten--find-parents
                  (zettelkasten--filename-to-id (buffer-file-name))))
          (tags (zettelkasten--get-tags
                 (zettelkasten--filename-to-id (buffer-file-name)))))
      (save-excursion
        (when tags
          (goto-char (point-min))
          (insert
           "#+begin_export html\n<div class=\"tags\"><ul>\n"
           (mapconcat (lambda (el) (concat "<li><a href=\"" el
                                           ".html\">" el "</a></li>\n")) tags "")
           "</ul></div>\n#+end_export\n"))
        (when notes
          (goto-char (point-max))
          (insert
           (mapconcat #'identity (append
                                 '("\n* Backlinks\n")
                                 (mapcar
                                  (lambda
                                    (el)
                                    (concat "- " (zettelkasten--format-link el) "\n"))
                                  notes)) "")))))))

;;; ---------------------
;;; INTERACTIVE FUNCTIONS
;;; ---------------------

(defun zettelkasten-insert-link (note)
  "Insert a link to another NOTE in the current note.
if region is active use that as link text"
  (interactive
   (list (completing-read "Notes: "
                          (zettelkasten--list-notes) nil 'match)))
  (let ((region-text (when (use-region-p)
                       (prog1 (buffer-substring-no-properties (region-beginning)
                                                              (region-end))
                         (delete-region (region-beginning) (region-end))))))
    (insert (zettelkasten--format-link (zettelkasten--get-id note) region-text))))

(defun zettelkasten-create-new-note (prefix)
  "Create a new zettelkasten.

If PREFIX is used, or if the `zettelkasten-directory' is empty,
does not create a parent.

Also see `zettelkasten--create-new-note-ni' for more information."
  (interactive "P")
  (let ((title (read-string "Note title: "))
        (notes (zettelkasten--list-notes)))
    (zettelkasten--create-new-note-ni
     title
     (unless (or prefix (not notes))
       (completing-read "Parent note: " notes nil 'match)))))

(defun zettelkasten-open-parent (&optional note)
  "Find the parent notes to the NOTE that is given.

The format of the NOTE is anything that can be ready by
  `zettelkasten--get-id'."
  (interactive)
  (let* ((act-note
          (if note (zettelkasten--get-id note)
            (zettelkasten--filename-to-id (buffer-file-name))))
         (selected (completing-read
                    "Notes: "
                    (mapcar #'zettelkasten--display-for-search
                            (zettelkasten--find-parents act-note))
                    nil 'match)))
    (find-file (zettelkasten--make-filename (zettelkasten--get-id selected)))))

(defun zettelkasten-open-note (note)
  "Open an existing NOTE, searching by title and id."
  (interactive
   (list (completing-read "Notes: "
                          (zettelkasten--list-notes) nil 'match)))
  (find-file (zettelkasten--make-filename (zettelkasten--get-id note))))

(defun zettelkasten-open-note-by-tag ()
  "Open a note by filtering on tags."
  (interactive)
  (let* ((all (zettelkasten--get-tags-and-ids))
         (onlytags (car all))
         (tags (cdr all))
         (chosentag (completing-read
                     "Tags: "
                     onlytags
                     nil 'match))
         (chosennote
          (let ((ismember (member chosentag tags)))
            (completing-read
             "Note: "
             (mapcar #'zettelkasten--display-for-search (car (cdr ismember)))
             nil 'match))))
    (find-file (zettelkasten--make-filename (zettelkasten--get-id chosennote)))))

;;; ---------------------------------
;;; FUNCTIONS FOR `zettelkasten-mode'
;;; ---------------------------------

(defvar zettelkasten-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "i" #'zettelkasten-insert-link)
    (define-key map "n" #'zettelkasten-create-new-note)
    (define-key map "p" #'zettelkasten-open-parent)
    (define-key map "o" #'zettelkasten-open-note)
    (define-key map "t" #'zettelkasten-open-note-by-tag)
    map))

(defvar zettelkasten-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map zettelkasten-prefix zettelkasten-mode-map)
    map)
  "Keymap used for binding footnote minor mode.")

;;;###autoload
(define-minor-mode zettelkasten-mode
  "Enable the keymaps to be used with zettelkasten."
  :lighter " zettelkasten"
  :keymap zettelkasten-minor-mode-map
  :global t)

(provide 'zettelkasten)

;;; zettelkasten.el ends here
