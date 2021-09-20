;;; org-ref-prettify.el --- Prettify org-ref citation links  -*- lexical-binding: t -*-

;; Copyright © 2021 Alex Kost
;; Copyright © 2021 Vitus Schäfftlein

;; Author: Alex Kost <alezost@gmail.com>
;;         Vitus Schäfftlein <vitusschaefftlein@live.de>
;; Version: 0.1
;; Package-Version: 20210920.634
;; Package-Commit: 29e05416f102ceca50ac8b118a19a16f9fe7eb2f
;; Package-Requires: ((emacs "24.3") (org-ref "1.1.0") (bibtex-completion "1.0.0"))
;; URL: https://github.com/alezost/org-ref-prettify.el
;; Keywords: convenience

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

;;; Commentary:

;; This file provides a minor mode, `org-ref-prettify-mode', that is
;; supposed to be used with `org-ref' package.  After enabling this mode
;; (with "M-x org-ref-prettify-mode" command), you will see that the
;; citation org-ref links in the current buffer are shown in a more
;; readable format, e.g.:
;;
;;   [[cite:CoxeterPG2ed][53]]          ->  Coxeter, 1987, p. 53
;;   [[citetitle:CoxeterPG2ed]]         ->  Projective Geometry
;;   citeauthor:CoxeterPG2ed            ->  Coxeter
;;   [[parencite:CoxeterPG2ed][36-44]]  ->  (Coxeter, 1987, pp. 36-44)
;;
;; The citation links themselves are not changed, they are just
;; displayed differently.  You can disable the mode by running "M-x
;; org-ref-prettify-mode" again, and you see the original links.

;; Also, this file provides 2 more commands:
;; - `org-ref-prettify-edit-link-at-point',
;; - `org-ref-prettify-edit-link-at-mouse'.
;;
;; They allow you to edit the current link in the minibuffer.  By
;; default, they are bound to C-RET and the right mouse click
;; respectively.  But you can disable these bindings with:
;;
;;   (setq org-ref-prettify-bind-edit-keys nil)

