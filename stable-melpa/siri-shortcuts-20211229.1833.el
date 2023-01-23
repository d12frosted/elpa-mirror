;;; siri-shortcuts.el --- Interact with Siri Shortcuts  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Daniils Petrovs

;; Author: Daniils Petrovs <thedanpetrov@gmail.com>
;; URL: https://github.com/DaniruKun/siri-shortcuts.el
;; Version: 0.3
;; Package-Requires: ((emacs "25.2"))
;; Keywords: convenience multimedia

;; This file is not part of GNU Emacs.

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

;; This package allows you to interact with Siri Shortcuts in macOS.
;; It includes both user-facing interactive commands, as well as a
;; generic API wrapper around the Shortcuts URL scheme API.
;; More info in the official Apple docs: https://support.apple.com/en-gb/guide/shortcuts-mac/apd621a1ad7a/mac

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Make sure you are running at least macOS Monterey!

;; Put this file in your load-path, and put this in your init
;; file:

;; (require 'siri-shortcuts)

;;;; Usage

;; Run one of these commands:

;; `siri-shortcuts-run': Run a Siri Shortcut.

;;;; Tips

;; + You can customize settings in the `siri-shortcuts' group.

;;; Code:

;;;; Requirements

;;;; Customization

(defgroup siri-shortcuts nil
  "Settings for `siri-shortcuts'."
  :group 'external
  :link '(url-link "https://github.com/DaniruKun/siri-shortcuts.el"))

;;;; Variables

(defconst siri-shortcuts-ver-monterey "12.0"
  "Release version of macOS Monterey.")

;;;; Macros

(defmacro siri-shortcuts-with-min-macos-ver (min-ver &rest body)
  "Execute BODY if current macOS version meets MIN-VER requirement.
Otherwise prints error message."
  `(if (string-lessp (siri-shortcuts--osx-version) ,min-ver)
       (message (concat "Unsupported on this version of macOS, minimum required: " ,min-ver))
     ,@body))

;;;; Commands

(defalias 'siri-shortcuts-open #'siri-shortcuts-edit)

;;;###autoload
(defun siri-shortcuts-run (name)
  "Run a macOS Shortcut with a given NAME."
  (interactive
   (list (completing-read "Shortcut name: " (siri-shortcuts-list))))
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                                     (call-process "shortcuts" nil "*shortcuts*" nil "run" name)))

;;;###autoload
(defun siri-shortcuts-run-async (name)
  "Run a macOS Shortcut with a given NAME without waiting for completion."
  (interactive
   (list (completing-read "Shortcut name: " (siri-shortcuts-list))))
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                                     (start-process "shortcuts" "*shortcuts*" "shortcuts" "run" name)))

;;;###autoload
(defun siri-shortcuts-open-app ()
  "Open the Shortcuts app."
  (interactive)
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                                     (call-process "open" nil 0 nil "-a" "Shortcuts.app")))

;;;###autoload
(defun siri-shortcuts-create ()
  "Open the Shortcuts editor to create a new shortcut."
  (interactive)
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                    (siri-shortcuts-browse-url "create-shortcut")))

;;;###autoload
(defun siri-shortcuts-edit (name)
  "Edit a Shortcut with the given NAME."
  (interactive
   (list (completing-read "Shortcut name: " (siri-shortcuts-list))))
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                                     (siri-shortcuts-browse-url "open-shortcut" name)))

;;;###autoload
(defun siri-shortcuts-gallery-open ()
  "Open the Shortcuts Gallery."
  (interactive)
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                                (siri-shortcuts-browse-url "gallery")))

;;;###autoload
(defun siri-shortcuts-gallery-search (query)
  "Search the Gallery with the given QUERY."
  (interactive "sEnter search query: ")
  (siri-shortcuts-with-min-macos-ver siri-shortcuts-ver-monterey
                    (siri-shortcuts-browse-url "gallery/search" nil nil nil query)))

;;;; Functions

;;;;; Public

(defun siri-shortcuts-browse-url (&optional action name input text query)
  "Browse a Shortcuts scheme URL ACTION.
If ACTION is nil, then the bare URL is used, which will navigate to
Shortcuts app's last state.
ACTION - one of \"create-shortcut\", \"open-shortcut\",
 \"run-shortcut\", \"gallery\" or \"gallery/search\".
NAME - Shortcut name, can be unescaped.
INPUT - The initial input into the shortcut.
There are two input options: a text string or the word clipboard.
When the INPUT value is a text string, that text is used.
When the input value is Clipboard, the contents of the clipboard are used.
TEXT - If INPUT is set to text, then value of TEXT is passed as input
to the shortcut.
If INPUT is set to clipboard, then this parameter is ignored.
QUERY - determines the URL-encoded keywords to be searched in the Gallery.

See full details at: https://support.apple.com/en-gb/guide/shortcuts-mac/apd624386f42/mac"
  (let ((scheme "shortcuts://")
        (path (cond
               ((null action) "")
               ((string= action "create-shortcut") "create-shortcut")
               ((and (string= action "open-shortcut") name)
                (concat "open-shortcut?name=" (url-encode-url name)))
               ((and (string= action "run-shortcut") name)
                (concat "run-shortcut?name=" (url-encode-url name)
                        "&input=" input "&text=" (url-encode-url text)))
               ((string= action "gallery") "gallery")
               ((and (string= action "gallery/search") query)
                (concat "gallery/search?query=" (url-encode-url query))))))
    (browse-url (concat scheme path))))

(defun siri-shortcuts-list ()
  "Return a list of available shortcuts."
  (thread-first
    "shortcuts list"
    (shell-command-to-string)
    (split-string "\n")))

;;;;; Private

(defun siri-shortcuts--osx-version ()
  "Get macOS numerical version, e.g. 12.0.1."
  (string-trim (shell-command-to-string
                "sw_vers  -productVersion")))

;;;; Footer

(provide 'siri-shortcuts)

;;; siri-shortcuts.el ends here
