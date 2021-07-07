;;; voca-builder.el --- Helps you build up your vocabulary
;;
;; Copyright (C) 2015 Yi Tang
;;
;; Author: Yi Tang <yi.tang.uk@me.com>
;; Keywords: English vocabulary 
;; Package-Version: 20161101.1645
;; Package-Commit: 51573beec8cd8308477b0faf453aad93e17f57c5
;; Created: 28th March 2015
;; Package-Requires: ((popup "0.5.2"))
;; URL: https://github.com/yitang/voca-builder
;; Version: 0.1.0
;;
;; This program is free software; you can redistribute it and/or modify
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; * Commentary:
;;
;; voca-builder is an Emacs package that aimed to help you build up your
;; vocabulary by automating the most step in the process, so that you
;; actually spent time in learning new words.
;; It will do the checking, and shows the meaning as a popup above the
;; text. It also records the meaning and the sentence containing the word.
;; Finally, it can export vocabularies that have the same tags, or are
;; between two dates.
;;
;;; Use:
;;
;; To use voca-builder 
;;   (setq voca-builder/voca-file "~/.vocabulary.org")
;;   (setq voca-builder/export-file "~/.voca-builder-temp.org")
;;   (setq voca-builder/current-tag "Demo")
;;   (global-set-key (kbd "<f4>") 'voca-builder/search-popup) 
;;   
;; To export all the vocabulary tagged by TLOTR 
;;   (voca-builder/extract-by-tags "TLOTR") , get all the vocabularies tagged
;;   ;; by TLOTR,  The Lord of The Rings.
;; To export all the vocabulary recored between 2015-01-01 and 2015-03-01
;;   (voca-builder/extract-period "2015-01-01" "2015-03-01")
;;
;;; Code:

;; requires

(require 'org)
(require 'popup)
;;;; * Variables 
(defgroup voca-builder nil
  "Group voca-builder entries according to their version control status."
  :prefix "voca-builder-"
  :group 'convenience)

(defcustom voca-builder/voca-file "~/.vocabulary.org"
  "the file to store vocabularies" 
  :type 'file
  :group 'voca-builder)

(defcustom voca-builder/record-new-vocabulary t
  "If non-nil, record the new vocabulary that is checked and save the notes to voca-builder/voca-file."
  :type 'boolean
  :group 'voca-builder)

(defcustom voca-builder/record-with-ts t
  "if non-nil, record the vocabulary with a timestamp.

The timestamps are needed for export function"
  :type 'boolean
  :group 'voca-builder)

(defcustom voca-builder/popup-record-sentence t
  "If non-nil, record the sentence which contain the word that was looked into."
  :type 'boolean
  :group 'voca-builder)

(defcustom voca-builder/popup-show-short-meaning t
  "if non-nil, shows the short explnation of the vocabulary"
  :type 'boolean
  :group 'voca-builder)

(defcustom voca-builder/current-tag "Gene"
  "if non-nil, add tags to the vocabulary notes in org-mode"
  :type 'string
  :group 'voca-builder)

(defcustom voca-builder/popup-line-width 40
  "width of the popup menu"
  :type 'integer
  :group 'voca-builder)

;;;; * Functions 
(defun voca-builder/make-url (voca)
  (concat "http://www.vocabulary.com/dictionary/" voca))

(defun voca-builder/html-find-tag (tag &optional begining)
  "search for a html tag and return the point, if search filed, return the end of buffer point.
if begining is non-nil, return the point at the begining of the tag, instead of at the end"
  (cond ((search-forward tag nil t)
	 (if begining
	     (- (point) (length tag))
	   (point)))
	(t
	 ;;       (message "nothing found")
	 (point-max))))

(defun voca-builder/html-remove-emphasis-tags (a-string)
  "remove emphasis tags"
  (with-temp-buffer
    (insert a-string)
    (goto-char (point-min))
    (replace-string "<i>" "")
    (goto-char (point-min))
    (replace-string "</i>" "")
    (buffer-string)))

(defun voca-builder/html-find-content-of-tags (tag1 tag2)
  "It searchs the content that is wrapped by tag1 and tag2 in a HTML file, and return as a UTF-8 stirng. "
  (let* ((p-tag1 (voca-builder/html-find-tag tag1))
	 (p-tag2 (voca-builder/html-find-tag tag2 t))
	 (content (buffer-substring p-tag1 p-tag2))
	 (content-without-emphasis (voca-builder/html-remove-emphasis-tags content)))
    (decode-coding-string content-without-emphasis 'utf-8)))

(defun voca-builder/fetch-meaning (voca)
  "Parse the html content from www.vocabulary.com, and return the short and long meaning."
  (interactive)
  (with-current-buffer
      (url-retrieve-synchronously (voca-builder/make-url voca))
    (let* ((short-meaning (voca-builder/html-find-content-of-tags "<p class=\"short\">"
								  "</p>"))
	   (short-meaning (if (eq 0 (length short-meaning)) ;; if it has no short or long meaning. 
			      (voca-builder/html-find-content-of-tags "<meta name=\"description\" content =\""
								      "\" />")
			    short-meaning))	   
	   (long-meaning (voca-builder/html-find-content-of-tags "<p class=\"long\">"
								 "</p>"))
	   (long-meaning (if (eq 0 (length long-meaning)) ;; if it has no long meanings 
			     "nil"
			   long-meaning)))
      (if (string-match-p "Try the world&#039;s fastest, smartest dictionary:" short-meaning)
	  (cons "No meaning found"
		"No meaning found")
	(cons short-meaning
	      long-meaning)))))

(defun voca-builder/voca-org-entry (voca exp extra)
  "create a org-mode sub-tree for the new vocabulary, with timetsamp and tags"
  (let ((ts (if voca-builder/record-with-ts
		(format-time-string "[%Y-%m-%d %a %H:%M]")))
	(tag (if voca-builder/current-tag
		 (concat ":" voca-builder/current-tag ":")))
	(exp-filled (with-temp-buffer
		      (insert exp)
		      (fill-region (point-min) (point-max))
		      (buffer-string))))
    (concat "\n* " voca " " tag "\n" ts "\n\n" exp-filled "\n\n" extra)))

(defun voca-builder/record-voca (voca meaning extra)
  "save the vocabulary notes to file."
  (unless (string= "No meaning found" (car meaning))
    (cond (voca-builder/record-new-vocabulary
	   (let* ((string-meaning (concat
				   (car meaning)
				   "\n\n"
				   (cdr meaning)))
		  (org-entry (voca-builder/voca-org-entry voca string-meaning extra)))
	     (append-to-file org-entry nil voca-builder/voca-file))))))

(defun voca-builder/search-popup ()
  "search the word and shows the meaning in popup menu, may also save the notes"
  (interactive)
  (let* ((this-voca (thing-at-point 'word))
	 (this-sentence (if voca-builder/popup-record-sentence
			    (thing-at-point 'sentence)))
	 (meaning (voca-builder/fetch-meaning this-voca)))
    (if voca-builder/record-new-vocabulary
	(voca-builder/record-voca this-voca
				  meaning
				  this-sentence))
    (if voca-builder/popup-show-short-meaning
	(popup-tip (car meaning)
		   :width voca-builder/popup-line-width)
      (popup-tip (mapconcat 'identity
			    meaning
			    "\n")
		 :width voca-builder/popup-line-width))))

(defun voca-builder/search (this-voca)
  "search the word and shows the meaning in echo area, may also save the notes.
Back up function for voca-builder/search-popup."
  (interactive "sSearch for word: ")
  (let* ((this-sentence nil)
	 (meaning (voca-builder/fetch-meaning this-voca)))
    (if voca-builder/record-new-vocabulary
	(voca-builder/record-voca this-voca
				  meaning
				  this-sentence))
(if voca-builder/popup-show-short-meaning
	(message "%s" (car meaning))
      (message "%s" (mapconcat 'identity
			       meaning
			       "\n")))))

;;;; * Export 
(defun voca-builder/org-write-subtree ()
  "append current subtree to the voca-builder/export-file"
  (org-copy-subtree)
  (let ((str (with-temp-buffer
	       (org-paste-subtree)
	       (buffer-string))))
    (append-to-file str nil voca-builder/export-file)))


(defun voca-builder/extract-by-tags (tags)
  "export all vocabulary records with tags"
  (interactive)
  (org-map-entries 'voca-builder/org-write-subtree tags (list voca-builder/voca-file)))


(defun voca-builder/org-get-ts-for-subtree ()
  "search timesamp in the current subtree, for example [2015-03-28 Sat 12:01], and parse it to date"
  (search-forward-regexp "[0-9]+-[0-9]+-[0-9]+")
  (beginning-of-line)
  (forward-char)
  (voca-builder/encode-date (buffer-substring (point) (+ (point) 10))))

(defun voca-builder/encode-date (date1)
  "encode date
date: YYYY-MM-DD, for exmaple, 2015-12-01"
  (let* ((date1-s (split-string date1 "-")))
    (encode-time 0 0 0
		 (string-to-number (nth 2 date1-s))
		 (string-to-number (nth 1 date1-s))
		 (string-to-number (nth 0 date1-s)))))

(defun voca-builder/extract-by-periods-helper ()
  "it is created for FUN in org-map-entries does not take arguments"
  (let* ((ts-sub-tree (voca-builder/org-get-ts-for-subtree))
	 (p1 (time-less-p ts-sub-tree time2-internal))
	 (p2 (time-less-p time1-internal ts-sub-tree)))
    (if (and p1 p2)
	(voca-builder/org-write-subtree))))

(defun voca-builder/extract-period (p1 p2)
  "extract all vocabulary entries that are recorered between period p1 and p2.
period: YYYY-MM-DD, for exmaple, 2015-12-01"
  (interactive)
  (let ((time1-internal (voca-builder/encode-date p1))
	(time2-internal (voca-builder/encode-date p2)))
    (org-map-entries 'voca-builder/extract-by-periods-helper nil (list voca-builder/voca-file))))

(provide 'voca-builder)

;;;; * Test
;; (setq voca-builder/voca-file "~/vocabulary.org")
;; (setq voca-builder/current-tag "Demo")
;; (global-set-key (kbd "<f4>") 'voca-builder/search-popup)

;; (setq voca-builder/export-file "~/voca-builder-temp.org") 
;; (voca-builder/extract-by-tags "Demo") 
;; (voca-builder/extract-period "2015-01-05" "2015-04-01")

;;; voca-builder.el ends here
