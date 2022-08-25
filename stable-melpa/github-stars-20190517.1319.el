;;; github-stars.el --- Browse your Github Stars     -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/github-stars.el
;; Package-Requires: ((emacs "25.1") (ghub "2.0.0"))
;; Package-Version: 20190517.1319
;; Package-Commit: bb79c80574cfff865342b6e262f2c9762edb4c15
;; Keywords: tools
;; Created: Tue, 27 Mar 2018 20:59:43 +0800
;; Version: 0.1

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

;; Browse your Github Stars.

;;; Code:

(require 'ghub)
(require 'let-alist)
(require 'map)                          ; `map-apply'

(defgroup github-stars nil
  "Browse your github stars."
  :group 'tools)

(defvar github-stars-github-token-scopes '()
  "The Github API scopes needed by github-stars.")

(defun github-stars--read-link-header ()
  (let* ((link (cdr (assoc "Link" ghub-response-headers)))
         (links (and link
                     (mapcar (lambda (elt) (split-string elt "; "))
                             (split-string link ","))))
         next last first prev
         match)
    (when links
      (pcase-dolist (`(,target ,rel) links)
        (when (string-match "[?&]page=\\([^&>]+\\)" target)
          (setq match (match-string 1 target))
          (pcase rel
            ("rel=\"next\""  (setq next match))
            ("rel=\"last\""  (setq last match))
            ("rel=\"first\"" (setq first match))
            ("rel=\"prev\""  (setq prev match)))))
      `((next  . ,next)
        (last  . ,last)
        (first . ,first)
        (prev  . ,prev)))))

(defun github-stars--report-progress ()
  (let-alist (github-stars--read-link-header)
    (if .next
        (let ((message-log-max nil))
          (message "github-stars: (%s) Fetching your github stars [%s/%s]..."
                   (format-time-string "%H:%M:%S")
                   .next .last))
      (message nil))))

(defun github-stars--read-response (status)
  (let ((list (ghub--read-json-payload status)))
    (prog1 (mapcar (lambda (alist)
                     (let-alist alist
                       (list (cons 'starred-at  .starred_at)
                             (cons 'owner/name  .repo.full_name)
                             (cons 'owner       .repo.owner.login)
                             (cons 'name        .repo.name)
                             (cons 'url         .repo.html_url)
                             (cons 'description .repo.description)
                             (cons 'language    .repo.language))))
                   list)
      (github-stars--report-progress))))

(defvar github-stars nil)

(defun github-stars ()
  "Return hash table listing github stars."
  (unless github-stars
    (let ((response (ghub-get "/user/starred" nil
                              :query '((per_page . "100"))
                              :headers '(("Accept" .
                                          "application/vnd.github.v3.star+json"))
                              :unpaginate t
                              :reader #'github-stars--read-response
                              :auth 'github-stars)))
      (setq github-stars (make-hash-table :test #'equal))
      (dolist (alist response)
        (puthash (let-alist alist .owner/name) alist github-stars))))
  github-stars)

;; https://emacs.stackexchange.com/questions/31448/report-duplicates-in-a-list
(defun github-stars--find-duplicates (list)
  (let ((table (make-hash-table :test #'equal))
        result)
    (dolist (x list)
      (cl-incf (gethash x table 0)))
    (maphash (lambda (key value)
               (when (> value 1)
                 (push key result)))
             table)
    result))

(defun github-stars--names-uniquify ()
  (let* ((names (map-apply
                 (lambda (_ alist)
                   (let-alist alist .name))
                 (github-stars)))
         (dups (github-stars--find-duplicates names)))
    (map-apply
     (lambda (key alist)
       (let-alist alist
         (if (member .name dups)
             (cons (concat .name "\\" .owner) key)
           (cons .name key))))
     (github-stars))))

(defun github-stars--completing-read ()
  (let* ((alist (github-stars--names-uniquify))
         (uniquified (completing-read "Browse Github Star: " alist nil t)))
    (cdr (assoc uniquified alist))))

;;;###autoload
(defun github-stars-browse-url (owner/name)
  "Prompt you for one of your github stars and open it in the web browser."
  (interactive (list (github-stars--completing-read)))
  (browse-url (concat "https://github.com/" owner/name)))


;;; Listing

(defun github-stars-list-columns-name (owner/name)
  (alist-get 'name (gethash owner/name (github-stars))))

(defun github-stars-list-columns-starred-at (owner/name)
  (let ((string (alist-get 'starred-at (gethash owner/name (github-stars)))))
    ;; NOTE One can use `parse-iso8601-time-string' to parse the string
    ;; IDEA Use human-readable format, such as "19 days ago"
    (substring string 0 (eval-when-compile (length "1999-12-31")))))

(defun github-stars-list-columns-description (owner/name)
  (alist-get 'description (gethash owner/name (github-stars))))

(defcustom github-stars-list-columns
  '(("Name"        25 github-stars-list-columns-name nil)
    ("Starred"     14 github-stars-list-columns-starred-at nil)
    ("Description" 99 github-stars-list-columns-description nil))
  "List of columns displayed by `github-stars-list'.

Each element has the form (HEADER WIDTH FORMAT PROPS).

HEADER is the string displayed in the header.  WIDTH is the width
of the column.  FORMAT is a function that is called with one
argument, one key of the hash table `github-stars', i.e., owner/name.
It has to return a string to be inserted or nil.  PROPS is
an alist that supports the keys `:right-align' and `:pad-right'."
  :group 'github-stars
  :type `(repeat (list :tag "Column"
                       (string   :tag "Header Label")
                       (integer  :tag "Column Width")
                       (function :tag "Inserter Function")
                       (repeat   :tag "Properties"
                                 (list (choice :tag "Property"
                                               (const :right-align)
                                               (const :pad-right)
                                               (symbol))
                                       (sexp   :tag "Value"))))))

(defcustom github-stars-list-mode-hook '(hl-line-mode)
  "Hook run after entering Github-Stars-List mode."
  :group 'github-stars
  :type 'hook
  :options '(hl-line-mode))

(defvar github-stars-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "C-m") #'github-stars-list-browse-url)
    map)
  "Local keymap for Github-Stars-List mode buffers.")

(defun github-stars-list-browse-url ()
  "Browse url of the star at point."
  (interactive)
  (let ((owner/name (tabulated-list-get-id)))
    (if owner/name
        (github-stars-browse-url owner/name)
      (user-error "There is no star at point"))))

(define-derived-mode github-stars-list-mode tabulated-list-mode "Github Stars"
  "Major mode for browsing a list of your github stars."
  (setq tabulated-list-padding  0)
  (setq tabulated-list-sort-key (cons "Starred" t))
  (setq tabulated-list-format
        (vconcat (mapcar (pcase-lambda (`(,title ,width ,_fn ,props))
                           (nconc (list title width t)
                                  (apply #'append props)))
                         github-stars-list-columns)))
  (tabulated-list-init-header))

;;;###autoload
(defun github-stars-list ()
  "Display a list of your github stars."
  (interactive)
  (with-current-buffer (get-buffer-create "*Github Stars*")
    (github-stars-list-mode)
    (setq tabulated-list-entries
          (lambda ()
            (map-apply
             (lambda (owner/name _alist)
               (list owner/name
                     (vconcat (mapcar (pcase-lambda (`(,_ ,_ ,fn ,_))
                                        (or (funcall fn owner/name) ""))
                                      github-stars-list-columns))))
             (github-stars))))
    (tabulated-list-print)
    (switch-to-buffer (current-buffer))))

(provide 'github-stars)
;;; github-stars.el ends here
