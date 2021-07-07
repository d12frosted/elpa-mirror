;;; hyperspace.el --- Get there from here           -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2019  Ian Eure

;; Author: Ian Eure <ian@retrospec.tv>
;; URL: https://github.com/ieure/hyperspace-el
;; Package-Version: 20190209.644
;; Package-Commit: 5fdd680dc2e7b8a064cfdf93d6948546ff51afc2
;; Version: 0.8.4
;; Package-Requires: ((emacs "25") (s "1.12.0"))
;; Keywords: tools, convenience

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

;;; Commentary:

;; Hyperspace is a way to get nearly anywhere from wherever you are,
;; whether that's within Emacs or on the web.  It's somewhere in
;; between Quicksilver and keyword URLs, giving you a single,
;; consistent interface to get directly where you want to go.  It’s
;; for things that you use often, but not often enough to justify a
;; dedicated binding.
;;
;; When you enter Hyperspace, it prompts you where to go:
;;
;; HS:
;;
;; This prompt expects a keyword and a query.  The keyword picks where
;; you want to go, and the remainder of the input is an optional
;; argument which can be used to further search or direct you within
;; that space.
;;
;; Some concrete examples:
;;
;; | *If you enter*   | *then Hyperspace*                                        |
;; |------------------+----------------------------------------------------------|
;; | "lf"             | opens elfeed                                             |
;; | "lf blah"        | opens elfeed, searches for "blah"                        |
;; | "bb"             | shows all BBDB entries                                   |
;; | "bb kenneth"     | shows all BBDB entries with a name matching "kenneth"    |
;; | "ddg foo"        | searches DuckDuckGo for "foo" using browse-url           |
;; | "wp foo"         | searches Wikipedia for "foo" using browse-url            |
;;

;;; Code:

