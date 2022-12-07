;;; org2issue.el --- export org to github issue

;; Copyright (C) 2004-2016 DarkSun <lujun9972@gmail.com>.

;; Author: DarkSun <lujun9972@gmail.com>
;; Created: 2016-03-24
;; Version: 0.1
;; Package-Version: 20190531.941
;; Package-Commit: 910b98c858762fd14b11d261626c5e979dde0833
;; Keywords: convenience, github, org
;; Package-Requires: ((org "8.0") (emacs "24.4") (ox-gfm "0.1") (gh "0.1") (s "20160405.920"))
;; URL: https://github.com/lujun9972/org2issue

;; This file is NOT part of GNU Emacs.

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

;;; Source code
;;
;; org2issue's code can be found here:
;;   http://github.com/lujun9972/org2issue

;;; Commentary:

;; org2issue is a little tool that export org to github issue

;; Quick start:

;; 1. specify ~org2issue-user~ as your github username
;; 2. specify ~org2issue-blog-repo~ as the blog repository name
;; 3. open the org file and execute =M-x org2issue=
;; 4. if ~org2issue-browse-issue~ is non-nil, the new/updated issue will be browsed by =browse-url=

;; BUGS
;; + It can't add issue labels.

;; To add issue labels. You have to redefine the method `gh-issues-issue-req-to-update` as below:
;; #+BEGIN_SRC emacs-lisp
;; (defmethod gh-issues-issue-req-to-update ((req gh-issues-issue))
;;   (let ((assignee (oref req assignee))
;;         (labels (oref req labels))
;;         (milestone (oref req milestone))
;;         (to-update `(("title" . ,(oref req title))
;;                      ("state" . ,(oref req state))
;;                      ("body" . ,(oref req body)))))

;;     (when labels (nconc to-update `(("labels" . ,(oref req labels) ))))
;;     (when milestone
;;       (nconc to-update `(("milestone" . ,(oref milestone number)))))
;;     (when assignee
;;       (nconc to-update `(("assignee" . ,(oref assignee login) ))))
;;     to-update))
;; #+END_SRC

