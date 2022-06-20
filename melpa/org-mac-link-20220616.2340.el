;;; org-mac-link.el --- Insert org-mode links to items selected in various Mac apps -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2010-2022 Free Software Foundation, Inc.
;;
;; Author: Anthony Lander <anthony.lander@gmail.com>
;;         John Wiegley <johnw@gnu.org>
;;         Christopher Suckling <suckling at gmail dot com>
;;         Daniil Frumin <difrumin@gmail.com>
;;         Alan Schmitt <alan.schmitt@polytechnique.org>
;;         Mike McLean <mike.mclean@pobox.com>
;; Version: 1.9
;; Package-Version: 20220616.2340
;; Package-Commit: 0b18c1d070b9601cc65c40e902169e367e4348c9
;; Keywords: files, wp, url, org
;; Package-Requires: ((emacs "27.1"))
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Homepage: https://gitlab.com/aimebertrand/org-mac-link
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;
;;; Commentary:
;;
;; This code allows you to grab either the current selected items, or
;; the frontmost url in various mac appliations, and insert them as
;; hyperlinks into the current org-mode document at point.
;;
;; This code is heavily based on, and indeed incorporates,
;; org-mac-message.el written by John Wiegley and Christopher
;; Suckling.
;;
;; Detailed comments for each application interface are inlined with
;; the code.  Here is a brief overview of how the code interacts with
;; each application:
;;
;; Finder.app - grab links to the selected files in the frontmost window
;; Mail.app - grab links to the selected messages in the message list
;; AddressBook.app - Grab links to the selected addressbook Cards
;; Firefox.app - Grab the url of the frontmost tab in the frontmost window
;; Vimperator/Firefox.app - Grab the url of the frontmost tab in the frontmost window
;; Safari.app - Grab the url of the frontmost tab in the frontmost window
;; Google Chrome.app - Grab the url of the frontmost tab in the frontmost window
;; Brave.app - Grab the url of the frontmost tab in the frontmost window
;; Together.app - Grab links to the selected items in the library list
;; Skim.app - Grab a link to the selected page in the topmost pdf document
;; Microsoft Outlook.app - Grab a link to the selected message in the message list
;; DEVONthink Pro Office.app - Grab a link to the selected DEVONthink item(s); open DEVONthink item by reference
;; Evernote.app - Grab a link to the selected Evernote item(s); open Evernote item by ID
;; qutebrowser.app - Grab the url of the frontmost tab in the frontmost window
;;
;;
;; Installation:
;;
;; Add (require 'org-mac-link) to your `.emacs' or `init.el'.
;;
;; If you are using `use-package' add the following:
;; (use-package org-mac-link
;;   :ensure t)
;;
;; Optionally bind a key to activate the link grabber menu, like this:
;; (add-hook 'org-mode-hook (lambda ()
;;   (define-key org-mode-map (kbd "C-c g") 'org-mac-link-get-link)))
;;
;; Usage:
;;
;; Type C-c g (or whatever key you defined, as above), or type M-x
;; org-mac-link-get-link RET to activate the link grabber.  This will present
;; you with a menu to choose an application from which to grab a link
;; to insert at point.  You may also type C-g to abort.
;;
;; Customizing:
;;
;; You may customize which applications appear in the grab menu by
;; customizing the group `org-mac-link'.  Changes take effect
;; immediately.
;;
;;
;;; Code:

(require 'org)
(require 'org-goto)

(defgroup org-mac-link nil
  "Options for grabbing links from Mac applications."
  :tag "Org Mac link"
  :group 'org-link)

(defcustom org-mac-link-finder-app-p t
  "Add menu option [F]inder to grab links from the Finder."
  :tag "Grab Finder.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-mail-app-p t
  "Add menu option [m]ail to grab links from Mail.app."
  :tag "Grab Mail.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-outlook-app-p t
  "Add menu option [o]utlook to grab links from Microsoft Outlook.app."
  :tag "Grab Microsoft Outlook.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-outlook-path "/Applications/Microsoft Outlook.app"
  "The path to the installed copy of Microsoft Outlook.app.
Do not escape spaces as the AppleScript call will quote this string."
  :tag "Path to Microsoft Outlook"
  :group 'org-mac-link
  :type 'string)

(defcustom org-mac-link-devonthink-app-p t
  "Add menu option [d]EVONthink to grab links from DEVONthink Pro Office.app."
  :tag "Grab DEVONthink Pro Office.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-addressbook-app-p t
  "Add menu option [a]ddressbook to grab links from AddressBook.app."
  :tag "Grab AddressBook.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-safari-app-p t
  "Add menu option [s]afari to grab links from Safari.app."
  :tag "Grab Safari.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-firefox-app-p t
  "Add menu option [f]irefox to grab links from Firefox.app."
  :tag "Grab Firefox.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-firefox-vimperator-p nil
  "Add menu option [v]imperator to grab links from Firefox.app with Vimperator."
  :tag "Grab Vimperator/Firefox.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-chrome-app-p t
  "Add menu option [c]hrome to grab links from Google Chrome.app."
  :tag "Grab Google Chrome.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-brave-app-p t
  "Add menu option [b]rave to grab links from Brave.app."
  :tag "Grab Brave.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-together-app-p nil
  "Add menu option [t]ogether to grab links from Together.app."
  :tag "Grab Together.app links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-skim-app-p
  (< 0 (length (shell-command-to-string
                "mdfind kMDItemCFBundleIdentifier == 'net.sourceforge.skim-app.skim'")))
  "Add menu option [S]kim to grab page links from Skim.app."
  :tag "Grab Skim.app page links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-highlight-selection-p nil
  "Highlight the active selection when grabbing a link from Skim.app."
  :tag "Highlight selection in Skim.app"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-acrobat-app-p t
  "Add menu option [A]crobat to grab page links from Acrobat.app."
  :tag "Grab Acrobat.app page links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-mail-account nil
  "The Mail.app account in which to search for flagged messages."
  :tag "Org Mail.app Account"
  :group 'org-mac-link
  :type 'string)

(defcustom org-mac-link-evernote-app-p nil
  "Add menu option [e]vernote to grab note links from Evernote.app."
  :tag "Grab Evernote.app note links"
  :group 'org-mac-link
  :type 'boolean)

(defcustom org-mac-link-evernote-path nil
  "The path to the installed copy of Evernote.app.
Do not escape spaces as the AppleScript call will quote this string."
  :tag "Path to Evernote"
  :group 'org-mac-link
  :type 'string)

(defcustom org-mac-link-qutebrowser-app-p t
  "Add menu option [q]utebrowser to grab links from qutebrowser.app."
  :tag "Grab qutebrowser.app links"
  :group 'org-mac-link
  :type 'boolean)



;; In mac.c, removed in Emacs 23.
(declare-function org-mac-link-do-applescript "org-mac-message" (script))
(unless (fboundp 'org-mac-link-do-applescript)
  ;; Need to fake this using shell-command-to-string
  (defun org-mac-link-do-applescript (script)
    (let (start cmd return)
      (while (string-match "\n" script)
        (setq script (replace-match "\r" t t script)))
      (while (string-match "'" script start)
        (setq start (+ 2 (match-beginning 0))
              script (replace-match "\\'" t t script)))
      (setq cmd (concat "osascript -e '" script "'"))
      (setq return (shell-command-to-string cmd))
      (concat "\"" (org-trim return) "\""))))

;;;###autoload
(defun org-mac-link-get-link ()
  "Prompt for an application to grab a link from.
When done, go grab the link, and insert it at point."
  (interactive)
  (let* ((descriptors
	  `(("F" "inder" org-mac-link-finder-insert-selected ,org-mac-link-finder-app-p)
	    ("m" "ail" org-mac-link-mail-insert-selected ,org-mac-link-mail-app-p)
	    ("d" "EVONthink Pro Office" org-mac-link-devonthink-item-insert-selected
	     ,org-mac-link-devonthink-app-p)
	    ("o" "utlook" org-mac-link-outlook-message-insert-selected ,org-mac-link-outlook-app-p)
	    ("a" "ddressbook" org-mac-link-addressbook-item-insert-selected ,org-mac-link-addressbook-app-p)
	    ("s" "afari" org-mac-link-safari-insert-frontmost-url ,org-mac-link-safari-app-p)
	    ("f" "irefox" org-mac-link-firefox-insert-frontmost-url ,org-mac-link-firefox-app-p)
	    ("v" "imperator" org-mac-link-vimperator-insert-frontmost-url ,org-mac-link-firefox-vimperator-p)
	    ("c" "hrome" org-mac-link-chrome-insert-frontmost-url ,org-mac-link-chrome-app-p)
	    ("b" "rave" org-mac-link-brave-insert-frontmost-url ,org-mac-link-brave-app-p)
        ("e" "evernote" org-mac-link-evernote-note-insert-selected ,org-mac-link-evernote-app-p)
	    ("t" "ogether" org-mac-link-together-insert-selected ,org-mac-link-together-app-p)
	    ("S" "kim" org-mac-link-skim-insert-page ,org-mac-link-skim-app-p)
	    ("A" "crobat" org-mac-link-acrobat-insert-page ,org-mac-link-acrobat-app-p)
	    ("q" "utebrowser" org-mac-link-qutebrowser-insert-frontmost-url ,org-mac-link-qutebrowser-app-p)))
         (menu-string (make-string 0 ?x))
         input)

    ;; Create the menu string for the keymap
    (mapc (lambda (descriptor)
            (when (elt descriptor 3)
              (setf menu-string (concat menu-string
					"[" (elt descriptor 0) "]"
					(elt descriptor 1) " "))))
          descriptors)
    (setf (elt menu-string (- (length menu-string) 1)) ?:)

    ;; Prompt the user, and grab the link
    (message menu-string)
    (setq input (read-char-exclusive))
    (mapc (lambda (descriptor)
            (let ((key (elt (elt descriptor 0) 0))
                  (active (elt descriptor 3))
                  (grab-function (elt descriptor 2)))
              (when (and active (eq input key))
                (call-interactively grab-function))))
          descriptors)))

