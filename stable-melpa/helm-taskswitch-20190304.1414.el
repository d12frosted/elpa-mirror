;;; helm-taskswitch.el --- Use helm to switch windows and buffers  -*- lexical-binding: t -*-

;; Author: Brian Caruso <briancaruso@gmail.com>
;; Maintainer: Brian Caruso <briancaruso@gmail.com>
;; Created: 2016-05-27
;; URL: https://github.com/bdc34/helm-taskswitch
;; Package-Commit: 59f7cb99defa6e6bf6e7d599559fa8d5786cf8a9
;; Package-Version: 20190304.1414
;; Package-X-Original-Version: 2.0.0
;; Package-Requires: ((emacs "24")(helm "3.0"))
;; Keywords: frames

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; `helm-taskswitch' provides an X window and buffer switching with helm.

;; ## Table of Contents

;; - [Installation](#installation)
;; - [Usage](#usage)
;; - [Issues](#issues)
;; - [License](#license)
;; - [TODOs](#TODOs)

;; ## Installation

;; Install wmctrl and helm.

;; ## Usage

;; To activate use `M-x helm-task-switcher'.

;; ## Issues / bugs

;; If you discover an issue or bug in `helm-taskswitch' not already noted:

;; * as a TODO item, or

;; please create a new issue with as much detail as possible, including:

;; * which version of Emacs you're running on which operating system, and

;; * how you installed `helm-task-switcher', wmctrl and helm.

;; ## TODOs

;; * Track or get with focus history and use it to order candidates.
;; There is a strat on this commented out at the bottom.  The current
;; order is arbitrary.

;; Intersting blog post about alt-tab, suggests markov model
;; http://www.azarask.in/blog/post/solving-the-alt-tab-problem/
;; Ideas from that: other hot key for "go back to most recent window"

;; * Keep Emacs out of focust history
;; Filter Emacs out of focus history when it is used for switching.

;; * Dedup WMCLASS
;; WMCLASS is often program.Program, transform theses to just Program

;; * Strip WMCLASS from end of title
;; Title often ends with WMCLASS or something like that.  Try to strip these off.

;; ## License

