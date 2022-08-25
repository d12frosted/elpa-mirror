;;; totd.el --- Display a random daily emacs command.

;; Copyright (C) 2015 Erik Hetzner

;; Author: Erik Hetzner <egh@e6h.org>
;; Keywords: help
;; Package-Version: 20150519.1440
;; Package-Commit: a715f7f2df416b8a6c827a9493ce7004180a3a4f
;; Package-Requires: ((s "1.9.0") (cl-lib "0.5"))

;; This file is not part of GNU Emacs.

;; totd.el is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; totd.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with totd.el. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; totd.el provides a daily morning "tip" - a command, bound to a key,
;; selected at random from keymaps. To enable it, install via MELPA, then
;; add:

;; (totd-start)

;; to your `~/.emacs.d/init.el` file.

;; To display a tip right now, run `M-x totd`.

;; By default, totd will display a random command that is bound to a key
;; in `global-map`. To add maps (e.g. `org-mode-map`) to use a source for
;; your daily tip, customize `totd-keymaps` by adding a symbol name.

;; Inspired by http://emacswiki.org/emacs/TipOfTheDay

;;; Code:

(require 'cl-lib)
(require 's)

(defcustom totd-keymaps
  '(global-map)
  "List of keymap variable names to use to display tip of the day."
  :group 'totd
  :type '(repeat variable))

(defcustom totd-time
  "09:00am"
  "Time to display a tip of the day.  Accepts any value supported by `diary-entry-time'."
  :group 'totd
  :type 'string)

;;;###autoload
(defun totd ()
  "Display a tip of the day."
  (interactive)
  (let* ((commands
          (cl-loop for s being the symbols
                   when (and (commandp s)
                             (where-is-internal s (mapcar #'eval totd-keymaps) t))
                   collect s))
         (command (nth (random (length commands)) commands))
         (bindings
          (cl-loop for map in totd-keymaps
                   for keys = (where-is-internal command (list (eval map)))
                   for map-name = (if (eq map 'global-map)
                                      "all buffers"
                                    (s-replace "-map" "" (symbol-name map)))
                   when (not (null keys))
                   concat (format "\n  In %s: %s" map-name (mapconcat #'key-description keys ", ")))))
    (with-help-window "*Tip of the day*"
      (princ (with-temp-buffer
               (insert (describe-function command))
               (goto-char (point-min))
               (if (re-search-forward "It is bound" nil t)
                   (progn
                     (forward-line 0)
                     (kill-line))
                 (goto-char (point-min))
                 (forward-paragraph 1)
                 (insert "\n\n")
                 (forward-line -1))
               (insert (concat "It is bound to:\n" bindings))
               (goto-char (point-min))
               (if (executable-find "figlet")
                   (insert (concat
                            (shell-command-to-string
                             (format "figlet %s -f small -w 80" command))
                            "\n"))
                 (insert (format "%s\n\n" command)))
               (buffer-string))))))

(defvar totd-timer
  nil
  "Holds the timer for a tip of the day.")

;;;###autoload
(defun totd-start ()
  "Start displaying tip of the day.  Will display time at `totd-time'."
  (interactive)
  (setq totd-timer (run-at-time totd-time 86400 #'totd)))

;;;###autoload
(defun totd-stop ()
  "Stop displaying tip of the day."
  (interactive)
  (cancel-timer totd-timer))

(provide 'totd)
;;; totd.el ends here
