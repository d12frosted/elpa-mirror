;;; filetags.el --- Package to manage filetags in filename  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Max Beutelspacher

;; Author: Max Beutelspacher
;; URL: https://github.com/DerBeutlin/filetags.el
;; Package-Version: 20190706.804
;; Package-Commit: 01e6a919507a832ee001a2a0fc257657f8b04b72
;; Keywords: convenience, files
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A package to organize filetags in the filename.


;;; Code:
(require 'seq)
(require 'subr-x)
(require 'cl-lib)
(require 'dired)

(defgroup filetags nil "A helper for managing filetags directly in the filename"
  :group 'applications)

(defcustom filetags-delimiter-between-filename-and-tags " -- " "Delimiter between filename and tags."
   :type 'string)

(defcustom filetags-delimiter-between-tags " " "Delimiter between individual tags."
  :type 'string)

(defcustom filetags-controlled-vocabulary '(())
  "List of lists of possible filetags.
The tags in this list as well as tags already used in the
filename are used for the autocompletion.
If the variable `filetags-enforce-controlled-vocabulary' is t
then no other tags can be added.
Tags in the same sublist are mutually exclusive tags."
  :type 'sexp)

(defcustom filetags-load-controlled-vocabulary-from-file nil
  "Toggle if filetags should be loaded from file.
If t then the variable `filetags-controlled-vocabulary' is ignored
and the tags are loaded from a file with name .filetags in the upper tree."
  :type 'bool)

(defcustom filetags-enforce-controlled-vocabulary nil
  "If t, only tags in the controlled vocabulary can be used.
The controlled vocabulary is either loaded from file
if the variable `filetags-load-controlled-vocabulary-from-file' is t
or is set in the variable `filetags-controlled-vocabulary'."
   :type 'bool)

(defun filetags-extract-filetags (filename)
  "Extract the tags from FILENAME and return them as a sorted, unique list."
  (if (string-match-p (regexp-quote filetags-delimiter-between-filename-and-tags)
                      (file-name-sans-extension filename))
      (filetags-sort-and-uniq-tags (split-string (car (last (split-string (file-name-sans-extension filename)
                                                                          filetags-delimiter-between-filename-and-tags)))
                                                 (regexp-quote filetags-delimiter-between-tags) t split-string-default-separators))
    nil))

(defun filetags-sort-and-uniq-tags (tags)
  "Take a list of strings TAGS, remove duplicates and sort them."
  (remove nil(sort (cl-remove-duplicates tags :test 'string=)
                   'string<)))

(defun filetags-extract-filename-without-tags (filename)
  "Return the FILENAME but remove the tags.
Tags are separated from the rest of the filename
using the delimiter set in the variable `filetags-delimiter-between-filename-and-tags'."
  (car (split-string (file-name-sans-extension filename)
                     filetags-delimiter-between-filename-and-tags)))

(defun filetags-generate-new-filename (filename tags)
  "Generate filename with list of strings TAGS from FILENAME.
Tags are separated from the rest of the filename
using the delimiter set in the variable `filetags-delimiter-between-filename-and-tags'."
  (let ((new_filename (filetags-extract-filename-without-tags filename))
        (extension (file-name-extension filename)))
    (concat new_filename
            (when tags
              (concat filetags-delimiter-between-filename-and-tags
                      (mapconcat #'identity (filetags-sort-and-uniq-tags tags) filetags-delimiter-between-tags)))
            (when extension ".") extension)))

(defun filetags-add-tags-to-filename (fullname tags)
  "Append TAGS in alphabetical and unique order to FULLNAME."
  (let* ((old_tags (filetags-extract-filetags (file-name-nondirectory fullname)))
         (all_tags (filetags-sort-and-uniq-tags (append tags old_tags)))
         (new_file_name (filetags-generate-new-filename (file-name-nondirectory fullname)
                                                        all_tags)))
    (concat (file-name-directory fullname)
            new_file_name)))

(defun filetags-remove-tags (fullname tags)
  "Remove any occurence of TAGS from the FULLNAME."
  (let* ((old_tags (filetags-extract-filetags (file-name-nondirectory fullname)))
         (all_tags (filetags-sort-and-uniq-tags (cl-set-difference old_tags tags :test 'string=)))
         (new_file_name (filetags-generate-new-filename (file-name-nondirectory fullname)
                                                        all_tags)))
    (concat (file-name-directory fullname)
            new_file_name)))

(defun filetags-update-tags (fullname tags-with-prefix)
  "Append or remove TAGS-WITH-PREFIX from/to FULLNAME depending on the prefix.
Tags with a + as prefix are appended.
Tags with a - as prefix are removed."
  (let* ((tags-to-add (filetags-filter-add-tags tags-with-prefix))
         (tags-to-remove (append (filetags-all-mutually-exclusive-tags-to-remove
                                  tags-to-add)
                                 (filetags-filter-remove-tags tags-with-prefix)))
         (new-filename))
    (setq new-filename (filetags-add-tags-to-filename fullname tags-to-add))
    (filetags-remove-tags new-filename tags-to-remove)))

(defun filetags-update-tags-write (fullname tags-with-prefix)
  "Rename the file FULLNAME with added or removed tags.
Tags in TAGS-WITH-PREFIX are removed or added depending on their prefix.
Tags with a + as prefix are appended.
Tags with a - as prefix are removed."
  (let ((new-filename (filetags-update-tags fullname tags-with-prefix)))
    (progn
      (unless (string= fullname new-filename)
        (if (not (file-exists-p new-filename))(rename-file fullname new-filename nil) (message (format "File %s already exists" new-filename))))
      (unless (string= (file-truename new-filename) new-filename)
        (filetags-rename-link-origin-and-relink new-filename tags-with-prefix))
      new-filename)))

(defun filetags-filter-add-tags (tags-with-prefix)
  "Filter out the tags out of TAGS-WITH-PREFIX that have the + prefix."
  (mapcar (lambda (str)
            (filetags-trim-action str "+"))
          (seq-filter (lambda (tag)
                        (string-prefix-p "+" tag))
                      tags-with-prefix)))

(defun filetags-filter-remove-tags (tags-with-prefix)
  "Filter out the tags out of TAGS-WITH-PREFIX that have the - prefix."
  (mapcar (lambda (str)
            (filetags-trim-action str "-"))
          (seq-filter (lambda (tag)
                        (string-prefix-p "-" tag))
                      tags-with-prefix)))

(defun filetags-union (list)
  "Return the sorted and unique union of a list of list of strings LIST."
  (filetags-sort-and-uniq-tags (filetags-flatten list)))

(defun filetags-intersection (l &rest rest)
  "Return the sorted and unique intersection of a list of list of strings L.
REST are optional arguments like providing the test method using :test.
taken from https://stackoverflow.com/a/31422481"
  (filetags-sort-and-uniq-tags (cond
                                ((null l) nil)
                                ((null (cdr l))
                                 (car l))
                                (t (apply #'cl-intersection
                                          (car l)
                                          (apply #'filetags-intersection
                                                 (cdr l) rest)
                                          rest)))))


(defun filetags-flatten (l)
  "Flatten the list of list L to a list containing all elements.
taken from https://stackoverflow.com/a/2712585"
  (cond ((null l) nil)
        ((atom (car l)) (cons (car l) (filetags-flatten (cdr l))))
        (t (append (filetags-flatten (car l)) (filetags-flatten (cdr l))))))


(defun filetags-accumulate-remove-tags-candidates (filenames)
  "Accumulate all tags in FILENAMES to form a list of candidates to remove."
  (filetags-union (mapcar #'filetags-extract-filetags filenames)))

(defun filetags-accumulate-add-tags-candidates (filenames)
  "Form a list of possible candidates for removal.
Accumulate all tags from the controlled vocabulary which are not in FILENAMES
to form the list."
  (let ((remove-tags (filetags-accumulate-remove-tags-candidates
                      filenames))
        (tags-in-every-file (filetags-intersection (mapcar #'filetags-extract-filetags filenames)
                                                   :test #'string=)))
    (filetags-sort-and-uniq-tags (filetags-union (list
                                                  (cl-set-difference remove-tags tags-in-every-file
                                                                     :test #'string=)
                                                  (cl-set-difference (filetags-union (filetags-get-controlled-vocabulary))
                                                                     tags-in-every-file
                                                                     :test #'string=))))))

(defun filetags-prepend (prefix tag)
  "Prepend PREFIX to TAG."
  (concat prefix tag))


(defun filetags-prepend-list (prefix tags)
  "Prepend PREFIX to every tag in TAGS."
  (mapcar (lambda (str) (filetags-prepend prefix str)) tags))

(defun filetags-completing-read-tag (collection selected-tags)
  "Completing read function for filetags with collection COLLECTION.
SELECTED-TAGS is a list of already selected tags.
If \"Commit\" is chosen return nil otherwise return the chosen tag."
(let ((new-tag
       (completing-read
        (concat "Add/remove tags with '+<tag>' or '-<tag>' "
                (if selected-tags
                    (format " (%s)" (mapconcat #'identity selected-tags " ")))
                ":")
        (push "Commit" collection)
        nil
        filetags-enforce-controlled-vocabulary
        nil
        nil
        "Commit")))
  (unless (string= new-tag "Commit") new-tag)))


;;;###autoload
(defun filetags-dired-update-tags ()
  "Prompt the user for tag-actions and perform these actions.
The action can be to add a tag with prefix +
or to remove a tag with prefix -.
The actions are applied on marked files in dired if existing
or the file on point otherwise."
  (interactive)
  (let* ((tags-with-prefix)
         (entered-tag t)
         (filenames (if (dired-get-marked-files)
                        (dired-get-marked-files)
                      '((dired-get-filename))))
         (add-candidates (filetags-prepend-list "+"
                                                (filetags-accumulate-add-tags-candidates filenames)))
         (remove-candidates (filetags-prepend-list "-"
                                                   (filetags-accumulate-remove-tags-candidates
                                                    filenames))))
    (while entered-tag
      (progn
        (setq entered-tag (filetags-completing-read-tag (filetags-construct-candidates add-candidates
                                                                               remove-candidates tags-with-prefix)
                                                tags-with-prefix))
        (if entered-tag
            (if (or (string-prefix-p "+" entered-tag)
                    (string-prefix-p "-" entered-tag))
                (setq tags-with-prefix (filetags-update-tags-with-prefix entered-tag
                                                                         tags-with-prefix))
              (message "Tag Action has to start with + or -"))
          (progn
            (dolist (filename filenames)
              (filetags-update-tags-write filename tags-with-prefix)))
          (revert-buffer nil t t))))))


(defun filetags-update-tags-with-prefix (entered-tag tags-with-prefix)
  "Merge ENTERED-TAG into TAGS-WITH-PREFIX.
Add the tag if not already present.
If the inverse tag action is already present remove it."
  (let* ((inverse-entered-tag (filetags-inverse-tag entered-tag)))
    (if (member inverse-entered-tag tags-with-prefix)
        (setq tags-with-prefix (delete inverse-entered-tag tags-with-prefix))
      (unless (member entered-tag tags-with-prefix)
        (push entered-tag tags-with-prefix)))))

(defun filetags-inverse-tag (tag)
  "Return the tag with the inverse prefix to TAG."
  (let ((bare-tag (filetags-trim-all-actions tag))
        (prefix-tag (substring tag 0 1)))
    (if (string= prefix-tag "+")
        (filetags-prepend "-" bare-tag)
      (filetags-prepend "+" bare-tag))))

(defun filetags-trim-action (tag action)
  "Remove ACTION from prefixed TAG."
  (if (string-prefix-p action tag) (substring tag 1) tag))

(defun filetags-trim-all-actions (tag)
  "Remove all actions from prefixed TAG."
  (if (string-prefix-p "+" tag) (filetags-trim-action tag "+") (filetags-trim-action tag "-")))


(defun filetags-construct-candidates (add-candidates remove-candidates tags-with-prefix)
  "Merge ADD-CANDIDATES and REMOVE-CANDIDATES into TAGS-WITH-PREFIX.
ADD candidates only if not already present and add the inverses of TAGS—WITH—PREFIX."
  (let ((inverse-tags (mapcar #'filetags-inverse-tag tags-with-prefix))
        (unused-add-candidates (cl-set-difference add-candidates tags-with-prefix
                                               :test 'string=))
        (unused-remove-candidates (cl-set-difference remove-candidates tags-with-prefix
                                                  :test 'string=)))
    (filetags-sort-and-uniq-tags (append (append unused-add-candidates unused-remove-candidates)
                                         inverse-tags))))


(defun filetags-mutually-exclusive-tags-to-remove (tag)
  "Return all corresponding mutually exclusive tags to TAG.
Mutually exclusive tags are the tags in a sublist in the variable
`filetags-controlled-vocabulary' or which are in the same line in
the .filetags file."
  (let (mutually-exclusive-tags)
    (dolist (tags (filetags-get-controlled-vocabulary))
      (when (and (> (length tags) 1)
                 (seq-contains tags tag #'string=))
        (setq mutually-exclusive-tags (append mutually-exclusive-tags
                                              (delete tag tags)))))
    (filetags-sort-and-uniq-tags mutually-exclusive-tags)))

(defun filetags-all-mutually-exclusive-tags-to-remove (tags)
  "Return corresponding mutually exclusive tags for all tags in the list TAGS.
Mutually exclusive tags are the tags in a sublist in the variable
`filetags-controlled-vocabulary' or which are in the same line in
the .filetags file."
  (let (mutually-exclusive-tags)
    (dolist (tag tags)
      (setq mutually-exclusive-tags (append mutually-exclusive-tags
                                            (filetags-mutually-exclusive-tags-to-remove
                                             tag))))
    (filetags-sort-and-uniq-tags mutually-exclusive-tags)))


(defun filetags-read-controlled-vocabulary-from-file (file)
  "Read controlled vocabulary from a  provided .filetags FILE."
  (if file
      (with-temp-buffer
        (insert-file-contents file)
        (mapcar #'filetags-parse-vocabulary-line
                (split-string (buffer-string)
                              "\n"
                              t)))
    '(())))

(defun filetags-parse-vocabulary-line (line)
  "Parse one LINE of a .filetags file."
  (split-string (car (split-string line "#"))
                " "
                t))

(defun filetags-get-controlled-vocabulary ()
  "Return controlled vocabulary either from variable or from file.
Whether to read it from variable or from file
depends on the value of the variable
`filetags-load-controlled-vocabulary-from-file'."
  (if filetags-load-controlled-vocabulary-from-file
      (filetags-read-controlled-vocabulary-from-file (filetags-find-dot-filetags-in-upper-tree (dired-current-directory)))
    filetags-controlled-vocabulary))

(defun filetags-find-dot-filetags-in-upper-tree (dir)
  "Search for .filetags file in DIR and all upper directories and return the path to file."
  (let ((file-candidate (concat (file-name-as-directory dir) ".filetags"))
        (parent-dir (file-name-directory (directory-file-name dir))))
    (when (string= parent-dir dir)
      (setq parent-dir nil))
    (if (file-exists-p file-candidate)
        file-candidate
      (when parent-dir
        (filetags-find-dot-filetags-in-upper-tree
         parent-dir)))))

(defun filetags-rename-link-origin-and-relink (path tags-with-prefix)
  "Add TAGS-WITH-PREFIX to PATH keep existing links intact."
  (let ((origin-path (file-chase-links path 1)))
    (unless (string= origin-path path )
      (let* ((origin-new-filename (filetags-update-tags-write origin-path tags-with-prefix)))
        (make-symbolic-link origin-new-filename path t)))))

(provide 'filetags)
;;; filetags.el ends here