;; [GNU General Public License version 3](http://www.gnu.org/licenses/gpl.html), or (at your option) any later version;; Code from https://github.com/flexibeast/ewmctrl is used under GNU 3.

;;; Code:

(require 'helm)
(require 'helm-for-files) ;; needed for helm-source-recentf

;; Customisable variables.

(defgroup helm-taskswitch nil
  "Use helm to switch between tasks (X11 windows or buffers)"
  :prefix "helm-taskswitch-"
  :group 'external)

(defcustom helm-taskswitch-wmctrl-path "/usr/bin/wmctrl"
  "Absolute path to wmctrl executable."
  :type '(file :must-match t)
  :group 'helm-taskswitch)

(defcustom helm-taskswitch-title-transform 'identity
  "Transform title of a single client window for display in helm selection."
  :group 'helm-taskswitch
  :type '(repeat function))

(defcustom helm-taskswitch-wmclass-width 12
  "Column with of wmclass field when displayed."
  :group 'helm-taskswitch
  :type 'integer)

(defgroup helm-taskswitch-faces nil
  "Customize the appearance of helm-taskswitch."
  :prefix "helm-"
  :group 'helm-taskswitch
  :group 'helm-faces)

(defface helm-taskswitch-browser-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for web browsers."
  :group 'helm-taskswitch-faces)

(defface helm-taskswitch-term-face
  '((t (:inherit font-lock-string-face)))
  "Face used for terminals."
  :group 'helm-taskswitch-faces)

(defface helm-taskswitch-emacs-face
  '((t (:inherit font-lock-regexp-grouping-construct)))
  "Face used for emacs."
  :group 'helm-taskswitch-faces)


;; Internal Code

(defun helm-taskswitch-format-candidate (al)
  "Formats a candidate client window for task switcher.

  AL is the associative list for a window."
  (let* ((ddfmt (format "%d.%d" helm-taskswitch-wmclass-width helm-taskswitch-wmclass-width))
         (wmtitlefmt (concat "%-" ddfmt "s %s"))
         (windowstr (format wmtitlefmt (helm-taskswitch-wmclass al) (helm-taskswitch-title al))))
    (cons windowstr (list al))))

(defun helm-taskswitch-title (al)
  "Formats the title of a window.

  AL is an associative list for a window."
  (let ((title   (cdr (assoc 'title   al))))
    (funcall helm-taskswitch-title-transform
             (replace-regexp-in-string "- Google Chrome" "" title))))

(defun helm-taskswitch-wmclass (al)
  "Gets the WMCLASS for window AL associative list."
  (let ((wmclass (cdr (assoc 'wmclass al))))
    (cond ((string-equal wmclass "google-chrome.Google-chrome" )
           (propertize "Chrome" 'face 'helm-taskswitch-browser-face ))
          ((string-equal wmclass "terminator.Terminator")
           (propertize "Terminator" 'face 'helm-taskswitch-term-face))
          ((string-equal wmclass "emacs.Emacs")
           (propertize "Emacs" 'face 'helm-taskswitch-emacs-face))
          (t wmclass) )))

(defconst helm-taskswitch--wmctrl-field-count 10)
(defconst helm-taskswitch--wmctrl-field-regex
  (concat "^"
          (mapconcat 'identity (make-list (1- helm-taskswitch--wmctrl-field-count) "\\(\\S-+\\)\\s-+") "")
          "\\(.+\\)"))

(defun helm-taskswitch--list-windows ()
  "Internal function to get a list of desktop windows via `wmctrl'."
  (let ((bfr (generate-new-buffer " *helm-taskswitch-wmctrl-output*"))
        (windows-list '()))
    (with-current-buffer bfr
      (call-process-shell-command (concat helm-taskswitch-wmctrl-path " -lGxp") nil t)
      (goto-char (point-min))
      (while (re-search-forward helm-taskswitch--wmctrl-field-regex nil t)
        (let ((window-id (match-string 1))
              (desktop-number (match-string 2))
              (pid (match-string 3))
              (x-offset (match-string 4))
              (y-offset (match-string 5))
              (width (match-string 6))
              (height (match-string 7))
              (wmclass (match-string 8))
              (client-host (match-string 9))
              (title (match-string 10)))
          (setq windows-list
                (append windows-list
                        (list
                         `((window-id . ,window-id)
                           (desktop-number . ,desktop-number)
                           (pid . ,pid)
                           (x-offset . ,x-offset)
                           (y-offset . ,y-offset)
                           (width . ,width)
                           (height . ,height)
                           (wmclass . ,wmclass)
                           (client-host . ,client-host)
                           (title . ,title))))))))
    (kill-buffer bfr)
    windows-list))


(defun helm-taskswitch-focus-window-by-candidate (al)
  "Internal function to focus the desktop window specified by AL, a window associative list."
  (let* ((id (cdr (assoc 'window-id (car al))))
         (cmd (concat helm-taskswitch-wmctrl-path " -i -a '" id "'")))
    (message cmd)
    (call-process-shell-command cmd)))


(defun helm-taskswitch-close-candidate (al)
  "Closes a candidate AL, a window associative list from ‘helm-taskswitch--list-windows’."
    (let* ((id (cdr (assoc 'window-id (car al))))
           (cmd (concat helm-taskswitch-wmctrl-path " -i -c '" id "'")))
      (message (concat "helm-taskswitch: closing X client with " cmd))
      (call-process-shell-command cmd)))

(defun helm-taskswitch-close-candidates (_al)
  "Closes all selected candidates.  AL is ignored but seems to be needed by helm."
  (mapc 'helm-taskswitch-close-candidate (helm-marked-candidates)))
  
(defun helm-taskswitch-client-candidates ()
  "Return a list windows with title and wmclass."
  (mapcar 'helm-taskswitch-format-candidate (helm-taskswitch--list-windows)))


(defvar helm-taskswitch-source-x-windows
      (helm-build-sync-source "X Windows"
        :fuzzy-match t
        :candidates 'helm-taskswitch-client-candidates
        :action '(("Focus window" . helm-taskswitch-focus-window-by-candidate )
                  ("Close window(s)" . helm-taskswitch-close-candidates)
                  ("dump client window s-exp" . prin1 )))
      "Helm source that provides X windows and actions.")


;;;###autoload
(defun helm-taskswitch ()
  "Use helm to switch between tasks (X11 windows, buffers or recentf)."
  (interactive)
  (run-hooks 'helm-taskswitch-open-hooks )
  (select-frame-set-input-focus (window-frame (selected-window)))
  (unless helm-source-buffers-list
   (setq helm-source-buffers-list
          (helm-make-source "Buffers" 'helm-source-buffers)))
  (helm :sources '(helm-taskswitch-source-x-windows
                   helm-source-buffers-list
                   helm-source-recentf
                   helm-source-buffer-not-found)
        :buffer "*helm-taskswitch*"
        :truncate-lines t))


;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

(provide 'helm-taskswitch)
;;; helm-taskswitch.el ends here
