;;; orglink.el --- use Org Mode links in other modes  -*- lexical-binding: t -*-

;; Copyright (C) 2004-2013  Free Software Foundation, Inc.
;; Copyright (C) 2013-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/orglink
;; Keywords: hypertext
;; Package-Version: 20211007.2234
;; Package-Commit: 071f9a64c9479a423c78dee85539680e3c1aa875

;; Package-Requires: ((emacs "24.3") (org "9.3") (seq "2.20"))
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

(require 'org)
(require 'seq)

(defvar hl-todo-keyword-faces)
(defvar outline-minor-mode)

(defgroup orglink nil
  "Use Org Mode links in other modes."
  :prefix "orglink-"
  :group 'font-lock-extra-types)

(defcustom orglink-activate-links '(bracket angle plain)
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
    (error "Orglink Mode doesn't make sense in Org Mode"))
  (cond (orglink-mode
         (org-load-modules-maybe)
         (add-hook 'org-open-link-functions
                   'orglink-heading-link-search nil t)
         (font-lock-add-keywords nil (orglink-font-lock-keywords) t)
         (setq-local org-link-descriptive org-link-descriptive)
         (when org-link-descriptive
           (add-to-invisibility-spec '(org-link)))
         (setq-local font-lock-unfontify-region-function
                     'orglink-unfontify-region)
         (setq-local org-mouse-map orglink-mouse-map))
        (t
         (remove-hook 'org-open-link-functions
                      'orglink-heading-link-search t)
         (font-lock-remove-keywords nil (orglink-font-lock-keywords t))
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
         (message "Refusing to turn on `orglink-mode' in `org-mode'"))
        ((apply 'derived-mode-p orglink-activate-in-modes)
         (orglink-mode 1))))

(defun orglink-unfontify-region (beg end)
  (org-unfontify-region beg end)
  ;; The above does not remove the following properties.
  ;; TODO Should it? Should we? Ask on mailing-list.
  (remove-text-properties beg end '(help-echo t rear-nonsticky t)))

(defun orglink-font-lock-keywords (&optional all)
  `(,@(and (or all (memq 'bracket orglink-activate-links))
           '((orglink-activate-bracket-links (0 'org-link t))))
    ,@(and (or all (memq 'angle orglink-activate-links))
           '((orglink-activate-angle-links (0 'org-link t))))
    ,@(and (or all (memq 'plain orglink-activate-links))
           '((orglink-activate-plain-links (0 'org-link t))))))

(defun orglink-activate-bracket-links (limit)
  "Add text properties for bracketed links."
  (when (orglink-match org-link-bracket-re limit)
    (let* ((hl (match-string-no-properties 1))
           (help (concat "LINK: " (save-match-data (org-link-unescape hl))))
           (ip (list 'invisible 'org-link
                     'keymap org-mouse-map 'mouse-face 'highlight
                     'font-lock-multiline t 'help-echo help
                     'htmlize-link `(:uri ,hl)))
           (vp (list 'keymap org-mouse-map 'mouse-face 'highlight
                     'font-lock-multiline t 'help-echo help
                     'htmlize-link `(:uri ,hl))))
      ;; We need to remove the invisible property here.  Table narrowing
      ;; may have made some of this invisible.
      (org-remove-flyspell-overlays-in (match-beginning 0) (match-end 0))
      (remove-text-properties (match-beginning 0) (match-end 0)
                              '(invisible nil))
      (if (match-end 2)
          (progn
            (add-text-properties (match-beginning 0) (match-beginning 2) ip)
            (org-rear-nonsticky-at (match-beginning 2))
            (add-text-properties (match-beginning 2) (match-end 2) vp)
            (org-rear-nonsticky-at (match-end 2))
            (add-text-properties (match-end 2) (match-end 0) ip)
            (org-rear-nonsticky-at (match-end 0)))
        (add-text-properties (match-beginning 0) (match-beginning 1) ip)
        (org-rear-nonsticky-at (match-beginning 1))
        (add-text-properties (match-beginning 1) (match-end 1) vp)
        (org-rear-nonsticky-at (match-end 1))
        (add-text-properties (match-end 1) (match-end 0) ip)
        (org-rear-nonsticky-at (match-end 0)))
      t)))

(defun orglink-activate-angle-links (limit)
  "Add text properties for angle links."
  (when (orglink-match org-link-angle-re limit)
    (org-remove-flyspell-overlays-in (match-beginning 0) (match-end 0))
    (add-text-properties (match-beginning 0) (match-end 0)
                         (list 'mouse-face 'highlight
                               'keymap org-mouse-map
                               'font-lock-multiline t))
    (org-rear-nonsticky-at (match-end 0))
    t))

(defun orglink-activate-plain-links (limit)
  "Add link properties for plain links."
  (when (orglink-match org-link-plain-re limit)
    (let ((face (get-text-property (max (1- (match-beginning 0)) (point-min))
                                   'face))
          (link (match-string-no-properties 0)))
      (unless (if (consp face) (memq 'org-tag face) (eq 'org-tag face))
        (org-remove-flyspell-overlays-in (match-beginning 0) (match-end 0))
        (add-text-properties (match-beginning 0) (match-end 0)
                             (list 'mouse-face 'highlight
                                   'face 'org-link
                                   'htmlize-link `(:uri ,link)
                                   'keymap org-mouse-map))
        (org-rear-nonsticky-at (match-end 0))
        t))))

(defun orglink-match (regexp limit)
  (and (re-search-forward regexp limit t)
       (or orglink-match-anywhere
           (orglink-inside-comment-or-docstring-p))
       (not (org-in-src-block-p))))

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
