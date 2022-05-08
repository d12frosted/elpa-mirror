;;; org-ref-prettify.el --- Prettify org-ref citation links  -*- lexical-binding: t -*-

;; Copyright © 2021–2022 Alex Kost
;; Copyright © 2021 Vitus Schäfftlein

;; Author: Alex Kost <alezost@gmail.com>
;;         Vitus Schäfftlein <vitusschaefftlein@live.de>
;; Version: 0.2
;; Package-Version: 20220507.649
;; Package-Commit: 0ec3b6e398ee117c8b8a787a0422b95d9e95f7bb
;; Package-Requires: ((emacs "24.3") (org-ref "3.0") (bibtex-completion "1.0.0"))
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
;;   [[cite:&CoxeterPG2ed pg 53]]       ->  Coxeter, 1987, p. 53
;;   [[citetitle:&CoxeterPG2ed ch 3]]   ->  Projective Geometry ch 3
;;   [[parencite:&CoxeterPG2ed 36-44]]  ->  (Coxeter, 1987, pp. 36-44)
;;   [[citeauthor:See &GorFG; &RotITG; &AschFGT2ed]]  ->  See Gorenstein; Rotman; Aschbacher

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

(defvar org-ref-prettify-paren-types
  '("parencite" "parencites" "citep")
  "List of cite types that should be displayed in parentheses.")

(defvar org-ref-prettify-regexp
  (rx-to-string
   `(and "[[" (group (or ,@(mapcar #'car org-ref-cite-types)))
         ;; (+? (not "]")) is not supported in `rx' by Emacs <27.
         ;; See <https://github.com/alezost/org-ref-prettify.el/issues/3>.
         ":" (group (regexp "[^]]+?")) "]]")
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
        (concat (car (split-string (car names) ", *"))
                " et al.")
      (mapconcat (lambda (str)
                   (car (split-string str ", *")))
                 names
                 " and "))))

(defun org-ref-prettify-postfix-to-page (postfix)
  "Return formatted page string if POSTFIX contains only page number."
  (when (string-match
         ;; (rx string-start (* space) (? "pg" (? ".") (+ space)) (group (+ (any digit "-"))) (* space) string-end)
         "\\`[[:space:]]*\\(?:pg\\.?[[:space:]]+\\)?\\([[:digit:]-]+\\)[[:space:]]*\\'"
         postfix)
    (let ((page (match-string-no-properties 1 postfix)))
      (concat (if (cdr (split-string page "-"))
                  "pp." "p.")
              (if org-ref-prettify-space-before-page-number
                  " " "")
              page))))

