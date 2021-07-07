;;; cheat-sh.el --- Interact with cheat.sh  -*- lexical-binding: t -*-
;; Copyright 2017-2019 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.8
;; Package-Version: 20210607.1307
;; Package-Commit: 33bae22feae8d3375739c6bdef08d0dcdf47ee42
;; Keywords: docs, help
;; URL: https://github.com/davep/cheat-sh.el
;; Package-Requires: ((emacs "25.1"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; cheat-sh.el provides a simple Emacs interface for looking things up on
;; cheat.sh.

;;; Code:

(require 'cl-lib)
(require 'url-vars)

(defgroup cheat-sh nil
  "Interact with cheat.sh."
  :group 'docs)

(defface cheat-sh-section
  '((t :inherit (bold font-lock-doc-face)))
  "Face used on sections in a cheat-sh output window."
  :group 'cheat-sh)

(defface cheat-sh-caption
  '((t :inherit (bold font-lock-function-name-face)))
  "Face used on captions in the cheat-sh output window."
  :group 'cheat-sh)

(defcustom cheat-sh-list-timeout (* 60 60 4)
  "Seconds to wait before deciding the cached sheet list is \"stale\"."
  :type 'integer
  :group 'cheat-sh)

(defcustom cheat-sh-topic-mode-map
  '((awk-mode . "awk")
    (c++-mode . "cpp")
    (c-mode . "c")
    (clojure-mode . "clojure")
    (clojurescript-mode . "clojure")
    (dockerfile-mode . "docker")
    (emacs-lisp-mode . "elisp")
    (fish-mode . "fish")
    (go-mode . "go")
    (haskell-mode . "haskell")
    (hy-mode . "hy")
    (java-mode . "java")
    (js-jsx-mode . "javascript")
    (js-mode . "javascript")
    (lisp-interaction-mode . "elisp")
    (lisp-mode . "lisp")
    (objc-mode . "objectivec")
    (pike-mode . "pike")
    (powershell-mode . "powershell")
    (python-mode . "python")
    (rust-mode . "rust")
    (sh-mode . "bash"))
  "Map of Emacs major mode names to cheat.sh topic names."
  :type '(repeat (cons
                  (symbol :tag "Major mode")
                  (string :tag "cheat.sh topic")))
  :group 'cheat-sh)

(defconst cheat-sh-url "http://cheat.sh/%s?T"
  "URL for cheat.sh.")

(defconst cheat-sh-user-agent "cheat-sh.el (curl)"
  "User agent to send to cheat.sh.

Note that \"curl\" should ideally be included in the user agent
string because of the way cheat.sh works.

cheat.sh looks for a specific set of clients in the user
agent (see https://goo.gl/8gh95X for this) to decide if it should
deliver plain text rather than HTML. cheat-sh.el requires plain
text.")

(defun cheat-sh-get (thing)
  "Get THING from cheat.sh."
  (let* ((url-request-extra-headers `(("User-Agent" . ,cheat-sh-user-agent)))
         (buffer (url-retrieve-synchronously (format cheat-sh-url (url-hexify-string thing)) t t)))
    (when buffer
      (unwind-protect
          (with-current-buffer buffer
            (set-buffer-multibyte t)
            (setf (point) (point-min))
            (when (search-forward-regexp "^$" nil t)
              (buffer-substring (1+ (point)) (point-max))))
        (kill-buffer buffer)))))

(defvar cheat-sh-sheet-list nil
  "List of all available sheets.")

(defvar cheat-sh-sheet-list-acquired nil
  "The time when variable `cheat-sh-sheet-list' was populated.")

(defun cheat-sh-sheet-list-cache ()
  "Return the list of sheets.

The list is cached in memory, and is considered \"stale\" and is
refreshed after `cheat-sh-list-timeout' seconds."
  (when (and cheat-sh-sheet-list-acquired
             (> (- (time-to-seconds) cheat-sh-sheet-list-acquired) cheat-sh-list-timeout))
    (setq cheat-sh-sheet-list nil))
  (or cheat-sh-sheet-list
      (let ((list (cheat-sh-get ":list")))
        (when list
          (setq cheat-sh-sheet-list-acquired (time-to-seconds))
          (setq cheat-sh-sheet-list (split-string list "\n"))))))

(defun cheat-sh-read (prompt &optional initial)
  "Read input from the user, showing PROMPT to prompt them.

This function is used by some `interactive' functions in
cheat-sh.el to get the item to look up. It provides completion
based of the sheets that are available on cheat.sh.

If a value is passed for INITIAL it is used as the initial
input."
  (completing-read prompt (cheat-sh-sheet-list-cache) nil nil initial))

;;; Major mode

(defconst cheat-sh-font-lock-keywords
  '(;; "[Search section]"
    ("^\\(\\[.*\\]\\)$"        . 'cheat-sh-section)
    ;; "# Result caption"
    ("^\\(#.*\\)$"             . 'cheat-sh-caption)
    ;; "cheat-sh help caption:"
    ("^\\([^[:space:]].*:\\)$" . 'cheat-sh-caption)))

(define-derived-mode cheat-sh-mode special-mode "Cheat"
  "Major mode for viewing results from cheat-sh.
Commands:
\\{cheat-sh-mode-map}"
  :abbrev-table nil
  (setq font-lock-defaults (list cheat-sh-font-lock-keywords)))

(defun cheat-sh-mode-setup ()
  "Set up the cheat mode for the current buffer."
  (cheat-sh-mode)
  (setq buffer-read-only nil))

;;;###autoload
(defun cheat-sh (thing)
  "Look up THING on cheat.sh and display the result."
  (interactive (list (cheat-sh-read "Lookup: ")))
  (let ((result (cheat-sh-get thing)))
    (if result
        (let ((temp-buffer-window-setup-hook
               (cons 'cheat-sh-mode-setup temp-buffer-window-show-hook)))
          (with-temp-buffer-window "*cheat.sh*" nil 'help-window-setup
            (princ result)))
      (error "Can't find anything for %s on cheat.sh" thing))))

;;;###autoload
(defun cheat-sh-region (start end)
  "Look up the text between START and END on cheat.sh."
  (interactive "r")
  (deactivate-mark)
  (cheat-sh (buffer-substring-no-properties start end)))

;;;###autoload
(defun cheat-sh-maybe-region ()
  "If region is active lookup content of region, otherwise prompt."
  (interactive)
  (call-interactively (if mark-active #'cheat-sh-region #'cheat-sh)))

;;;###autoload
(defun cheat-sh-help ()
  "Get help on using cheat.sh."
  (interactive)
  (cheat-sh ":help"))

;;;###autoload
(defun cheat-sh-list (thing)
  "Get a list of topics available on cheat.sh.

Either gets a topic list for subject THING, or simply gets a list
of all available topics on cheat.sh if THING is supplied as an
empty string."
  (interactive (list (cheat-sh-read "List sheets for: ")))
  (cheat-sh (format "%s/:list" thing)))

;;;###autoload
(defun cheat-sh-search (thing)
  "Search for THING on cheat.sh and display the result."
  (interactive "sSearch: ")
  (cheat-sh (concat "+" thing)))

(defun cheat-sh-guess-topic ()
  "Attempt to guess a topic to search."
  (alist-get major-mode cheat-sh-topic-mode-map))

;;;###autoload
(defun cheat-sh-search-topic (topic thing)
  "Search TOPIC for THING on cheat.sh and display the result."
  (interactive
   (list (cheat-sh-read "Topic: " (cheat-sh-guess-topic))
         (read-string "Search: ")))
  (cheat-sh (concat topic "/" thing)))

(provide 'cheat-sh)

;;; cheat-sh.el ends here
