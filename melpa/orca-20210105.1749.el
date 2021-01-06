;;; orca.el --- Org Capture -*- lexical-binding: t -*-

;; Copyright (C) 2017-2021 Oleh Krehel

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/orca
;; Package-Version: 20210105.1749
;; Package-Commit: c50b98da70d08b27ad1751c57bc7edcf27cd1d79
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3") (zoutline "0.1.0"))
;; Keywords: org, convenience

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `org-capture' is powerful but also complex.  This package provides
;; several convenient recipes for configuring `org-capture'.

;;; Code:
(require 'org-protocol)
(require 'org-capture)

;;* Org config
;; In the Firefox extension https://github.com/sprig/org-capture-extension:
;; - "L" is unselected template
;; - "p" is selected template
(dolist (key '("L" "p"))
  (unless (assoc key org-capture-templates)
    (add-to-list 'org-capture-templates
                 `(,key "Link" entry #'orca-handle-link
                        "* TODO %(orca-wash-link)\nAdded: %T\n%?"))))
(setq org-protocol-default-template-key "L")

;;* Orca config
(defgroup orca nil
  "Org capture"
  :group 'org)

(defcustom orca-wash-list
  '((" - Emacs Stack Exchange" "")
    (" - Stack Overflow" ""))
  "A list of (REGEX REP) to be applied on link title."
  :type 'list)

(defcustom orca-org-directory "~/Dropbox/org"
  "The directory where the Org files are."
  :type 'directory)

(defcustom orca-handler-list
  (let ((emacs (expand-file-name "wiki/emacs.org" orca-org-directory))
        (reddit (expand-file-name "wiki/reddit.org" orca-org-directory))
        (entor (expand-file-name "wiki/ent.org" orca-org-directory))
        (stack (expand-file-name "wiki/stack.org" orca-org-directory))
        (github (expand-file-name "wiki/github.org" orca-org-directory)))
    `((orca-handler-project)
      (orca-handler-current-buffer "\\* Tasks")
      (orca-handler-match-url "https://\\(?:www\\.\\)?\\(?:old\\.\\)?reddit.com/r/emacs" ,emacs "\\* Reddit")
      (orca-handler-match-url "https://\\(?:www\\.\\)?\\(?:old\\.\\)?reddit.com/r/" ,reddit "\\* Posts")
      (orca-handler-match-url "https://emacs.stackexchange.com/" ,emacs "\\* Questions")
      (orca-handler-match-url "http://stackoverflow.com/" ,stack "\\* Questions")
      (orca-handler-match-url "https://git\\(?:hub\\|lab\\).com/[^/]+/[^/]+/?\\'" ,github "\\* Repos")
      (orca-handler-file ,entor "\\* Articles")))
  "List of handlers by priority.

Each item is a function of zero arguments that opens an
appropiriate file and returns non-nil on match."
  :type '(repeat
          (choice
           (list
            :tag "Current buffer"
            (const orca-handler-current-buffer)
            (string :tag "Heading"))
           (list
            :tag "URL matching regex"
            (const orca-handler-match-url)
            (string :tag "URL")
            (string :tag "File")
            (string :tag "Heading"))
           (list
            :tag "Default"
            (const orca-handler-file)
            (string :tag "File")
            (string :tag "Heading")))))

;;* Functions
(defun orca-wash-link ()
  "Return a pretty-printed top of `org-stored-links'.
Try to remove superfluous information, like the website title."
  (let ((link (caar org-stored-links))
        (title (cl-cadar org-stored-links)))
    (dolist (repl orca-wash-list)
      (setq title (replace-regexp-in-string
                   (nth 0 repl) (nth 1 repl) title)))
    (org-link-make-string link title)))

(defun orca-require-program (program)
  "Check system for PROGRAM, printing error if unfound."
  (or (and (stringp program)
           (not (string= program ""))
           (executable-find program))
      (user-error "Required program \"%s\" not found in your path" program)))

(defun orca-raise-frame ()
  "Put Emacs frame into focus."
  (if (eq system-type 'gnu/linux)
      (progn
        (orca-require-program "wmctrl")
        (call-process
         "wmctrl" nil nil nil "-i" "-R"
         (frame-parameter (selected-frame) 'outer-window-id)))
    (raise-frame)))

;;* Handlers
(defvar orca-dbg-buf nil)

(defun orca--find-capture-buffer ()
  (let ((p (lambda (b) (with-current-buffer b (eq major-mode 'org-mode)))))
    (or (cl-find-if p (mapcar #'window-buffer (window-list)))
        (cl-find-if p (buffer-list)))))

(defun orca-handler-current-buffer (heading)
  "Select the current `org-mode' buffer with HEADING."
  ;; We are in the server buffer; the actual current buffer is first
  ;; on `buffer-list'.
  (let ((orig-buffer (nth 0 (buffer-list))))
    (when (with-current-buffer orig-buffer
            (and (eq major-mode 'org-mode)
                 (save-excursion
                   (goto-char (point-min))
                   (re-search-forward heading nil t))))
      (switch-to-buffer orig-buffer)
      (goto-char (match-end 0))
      (org-capture-put
       :immediate-finish t
       :jump-to-captured t)
      t)))

(defun orca-handler-project ()
  "Select the current project."
  (let ((orig-buffer (nth 0 (buffer-list)))
        pt)
    (setq orca-dbg-buf orig-buffer)
    (when (with-current-buffer orig-buffer
            (and (eq major-mode 'org-mode)
                 (save-excursion
                   (outline-back-to-heading)
                   (while (> (org-current-level) 1)
                     (setq pt (point))
                     (zo-left 1))
                   (equal (org-get-heading) "Projects"))))
      (org-capture-put
       :immediate-finish t
       :jump-to-captured t)
      (switch-to-buffer orig-buffer)
      (goto-char pt))))

(defun orca-handler-file (file heading)
  "Select FILE at HEADING."
  (when (file-exists-p file)
    (find-file file)
    (goto-char (point-min))
    (re-search-forward heading nil t)
    (org-capture-put
     :immediate-finish t
     :jump-to-captured t)
    (point)))

(defun orca-handler-match-url (url-regex file heading)
  "For link matching URL-REGEX select FILE at HEADING."
  (when (string-match url-regex (caar org-stored-links))
    (orca-handler-file file heading)))

(defun orca-detect-already-captured-link ()
  (let* ((link (caar org-stored-links))
         (default-directory orca-org-directory)
         (old-links
          (counsel--sl
           (format "rg -Fn '%s'" link))))
    (if old-links
        (progn
          (message "%d old link(s)" (length old-links))
          (let ((old-link (car old-links)))
            (if (string-match "^\\(.*\\):\\([0-9]+\\):\\(.*\\)$" old-link)
                (let ((file (match-string 1 old-link))
                      (line (string-to-number (match-string 2 old-link))))
                  (find-file file)
                  (goto-char (point-min))
                  (forward-line (1- line)))
              (error "Could not match %s" old-link)))
          t))))

(defun orca-handle-link ()
  "Select a location to store the current link."
  (orca-raise-frame)
  (if (and (file-exists-p orca-org-directory)
           (file-exists-p (expand-file-name ".git" orca-org-directory))
           (orca-detect-already-captured-link))
      (org-capture-kill)
    (let ((hands orca-handler-list)
          hand)
      (while (and (setq hand (pop hands))
                  (null
                   (apply (car hand) (cdr hand))))))))

(provide 'orca)

;;; orca.el ends here