;;; Code:
(require 'gh)
(require 'gh-issues)
(require 'ox-gfm)
(require 's)

(defgroup org2issue nil
  "org to github issue based blog")

(defcustom org2issue-user user-login-name
  "Github username"
  :group 'org2issue
  :type 'string)

(defcustom org2issue-blog-repo "blog"
  "The blog repository name"
  :group 'org2issue
  :type 'string)

(defcustom org2issue-browse-issue t
  "Browse the new issue or not"
  :group 'org2issue
  :type 'boolean)

(defcustom org2issue-update-file nil
  "When set, will insert the issue-url into this file which is recommand to be an absolote path"
  :group 'org2issue
  :type '(choice (file :tag "Insert issue-url into which file")
                 (const nil :tag "Do't insert issue-url into any file")))

(defcustom org2issue-update-item-format "+ [[${html-url}][${title}]]"
  "Set the content format of `org2issue-update-file'. It should contain \"${html-url}\" and not contain newline"
  :group 'org2issue
  :type 'string
  :set (lambda (item val)
         (unless (s-contains-p "${html-url}" val)
           (error "The format should contain \"$(html-url)\""))
         (when (s-contains-p "\n" val)
           (error "The format should not contain newline"))
         (set-default item val)))

(defcustom org2issue-after-post-issue-functions nil
  "Functions run after post or update an issue. The functions are run with one argument, the returned issue"
  :group 'org2issue
  :type 'hook)

(defun org2issue--read-org-option (option)
  "Read option value of org file opened in current buffer.
e.g:
#+TITLE: this is title
will return \"this is title\" if OPTION is \"TITLE\""
  (let ((case-fold-search t)
        (match-regexp (org-make-options-regexp `(,option))))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward match-regexp nil t)
        (match-string-no-properties 2 nil)))))

(defun org2issue--get-title ()
  "Get the title of org file."
  (or (org2issue--read-org-option "TITLE")
      (file-name-sans-extension (buffer-name))))

(defun org2issue--get-tags ()
  "Get the tags of org file"
  (let ((tags (org2issue--read-org-option "TAGS")))
    (when tags
      (apply #'vector (split-string tags)))))

(defun org2issue--write-org-option (option value)
  "Write option and value to org file opened in current buffer. "
  (let ((case-fold-search t)
        (match-regexp (org-make-options-regexp `(,option))))
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward match-regexp nil t)
          (setf (buffer-substring (progn
                                    (search-backward ":")
                                    (+ 1 (point)))
                                  (progn
                                    (end-of-line)
                                    (point)))
                value)
        (goto-char (point-min))
        (insert (concat "#+" option ": " value "\n"))))))

(defun org2issue--update-readme (&rest issues)
  (when org2issue-update-file
    (with-temp-file org2issue-update-file
      (when (file-exists-p org2issue-update-file)
        (insert-file-contents org2issue-update-file))
      (dolist (issue issues)
        (cl-assert (gh-issues-issue-p issue) t "should only accept gh-issues-issue object")
        (let ((html-url (oref issue html-url))
              (state (oref issue state)))
          (goto-char (point-min))
          (when (search-forward-regexp (format "%s[^0-9]" (regexp-quote html-url)) nil t)
            (beginning-of-line)
            (kill-line 2))
          (when (string-equal "open" state)
            (goto-char (point-min))
            (insert (s-format org2issue-update-item-format 'oref issue))
            (newline)
            (newline)))))))

(defun org2issue-regenerate-readme ()
  "Fetch issue list and use them to rewrite `org2issue-update-file'"
  (interactive)
  ;; cleanup origin file contents
  (with-temp-file org2issue-update-file)
  ;; rewrite file contents
  (let* ((api (gh-issues-api "api"))
         (issues (reverse (oref (gh-issues-issue-list api org2issue-user org2issue-blog-repo)
                                data)))
         (open-issues (remove-if (lambda (issue)
                                   (string= "close" (oref issue state)))
                                 issues)))
    (apply #'org2issue--update-readme open-issues)))

(defun org2issue--json-encode-string (string)
  "Patch for json.el in emacs25"
  (let ((l (length string))
        (start 0)
        res mb)
    ;; Only escape quotation mark, backslash and the control
    ;; characters U+0000 to U+001F (RFC 4627, ECMA-404).
    (while (setq mb (string-match "[\"\\[:cntrl:]]\\|\\cc" string start))
      (let* ((c (aref string mb))
             (special (rassq c json-special-chars)))
        (push (substring string start mb) res)
        (push (if special
                  ;; Special JSON character (\n, \r, etc.).
                  (string ?\\ (car special))
                ;; Fallback: UCS code point in \uNNNN form.
                (format "\\u%04x" c))
              res)
        (setq start (1+ mb))))
    (push (substring string start l) res)
    (push "\"" res)
    (apply #'concat "\"" (nreverse res))))

(defun org2issue--convert-src (body &optional filename)
  (let ((filename (or filename (buffer-file-name))))
    (with-temp-buffer
      (insert body)
      (goto-char (point-min))
      (while (re-search-forward
;;; TODO: not only links need to convert, but also inline
;;; images, may add others later
              ;; "<a[^>]+href=\"\\([^\"]+\\)\"[^>]*>\\([^<]*\\)</a>" nil t)
              "<[a-zA-Z]+[^/>]+\\(src\\|href\\)=\"\\([^\"]+\\)\"[^>]*>" nil t)
        (let* ((root-path (vc-git-root filename))
               (asset-path (match-string 2))
               (asset-path-begin (match-beginning 2))
               (asset-path-end (match-end 2))
               (asset-abs-path (expand-file-name asset-path (file-name-directory filename)))
               (asset-relative-path (file-relative-name asset-abs-path root-path)))
          (unless (url-type (url-generic-parse-url asset-path)) ;; 判断是否为绝对路径的URI
            (if (not (file-exists-p asset-abs-path))
                (message "ORG2ISSUE: [WARN] File %s in hyper link does not exist, org file: %s." asset-abs-path filename)
              (let ((converted-path
                     (with-temp-buffer
                       (insert (vc-git-dir-extra-headers default-directory))
                       (re-search-backward "^Remote[[:blank:]]+:[[:blank:]]+\\([^[:blank:]\r\n]+\\)")
                       (match-string 1))
                     (concat "/" (file-relative-name pub-abs-path pub-root-dir)))) ;TODO 转换后的地址
                (setf (buffer-substring asset-path-begin asset-path-end) converted-path))))))
      (buffer-string))))

;;;###autoload
(defun org2issue (&optional delete)
  (interactive "P")
  (let ((api (gh-issues-api "api"))
        (tags (org2issue--get-tags))
        (title (org2issue--get-title))
        (body (org-export-as 'gfm))
        (orign-issue-data (org2issue--read-org-option "ORG2ISSUE-ISSUE"))
        response-issue)
    (unwind-protect 
        (progn
          (when (version<= "25.0" emacs-version)
            (advice-add 'json-encode-string :override #'org2issue--json-encode-string))
          (setq response-issue (if orign-issue-data
                                   (org2issue-update api title body tags (split-string orign-issue-data) delete)
                                 (org2issue-add api title body tags)))
          (run-hook-with-args 'org2issue-after-post-issue-functions response-issue))
      (when (advice-member-p #'org2issue--json-encode-string 'json-encode-string)
        (advice-remove 'json-encode-string #'org2issue--json-encode-string)))
    (let ((html-url (oref response-issue html-url))
          (number (oref response-issue number)))
      (unless orign-issue-data
        (org2issue--write-org-option "ORG2ISSUE-ISSUE" (format "%s %s %d" org2issue-user org2issue-blog-repo number)))
      (org2issue--update-readme response-issue)
      (when org2issue-browse-issue
        (browse-url html-url)))))

(defun org2issue-add (api title body tags)
  (let ((issue (make-instance 'gh-issues-issue
                              :title title
                              :body body
                              :labels tags)))
    (oref (gh-issues-issue-new api org2issue-user org2issue-blog-repo issue) data)))

(defun org2issue-update (api title body tags orign-issue-data &optional delete)
  (let ((issue (make-instance 'gh-issues-issue
                              :title title
                              :body body
                              :labels tags
                              :state (if delete
                                         'closed
                                       'open)))
        (org2issue-user (nth 0 orign-issue-data))
        (org2issue-blog-repo (nth 1 orign-issue-data))
        (org2issue-number (string-to-number (nth 2 orign-issue-data))))
    (oref (gh-issues-issue-update api org2issue-user org2issue-blog-repo org2issue-number issue) data)))

(provide 'org2issue)
;;; org2issue.el ends here

