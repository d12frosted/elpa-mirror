;;; abgaben.el --- review and correct assignments received by mail
     
;; Copyright (C) 2017 Arne Köhn
     
;; Author: Arne Köhn <arne@chark.eu>
;; Created: 31 Oct 2017
;; Keywords: mail outlines convenience
;; Package-Commit: 20d14830f07d66e2a04bcad1498a4a6fbf4b4451
;; Homepage: http://arne.chark.eu/
;; Package-Requires: ((pdf-tools "0.80") (f "0.19.0") (s "1.11.0"))
;; Package-Version: 20171119.646
;; Package-X-Original-Version: 1.1.2

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
;; abgaben.el (German for what students return when given assignments)
;; is a set of functions for dealing with assignments.  It assumes
;; that you use mu4e for your mails and org-mode for notes.
;;
;; You should add something like this to your configuration:
;; (add-to-list 'mu4e-view-attachment-actions
;; '("gAbGabe speichern" . abgaben-capture-submission) t)
;; and of course customize the variables of this package.
;;
;; The basic workflow is as follows:
;; You receive mails with assignments from your students
;; You use an attachment action (A g  if you used the example above) where you
;;  - select the group this assignment belongs to
;;    e.g. you have several different courses or (as I usually have)
;;    two groups for your practical
;;  - select the current week
;; It then saves that attachment to ABGABEN-ROOT-FOLDER/[group]/[week]/
;; and creates the directories as needed.
;; the the assignment is a .zip or .tar.gz file, it will automatically be
;; unpacked into a new directory.
;; After that, it produces a new heading in your ABGABEN-ORG-File
;; under ABGABEN-HEADING / [group] / [week]
;; containing a link to the saved attachment and the email.
;; (Note: The ABGABEN-HEADING / [group] heading needs to exist already,
;; 	   the week heading will be created if it does not exist)

;; You can then open the PDFs from your org file and annotate them.
;; After your annotations, you can use
;; abgaben-export-pdf-annot-to-org to export your annotations as
;; subheadings of the current assignment.  This export will capture
;; all points you have given by matching your annotation lines to
;; abgaben-points-re and summing the points achieved and achievable
;; points.

;; You can then invoke abgaben-prepare-reply to open the original
;; mail.  You will have a reply in your kill-ring prepared with your
;; annotations exported as text and the annotated pdf as attachment.

;; Press reply, yank, send, your are done!


;;; Code:
(provide 'abgaben)
(require 'pdf-annot)
(require 'f)
(require 's)
(require 'mu4e)

(defconst abgaben-pdf-tools-org-non-exportable-types
  (list 'link)
  "Types of annotation that are not to be exported.")

;;;###autoload
(defgroup abgaben nil "A system for receiving and grading
submissions for assignments using mu4e, org-mode and pdf-tools"
  :group 'applications)

;;;###autoload
(defcustom abgaben-root-folder (expand-file-name "$HOME/abgaben/")
  "Directory in which submissions will be saved."
  :group 'abgaben
  :type '(string))

;;;###autoload
(defcustom abgaben-org-file
  (f-join abgaben-root-folder "abgaben.org")
  "File in which the links and notes are saved."
  :group 'abgaben
  :type '(string))

;;;###autoload
(defcustom abgaben-heading "Abgaben"
  "Name or ID of the org heading under which submissions should be inserted."
  :group 'abgaben
  :type '(string))

;;;###autoload
(defcustom abgaben-points-re "assignment [0-9.]*: ?\\([0-9.]*\\)/\\([0-9.]*\\)"
  "Regular expression to match points in comments.
Has two groups: first for points achieved, second for achievable points."
  :group 'abgaben
  :type '(regexp))

;;;###autoload
(defcustom abgaben-all-groups '("group1" "group2")
  "Groups which you have, e.g. different days."
  :group 'abgaben
  :type '(repeat string))


;;;###autoload
(defcustom abgaben-all-weeks (mapcar (lambda (x) (format "%02d" x)) (number-sequence 1 14))
  "All weeks, defaults to 01..14."
  :group 'abgaben
  :type '(repeat string))

(defcustom abgaben-points-heading "your points"
  "Heading used for collected points."
  :group 'abgaben
  :type 'string)

(defcustom abgaben-points-overall "overall"
  "Prefix for accumulation of your points, i.e. 'Overall' in 'Overall: 50/100'."
  :group 'abgaben
  :type 'string)


(defvar abgaben--curr-week (car abgaben-all-weeks))
(defvar abgaben--curr-group (car abgaben-all-groups))

(defun abgaben--get-group ()
  "Prompt for a group and save the answer as new default."
  (setq abgaben--curr-group (completing-read "Which group? " abgaben-all-groups nil t nil nil abgaben--curr-group))
  abgaben--curr-group)

(defun abgaben--get-week ()
  "Prompt for a week and save the answer as new default."
  (setq abgaben--curr-week (completing-read "Which week? " abgaben-all-weeks nil t nil nil abgaben--curr-week))
  abgaben--curr-week)

;;;###autoload
(defun abgaben-capture-submission (msg attnum)
  "Add this to your mu4e attachment actions.
Save an attachment from an e-mail and add information about this
assignment to the org file.  MSG is and ATTNUM are the message
and attachment number."
  (let* ((mu4e-attachment-dir (f-join abgaben-root-folder (abgaben--get-group) (abgaben--get-week)))
		 (att (mu4e~view-get-attach msg attnum))
		 (fname (plist-get att :name))
		 (msgid (or (plist-get msg :message-id) "<none>"))
         (subject (or (plist-get msg :subject) "<none>")))
	(make-directory mu4e-attachment-dir t)
	(mu4e-view-save-attachment-single msg attnum)
	(find-file abgaben-org-file)
	(goto-char (point-min))
	(org-link-search abgaben-heading)
	(search-forward (concat "** " abgaben--curr-group))
	(save-restriction
	  (org-narrow-to-subtree)
	  ;; search for current week's headline, if present
	  (let ((week-headl
			 (org-element-map (org-element-parse-buffer) 'headline
			   (lambda (x)
				 (if (string-equal abgaben--curr-week (org-element-property :raw-value x))
					 x
				   nil))
			   nil t)))
		;; go to that headline or create new if not present
		(if week-headl
			(goto-char (org-element-property :begin week-headl))
		  (end-of-line)
		  (org-insert-heading nil t)
		  (org-do-demote)
		  (insert abgaben--curr-week)))
	  (end-of-line)
	  (org-insert-heading nil t)
	  (org-do-demote)
	  (insert (concat "[[file:" (org-link-escape (f-join mu4e-attachment-dir  (abgaben--maybe-unzip mu4e-attachment-dir fname))) "][" fname "]]"))
	  (insert (concat " Email: [[mu4e:msgid:" msgid "][" subject "]]")))))

(defun abgaben--maybe-unzip (directory fname)
  "Extract FNAME in DIRECTORY if it is an archive; return directory/file to link to."
  (let ((default-directory directory))
	(cond
	 ;; extract zip files
	 ((s-ends-with? ".zip" fname t)
	  (let ((subdir (s-chop-suffix ".zip" fname)))
		(call-process "mkdir" nil nil nil subdir)
		(call-process "unzip" nil nil nil fname "-d" subdir)
		subdir))
	 ;; extract tar.gz files
	 ((s-ends-with? ".tar.gz" fname t)
	  (let ((subdir (s-chop-suffix ".tar.gz" fname)))
		(call-process "mkdir" nil nil nil subdir)
		(call-process "tar" nil nil nil "-xaf" fname "-C" subdir)
		subdir))
	 ((s-ends-with? ".rar" fname t)
	  (let ((subdir (s-chop-suffix ".rar" fname)))
		(call-process "mkdir" nil nil nil subdir)
		(call-process "unrar" nil nil nil "x" fname subdir)
		subdir))

	 ;; not recognized; do nothing
	 (fname))))

(defun abgaben-get-file-at-heading ()
  "Get the path to the first file linked in this heading."
  (save-excursion
	(save-restriction
	  (beginning-of-line)
	  (org-narrow-to-subtree)
	  (org-element-map
		  (org-element-parse-buffer)
		  'link
		(lambda (elem)
		  (if (string-equal (org-element-property :type elem) "file")
			  (org-link-unescape (org-element-property :path elem))
			nil))
		nil
		t))))

;;;###autoload
(defun abgaben-export-pdf-annot-to-org ()
  "Export annotations of the current submission as subheadings of the current entry."
  (interactive)
  (save-restriction
	(save-excursion
	  (beginning-of-line)
	  (org-narrow-to-subtree)
	  (end-of-line)
	  (delete-region (point) (point-max))
	  ;; (widen)
	  (let* ((pdffile (abgaben-get-file-at-heading))
			 (annots (sort (pdf-info-getannots nil pdffile) 'pdf-annot-compare-annotations))
			 (buffer (current-buffer)))
		(end-of-line)
		;; already insert the subheading for the points, to be filled later
		(org-insert-heading-respect-content)
		(backward-char)
		(insert (concat "* " abgaben-points-heading))
		(save-excursion
		  ;; org-set-property sometimes never returns if buffer not in org-mode
		  ;; traverse all annotations that should be exported and export them
		  (mapc
		   (lambda (annot)
			 (progn
			   (end-of-line)
			   (org-insert-heading-respect-content)
			   (insert (symbol-name (pdf-annot-get-id annot)))
			   ;; insert text from marked-up region in an org-mode
			   ;; quote or the text of a text annotation
			   (insert (concat "\n" (pdf-annot-get annot 'contents)))))
		   (cl-remove-if
			(lambda (annot) (member (pdf-annot-get-type annot) abgaben-pdf-tools-org-non-exportable-types))
			annots)))
		;; Last: find all point annotations and insert them under the points subheading
		(insert "\n")
		(let* ((punkteliste (abgaben-matches-in-buffer abgaben-points-re))
			  (punkte (mapcar
					   (lambda (x)
						 (string-match abgaben-points-re x)
						 (cons (string-to-number (match-string 1 x))
							   (string-to-number (match-string 2 x))))
					   punkteliste)))
		  (mapc (lambda (x)
					(insert (concat x "\n")))
				  punkteliste)
		  (insert (concat abgaben-points-overall ": "))
		  (insert (number-to-string (apply '+ (mapcar 'car punkte))))
		  (insert "/")
		  (insert (number-to-string (apply '+ (mapcar 'cdr punkte))))
		  )))))


(defun abgaben-matches-in-buffer (regexp &optional buffer)
  "Return a list of lines matching REGEXP in BUFFER or current buffer."
  (let ((matches))
    (save-match-data
      (save-excursion
        (with-current-buffer (or buffer (current-buffer))
          (goto-char 1)
          (while (search-forward-regexp regexp nil t 1)
            (push (match-string 0) matches))))
      (reverse matches))))

(defun abgaben--construct-email-body ()
  "Build a reply text and copy it to kill ring."
  (save-restriction
	(save-excursion
	  (let ((fname (abgaben-get-file-at-heading)))
		(org-copy-subtree)
		(with-temp-buffer
		  (yank)
		  (goto-char (point-min))
		  ;; delete heading for this
		  (kill-whole-line)
		  (goto-char (point-max))
		  (insert "<#part type=\"application/pdf\" filename=\"")
		  (insert fname)
		  (insert "\" disposition=attachment><#/part>")
		  (kill-new  (buffer-string)))))))

;;;###autoload
(defun abgaben-prepare-reply ()
  "Prepare an email to send the reviewed assignment.
Opens Mail corresponding to submission and
saves the response in the kill ring for sending a reply"
  (interactive)
  (save-excursion
	(abgaben--construct-email-body)
	(beginning-of-line)
	(search-forward "Email:")
	(search-forward "[[")
	(org-open-at-point)))
;;; abgaben.el ends here
