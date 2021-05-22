;;; dpaste.el --- Emacs integration for dpaste.com

;; Copyright (C) 2008, 2009 Greg Newman <greg@gregnewman.org>

;; Version: 0.2
;; Package-Version: 20160303.2112
;; Package-Commit: 5ebabb466a6ae70882549855b6b2194fc32189f8
;; Keywords: paste pastie pastebin dpaste python
;; Created: 01 Dec 2008
;; Author: Greg Newman <greg@gregnewman.org>
;;         Guilherme Gondim <semente@taurinus.org>
;; Maintainer: Greg Newman <greg@gregnewman.org>

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;; dpaste.el provides functions to post a region or buffer to
;; <http://dpaste.com> and put the paste URL into the kill-ring.

;; Inspired by gist.el

;; Current dpaste.com API usage example:

;;     curl -si -F 'content=<-' http://dpaste.com/api/v2/ \
;;       | grep ^Location: | colrm 1 10

;; Thanks to Paul Bissex (http://news.e-scribe.com) for a great paste
;; service.

;; Installation and setup:

;; Put this file in a directory where Emacs can find it. On GNU/Linux
;; it's usually /usr/local/share/emacs/site-lisp/ and on Windows it's
;; something like "C:\Program Files\Emacs<version>\site-lisp". Then
;; add the follow instructions in your .emacs.el:

;;     (require 'dpaste nil)
;;     (global-set-key (kbd "C-c p") 'dpaste-region-or-buffer)
;;     (setq dpaste-poster "Guido van Rossum")

;; Then with C-c p you can run `dpaste-region-or-buffer'. With a prefix
;; argument (C-u C-c p), your paste will use the hold option.

;;; Code:
(require 'url)

(defvar dpaste-poster (user-full-name)
  "Paste author name or e-mail. Don't put more than 30 characters here.")

(defvar dpaste-supported-modes-alist
  '((c++-mode . "cpp")
    (c-mode . "c")
    (conf-mode . "ini")
    (conf-space-mode . "ini")
    (conf-unix-mode . "ini")
    (conf-windows-mode . "ini")
    (cperl-mode . "perl")
    (css-mode . "css")
    (diff-mode . "diff")
    (diff-mode . "diff")
    (emacs-lisp-mode . "common-lisp")
    (haskell-mode . "haskell")
    (html-mode . "html")
    (inferior-python-mode . "pycon")
    (java-mode . "java")
    (javascript-mode . "js")
    (js2-mode . "js")
    (lisp-interaction-mode . "common-lisp")
    (lisp-mode . "common-lisp")
    (lua-mode . "lua")
    (magit-diff-mode . "diff")
    (makefile-automake-mode . "make")
    (makefile-bsdmake-mode . "make")
    (makefile-gmake-mode . "make")
    (makefile-imake-mode . "make")
    (makefile-makepp-mode . "make")
    (makefile-mode . "make")
    (prolog-mode . "prolog")
    (python-2-mode . "python")
    (python-3-mode . "python3")
    (python-basic-mode . "python")
    (python-mode . "python")
    (ruby-mode . "rb")
    (scheme-mode . "scheme")
    (sh-mode . "bash")
    (shell-mode . "bash")
    (smalltalk-mode . "smalltalk")
    (sql-mode . "sql")
    (web-mode . "html")
    (xml-mode . "xml")
    (yaml-mode . "yaml")))


;;;###autoload
(defun dpaste-region (begin end title &optional arg)
  "Post the current region or buffer to dpaste.com and yank the
url to the kill-ring."
  (interactive "r\nsPaste title: \nP")
  (let* ((syntax (or (cdr (assoc major-mode dpaste-supported-modes-alist))
                     ""))
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (format "content=%s&syntax=%s&title=%s&poster=%s"
                  (url-hexify-string (buffer-substring-no-properties begin end))
                  (url-hexify-string syntax)
                  (url-hexify-string title)
                  (url-hexify-string dpaste-poster))))
    (with-current-buffer (url-retrieve-synchronously
                          "http://dpaste.com/api/v2/")
      (goto-char (point-min))
      (if (search-forward-regexp
           "^Location: \\(http://dpaste.com/[[:upper:][:digit:]]+\\)"
           (point-max)
           t)
          (let ((paste-url (match-string 1)))
            (message "Paste created: %s (yanked)" paste-url)
            (kill-new paste-url)
            (kill-buffer))
        ;; if we can't find the Location, show the http result buffer
        (switch-to-buffer (current-buffer)))
      )))

;;;###autoload
(defun dpaste-buffer (title &optional arg)
  "Post the current buffer to dpaste.com and yank the url to the
kill-ring."
  (interactive "sPaste title: \nP")
  (dpaste-region (point-min) (point-max) title arg))

;;;###autoload
(defun dpaste-region-or-buffer (title &optional arg)
  "Post the current region or buffer to dpaste.com and yank the
url to the kill-ring."
  (interactive "sPaste title: \nP")
  (if (use-region-p)
      (dpaste-region (region-beginning) (region-end) title arg)
    (dpaste-buffer title arg)))


(provide 'dpaste)
;;; dpaste.el ends here.
