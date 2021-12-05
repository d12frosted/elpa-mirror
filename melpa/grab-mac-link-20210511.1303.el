;;; grab-mac-link.el --- Grab link from Mac Apps and insert it into Emacs  -*- lexical-binding: t; -*-

;; Copyright (c) 2010-2016 Free Software Foundation, Inc.
;; Copyright (C) 2016-2020 Xu Chunyang

;; The code is heavily inspired by org-mac-link.el

;; Authors of org-mac-link.el:
;;      Anthony Lander <anthony.lander@gmail.com>
;;      John Wiegley <johnw@gnu.org>
;;      Christopher Suckling <suckling at gmail dot com>
;;      Daniil Frumin <difrumin@gmail.com>
;;      Alan Schmitt <alan.schmitt@polytechnique.org>
;;      Mike McLean <mike.mclean@pobox.com>

;; Author: Xu Chunyang
;; URL: https://github.com/xuchunyang/grab-mac-link.el
;; Package-Version: 20210511.1303
;; Package-Commit: 2c722016ca01bd4265d57c4a7d55712c94cf4ea5
;; Version: 0.3
;; Package-Requires: ((emacs "24"))
;; Keywords: mac, hyperlink
;; Created: Sat Jun 11 15:07:18 CST 2016

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

;; The following applications are supportted:
;; - Chrome
;; - Safari
;; - Firefox
;; - Finder
;; - Mail
;; - Terminal
;; - Skim
;; - qutebrowser
;;
;; The following link types are supported:
;; - plain:    https://www.wikipedia.org/
;; - markdonw: [Wikipedia](https://www.wikipedia.org/)
;; - org:      [[https://www.wikipedia.org/][Wikipedia]]
;; - html:     <a href="https://www.wikipedia.org/">Wikipedia</a>
;;
;; To use, type M-x grab-mac-link or call `grab-mac-link' from Lisp
;;
;;   (grab-mac-link APP &optional LINK-TYPE)
;;
;; There is a DWIM version, M-x grab-mac-link-dwim, it chooses an application
;; according to `grab-mac-link-dwim-favourite-app' and link type according to
;; `major-mode'.

;;; Code:

(declare-function org-add-link-type "org-compat" (type &optional follow export))
(declare-function org-make-link-string "org" (link &optional description))

(defvar org-stored-links)

(defun grab-mac-link-split (as-link)
  (split-string as-link "::split::"))

(defun grab-mac-link-unquote (s)
  (if (string-prefix-p "\"" s)
      (substring s 1 -1)
    s))

(defun grab-mac-link-make-plain-link (url _name)
  url)

(defvar grab-mac-link-org-setup-p nil)

(defun grab-mac-link-org-setup ()
  (require 'org)
  (unless (require 'org-mac-link nil 'no-error)
    ;; Handle links from Skim.app
    ;;
    ;; Original code & idea by Christopher Suckling (org-mac-protocol)

    (org-add-link-type "skim" 'org-mac-skim-open)

    (defun org-mac-skim-open (uri)
      "Visit page of pdf in Skim"
      (let* ((page (when (string-match "::\\(.+\\)\\'" uri)
                     (match-string 1 uri)))
             (document (substring uri 0 (match-beginning 0))))
        (do-applescript
         (concat
          "tell application \"Skim\"\n"
          "activate\n"
          "set theDoc to \"" document "\"\n"
          "set thePage to " page "\n"
          "open theDoc\n"
          "go document 1 to page thePage of document 1\n"
          "end tell"))))

    ;; Handle links from Mail.app

    (org-add-link-type "message" 'org-mac-message-open)

    (defun org-mac-message-open (message-id)
      "Visit the message with MESSAGE-ID.
This will use the command `open' with the message URL."
      (start-process (concat "open message:" message-id) nil
                     "open" (concat "message://<" (substring message-id 2) ">")))))

(defun grab-mac-link-make-org-link (url name)
  (unless grab-mac-link-org-setup-p
    (setq grab-mac-link-org-setup-p t)
    (grab-mac-link-org-setup))
  (org-make-link-string url name))

(defun grab-mac-link-make-markdown-link (url name)
  "Make a Markdown inline link."
  (format "[%s](%s)" name url))

(defun grab-mac-link-make-html-link (url name)
  "Make an HTML <a> link."
  (format "<a href=\"%s\">%s</a>" url name))


;; Google Chrome.app

(defun grab-mac-link-chrome-1 ()
  (let ((result
         (do-applescript
          (concat
           "set frontmostApplication to path to frontmost application\n"
           "tell application \"Google Chrome\"\n"
           "	set theUrl to get URL of active tab of first window\n"
           "	set theTitle to get title of active tab of first window\n"
           "	set theResult to (get theUrl) & \"::split::\" & theTitle\n"
           "end tell\n"
           "activate application (frontmostApplication as text)\n"
           "set links to {}\n"
           "copy theResult to the end of links\n"
           "return links as string\n"))))
    (grab-mac-link-split
     (replace-regexp-in-string
      "^\"\\|\"$" "" (car (split-string result "[\r\n]+" t))))))


