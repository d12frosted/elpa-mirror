;;; helm-lines.el --- A helm interface for completing by lines -*- lexical-binding: t; -*-

;; Copyright (C) 2012-2016 Free Software Foundation, Inc.

;; Author: @torgeir
;; Version: 1.4.0
;; Package-Version: 20220103.1909
;; Package-Commit: f5ad178818d223f32a0bf60d370b50c01df5f3da
;; Keywords: files helm rg ag pt vc git lines complete tools languages
;; Package-Requires: ((emacs "24.4") (helm "1.9.8"))
;; URL: https://github.com/torgeir/helm-lines.el/

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

;; A helm interface for completing by lines in project.
;;
;; Run `helm-lines' to complete the current line by other lines that
;; exist in the current git project.
;;
;; Enable `helm-follow-mode' to replace in place as you jump around
;; the suggestions.
;;
;; The project root is defined by the result of
;; `helm-lines-project-root-function', and by default it is the root
;; of the current version-control tree.  Projectile users might like
;; to set this variable to `projectile-root'.
;;
;; Requires `rg' [1], `ag' [2], `pt' [3] or similar to be installed. If you prefer
;; something other than `ag' you need to customize the
;; `helm-lines-search-function' accordingly, see below.
;;
;; The lines completed against are defined by the result of the
;; `helm-lines-search-function', and by default it is `helm-lines-search-ag'.
;; Users that prefer `pt' over `rg' or `ag' can set this variable to
;; `helm-lines-search-pt'. Other engines can be supported by supplying a
;; custom search function. It will be called with the shell quoted query and the
;; shell quoted folder to search in.
;;
;;   [1]: https://github.com/BurntSushi/ripgrep
;;   [2]: https://github.com/ggreer/the_silver_searcher
;;   [3]: https://github.com/monochromegane/the_platinum_searcher

;;; Code:

(require 'helm)
(require 'thingatpt)
(require 'subr-x)


(defgroup helm-lines nil
  "Completion by lines in project."
  :group 'helm)


(defcustom helm-lines-project-root-function 'vc-root-dir
  "Function called to find the root directory of the current project."
  :type 'function)


(defun helm-lines-search-rg (query root)
  "Search for lines matching QUERY in ROOT folder with `rg'."
  ;; https://jdhao.github.io/2020/02/16/ripgrep_cheat_sheet/
  (format (concat "rg"
                  " \"%s\" %s"
                  " --no-line-number"
                  " --no-filename"
                  " --ignore-case"
                  " -g '!.git'"
                  " -g '!target'"
                  " -g '!node_modules'")
          query root))


(defun helm-lines-search-ag (query root)
  "Search for lines matching QUERY in ROOT folder with `ag'."
  (format (concat "ag"
                  " --nocolor"
                  " --nonumbers"
                  " --nofilename"
                  " --ignore .git"
                  " --ignore target"
                  " --ignore node_modules"
                  " --ignore-case"
                  " \"%s\" %s")
          query root))


(defun helm-lines-search-pt (query root)
  "Search for lines matching QUERY in ROOT folder with `pt'."
  (format (concat "pt"
                  " --nocolor"
                  " --nonumbers"
                  " --nogroup"
                  " --ignore-case"
                  " \"%s\" %s"
                  ;; remove leading file names as no option exist to remove them
                  " | sed -E \"s/[^:]+://\""
                  )
          query root))


(defcustom helm-lines-search-function 'helm-lines-search-ag
  "Function called to find lines matching query. It is passed the search string
and the folder to search in."
  :type 'function)


(defun helm-lines--action (line)
  "Insert the selected LINE at the beginning of the current line.
Indents the line after inserting it."
  (move-beginning-of-line 1)
  (unless (eolp)
    (kill-line))
  (insert line)
  (indent-for-tab-command))


(defvar helm-lines-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "C-n") 'helm-next-line)
    (define-key map (kbd "C-p") 'helm-previous-line)
    map)
  "Keymap used in helm project lines.")


(defun helm-lines--async-shell-command (cmd)
  "Execute shell CMD async. Puts the output in a *helm-lines* buffer."
  (let ((name "helm-lines"))
    (start-process-shell-command name (format "*%s*" name) cmd)))


(defun helm-lines--candidates (root)
  "Helm candidates by listing all lines under the current git ROOT."
  (let* ((query (if (string-empty-p helm-pattern) "^.*$" helm-pattern))
         (cmd (concat (funcall helm-lines-search-function
                               (shell-quote-argument query)
                               (shell-quote-argument root))
                      " | grep -Ev \"^$\""        ;; remove empty lines
                      " | sed -E \"s/^[ \t]*//\"" ;; remove leading ws
                      " | sort -u"                ;; unique
                      " | head -n 100")))
    (helm-lines--async-shell-command cmd)))


(defun helm-lines ()
  "Helm-lines entry point."
  (interactive)
  (unless (or (executable-find "rg")
              (executable-find "ag")
              (executable-find "pt"))
    (user-error "Helm-lines: Could not find executable `rg', `ag' or `pt', did you install any of them? https://github.com/BurntSushi/ripgrep, https://github.com/ggreer/the_silver_searcher or https://github.com/monochromegane/the_platinum_searcher"))
  (let ((git-root (expand-file-name (or (funcall helm-lines-project-root-function)
                                        (error "Couldn't determine project root")))))
    (helm :input (string-trim (thing-at-point 'line t))
          :sources (helm-build-async-source "Complete line in project"
                     :candidates-process (lambda () (helm-lines--candidates git-root))
                     :action 'helm-lines--action)
          :keymap helm-lines-map)))


(provide 'helm-lines)

;;; helm-lines.el ends here