(cl-defun org-ref-prettify-format (&key type author year title pre post)
  "Return a string formatted for TYPE citation link.
Any argument must be either a string or nil.

TYPE is a string like \"cite\", \"citetitle\", etc.

AUTHOR, YEAR, TITLE, and PAGE are self-explanatory.

PRE and POST are what taken from the citation before and after &key."
  (let* ((page (and post (org-ref-prettify-postfix-to-page post)))
         (str
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
    (concat pre
            (if (or page (null post))
                str
              (concat str
                      ;; Add leading space to POST if it does not have it.
                      (if (string-match-p "\\` " post)
                          post
                        (concat " " post)))))))

(defun org-ref-prettify-get-entry-fields (entry)
  "Return (AUTHOR YEAR TITLE) list for the citation ENTRY."
  (if entry
      (let ((author (cdr (or (assoc "author" entry)
                             (assoc "editor" entry))))
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
        (type      (match-string-no-properties 1)))
    ;; Match data ^^^ should be saved before calling `org-element-context'.
    (let ((link (save-excursion
                  (goto-char type-end)
                  (org-element-context)))
          (prettified (get-text-property type-end 'org-ref-prettified)))
      (when (and link (not prettified))
        (let* ((cite-data (org-ref-parse-cite-path
                           (org-element-property :path link)))
               (refs (plist-get cite-data :references))
               (prefix (plist-get cite-data :prefix))
               (suffix (plist-get cite-data :suffix))
               (keys (mapcar (lambda (ref)
                               (plist-get ref :key))
                             refs))
               (data (delq nil (org-ref-prettify-get-fields keys)))
               (strings
                (cl-mapcar
                 (lambda (fields ref)
                   (cl-multiple-value-bind (author year title)
                       fields
                     (when (or author year title)
                       (let ((pre (or (plist-get ref :prefix) prefix))
                             (post (or (plist-get ref :suffix) suffix)))
                         (funcall org-ref-prettify-format-function
                                  :type type
                                  :author author
                                  :year year
                                  :title title
                                  :pre pre
                                  :post post)))))
                 data refs))
               (strings (delq nil strings)))
          (when strings
            (let* ((display-string (mapconcat #'identity strings "; "))
                   (display-string (if (member type org-ref-prettify-paren-types)
                                       (concat "(" display-string ")")
                                     display-string)))
              (with-silent-modifications
                (put-text-property beg end 'display display-string))))
          ;; Add 'prettified' property even for non-existing links to
          ;; avoid redundant calls of `bibtex-completion-get-entry'.
          (put-text-property beg type-end 'org-ref-prettified t)))))
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
         '(org-ref-prettified nil
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

(defvar org-ref-prettify-minibuffer-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "TAB") 'org-ref-prettify-minibuffer-move-next)
    map)
  "Keymap for reading citation links from the minibuffer.")

(defun org-ref-prettify-minibuffer-move-next ()
  "Move the point to the next &key or to the end of the link."
  (interactive)
  (let ((pos (point)))
    (if (re-search-forward "&" nil t)
        (if (= pos (1- (point)))
            (org-ref-prettify-minibuffer-move-next)
          (backward-char))
      (if (looking-at-p "]]")
          (progn
            (goto-char (point-min))
            (org-ref-prettify-minibuffer-move-next))
        (re-search-forward "]]" nil t)
        (backward-char 2)))))

;;;###autoload
(defun org-ref-prettify-edit-link-at-point (&optional where)
  "Edit the current citation link in the minibuffer.
WHERE means where the point should be put in the minibuffer.  If
it is nil, try to be smart about its placement; otherwise, it can
be one of: `type', `beg', or `end'."
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
                          (- (cl-case where
                               (beg beg)
                               (type (match-end 1))
                               (t (match-end 2)))
                             beg -1)))
                       (new (read-from-minibuffer
                             "Link: "
                             (cons (match-string-no-properties 0)
                                   mb-pos)
                             org-ref-prettify-minibuffer-map)))
                  (goto-char beg)
                  (delete-region beg end)
                  (insert new))))
          (user-error "Not at a citation link"))))))

(defun org-ref-prettify-edit-link-at-point-maybe ()
  "Edit the current citation link in the minibuffer.
See `org-ref-prettify-edit-link-at-point' for details."
  (interactive)
  (if (get-text-property (point) 'org-ref-prettified)
      (org-ref-prettify-edit-link-at-point)
    (call-interactively (lookup-key org-mode-map [C-return]))))

;;;###autoload
(defun org-ref-prettify-edit-link-at-mouse (event &optional where)
  "Edit the citation link at mouse position in the minibuffer.
This should be bound to a mouse click EVENT type.
See `org-ref-prettify-edit-link-at-point' for the meaning of WHERE."
  (interactive "e")
  (mouse-set-point event)
  (org-ref-prettify-edit-link-at-point where))

(defun org-ref-prettify-edit-link-at-mouse-maybe (event &optional where)
  "Edit the citation link at mouse position in the minibuffer.
This should be bound to a mouse click EVENT type.
See `org-ref-prettify-edit-link-at-point' for the meaning of WHERE."
  (interactive "e")
  (mouse-set-point event)
  (if (get-text-property (point) 'org-ref-prettified)
      (org-ref-prettify-edit-link-at-point where)
    (org-find-file-at-mouse event)))

(when org-ref-prettify-bind-edit-keys
  ;; We cannot use `org-ref-cite-keymap' because this keymap is active
  ;; only when the point is placed after "link-type:".  But for the
  ;; prettified link, the point is placed at the first symbol.
  ;; XXX Using `org-mouse-map' like this is horrible but I do not know
  ;; how this can be done another way.
  (define-key org-mouse-map [C-return] 'org-ref-prettify-edit-link-at-point-maybe)
  (define-key org-mouse-map [mouse-3] 'org-ref-prettify-edit-link-at-mouse-maybe))

(provide 'org-ref-prettify)

;;; org-ref-prettify.el ends here