;; Firefox.app

(defun grab-mac-link-firefox-1 ()
  (let ((result
         (do-applescript
          (concat
           "set oldClipboard to the clipboard\n"
           "set frontmostApplication to path to frontmost application\n"
           "tell application \"Firefox\"\n"
           "	activate\n"
           "	delay 0.15\n"
           "	tell application \"System Events\"\n"
           "		keystroke \"l\" using {command down}\n"
           "		keystroke \"a\" using {command down}\n"
           "		keystroke \"c\" using {command down}\n"
           "	end tell\n"
           "	delay 0.15\n"
           "	set theUrl to the clipboard\n"
           "	set the clipboard to oldClipboard\n"
           "	set theResult to (get theUrl) & \"::split::\" & (get name of window 1)\n"
           "end tell\n"
           "activate application (frontmostApplication as text)\n"
           "set links to {}\n"
           "copy theResult to the end of links\n"
           "return links as string\n"))))
    (grab-mac-link-split
     (car (split-string result "[\r\n]+" t)))))


;; Safari.app

(defun grab-mac-link-safari-1 ()
  (grab-mac-link-split
   (grab-mac-link-unquote
    (do-applescript
     (concat
      "tell application \"Safari\"\n"
      "	set theUrl to URL of document 1\n"
      "	set theName to the name of the document 1\n"
      "	return theUrl & \"::split::\" & theName\n"
      "end tell\n")))))


;; Finder.app

(defun grab-mac-link-finder-selected-items ()
  (split-string
   (do-applescript
    (concat
     "tell application \"Finder\"\n"
     " set theSelection to the selection\n"
     " set links to {}\n"
     " repeat with theItem in theSelection\n"
     " set theLink to \"file://\" & (POSIX path of (theItem as string)) & \"::split::\" & (get the name of theItem) & \"\n\"\n"
     " copy theLink to the end of links\n"
     " end repeat\n"
     " return links as string\n"
     "end tell\n"))
   "\n" t))

