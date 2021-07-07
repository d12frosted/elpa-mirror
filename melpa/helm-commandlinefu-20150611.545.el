;;; helm-commandlinefu.el --- Search and browse commandlinefu.com from helm  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Chunyang Xu

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; URL: https://github.com/xuchunyang/helm-commandlinefu
;; Package-Version: 20150611.545
;; Package-Commit: 9ee7e018c5db23ae9c8d1c8fa969876f15b7280d
;; Package-Requires: ((emacs "24.1") (helm "1.7.0") (json "1.3") (let-alist "1.0.3"))
;; Keywords: commandlinefu.com
;; Version: 0.3

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

;; A Helm extension to search and browse
;; [Commandlinefu.com](http://www.commandlinefu.com/).

;; ## Usage
;; - `helm-commandlinefu-search'
;; - `helm-commandlinefu-browse'

;; ## Similar project
;; - [clf - Command line tool to search snippets on Commandlinefu.com](https://github.com/ncrocfer/clf)

;;; Change Log:
;; 0.3   - 2015/05/31 - Add helm interface for clf.
;; 0.2   - 2015/05/30 - Add Search.
;; 0.1   - 2015/05/30 - Created File.

;;; Code:

(require 'helm)
(require 'json)
(require 'let-alist)

(defgroup helm-commandlinefu nil
  "commandlinefu.com with helm interface."
  :group 'helm)

(defcustom helm-commandlinefu-full-frame-p t
  "Use current window to show the candidates.
If t then Helm doesn't pop up a new window."
  :group 'helm-commandlinefu
  :type 'boolean)

(and (featurep 'helm-config)
     (easy-menu-add-item nil '("Tools" "Helm" "Tools") ["Search Commandlinefu.com" helm-commandlinefu-search t])
     (easy-menu-add-item nil '("Tools" "Helm" "Tools") ["Browse Commandlinefu.com" helm-commandlinefu-browse t]))

(defvar helm-commandlinefu--json nil)

(defun helm-commandlinefu--request (url)
  "Request URL and return JSON object."
  (let ((url-automatic-caching t)
        (json nil))
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char (point-min))
      (when (not (string-match "200 OK" (buffer-string)))
        (error "Problem connecting to the server"))
      (re-search-forward "^$" nil 'move)
      (setq json (buffer-substring-no-properties (point) (point-max)))
      (kill-buffer (current-buffer)))
    (json-read-from-string json)))

(defun helm-commandlinefu--browse-url (&optional sort-by-date)
  "Create browse url, sort by votes(if SORT-BY-DATE is non-nil, sort by date)."
  (format "http://www.commandlinefu.com/commands/browse/%s/json/"
          (if sort-by-date "" "sort-by-votes")))

(defun helm-commandlinefu--search-url (query &optional sort-by-date)
  "Create search url base on QUERY, sort by votes(if SORT-BY-DATE is non-nil, sort by date)."
  (let ((base64-query (base64-encode-string
                       (mapconcat #'identity (split-string query) " ")))
        (url-query (mapconcat #'identity (split-string query) "-")))
    (format "http://www.commandlinefu.com/commands/matching/%s/%s/%s/json"
            url-query
            base64-query
            (if sort-by-date "" "sort-by-votes"))))

(defun helm-commandlinefu--browse-candidates ()
  "Build helm source candidates for `helm-commandlinefu--browse-source'."
  (mapcar (lambda (elt)
            (let-alist elt
              (cons (concat (propertize (concat "# " .summary)
                                        'face 'font-lock-comment-face)
                            "\n" .command)
                    (list :url .url
                          :votes (string-to-number .votes)
                          :command .command
                          :summary .summary
                          :id .id))))
          (append helm-commandlinefu--json nil)))

(defun helm-commandlinefu--search-candidates ()
  "Build helm source candidates for `helm-commandlinefu--search-source'."
  (mapcar (lambda (elt)
            (let-alist elt
              (cons (concat (propertize (concat "# " .summary)
                                        'face 'font-lock-comment-face)
                            "  "
                            (propertize helm-pattern 'display "     ")
                            "\n" .command)
                    (list :url .url
                          :votes (string-to-number .votes)
                          :command .command
                          :summary .summary
                          :id .id))))
          (append (helm-commandlinefu--request
                   (helm-commandlinefu--search-url helm-pattern))
                  nil)))

(defvar helm-commandlinefu--actions
  '(("Execute command" .
     (lambda (candidate)
       (shell-command
        (read-shell-command "Shell Command: "
                            (plist-get candidate :command)))))
    ("Save command to kill-ring" .
     (lambda (candidate)
       (kill-new (plist-get candidate :command))))
    ("Browse URL" .
     (lambda (candidate)
       (browse-url (plist-get candidate :url))))))

(defvar helm-commandlinefu--browse-source
  (helm-build-sync-source "commandlinefu.coms archive"
    :candidates #'helm-commandlinefu--browse-candidates
    :persistent-help "Execute command without confirm"
    :persistent-action (lambda (candidate)
                         (shell-command (plist-get candidate :command)))
    :action helm-commandlinefu--actions
    :multiline t))

(defvar helm-commandlinefu--search-source
  (helm-build-sync-source "Search commandlinefu.com"
    :candidates #'helm-commandlinefu--search-candidates
    :persistent-help "Execute command without confirm"
    :persistent-action (lambda (candidate)
                         (shell-command (plist-get candidate :command)))
    :action helm-commandlinefu--actions
    :multiline t
    :nohighlight t
    :matchplugin nil
    :volatile t
    :requires-pattern 2))

;;;###autoload
(defun helm-commandlinefu-browse (&optional sort-by-date)
  "Browse the Commandlinefu.com archive, sort by votes.
If SORT-BY-DATE is non-nil, sort by date."
  (interactive "P")
  (setq helm-commandlinefu--json
        (helm-commandlinefu--request (helm-commandlinefu--browse-url
                                      sort-by-date)))
  (helm :sources 'helm-commandlinefu--browse-source
        :buffer "*helm-commandlinefu-browse*"
        :full-frame helm-commandlinefu-full-frame-p))

;;;###autoload
(defun helm-commandlinefu-search ()
  "Browse Commandlinefu.com, sort by votes."
  (interactive)
  (helm :sources 'helm-commandlinefu--search-source
        :buffer "*helm-commandlinefu-search*"
        :full-frame helm-commandlinefu-full-frame-p))

;;;###autoload
(defun helm-commandlinefu-search-clf ()
  "Helm interface for clf.
see URL `https://github.com/ncrocfer/clf'."
  (interactive)
  (require 'helm-grep)
  (unless (and (executable-find "clf") (executable-find "awk"))
    (message "Both \"clf\" and \"awk\" are needed to run this command"))
  (helm :sources
        (helm-build-async-source "Search Commandlinefu.com using clf"
          :candidates-process
          (lambda ()
            (let ((proc
                   (start-process-shell-command
                    "clf" helm-buffer
                    (format "clf %s  | awk 'NF {key=$0; getline; print key \",,\" $0;}'"
                            helm-pattern))))
              (prog1 proc
                (set-process-sentinel
                 proc
                 (lambda (_process event)
                   (if (string= event "finished\n")
                       (with-helm-window
                         (setq mode-line-format
                               '(" " mode-line-buffer-identification " "
                                 (line-number-mode "%l") " "
                                 (:eval (propertize
                                         (format "[clf Process Finish- (%s results)]"
                                                 (max (1- (count-lines
                                                           (point-min) (point-max))) 0))
                                         'face 'helm-grep-finish))))
                         (force-mode-line-update))))))))
          :candidate-transformer
          (lambda (candidates)
            (mapcar (lambda (candidate)
                      (replace-regexp-in-string ",," "\n" candidate))
                    candidates))
          :coerce (lambda (candidate)
                    (substring candidate (1+ (string-match "\n" candidate))))
          :persistent-help "Execute command without confirm"
          :persistent-action #'shell-command
          :action '(("Execute command" .
                     (lambda (candidate)
                       (shell-command
                        (read-shell-command "Shell Command: " candidate))))
                    ("Save command to kill-ring" . kill-new))
          :multiline t
          :requires-pattern 2
          :nohighlight t)
        :buffer "*helm-commandlinefu-search-clf*"
        :full-frame helm-commandlinefu-full-frame-p))

(provide 'helm-commandlinefu)
;;; helm-commandlinefu.el ends here
