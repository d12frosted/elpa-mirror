;;; jetbrains.el --- JetBrains IDE bridge -*- lexical-binding: t -*-

;; Copyright (C) 2017 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 19 Oct 2017
;; Version: 0.0.1
;; Package-Version: 20180301.502
;; Package-Commit: 56f71a17d455581c10d48f6dbb31d9e2126227bf
;; Keywords: tools php
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5") (f "0.17"))
;; URL: https://github.com/emacs-php/jetbrains.el

;; This file is NOT part of GNU Emacs.

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

;; Jetbrains IDEs and Emacs are best friend!
;;
;; ## Support IDEs
;;
;; - Android Studio: `studio'
;; - AppCode: `appcode'
;; - CLion: `clion'
;; - Gogland: `gogland'
;; - IntelliJ IDEA: `idea'
;; - PhpStorm: `pstorm'
;; - PyCharm: `charm'
;; - Rider: `rider'
;; - RubyMine: `mine'
;; - WebStorm: `wstorm'
;;
;; ## Setup
;;
;; Please run `Tools > Create Command-line Launcher...' by menu in your IDE.
;;
;;
;; ### .dir-locals.el
;;
;; I encourage you to create a `.dir-locals.el` file in your project.
;;
;;     ((nil . (jetbrains-ide "PhpStorm")))
;;
;; ### Interoperability
;;
;; You can return to Emacs from the IDE.
;; Please see follows article: "Quick Tip: Getting Emacs and IntelliJ to play together"
;; https://developer.atlassian.com/blog/2015/03/emacs-intellij/
;;
;; ## FAQ
;;
;; ### Q.  Do you support proprietary software?
;;
;; A. Partially, yes.
;;
;; I am a supporter of the Free Software Movement.
;; However, since I am a lazy programmer, I know that the IDE's support can save
;; a lot of time and effort.  Proprietary software is unethical, but some of them are
;; powerful and practical.  The IDEs are a bit lacking in the charm of hacking.
;; I would like to increase the time we spend lazily away from business
;; by interoperating them.
;;
;; When the practical development environment is completed by free softwares,
;; I will stop recommending you to proprietary software.
;;

;;; Code:
(require 'cl-lib)
(require 'f)

(defgroup jetbrains nil "JetBrains IDE bridge"
  :prefix "jetbrains-"
  :group 'tools)

(defvar jetbrains-known-ide-alist
  '(("Android Studio" . studio)
    ("AppCode"        . appcode)
    ("CLion"          . clion)
    ("Gogland"        . gogland)
    ("IntelliJ IDEA"  . idea)
    ("PhpStorm"       . pstorm)
    ("PyCharm"        . charm)
    ("Rider"          . rider)
    ("RubyMine"       . mine)
    ("WebStorm"       . wstrom)))

(defvar jetbrains-major-mode-ide-alist
  '(((go-mode)         . (gogland))
    ((php-mode)        . (pstorm))
    ((python-mode)     . (charm))
    ((ruby-mode)       . (mine))
    ((c-mode c++-mode) . (clion))
    ((css-mode html-mode nxml-mode scss-mode sql-mode web-mode)
     . (charm mine pstorm wstrom))))

;;;###autoload
(progn
  (defvar-local jetbrains-ide nil)
  (put 'jetbrains-ide 'safe-local-variable 'jetbrains-ide-symbol))

(defun jetbrains-ide-symbol (name)
  "Return symbol of IDE by `NAME'."
  (if (symbolp name)
      (car-safe (memq name (member name (mapcar #'cdr jetbrains-known-ide-alist))))
    (when (stringp name)
      (or (assoc-default name jetbrains-known-ide-alist #'string-equal)
          (car-safe (member (intern name) (mapcar #'cdr jetbrains-known-ide-alist)))))))

(defun jetbrains--detect-ide (filename current-major-mode)
  "Return symbol of IDE by `FILENAME' and `CURRENT-MAJOR-MODE'."
  (unless t filename)
  (or (jetbrains-ide-symbol jetbrains-ide)
      (let ((candidates (cl-loop for a in jetbrains-major-mode-ide-alist
                                 if (memq current-major-mode (car a))
                                 return (cdr a))))
        (cl-loop for c in candidates
                 if (executable-find (symbol-name c))
                 return c))))

;;;###autoload
(defun jetbrains-open-project (ide ide-root)
  "Open project in JetBrains IDE by `IDE' and `IDE-ROOT'."
  (interactive
   (list (or jetbrains-ide
             (completing-read "Select IDE: "
                              (cl-loop for a in jetbrains-known-ide-alist
                                       if (executable-find (symbol-name (cdr a)))
                                       collect (car a))))
         (or (locate-dominating-file (f-dirname buffer-file-name) ".idea")
             (let ((dir (read-file-name "Project root: " default-directory)))
               (if (f-dir? dir)
                   dir
                 (f-dirname dir))))))
  (let ((ide-helper (jetbrains-ide-symbol ide)))
    (when ide-helper
      (shell-command
       (mapconcat #'shell-quote-argument
                  (list (symbol-name ide-helper)
                        (f-expand ide-root))
                  " ")))))

;;;###autoload
(defun jetbrains-open-buffer-file ()
  "Open buffer file in JetBrains IDE."
  (interactive)
  (when buffer-file-name
    (let ((ide-helper (jetbrains--detect-ide buffer-file-name major-mode)))
      (when ide-helper
        (shell-command
         (mapconcat #'shell-quote-argument
                    (list (symbol-name ide-helper)
                          buffer-file-name
                          "--line"
                          (int-to-string (line-number-at-pos)))
                    " "))))))

;;;###autoload
(defun jetbrains-create-dir-local-file ()
  "Create project file `.dir-locals.el' for `jetbrains.el'."
  (interactive)
  (add-dir-local-variable nil 'jetbrains-ide
                          (completing-read "Select JetBrains IDE: "
                                           (mapcar 'car jetbrains-known-ide-alist))))

(provide 'jetbrains)
;;; jetbrains.el ends here