(defun grab-mac-link-finder-1 ()
  "Return selected file in Finder.
If there are more than more selected files, just return the first one.
If there is none, return nil."
  (car (mapcar #'grab-mac-link-split (grab-mac-link-finder-selected-items))))


;; Mail.app

(defun grab-mac-link-mail-1 ()
  "AppleScript to create links to selected messages in Mail.app."
  (grab-mac-link-split
   (do-applescript
    (concat
     "tell application \"Mail\"\n"
     "set theLinkList to {}\n"
     "set theSelection to selection\n"
     "repeat with theMessage in theSelection\n"
     "set theID to message id of theMessage\n"
     "set theSubject to subject of theMessage\n"
     "set theLink to \"message://<\" & theID & \">::split::\" & theSubject\n"
     "if (theLinkList is not equal to {}) then\n"
     "set theLink to \"\n\" & theLink\n"
     "end if\n"
     "copy theLink to end of theLinkList\n"
     "end repeat\n"
     "return theLinkList as string\n"
     "end tell"))))


;; Terminal.app

(defun grab-mac-link-terminal-1 ()
  (grab-mac-link-split
   (grab-mac-link-unquote
    (do-applescript
     (concat
      "tell application \"Terminal\"\n"
      "  set theName to custom title in tab 1 of window 1\n"
      "  do script \"pwd | pbcopy\" in window 1\n"
      "  set theUrl to do shell script \"pbpaste\"\n"
      "  return theUrl & \"::split::\" & theName\n"
      "end tell")))))


;; Skim.app
(defun grab-mac-link-skim-1 ()
  (grab-mac-link-split
   (do-applescript
    (concat
     "tell application \"Skim\"\n"
     "set theDoc to front document\n"
     "set theTitle to (name of theDoc)\n"
     "set thePath to (path of theDoc)\n"
     "set thePage to (get index for current page of theDoc)\n"
     "set theSelection to selection of theDoc\n"
     "set theContent to contents of (get text for theSelection)\n"
     "if theContent is missing value then\n"
     "    set theContent to theTitle & \", p. \" & thePage\n"
     "end if\n"
     "set theLink to \"skim://\" & thePath & \"::\" & thePage & "
     "\"::split::\" & theContent\n"
     "end tell\n"
     "return theLink as string\n"))))


;; qutebrowser.app

(defun grab-mac-link-qutebrowser-1 ()
  (let ((result
         (do-applescript
          (concat
           "set oldClipboard to the clipboard\n"
           "set frontmostApplication to path to frontmost application\n"
           "tell application \"qutebrowser\"\n"
           "	activate\n"
           "	delay 0.15\n"
           "	tell application \"System Events\"\n"
           "		keystroke \"y\"\n"
           "		keystroke \"y\"\n"
           "	end tell\n"
           "	delay 0.15\n"
           "	set theUrl to the clipboard\n"
           "	set the clipboard to oldClipboard\n"
           "	delay 0.15\n"
           "	tell application \"System Events\"\n"
           "		keystroke \"y\"\n"
           "		keystroke \"T\"\n"
           "	end tell\n"
           "	delay 0.15\n"
           "	set theTitle to the clipboard\n"
           "	set the clipboard to oldClipboard\n"
	       "    set theResult to (get theUrl) & \"::split::\" & (get theTitle)\n"
           "end tell\n"
           "activate application (frontmostApplication as text)\n"
           "set links to {}\n"
           "copy theResult to the end of links\n"
           "return links as string\n"))))
    (grab-mac-link-split
     (car (split-string result "[\r\n]+" t)))))


;; One Entry point for all

;;;###autoload
(defun grab-mac-link (app &optional link-type)
  "Prompt for an application to grab a link from.
When done, go grab the link, and insert it at point.

With a prefix argument, instead of \"insert\", save it to
kill-ring. For org link, save it to `org-stored-links', then
later you can insert it via `org-insert-link'.

If called from lisp, grab link from APP and return it (as a
string) with LINK-TYPE.  APP is a symbol and must be one of
'(chrome safari finder mail terminal), LINK-TYPE is also a symbol
and must be one of '(plain markdown org), if LINK-TYPE is omitted
or nil, plain link will be used."
  (interactive
   (let ((apps
          '((?c . chrome)
            (?s . safari)
            (?f . firefox)
            (?F . finder)
            (?m . mail)
            (?t . terminal)
            (?S . skim)
            (?q . qutebrowser)))
         (link-types
          '((?p . plain)
            (?m . markdown)
            (?o . org)
            (?h . html)))
         (propertize-menu
          (lambda (string)
            "Propertize substring between [] in STRING."
            (with-temp-buffer
              (insert string)
              (goto-char 1)
              (while (re-search-forward "\\[\\(.+?\\)\\]" nil 'no-error)
                (replace-match (format "[%s]" (propertize (match-string 1) 'face 'bold))))
              (buffer-string))))
         input app link-type)
     (let ((message-log-max nil))
       (message (funcall propertize-menu
                         "Grab link from [c]hrome [s]afari [f]irefox [F]inder [m]ail [t]erminal [S]kim [q]utebrowser:")))
     (setq input (read-char-exclusive))
     (setq app (cdr (assq input apps)))
     (let ((message-log-max nil))
       (message (funcall propertize-menu
                         (format "Grab link from %s as a [p]lain [m]arkdown [o]rg [h]tml link:" app))))
     (setq input (read-char-exclusive))
     (setq link-type (cdr (assq input link-types)))
     (list app link-type)))

  (setq link-type (or link-type 'plain))
  (unless (and (memq app '(chrome safari firefox finder mail terminal skim qutebrowser))
               (memq link-type '(plain org markdown html)))
    (error "Unknown app %s or link-type %s" app link-type))
  (let* ((grab-link-func (intern (format "grab-mac-link-%s-1" app)))
         (make-link-func (intern (format "grab-mac-link-make-%s-link" link-type)))
         (link (apply make-link-func (funcall grab-link-func))))
    (when (called-interactively-p 'any)
      (if current-prefix-arg
          (if (eq link-type 'org)
              (let* ((res (funcall grab-link-func))
                     (link (car res))
                     (desc (cadr res)))
                (push (list link desc) org-stored-links)
                (message "Stored: %s" desc))
            (kill-new link)
            (message "Copied: %s" link))
        (insert link)))
    link))

;; NOTE A good idea is to use most recent application, however I don't know how
;; to get such information.
(defvar grab-mac-link-dwim-favourite-app nil)

;;;###autoload
(defun grab-mac-link-dwim (app)
  (interactive
   (list
    (or
     (and (not current-prefix-arg) grab-mac-link-dwim-favourite-app)
     (intern (completing-read "Application: "
                              '(chrome safari firefox finder mail terminal skim qutebrowser)
                              nil t)))))
  (let ((link-type (cond
                    ((derived-mode-p 'markdown-mode) 'markdown)
                    ((derived-mode-p 'org-mode)      'org)
                    ((derived-mode-p 'html-mode)     'html)
                    (t 'plain))))
    (insert (grab-mac-link app link-type))))

(provide 'grab-mac-link)
;;; grab-mac-link.el ends here
