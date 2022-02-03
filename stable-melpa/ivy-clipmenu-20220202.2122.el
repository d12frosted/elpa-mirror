;;; ivy-clipmenu.el --- Ivy client for clipmenu -*- lexical-binding: t -*-

;; Author: William Carroll <wpcarro@gmail.com>
;; URL: https://github.com/wpcarro/ivy-clipmenu.el
;; Package-Version: 20220202.2122
;; Package-Commit: 7c200cd4732821187084fad23547ee3f58365062
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1") (f "0.20.0") (s "1.12.0") (dash "2.16.0") (ivy "0.13.0"))

;; This file is NOT part of GNU Emacs.

;; The MIT License (MIT)
;;
;; Copyright (c) 2016 Al Scott
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;; Ivy integration with the clipboard manager, clipmenu.  Essentially, clipmenu
;; turns your system clipboard into a list.
;;
;; To use this module, you must first install clipmenu and ensure that the
;; clipmenud daemon is running.  Refer to the installation instructions at
;; https://github.com/cdown/clipmenu for those details.
;;
;; This module intentionally does not define any keybindings since I'd prefer
;; not to presume my users' preferences.  Personally, I use EXWM as my window
;; manager, so I call `exwm-input-set-key' and map it to `ivy-clipmenu-copy'.
;;
;; Usually clipmenu integrates with rofi or dmenu.  This Emacs module integrates
;; with ivy.  Launch this when you want to select a clip.
;;
;; Clipmenu itself supports a variety of environment variables that allow you to
;; customize its behavior.  These variables are respected herein.  If you'd
;; prefer to customize clipmenu's behavior from within Emacs, refer to the
;; variables defined in this module.
;;
;; For more information:
;; - See `clipmenu --help`.
;; - Visit github.com/cdown/clipmenu.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dependencies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'f)
(require 's)
(require 'dash)
(require 'ivy)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup ivy-clipmenu nil
  "Ivy integration for clipmenu."
  :group 'ivy)

(defcustom ivy-clipmenu-directory
  (or (getenv "CM_DIR")
      (getenv "XDG_RUNTIME_DIR")
      (getenv "TMPDIR")
      (temporary-file-directory))
  "Base directory for clipmenu's data."
  :type 'string
  :group 'ivy-clipmenu)

(defcustom ivy-clipmenu-executable-version 6
  "The major version number for the clipmenu executable."
  :type 'integer
  :group 'ivy-clipmenu)

(defcustom ivy-clipmenu-history-length
  (or (getenv "CM_HISTLENGTH") 25)
  "Limit the number of clips in the history.
This value defaults to 25."
  :type 'integer
  :group 'ivy-clipmenu)

(defvar ivy-clipmenu-history nil
  "History for `ivy-clipmenu-copy'.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ivy-clipmenu--parse-content (x)
  "Parse the label from the entry, X, in clipmenu's line-cache."
  (->> (s-split " " x)
       (-drop 1)
       (s-join " ")))

;; NOTE: This should be a function to recompute its value when
;; a user updates `ivy-clipmenu-executable-version'.
(defun ivy-clipmenu--cache-directory ()
  "Directory where the clips are stored."
  (f-join ivy-clipmenu-directory
          (format "clipmenu.%s.%s"
                  ivy-clipmenu-executable-version
                  (getenv "USER"))))

(defun ivy-clipmenu--list-clips ()
  "Return a list of the content of all of the clips."
  (->> (f-join (ivy-clipmenu--cache-directory) "line_cache*")
       f-glob
       (-map (lambda (path)
               (s-split "\n" (f-read path) t)))
       -flatten
       (-reject #'s-blank?)
       (-sort #'string>)
       (-map #'ivy-clipmenu--parse-content)
       delete-dups
       (-take ivy-clipmenu-history-length)))

(defun ivy-clipmenu--checksum (content)
  "Return the CRC checksum of CONTENT."
  (s-trim-right
   (with-temp-buffer
     (call-process "bash" nil (current-buffer) nil "-c"
                   (format "cksum <<<'%s'" (shell-quote-argument content)))
     (buffer-string))))

(defun ivy-clipmenu--line-to-content (line)
  "Map the chosen LINE from the line cache its content from disk."
  (->> line
       ivy-clipmenu--checksum
       (f-join (ivy-clipmenu--cache-directory))
       f-read))

(defun ivy-clipmenu--do-copy (x)
  "Copy string, X, to the system clipboard."
  (kill-new x)
  (message "[ivy-clipmenu.el] Copied!"))

(defun ivy-clipmenu-copy ()
  "Use `ivy-read' to select and copy a clip.
It's recommended to bind this function to a globally available keymap."
  (interactive)
  (let ((ivy-sort-functions-alist nil))
    (ivy-read "Clipmenu: "
              (ivy-clipmenu--list-clips)
              :history 'ivy-clipmenu-history
              :action (lambda (line)
                        (->> line
                             ivy-clipmenu--line-to-content
                             ivy-clipmenu--do-copy)))))

(provide 'ivy-clipmenu)
;;; ivy-clipmenu.el ends here