;; To install this package manually, add the following to your Emacs init file:
;;
;;   (add-to-list 'load-path "/path/to/org-ref-prettify")
;;   (autoload 'org-ref-prettify-mode "org-ref-prettify" nil t)

;;; Code:

(require 'cl-lib)
(require 'org-ref)
(require 'bibtex-completion)

(defgroup org-ref-prettify nil
  "Prettify `org-ref' citation links."
  :prefix "org-ref-prettify-"
  :group 'org-ref
  :group 'convenience)

(defcustom org-ref-prettify-format-function #'org-ref-prettify-format
  "Function used to format a prettified citation link."
  :type '(choice (function-item org-ref-prettify-format)
                 (function :tag "Other function"))
  :group 'org-ref-prettify)

(defcustom org-ref-prettify-space-before-page-number t
  "If nil, do not put a space between \"p.\" and page number."
  :type 'boolean
  :group 'org-ref-prettify)

(defvar org-ref-prettify-regexp
  (rx-to-string
   `(and (? "[[") (group (or ,@org-ref-cite-types))
         ":" (group (one-or-more (any alnum "-_,"))) (? "]")
         (? "["
            (? (group (* (any alpha space))) "::")
            (group (* (any digit "-")))
            (? "::" (group (* (not "]"))))
            "]")
         (? "]"))
   t)
  "Regular expression to match a citation link.")

(defvar org-ref-prettify-remove-general-regexp "[{}]"
  "Regular expression to remove from any bib-field.
Everything satisfying this regexp in any bib-file field will not
be displayed in the prettified citations.")

(defvar org-ref-prettify-remove-author-regexp
  (rx " " alpha ".")
  "Regular expression to remove from an 'author' bib-field.
Everything satisfying this regexp in an 'author' bib-file field
will not be displayed in the prettified citations.")

(defun org-ref-prettify-format-author (author)
  "Return a formatted string for AUTHOR."
  (let ((names (split-string
                (replace-regexp-in-string
                 org-ref-prettify-remove-author-regexp ""
                 (replace-regexp-in-string
                  org-ref-prettify-remove-general-regexp ""
                  author))
                " and ")))
    (if (> (length names) 3)
        (concat (car (split-string (car names) ", "))
                " et al.")
      (mapconcat (lambda (str)
                   (car (split-string str ", ")))
                 names
                 " and "))))

(cl-defun org-ref-prettify-format (&key type author year title
                                        pre-page page post-page)
  "Return a string formatted for TYPE citation link.
Any argument must be either a string or nil.

TYPE is a string like \"cite\", \"citetitle\", etc.

AUTHOR, YEAR, TITLE, and PAGE are self-explanatory.

PRE-PAGE and POST-PAGE are what taken from [PRE-PAGE::PAGE::POST-PAGE]
part of the citation."
  (let ((page (and page (not (string= "" page))
                   (concat (if (cdr (split-string page "-"))
                               "pp." "p.")
                           (if org-ref-prettify-space-before-page-number
                               " " "")
                           page
                           (and post-page (concat ", " post-page)))))
        (author (if pre-page
                    (concat pre-page " " author)
                  author)))
    (cond
     ((equal type "textcite")
      (concat author " (" year
              (and page (if year (concat ", " page) page))
              ")"))
     ((equal type "citeauthor") author)
     ((equal type "citeyear") year)
     ((equal type "citetitle") title)
     (t
      (concat author
              (and year (concat ", " year))
              (and page (concat ", " page)))))))

(defun org-ref-prettify-get-entry-fields (entry)
  "Return (AUTHOR YEAR TITLE) list for the citation ENTRY."
  (if entry
      (let ((author (cdr (assoc "author" entry)))
            (year   (or (cdr (assoc "year" entry))
                        (let ((date (cdr (assoc "date" entry))))
                          (and date
                               (car (split-string date "-"))))))
            (title  (cdr (assoc "title" entry))))
        (list (and (stringp author)
                   (org-ref-prettify-format-author author))
              (and (stringp year)
                   (replace-regexp-in-string
                    org-ref-prettify-remove-general-regexp
                    "" year))
              (and (stringp title)
                   (replace-regexp-in-string
                    org-ref-prettify-remove-general-regexp
                    "" title))))
    (list nil nil nil)))

(defun org-ref-prettify-get-fields (key)
  "Return (AUTHOR YEAR TITLE) list for the citation KEY.
KEY may be a single key or a list of keys."
  (let ((bibtex-completion-bibliography (org-ref-find-bibliography))
        (keys (if (listp key) key (list key))))
    (mapcar (lambda (key)
              (org-ref-prettify-get-entry-fields
               (ignore-errors (bibtex-completion-get-entry key))))
            keys)))

(defun org-ref-prettify-put ()
  "Prettify matching region in the current buffer."
  (let ((beg       (match-beginning 0))
        (end       (match-end 0))
        (type-end  (match-end 1))
        (type      (match-string-no-properties 1))
        (key       (match-string-no-properties 2))
        (pre-page  (match-string-no-properties 3))
        (page      (match-string-no-properties 4))
        (post-page (match-string-no-properties 5)))
    ;; Match data ^^^ should be saved before calling `org-element-context'.
    (let* ((link (save-excursion
                   (goto-char type-end)
                   (org-element-context)))
           (link-beg (org-element-property :begin link))
           (link-end (org-element-property :end link))
           (link-end (and link-end
                          (- link-end
                             (or (org-element-property :post-blank link)
                                 0))))
           (data-at-point (get-text-property type-end 'org-ref-prettify-data))
           (fresh         (get-text-property type-end 'org-ref-prettify-fresh)))
      (when (and link link-beg link-end
                 (or (not fresh) (null data-at-point)))
        (let* ((data (or data-at-point
                         (delq nil
                               (org-ref-prettify-get-fields
                                (split-string key ",")))))
               (strings
                (mapcar (lambda (fields)
                          (cl-multiple-value-bind (author year title)
                              fields
                            (when (or author year title)
                              (funcall org-ref-prettify-format-function
                                       :type type
                                       :author author
                                       :year year
                                       :title title
                                       :pre-page pre-page
                                       :page page
                                       :post-page post-page))))
                        data))
               (strings (delq nil strings)))
          (when strings
            (let* ((link-beg (max link-beg beg))
                   (link-end (min link-end end))
                   (display-string (mapconcat #'identity strings "; "))
                   (display-string (if (equal type "parencite")
                                       (concat "(" display-string ")")
                                     display-string)))
              (with-silent-modifications
                (unless data-at-point
                  (put-text-property link-beg type-end
                                     'org-ref-prettify-data data))
                (put-text-property link-beg type-end
                                   'org-ref-prettify-fresh t)
                (put-text-property link-beg link-end
                                   'display display-string))))))))
  ;; Return nil because we are not adding any face property.
  nil)

(defun org-ref-prettify-unprettify-buffer ()
  "Remove citation prettifications from the current buffer."
  (interactive)
  (with-silent-modifications
    (let ((inhibit-read-only t))
      (save-excursion
        (remove-text-properties
         (point-min) (point-max)
         '(org-ref-prettify-data nil
           org-ref-prettify-fresh nil
           display nil))))))

(defun org-ref-prettify-delete-backward-char ()
  "Delete the previous character.
If the previous character is a part of the citation link, remove
the whole link."
  (interactive)
  (let ((end (point))
        beg)
    (if (and (get-text-property (1- end) 'display)
             (save-excursion
               (beginning-of-line)
               (while (re-search-forward
                       org-ref-prettify-regexp end t)
                 (and (equal end (match-end 0))
                      (setq beg (match-beginning 0))))
               beg))
        (delete-region beg end)
      (call-interactively #'delete-backward-char))))

(defun org-ref-prettify-delete-forward-char ()
  "Delete the following character.
If the following character is a part of the citation link, remove
the whole link."
  (interactive)
  (let ((beg (point))
        end)
    (if (and (get-text-property beg 'display)
             (setq end (re-search-forward org-ref-prettify-regexp
                                          (line-end-position) t)))
        (delete-region beg end)
      (call-interactively #'delete-forward-char))))

(defvar org-ref-prettify-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap delete-backward-char] 'org-ref-prettify-delete-backward-char)
    (define-key map [remap delete-forward-char] 'org-ref-prettify-delete-forward-char)
    map))

;;;###autoload
(define-minor-mode org-ref-prettify-mode
  "Toggle Org Ref Prettify mode.

\\{org-ref-prettify-mode-map}"
  :init-value nil
  (let ((keywords
         `((,org-ref-prettify-regexp (0 (org-ref-prettify-put))))))
    (if org-ref-prettify-mode
        ;; Turn on.
        (font-lock-add-keywords nil keywords)
      ;; Turn off.
      (font-lock-remove-keywords nil keywords)
      (org-ref-prettify-unprettify-buffer))
    (jit-lock-refontify)))


;;; Edit a citation link

(defcustom org-ref-prettify-bind-edit-keys t
  "If nil, do not bind citation edit keys.

By default, you can edit the current citation link in the
minibuffer by pressing C-RET on the link or by clicking the right
mouse button on it.

Set this variable to nil, if you do not want these bindings.
Note: you need to set this variable before `org-ref-prettify' is
loaded."
  :type 'boolean
  :group 'org-ref-prettify)

(defun org-ref-prettify-strip-link (link)
  "Remove extra brackets if LINK has the form [[something][]]."
  (let ((linkp (string-match org-ref-prettify-regexp link)))
    (if linkp
        (let ((pre-page (match-string 3 link))
              (page     (match-string 4 link)))
          (if (or (and page (not (string-equal "" page)))
                  (and pre-page (not (string-equal "" pre-page))))
              link
            (concat (match-string 1 link) ":" (match-string 2 link))))
      link)))

;;;###autoload
(defun org-ref-prettify-edit-link-at-point (&optional where)
  "Edit the current citation link in the minibuffer.
WHERE means where the point should be put in the minibuffer.  If
it is nil, try to be smart about its placement; otherwise, it can
be one of: `type', `key', `page', `beg', or `end'."
  (interactive)
  (let ((pos (point))
        (eol (line-end-position))
        done)
    (save-excursion
      (beginning-of-line)
      (while (not done)
        (if (re-search-forward org-ref-prettify-regexp eol t)
            (let ((beg (match-beginning 0))
                  (end (match-end 0)))
              (when (<= beg pos end)
                (setq done t)
                (let* ((mb-pos
                        (unless (eq 'end where)
                          (- (or (cl-case where
                                   (beg beg)
                                   (type (match-end 1))
                                   (key  (match-end 2))
                                   (page (match-end 4))
                                   (t (or (match-end 4)
                                          (match-end 1))))
                                 beg)
                             beg -1)))
                       (new (read-string "Link: "
                                         (cons (match-string-no-properties 0)
                                               mb-pos))))
                  (goto-char beg)
                  (delete-region beg end)
                  (insert (org-ref-prettify-strip-link new)))))
          (user-error "Not at a citation link"))))))

;;;###autoload
(defun org-ref-prettify-edit-link-at-mouse (event &optional where)
  "Edit the citation link at mouse position in the minibuffer.
This should be bound to a mouse click EVENT type.
See `org-ref-prettify-edit-link-at-point' for the meaning of WHERE."
  (interactive "e")
  (mouse-set-point event)
  (org-ref-prettify-edit-link-at-point where))

(when org-ref-prettify-bind-edit-keys
  (define-key org-ref-cite-keymap [C-return] 'org-ref-prettify-edit-link-at-point)
  (define-key org-ref-cite-keymap [mouse-3] 'org-ref-prettify-edit-link-at-mouse))

(provide 'org-ref-prettify)

;;; org-ref-prettify.el ends here