(defun org-mac-link-paste-applescript-links (as-link-list)
  "Paste in a list AS-LINK-LIST from an applescript handler.
The links are of the form <link>::split::<name>."
  (let* ((noquote-as-link-list
	  (if (string-prefix-p "\"" as-link-list)
	      (substring as-link-list 1 -1)
	    as-link-list))
	 (link-list
          (mapcar (lambda (x) (if (string-match "\\`\"\\(.*\\)\"\\'" x)
				  (setq x (match-string 1 x)))
		    x)
		  (split-string noquote-as-link-list "[\r\n]+")))
         split-link URL description orglink rtn orglink-list)
    (while link-list
      (setq split-link (split-string (pop link-list) "::split::"))
      (setq URL (car split-link))
      (setq description (cadr split-link))
      (when (not (string= URL ""))
        (setq orglink (org-link-make-string URL description))
        (push orglink orglink-list)))
    (setq rtn (mapconcat #'identity orglink-list "\n"))
    (kill-new rtn)
    rtn))



;;; Handle links from Firefox.app
;;
;; This code allows you to grab the current active url from the main
;; Firefox.app window, and insert it as a link into an org-mode
;; document. Unfortunately, firefox does not expose an applescript
;; dictionary, so this is necessarily introduces some limitations.
;;
;; The applescript to grab the url from Firefox.app uses the System
;; Events application to give focus to the firefox application, select
;; the contents of the url bar, and copy it. It then uses the title of
;; the window as the text of the link. There is no way to grab links
;; from other open tabs, and further, if there is more than one window
;; open, it is not clear which one will be used (though emperically it
;; seems that it is always the last active window).

(defun org-mac-link-applescript-firefox-get-frontmost-url ()
  "AppleScript to get the links to the frontmost window of the Firefox.app."
  (let ((result
	 (org-mac-link-do-applescript
	  (concat
	   "set oldClipboard to the clipboard\n"
	   "set frontmostApplication to path to frontmost application\n"
	   "tell application \"Firefox\"\n"
	   "	activate\n"
	   "	delay 0.15\n"
	   "	tell application \"System Events\"\n"
	   "		keystroke \"l\" using {command down}\n"
	   "		delay 0.2\n"
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
    (car (split-string result "[\r\n]+" t))))

;;;###autoload
(defun org-mac-link-firefox-get-frontmost-url ()
  "Get the link to the frontmost window of the Firefox.app."
  (interactive)
  (message "Applescript: Getting Firefox url...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-firefox-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-firefox-insert-frontmost-url ()
  "Insert the link to the frontmost window of the Firefox.app."
  (interactive)
  (insert (org-mac-link-firefox-get-frontmost-url)))



;;; Handle links from Google Firefox.app running the Vimperator extension
;; Grab the frontmost url from Firefox+Vimperator. Same limitations are
;; Firefox

(defun org-mac-link-applescript-vimperator-get-frontmost-url ()
  "AppleScript to get links of frontmost window of Firefox.app with Vimperator."
  (let ((result
	 (org-mac-link-do-applescript
	  (concat
	   "set oldClipboard to the clipboard\n"
	   "set frontmostApplication to path to frontmost application\n"
	   "tell application \"Firefox\"\n"
	   "	activate\n"
	   "	delay 0.15\n"
	   "	tell application \"System Events\"\n"
	   "		keystroke \"y\"\n"
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
    (replace-regexp-in-string
     "\s+-\s+Vimperator" "" (car (split-string result "[\r\n]+" t)))))

;;;###autoload
(defun org-mac-link-vimperator-get-frontmost-url ()
  "Get the link to the frontmost window of the Firefox.app with Vimperator."
  (interactive)
  (message "Applescript: Getting Vimperator url...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-vimperator-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-vimperator-insert-frontmost-url ()
  "Insert the link to the frontmost window of the Firefox.app with Vimperator."
  (interactive)
  (insert (org-mac-link-vimperator-get-frontmost-url)))



;;; Handle links from Google Chrome.app
;; Grab the frontmost url from Google Chrome. Same limitations as
;; Firefox because Chrome doesn't publish an Applescript dictionary

(defun org-mac-link-applescript-chrome-get-frontmost-url ()
  "AppleScript to get the links to the frontmost window of the Chrome.app."
  (let ((result
	 (org-mac-link-do-applescript
	  (concat
	   "set frontmostApplication to path to frontmost application\n"
	   "tell application \"Google Chrome\"\n"
	   "	set theUrl to get URL of active tab of first window\n"
	   "	set theResult to (get theUrl) & \"::split::\" & (get name of window 1)\n"
	   "end tell\n"
	   "activate application (frontmostApplication as text)\n"
	   "set links to {}\n"
	   "copy theResult to the end of links\n"
	   "return links as string\n"))))
    (replace-regexp-in-string
     "^\"\\|\"$" "" (car (split-string result "[\r\n]+" t)))))

;;;###autoload
(defun org-mac-link-chrome-get-frontmost-url ()
  "Get the link to the frontmost window of the Chrome.app."
  (interactive)
  (message "Applescript: Getting Chrome url...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-chrome-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-chrome-insert-frontmost-url ()
  "Insert the link to the frontmost window of the Chrome.app."
  (interactive)
  (insert (org-mac-link-chrome-get-frontmost-url)))



;;; Handle links from Brave.app
;; Grab the frontmost url from Brave. Same limitations as
;; Firefox/Chrome because Brave doesn't publish an Applescript
;; dictionary

(defun org-mac-link-applescript-brave-get-frontmost-url ()
  "AppleScript to get the links to the frontmost window of the Brave.app."
  (let ((result
	 (org-mac-link-do-applescript
	  (concat
	   "set frontmostApplication to path to frontmost application\n"
	   "tell application \"Brave\"\n"
	   "	set theUrl to get URL of active tab of first window\n"
	   "	set theResult to (get theUrl) & \"::split::\" & (get name of window 1)\n"
	   "end tell\n"
	   "activate application (frontmostApplication as text)\n"
	   "set links to {}\n"
	   "copy theResult to the end of links\n"
	   "return links as string\n"))))
    (replace-regexp-in-string
     "^\"\\|\"$" "" (car (split-string result "[\r\n]+" t)))))

;;;###autoload
(defun org-mac-link-brave-get-frontmost-url ()
  "Get the link to the frontmost window of the Brave.app."
  (interactive)
  (message "Applescript: Getting Brave url...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-brave-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-brave-insert-frontmost-url ()
  "Insert the link to the frontmost window of the Brave.app."
  (interactive)
  (insert (org-mac-link-brave-get-frontmost-url)))



;;; Handle links from Safari.app
;; Grab the frontmost url from Safari.

(defun org-mac-link-applescript-safari-get-frontmost-url ()
  "AppleScript to get the links to the frontmost window of the Safari.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Safari\"\n"
    "	set theUrl to URL of document 1\n"
    "	set theName to the name of the document 1\n"
    "	return theUrl & \"::split::\" & theName & \"\n\"\n"
    "end tell\n")))

;;;###autoload
(defun org-mac-link-safari-get-frontmost-url ()
  "Get the link to the frontmost window of the Safari.app."
  (interactive)
  (message "Applescript: Getting Safari url...")
  (org-mac-link-paste-applescript-links
   (org-mac-link-applescript-safari-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-safari-insert-frontmost-url ()
  "Insert the link to the frontmost window of the Safari.app."
  (interactive)
  (insert (org-mac-link-safari-get-frontmost-url)))



;;; Handle links from together.app
(org-link-set-parameters "x-together-item" :follow #'org-mac-link-together-item-open)

(defun org-mac-link-together-item-open (uid _)
  "Open UID, which is a reference to an item in Together."
  (shell-command (concat "open -a Together \"x-together-item:" uid "\"")))

(defun org-mac-link-applescript-get-selected-together-items ()
  "AppleScript to get the links to selected items in the Together.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Together\"\n"
    "	set theLinkList to {}\n"
    "	set theSelection to selected items\n"
    "	repeat with theItem in theSelection\n"
    "		set theLink to (get item link of theItem) & \"::split::\" & (get name of theItem) & \"\n\"\n"
    "		copy theLink to end of theLinkList\n"
    "	end repeat\n"
    "	return theLinkList as string\n"
    "end tell")))

;;;###autoload
(defun org-mac-link-together-get-selected ()
  "Get the links to selected items in the Together.app."
  (interactive)
  (message "Applescript: Getting Together items...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-selected-together-items)))

;;;###autoload
(defun org-mac-link-together-insert-selected ()
  "Insert the links to selected items in the Together.app."
  (interactive)
  (insert (org-mac-link-together-get-selected)))



;;; Handle links from Finder.app

(defun org-mac-link-applescript-get-selected-finder-items ()
  "AppleScript to get the links to selected items in the Finder.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Finder\"\n"
    " set theSelection to the selection\n"
    " set links to {}\n"
    " repeat with theItem in theSelection\n"
    " set theLink to \"file:\" & (POSIX path of (theItem as string)) & \"::split::\" & (get the name of theItem) & \"\n\"\n"
    " copy theLink to the end of links\n"
    " end repeat\n"
    " return links as string\n"
    "end tell\n")))

;;;###autoload
(defun org-mac-link-finder-item-get-selected ()
  "Get the links to selected items in the Finder.app."
  (interactive)
  (message "Applescript: Getting Finder items...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-selected-finder-items)))

;;;###autoload
(defun org-mac-link-finder-insert-selected ()
  "Insert the links to selected items in the Finder.app."
  (interactive)
  (insert (org-mac-link-finder-item-get-selected)))



;;; Handle links from AddressBook.app
(org-link-set-parameters "addressbook" :follow #'org-mac-link-addressbook-item-open)

(defun org-mac-link-addressbook-item-open (uid _)
  "Open UID, which is a reference to an item in the addressbook."
  (shell-command (concat "open \"addressbook:" uid "\"")))

(defun org-mac-link-applescript-get-selected-addressbook-items ()
  "AppleScript to get the links to selected items in the addressbook."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Address Book\"\n"
    "	set theSelection to the selection\n"
    "	set links to {}\n"
    "	repeat with theItem in theSelection\n"
    "		set theLink to \"addressbook://\" & (the id of theItem) & \"::split::\" & (the name of theItem) & \"\n\"\n"
    "		copy theLink to the end of links\n"
    "	end repeat\n"
    "	return links as string\n"
    "end tell\n")))

;;;###autoload
(defun org-mac-link-addressbook-item-get-selected ()
  "Get the links to selected items in the addressbook."
  (interactive)
  (message "Applescript: Getting Address Book items...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-selected-addressbook-items)))

;;;###autoload
(defun org-mac-link-addressbook-item-insert-selected ()
  "Insert the links to selected items in the addressbook."
  (interactive)
  (insert (org-mac-link-addressbook-item-get-selected)))



;;; Handle links from Skim.app
;;
;; Original code & idea by Christopher Suckling (org-mac-protocol)

(org-link-set-parameters "skim" :follow #'org-mac-link-skim-open)

(defun org-mac-link-skim-open (uri _)
  "Visit page of pdf in Skim from URI."
  (let* ((page (when (string-match "::\\(.+\\)\\'" uri)
                 (match-string 1 uri)))
         (document (substring uri 0 (match-beginning 0))))
    (org-mac-link-do-applescript
     (concat
      "tell application \"Skim\"\n"
      "activate\n"
      "set theDoc to \"" document "\"\n"
      "set thePage to " page "\n"
      "open theDoc\n"
      "go document 1 to page thePage of document 1\n"
      "end tell"))))

(defun org-mac-link-applescript-get-skim-page-link ()
  "AppleScript to get the link to the page in the Skim.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Skim\"\n"
    "set theDoc to front document\n"
    "set theTitle to (name of theDoc)\n"
    "set thePath to (path of theDoc)\n"
    "set thePage to (get index of current page of theDoc)\n"
    "set theSelection to selection of theDoc\n"
    "set theContent to contents of (get text of theSelection)\n"
    "if theContent is missing value then\n"
    "    set theContent to theTitle & \", p. \" & thePage\n"
    (when org-mac-link-highlight-selection-p
      (concat
       "else\n"
       "    tell theDoc\n"
       "        set theNote to make new note with properties {type:highlight note, selection:theSelection} at page thePage\n"
       "        set text of theNote to (get text of theSelection)\n"
       "    end tell\n"))
    "end if\n"
    "set theLink to \"skim://\" & thePath & \"::\" & thePage & "
    "\"::split::\" & theContent\n"
    "end tell\n"
    "return theLink as string\n")))

;;;###autoload
(defun org-mac-link-skim-get-page ()
  "Get the link to the page in the Skim.app."
  (interactive)
  (message "Applescript: Getting Skim page link...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-skim-page-link)))

;;;###autoload
(defun org-mac-link-skim-insert-page ()
  "Insert the link to the page in the Skim.app."
  (interactive)
  (insert (org-mac-link-skim-get-page)))



;;; Handle links from Adobe Acrobat Pro.app
;;
;; Original code & idea by Christopher Suckling (org-mac-protocol)
;;
;; The URI format is path_to_pdf_file::page_number

(org-link-set-parameters "acrobat" :follow #'org-mac-link-acrobat-open)

(defun org-mac-link-acrobat-open (uri _)
  "Visit page of pdf in Acrobat from URI."
  (let* ((page (when (string-match "::\\(.+\\)\\'" uri)
                 (match-string 1 uri)))
         (document (substring uri 0 (match-beginning 0))))
    (org-mac-link-do-applescript
     (concat
      "tell application \"Adobe Acrobat Pro\"\n"
      "  activate\n"
      "  set theDoc to \"" document "\"\n"
      "  set thePage to " page "\n"
      "  open theDoc\n"
      "  tell PDF Window 1\n"
      "    goto page thePage\n"
      "  end tell\n"
      "end tell"))))

;; The applescript returns link in the format
;; "adobe:path_to_pdf_file::page_number::split::document_title, p.page_label"

(defun org-mac-link-applescript-get-acrobat-page-link ()
  "AppleScript to get the link to the page in the Adobe Acrobat Pro.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Adobe Acrobat Pro\"\n"
    "  set theDoc to active doc\n"
    "  set theWindow to (PDF Window 1 of theDoc)\n"
    "  set thePath to (file alias of theDoc)\n"
    "  set theTitle to (name of theWindow)\n"
    "  set thePage to (page number of theWindow)\n"
    "  set theLabel to (label text of (page thePage of theWindow))\n"
    "end tell\n"
    "set theResult to \"acrobat:\" & thePath & \"::\" & thePage & \"::split::\" & theTitle & \", p.\" & theLabel\n"
    "return theResult as string\n")))

;;;###autoload
(defun org-mac-link-acrobat-get-page ()
  "Get the link to the page in the Adobe Acrobat Pro.app."
  (interactive)
  (message "Applescript: Getting Acrobat page link...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-acrobat-page-link)))

;;;###autoload
(defun org-mac-link-acrobat-insert-page ()
  "Insert the link to the page in the Adobe Acrobat Pro.app."
  (interactive)
  (insert (org-mac-link-acrobat-get-page)))



;;; Handle links from Microsoft Outlook.app

(org-link-set-parameters "mac-outlook" :follow #'org-mac-link-outlook-message-open)

(defun org-mac-link-outlook-message-open (msgid _)
  "Open a message in Outlook using MSGID."
  (org-mac-link-do-applescript
   (concat
    "tell application \"" org-mac-link-outlook-path "\"\n"
    (format "open message id %s\n" (substring-no-properties msgid))
    "activate\n"
    "end tell")))

(defun org-mac-link-applescript-get-selected-outlook-mail ()
  "AppleScript to create links to selected messages in Microsoft Outlook.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"" org-mac-link-outlook-path "\"\n"
    "set msgCount to count current messages\n"
    "if (msgCount < 1) then\n"
    "return\n"
    "end if\n"
    "set theLinkList to {}\n"
    "set theSelection to (get current messages)\n"
    "repeat with theMessage in theSelection\n"
    "set theID to id of theMessage as string\n"
    "set theURL to \"mac-outlook:\" & theID\n"
    "set theSubject to subject of theMessage\n"
    "set theLink to theURL & \"::split::\" & theSubject & \"\n\"\n"
    "copy theLink to end of theLinkList\n"
    "end repeat\n"
    "return theLinkList as string\n"
    "end tell")))

(defun org-mac-link-shell-get-flagged-outlook-mail ()
  "Shell commands to create links to flagged messages in Microsoft Outlook.app."
  (mapconcat
   (lambda (x) ""
     (concat
      "mac-outlook:"
      (mapconcat
       (lambda (y) "" y)
       (split-string
	(shell-command-to-string
	 (format "mdls -raw -name com_microsoft_outlook_recordID -name kMDItemDisplayName \"%s\"" x))
	"\000")
       "::split::")
      "\n"))
   (with-temp-buffer
     (let ((coding-system-for-read (or file-name-coding-system 'utf-8))
	   (coding-system-for-write 'utf-8))
       (shell-command
	"mdfind com_microsoft_outlook_flagged==1"
	(current-buffer)))
     (split-string
      (buffer-string) "\n" t))
   ""))

;;;###autoload
(defun org-mac-link-outlook-message-get-links (&optional select-or-flag)
  "Create links to selected or flagged messages in Microsoft Outlook.app.
This will use AppleScript to get the message-id and the subject of the
messages in Microsoft Outlook.app and make a link out of it.
When SELECT-OR-FLAG is \"s\", get the selected messages (this is also
the default).  When SELECT-OR-FLAG is \"f\", get the flagged messages.
The Org-syntax text will be pushed to the kill ring, and also returned."
  (interactive "sLink to (s)elected or (f)lagged messages: ")
  (setq select-or-flag (or select-or-flag "s"))
  (message "Org Mac Outlook: searching mailboxes...")
  (org-mac-link-paste-applescript-links
   (if (string= select-or-flag "s")
	(org-mac-link-applescript-get-selected-outlook-mail)
      (if (string= select-or-flag "f")
	  (org-mac-link-shell-get-flagged-outlook-mail)
	(error "Please select \"s\" or \"f\"")))))

;;;###autoload
(defun org-mac-link-outlook-message-insert-selected ()
  "Insert a link to the messages currently selected in Microsoft Outlook.app.
This will use AppleScript to get the message-id and the subject
of the active mail in Microsoft Outlook.app and make a link out of it."
  (interactive)
  (insert (org-mac-link-outlook-message-get-links "s")))

;;;###autoload
(defun org-mac-link-outlook-message-insert-flagged (org-buffer org-heading)
  "Asks for an ORG-BUFFER and a heading within it, and replace message links.
If ORG-HEADING exists, delete all mac-outlook:// links in heading's first level.
If heading doesn't exist, create it at point-max.
Insert list of mac-outlook:// links to flagged mail after heading."
  (interactive "bBuffer in which to insert links: \nsHeading after which to insert links: ")
  (with-current-buffer org-buffer
    (goto-char (point-min))
    (let ((isearch-forward t)
          (message-re "\\[\\[\\(mac-outlook:\\)\\([^]]+\\)\\]\\(\\[\\([^]]+\\)\\]\\)?\\]"))
      (if (org-goto--local-search-headings org-heading nil t)
          (if (not (eobp))
              (progn
                (save-excursion
                  (while (re-search-forward
                          message-re (save-excursion (outline-next-heading)) t)
                    (delete-region (match-beginning 0) (match-end 0)))
                  (insert "\n" (org-mac-link-outlook-message-get-links "f")))
                (flush-lines "^$" (point) (outline-next-heading)))
	    (insert "\n" (org-mac-link-outlook-message-get-links "f")))
	(goto-char (point-max))
	(insert "\n")
	(org-insert-heading nil t)
	(insert org-heading "\n" (org-mac-link-outlook-message-get-links "f"))))))



;;; Handle links from Evernote.app

(org-link-set-parameters "mac-evernote" :follow #'org-mac-link-evernote-note-open)

(defun org-mac-link-evernote-path ()
  "Get path to evernote.
First consider the value of ORG-MAC-LINK-EVERNOTE-PATH, then attempt to find it.
Finding the path can be slow."
  (or org-mac-link-evernote-path
      (replace-regexp-in-string (rx (* (any " \t\n")) eos)
                                ""
                                (shell-command-to-string
                                 "mdfind kMDItemCFBundleIdentifier == 'com.evernote.Evernote'"))))

(defun org-mac-link-evernote-note-open (noteid _)
  "Open a note in Evernote using the NOTEID."
  (org-mac-link-do-applescript
   (concat
    "tell application \"" (org-mac-link-evernote-path) "\"\n"
    "    set theNotes to get every note of every notebook where its local id is \"" (substring-no-properties noteid) "\"\n"
    "    repeat with _note in theNotes\n"
    "        if length of _note is not 0 then\n"
    "            set _selectedNote to _note\n"
    "        end if\n"
    "    end repeat\n"
    "    open note window with item 1 of _selectedNote\n"
    "    activate\n"
    "end tell")))

(defun org-mac-link-applescript-get-selected-evernote-notes ()
  "AppleScript to create links to selected notes in Evernote.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"" (org-mac-link-evernote-path) "\"\n"
     "    set noteCount to count selection\n"
     "    if (noteCount < 1) then\n"
     "        return\n"
     "    end if\n"
     "    set theLinkList to {}\n"
     "    set theSelection to selection\n"
     "    repeat with theNote in theSelection\n"
     "        set theTitle to title of theNote\n"
     "        set theID to local id of theNote\n"
     "        set theURL to \"mac-evernote:\" & theID\n"
     "        set theLink to theURL & \"::split::\" & theTitle & \"\n\"\n"
     "        copy theLink to end of theLinkList\n"
     "    end repeat\n"
     "    return theLinkList as string\n"
     "end tell\n")))

;;;###autoload
(defun org-mac-link-evernote-note-insert-selected ()
  "Insert a link to the notes currently selected in Evernote.app.
This will use AppleScript to get the note id and the title of the
note(s) in Evernote.app and make a link out of it/them."
  (interactive)
  (message "Org Mac Evernote: searching notes...")
(insert (org-mac-link-paste-applescript-links
	 (org-mac-link-applescript-get-selected-evernote-notes))))



;;; Handle links from DEVONthink Pro Office.app

(org-link-set-parameters "x-devonthink-item" :follow #'org-mac-link-devonthink-item-open)

(defun org-mac-link-devonthink-item-open (uid _)
  "Open UID, which is a reference to an item in DEVONthink Pro Office."
  (shell-command (concat "open \"x-devonthink-item:" uid "\"")))

(defun org-mac-link-applescript-get-selected-devonthink-item ()
  "AppleScript to create links to selected items in DEVONthink Pro Office.app."
  (org-mac-link-do-applescript
   (concat
    "set theLinkList to {}\n"
    "tell application \"DEVONthink Pro\"\n"
    "set selectedRecords to selection\n"
    "set selectionCount to count of selectedRecords\n"
    "if (selectionCount < 1) then\n"
    "return\n"
    "end if\n"
    "repeat with theRecord in selectedRecords\n"
    "set theID to uuid of theRecord\n"
    "set theURL to \"x-devonthink-item:\" & theID\n"
    "set theSubject to name of theRecord\n"
    "set theLink to theURL & \"::split::\" & theSubject & \"\n\"\n"
    "copy theLink to end of theLinkList\n"
    "end repeat\n"
    "end tell\n"
    "return theLinkList as string")))

(defun org-mac-link-devonthink-get-links ()
  "Create links to the item(s) currently selected in DEVONthink Pro Office.
This will use AppleScript to get the `uuid' and the `name' of the
selected items in DEVONthink Pro Office.app and make links out of it/them.
This function will push the Org-syntax text to the kill ring, and return it."
  (message "Org Mac DEVONthink: looking for selected items...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-get-selected-devonthink-item)))

;;;###autoload
(defun org-mac-link-devonthink-item-insert-selected ()
  "Insert a link to the item(s) currently selected in DEVONthink Pro Office.
This will use AppleScript to get the `uuid'(s) and the name(s) of the
selected items in DEVONthink Pro Office and make link(s) out of it/them."
  (interactive)
  (insert (org-mac-link-devonthink-get-links)))



;;; Handle links from Mail.app

(org-link-set-parameters "message" :follow #'org-mac-link-mail-open)

(defun org-mac-link-mail-open (message-id _)
  "Visit the message with MESSAGE-ID.
This will use the command `open' with the message URL."
  (start-process (concat "open message:" message-id) nil
                 "open" (concat "message://%3C" (substring message-id 2) "%3E")))

(defun org-mac-link-applescript-get-selected-mail ()
  "AppleScript to create links to selected messages in Mail.app."
  (org-mac-link-do-applescript
   (concat
    "tell application \"Mail\"\n"
    "set theLinkList to {}\n"
    "set theSelection to selection\n"
    "repeat with theMessage in theSelection\n"
    "set theID to message id of theMessage\n"
    "set theSubject to subject of theMessage\n"
    "set theLink to \"message://\" & theID & \"::split::\" & theSubject\n"
    "if (theLinkList is not equal to {}) then\n"
    "set theLink to \"\n\" & theLink\n"
    "end if\n"
    "copy theLink to end of theLinkList\n"
    "end repeat\n"
    "return theLinkList as string\n"
    "end tell")))

(defun org-mac-link-applescript-get-flagged-mail ()
  "AppleScript to create links to flagged messages in Mail.app."
  (unless org-mac-link-mail-account
    (error "You must set org-mac-link-mail-account"))
  (org-mac-link-do-applescript
   (concat
    ;; Get links
    "tell application \"Mail\"\n"
    "set theMailboxes to every mailbox of account \"" org-mac-link-mail-account "\"\n"
    "set theLinkList to {}\n"
    "repeat with aMailbox in theMailboxes\n"
    "set theSelection to (every message in aMailbox whose flagged status = true)\n"
    "repeat with theMessage in theSelection\n"
    "set theID to message id of theMessage\n"
    "set theSubject to subject of theMessage\n"
    "set theLink to \"message://\" & theID & \"::split::\" & theSubject & \"\n\"\n"
    "copy theLink to end of theLinkList\n"
    "end repeat\n"
    "end repeat\n"
    "return theLinkList as string\n"
    "end tell")))

;;;###autoload
(defun org-mac-link-mail-get-links (&optional select-or-flag)
  "Create links to the messages currently selected or flagged in Mail.app.
This will use AppleScript to get the message-id and the subject of the
messages in Mail.app and make a link out of it.
When SELECT-OR-FLAG is \"s\", get the selected messages (this is also
the default).  When SELECT-OR-FLAG is \"f\", get the flagged messages.
The Org-syntax text will be pushed to the kill ring, and also returned."
  (interactive "sLink to (s)elected or (f)lagged messages: ")
  (setq select-or-flag (or select-or-flag "s"))
  (message "AppleScript: searching mailboxes...")
  (org-mac-link-paste-applescript-links
   (cond
    ((string= select-or-flag "s") (org-mac-link-applescript-get-selected-mail))
    ((string= select-or-flag "f") (org-mac-link-applescript-get-flagged-mail))
    (t (error "Please select \"s\" or \"f\"")))))

;;;###autoload
(defun org-mac-link-mail-insert-selected ()
  "Insert a link to the messages currently selected in Mail.app.
This will use AppleScript to get the message-id and the subject of the
active mail in Mail.app and make a link out of it."
  (interactive)
  (insert (org-mac-link-mail-get-links "s")))

;; The following line is for backward compatibility
(defalias 'org-mac-link-mail-insert-link #'org-mac-link-mail-insert-selected)

;;;###autoload
(defun org-mac-link-mail-insert-flagged (org-buffer org-heading)
  "Asks for an ORG-BUFFER and a heading within it, and replace message links.
If ORG-HEADING exists, delete all message:// links within heading's first level.
If heading doesn't exist, create it at point-max.
Insert list of message:// links to flagged mail after heading."
  (interactive "bBuffer in which to insert links: \nsHeading after which to insert links: ")
  (with-current-buffer org-buffer
    (goto-char (point-min))
    (let ((isearch-forward t)
          (message-re "\\[\\[\\(message:\\)\\([^]]+\\)\\]\\(\\[\\([^]]+\\)\\]\\)?\\]"))
      (if (org-goto--local-search-headings org-heading nil t)
          (if (not (eobp))
              (progn
                (save-excursion
                  (while (re-search-forward
                          message-re (save-excursion (outline-next-heading)) t)
                    (delete-region (match-beginning 0) (match-end 0)))
                  (insert "\n" (org-mac-link-mail-get-links "f")))
                (flush-lines "^$" (point) (outline-next-heading)))
	    (insert "\n" (org-mac-link-mail-get-links "f")))
	(goto-char (point-max))
	(insert "\n")
	(org-insert-heading nil t)
	(insert org-heading "\n" (org-mac-link-mail-get-links "f"))))))



;;; Handle links from qutebrowser.app

(defun org-mac-link-applescript-qutebrowser-get-frontmost-url ()
  "AppleScript to get the links to the frontmost window of the qutebrowser.app."
  (let ((result
         (org-mac-link-do-applescript
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
     (car (split-string result "[\r\n]+" t))))

;;;###autoload
(defun org-mac-link-qutebrowser-get-frontmost-url ()
  "Get the link to the frontmost window of the qutebrowser.app."
  (interactive)
  (message "Applescript: Getting qutebrowser url...")
  (org-mac-link-paste-applescript-links (org-mac-link-applescript-qutebrowser-get-frontmost-url)))

;;;###autoload
(defun org-mac-link-qutebrowser-insert-frontmost-url ()
  "Insert the link to the frontmost window of the qutebrowser.app."
  (interactive)
  (insert (org-mac-link-qutebrowser-get-frontmost-url)))



(provide 'org-mac-link)

;;; org-mac-link.el ends here