(require 'subr-x)
(require 's)

 ;; Action helpers

(defun hyperspace-action->browse-url-pattern (pattern query)
  "Browse a URL former from PATTERN and QUERY."
  (browse-url (format pattern query)))

(defun hyperspace-action->info (node &optional query)
  "Open an Info buffer for NODE.

   If QUERY is present, look it up in the index."
    (info node)
    (when query
      (Info-index query)))

 ;; Package definitions

(defvar hyperspace-history nil
  "History of Hyperspace actions.")

(defgroup hyperspace nil
  "Getting there from here"
  :prefix "hyperspace-"
  :group 'applications)

(defcustom hyperspace-actions
  '(("ddg" . "https://duckduckgo.com/?q=%s")
    ("dis" . "https://duckduckgo.com/?q=%s&iax=images&ia=images")
    ("wp"  . "https://en.wikipedia.org/wiki/%s")
    ("gg"  . "https://www.google.com/search?q=%s")
    ("gis" . "https://www.google.com/search?tbm=isch&q=%s")
    ("ggm" . "https://www.google.com/maps/search/%s")
    ("yt" . "https://www.youtube.com/results?search_query=%s")
    ("clp" . "https://portland.craigslist.org/search/sss?query=%s")
    ("eb" .  "https://www.ebay.com/sch/i.html?_nkw=%s")
    ("bb" . bbdb-search-name)
    ("el" . (apply-partially #'hyperspace-action->info "(elisp)Top"))
    ("av" . apropos-variable)
    ("ac" . apropos-command)
    ("af" . (lambda (query) (apropos-command query t))))

  "Where Hyperspace should send you.

   Hyperspace actions a cons of (KEYWORD . DISPATCHER).  When
   Hyperspace is invoked, the keyword is extracted and looked up
   in this alist; the remainder of the string is passed to the
   dispatcher as a QUERY argument.

   DISPATCHER can be a function which performs the action.

   DISPATCHER can also be an expression which returns a function
   to perform the action.

   Finally, DISPATCHER can be a string with a URL pattern containing
   '%s'.  The '%s' will be replaced with the query, and the URL browsed."

  :group 'hyperspace
  :type '(alist :key-type (string :tag "Keyword")
                :value-type (choice
                             (function :tag "Function")
                             (string :tag "URL Pattern")
                             (sexp :tag "Expression"))))

(defcustom hyperspace-default-action
  (caar hyperspace-actions)
  "A place to go if you don't specify one."
  :group 'hyperspace
  :type `(radio
          ,@(mapcar (lambda (action) (list 'const (car action))) hyperspace-actions)))

(defcustom hyperspace-max-region-size 256
  "Maximum size of a region to consider for a Hyperspace query.

   If the region is active when Hyperspace is entered, it's used
   as the default query, unless it's more than this number of
   characters."
  :group 'hyperspace
  :type 'integer)




(defun hyperspace--cleanup (text)
  "Clean TEXT so it can be used for a Hyperspace query."
  (save-match-data
    (string-trim
     (replace-regexp-in-string (rx (1+ (or blank "\n"))) " " text))))

(defun hyperspace--initial-text ()
  "Return the initial text.

   This is whatever's in the active region, but cleaned up."
  (when (use-region-p)
    (let* ((start (region-beginning))
           (end (region-end))
           (size (- end start)))
      (when (<= size hyperspace-max-region-size)
        (hyperspace--cleanup
         (buffer-substring-no-properties (region-beginning) (region-end)))))))

(defun hyperspace--initial (initial-text)
  "Turn INITIAL-TEXT into INITIAL-CONTENTS for reading."
  (when initial-text (cons (concat " " initial-text) 1)))

(defun hyperspace--process-input (text)
  "Process TEXT into an actionable keyword and query."
  (let ((kw-text (s-split-up-to "\\s-+" text 1)))
    (if (assoc (car kw-text) hyperspace-actions)
        kw-text
      (list hyperspace-default-action text))))

(defun hyperspace--query ()
  "Ask the user for the Hyperspace action and query.

   Returns (KEYWORD . QUERY).

   If the region isn't active, the user is prompted for the action and query.

   If the region is active, its text is used as the initial value
   for the query, and the user enters the action.

   If a prefix argument is specified and the region is active,
   `HYPERSPACE-DEFAULT-ACTION' is chosen without prompting."

  (let ((initial (hyperspace--initial-text)))
    (if (and initial current-prefix-arg)
        (list hyperspace-default-action initial)
      (hyperspace--process-input
       (read-from-minibuffer "HS: " (hyperspace--initial initial) nil nil
                             'hyperspace-history)))))

(defun hyperspace--evalable-p (form)
  "Can FORM be evaluated?"
  (and (listp form)
       (or (functionp (car form))
           (subrp (car form)))))

(defun hyperspace--dispatch (action &optional query)
  "Execute ACTION, with optional QUERY argument."
  (pcase action
    ((pred functionp) (funcall action query))
    ((pred hyperspace--evalable-p) (funcall (eval action) query))
    ((pred stringp) (hyperspace-action->browse-url-pattern action query))
    (_ (error "Unknown action"))))

;;;###autoload
(defun hyperspace (keyword &optional query)
  "Execute action for keyword KEYWORD, with optional QUERY."
  (interactive (hyperspace--query))
  (let ((action (cdr (assoc keyword hyperspace-actions))))
    (hyperspace--dispatch (or action hyperspace-default-action) query)))

;;;###autoload
(defun hyperspace-enter (&optional query)
  "Enter Hyperspace, sending QUERY to the default action.

   If the region is active, use that as the query for
   ‘hyperspace-default-action’.  Otherwise, prompt the user."
  (interactive (list (hyperspace--initial-text)))
  (hyperspace
   hyperspace-default-action
   (or query
       (read-from-minibuffer
        (format "HS: %s " hyperspace-default-action) nil nil
        'hyperspace-history))))

 ;; Minor mode

(defvar hyperspace-minor-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "H-SPC") #'hyperspace)
    (define-key kmap (kbd "<H-return>") #'hyperspace-enter)
    kmap))

;;;###autoload
(define-minor-mode hyperspace-minor-mode
  "Global (universal) minor mode to jump from here to there."
  nil nil hyperspace-minor-mode-map
  :group 'hyperspace
  :global t)

(provide 'hyperspace)

;;; hyperspace.el ends here
