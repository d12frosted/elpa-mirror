;;; orglink.el --- use Org Mode links in other modes  -*- lexical-binding: t -*-

;; Copyright (C) 2004-2013  Free Software Foundation, Inc.
;; Copyright (C) 2013-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/orglink
;; Keywords: hypertext
;; Package-Version: 20211010.2105
;; Package-Commit: 05df4989c987dece40a450bd5cfbbd6cda0f2e7a

;; Package-Requires: ((emacs "24.3") (org "9.5") (seq "2.20"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of Org Mode.
;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements support for some Org Mode link types in
;; other major modes.  Links can be opened and edited like in Org
;; Mode.

;; To use enable `global-orglink-mode' and customize
;; `orglink-activate-in-modes'.  Or use the buffer local
;; `orglink-mode'.  Do the latter now to linkify these examples:

;;   [[Code]]
;;   [[Code][start of code]]
;;   [[define-derived-mode orglink-mode][orglink-mode]]
;;   <mailto:jonas@bernoul.li>
;;   man:info
;;   <info:man>
;;   https://github.com/tarsius/orglink

;;; Code:

(require 'seq)

(require 'org)
(require 'org-element)

(defvar hl-todo-keyword-faces)
(defvar outline-minor-mode)

(defgroup orglink nil
  "Use Org Mode links in other modes."
  :prefix "orglink-"
  :group 'font-lock-extra-types)

(defvaralias 'orglink-activate-links 'orglink-highlight-links)
(defcustom orglink-highlight-links '(bracket angle plain)
  "Types of links that should be activated by `orglink-mode'.
This is a list of symbols, each leading to the activation of a
certain link type.

bracket  The [[link][description]] and [[link]] links.
angle    Links in angular brackets like <info:org>.
plain    Plain links in normal text like http://orgmode.org.

Changes to this variable only become effective after restarting
`orglink-mode', which has to be done separately in each buffer."
  :group 'orglink
  :safe (lambda (v)
          (and (listp v)
               (seq-every-p #'symbolp v)))
  :type '(set :greedy t
              (const :tag "Double bracket links" bracket)
              (const :tag "Angular bracket links" angle)
              (const :tag "Plain text links" plain)))

(defcustom orglink-match-anywhere nil
  "Whether to match anywhere or just in comments and doc-strings."
  :package-version '(orglink . "1.2.0")
  :group 'orglink
  :safe 'booleanp
  :type 'boolean)

(defcustom orglink-activate-in-modes '(emacs-lisp-mode)
  "Major modes in which `orglink-mode' should be activated.
This is used by `global-orglink-mode'.  Note that `orglink-mode'
is never activated in the *scratch* buffer, to avoid having to
load `org' at startup (because that would take a long time)."
  :group 'orglink
  :type '(repeat function))

(defcustom orglink-mode-lighter " OrgLink"
  "Mode lighter for Orglink Mode."
  :group 'orglink
  :type '(choice (const :tag "none" nil)
                 string))

(defvar orglink-mouse-map
  (let ((map (make-sparse-keymap)))
    (define-key map [follow-link] 'mouse-face)
    (define-key map [mouse-2]     'org-open-at-point-global)
    (define-key map [return]      'org-open-at-point-global)
    (define-key map [tab]         'org-next-link)
    (define-key map [backtab]     'org-previous-link)
    map)
  "Keymap used for `orglink-mode' link buttons.
The keymap stored in this variable is actually used by setting
the buffer local value of variable `org-mouse-map' to it's
value when `orglink-mode' is turned on.")

;;;###autoload
(define-minor-mode orglink-mode
  "Toggle display Org-mode links in other major modes.

On the links the following commands are available:

\\{orglink-mouse-map}"
  :lighter orglink-mode-lighter
  (when (derived-mode-p 'org-mode)
    (setq orglink-mode nil)
    (error "Orglink Mode doesn't make sense in Org Mode"))
  (cond (orglink-mode
         (org-load-modules-maybe)
         (add-hook 'org-open-link-functions
                   'orglink-heading-link-search nil t)
         (font-lock-add-keywords nil '((orglink-activate-links)) t)
         (setq-local org-link-descriptive org-link-descriptive)
         (when org-link-descriptive
           (add-to-invisibility-spec '(org-link)))
         (setq-local font-lock-unfontify-region-function
                     'orglink-unfontify-region)
         (setq-local org-mouse-map orglink-mouse-map))
        (t
         (remove-hook 'org-open-link-functions
                      'orglink-heading-link-search t)
         (font-lock-remove-keywords nil '((orglink-activate-links)))
         (remove-from-invisibility-spec '(org-link))
         (kill-local-variable 'org-link-descriptive)
         (kill-local-variable 'font-lock-unfontify-region-function)
         (kill-local-variable 'org-mouse-map)))
  (when font-lock-mode
    (if (and (fboundp 'font-lock-flush)
             (fboundp 'font-lock-ensure))
        (save-restriction
          (widen)
          (font-lock-flush)
          (font-lock-ensure))
      (with-no-warnings
        (font-lock-fontify-buffer)))))

;;;###autoload
(define-globalized-minor-mode global-orglink-mode
  orglink-mode turn-on-orglink-mode-if-desired)

(defun turn-on-orglink-mode-if-desired ()
  (cond ((derived-mode-p 'org-mode)
         ;; `org-mode' derives from `outline-mode', which derives
         ;; from `text-mode'.  Only warn if `org-mode' itself is
         ;; a member of `orglink-activate-in-modes'.
         (when (memq 'org-mode orglink-activate-in-modes)
           (message "Refusing to turn on `orglink-mode' in `org-mode'")))
        ((apply 'derived-mode-p orglink-activate-in-modes)
         (orglink-mode 1))))

(defun orglink-unfontify-region (beg end)
  (org-unfontify-region beg end)
  ;; The above does not remove the following properties.
  ;; TODO Should it? Should we? Ask on mailing-list.
  (remove-text-properties beg end '(help-echo t rear-nonsticky t)))

;; Modified copy of `org-activate-links'.
;; The modified part is clearly marked.
(defun orglink-activate-links (limit)
  (catch :exit
    (while (re-search-forward org-link-any-re limit t)
      (let* ((start (match-beginning 0))
             (end (match-end 0))
             (visible-start (or (match-beginning 3) (match-beginning 2)))
             (visible-end (or (match-end 3) (match-end 2)))
             (style (cond ((eq ?< (char-after start)) 'angle)
                          ((eq ?\[ (char-after (1+ start))) 'bracket)
                          (t 'plain))))
        ;;; BEGIN Modified part:
        (when (and (memq style orglink-highlight-links) ; Different variable.
                   ;; Additional condition:
                   (or orglink-match-anywhere
                       (orglink-inside-comment-or-docstring-p))
                   ;; Remove two conditions:
                   )
        ;;; END Modified part.
          (let* ((link-object (save-excursion
                                (goto-char start)
                                (save-match-data (org-element-link-parser))))
                 (link (org-element-property :raw-link link-object))
                 (type (org-element-property :type link-object))
                 (path (org-element-property :path link-object))
                 (face-property (pcase (org-link-get-parameter type :face)
                                  ((and (pred functionp) face) (funcall face path))
                                  ((and (pred facep) face) face)
                                  ((and (pred consp) face) face) ;anonymous
                                  (_ 'org-link)))
                 (properties            ;for link's visible part
                  (list 'mouse-face (or (org-link-get-parameter type :mouse-face)
                                        'highlight)
                        'keymap (or (org-link-get-parameter type :keymap)
                                    org-mouse-map)
                        'help-echo (pcase (org-link-get-parameter type :help-echo)
                                     ((and (pred stringp) echo) echo)
                                     ((and (pred functionp) echo) echo)
                                     (_ (concat "LINK: " link)))
                        'htmlize-link (pcase (org-link-get-parameter type
                                                                     :htmlize-link)
                                        ((and (pred functionp) f) (funcall f))
                                        (_ `(:uri ,link)))
                        'font-lock-multiline t)))
            (org-remove-flyspell-overlays-in start end)
            (org-rear-nonsticky-at end)
            (if (not (eq 'bracket style))
                (progn
                  (add-face-text-property start end face-property)
                  (add-text-properties start end properties))
              ;; Handle invisible parts in bracket links.
              (remove-text-properties start end '(invisible nil))
              (let ((hidden
                     (append `(invisible
                               ,(or (org-link-get-parameter type :display)
                                    'org-link))
                             properties)))
                (add-text-properties start visible-start hidden)
                (add-face-text-property start end face-property)
                (add-text-properties visible-start visible-end properties)
                (add-text-properties visible-end end hidden)
                (org-rear-nonsticky-at visible-start)
                (org-rear-nonsticky-at visible-end)))
            (let ((f (org-link-get-parameter type :activate-func)))
              (when (functionp f)
                (funcall f start end path (eq style 'bracket))))
            (throw :exit t)))))         ;signal success
    nil))

(defun orglink-inside-comment-or-docstring-p ()
  (and (nth 8 (syntax-ppss))
       (not (eq (get-text-property (point) 'face) 'font-lock-string-face))))

(defun orglink-heading-link-search (s)
  (let (case-fold-search pos)
    (save-excursion
      (goto-char (point-min))
      (and (or outline-minor-mode
               (derived-mode-p 'emacs-lisp-mode))
           (re-search-forward
            (concat "^" outline-regexp
                    (if (bound-and-true-p hl-todo-mode)
                        (regexp-opt (mapcar 'car hl-todo-keyword-faces))
                      "\\(?:\\sw+\\)")
                    "?" s)
            nil t)
           (setq pos (match-beginning 0))
           (goto-char pos)))))

;;; _
(provide 'orglink)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; orglink.el ends here
