;;; doom-modeline-now-playing.el --- Segment for Doom Modeline to show playerctl information -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Ellis Kenyő
;;
;; Author: Ellis Kenyő <me@elken.dev>
;; Maintainer: Ellis Kenyő <me@elken.dev>
;; Created: January 23, 2021
;; Modified: January 23, 2021
;; Version: 0.0.1
;; Package-Version: 20210831.1442
;; Package-Commit: ef9158dfdf32e8eb789b69e7394d0bddaa68f42c
;; Homepage: https://github.com/elken/doom-modeline-now-playing
;; Package-Requires: ((emacs "24.4") (doom-modeline "3.0.0") (async "1.9.3"))
;; SPDX-License-Identifier: GPL3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Depends on playerctl currently, not sure if I'm going
;;  to add support for anything else but feel free to contribute
;;  another provider :D
;;
;;  The below line need to be manually ran somewhere at your behest
;;
;;  (doom-modeline-now-playing-timer)
;;
;;  If you wish for the staus to update
;;; Code:

(require 'cl-lib)
(require 'doom-modeline)
(require 'async)

;;
;; Custom variables
;;

(defgroup doom-modeline-now-playing nil
  "Settings related to doom-modeline-now-playing"
  :group 'doom-modeline)

(defgroup doom-modeline-now-playing-faces nil
  "Faces related to doom-modeline-now-playing"
  :group 'doom-modeline-faces)

(defcustom doom-modeline-now-playing t
  "Whether to display the now-playing segment.

Non-nil to display in the modeline"
  :type 'boolean
  :group 'doom-modeline-now-playing)

(defcustom doom-modeline-now-playing-format "{{artist}} - {{title}}"
  "Default output format.
Supports a number of options \(which must be wrapped in handlebars\)
- `playerName': The name of the current player `\'string'
- `position': Position of the current track in microseconds `\'integer'
- `status': Playback status of the current player `\'string'
- `volume': Volume level `\'float'
- `album': Album of the current track `\'string'
- `artist': Artist of the current track `\'string'
- `title': Title of the current track `\'string'

As well as a number of functions:
- `lc(\'string)': Convert string to lowercase
- `uc(\'string)': Convert string to uppercase
- `duration(\'integer)': Convert int to hh:mm:ss
- `markup_escape\(\'string)': Escape XML markup
- `default(\'any\,\'any)': Return 1st arg unless null, then return 2nd
- `emoji(status|volume)': Convert either status or volume to emoji"
  :type 'string
  :group 'doom-modeline-now-playing)

(defcustom doom-modeline-now-playing-interval 5
  "Default delay in seconds to update the status."
  :type 'integer
  :group 'doom-modeline-now-playing)

(defcustom doom-modeline-now-playing-ignored-players '("firefox")
  "List of players to exclude from output."
  :type '(repeat string)
  :group 'doom-modeline-now-playing)

(defcustom doom-modeline-now-playing-max-length 40
  "Maximum length of output. Truncates with `...' after."
  :type 'integer
  :group 'doom-modeline-now-playing)

;;
;; Faces
;;

(defface doom-modeline-now-playing-icon
  '((t (:inherit success)))
  "Face for the now-playing icon"
  :group 'doom-modeline-now-playing-faces)

(defface doom-modeline-now-playing-text
  '((t (:inherit bold)))
  "Face for the now-playing text"
  :group 'doom-modeline-now-playing-faces)

;;
;; Segment
;;

(cl-defstruct (now-playing-status (:constructor now-playing-status-create))
  status player text)

(defvar doom-modeline-now-playing-status nil)
(defun doom-modeline-now-playing--update ()
  "Update the tokens for now-playing."
  (when (and doom-modeline-now-playing
             (> doom-modeline-now-playing-interval 0))
    (async-start
     `(lambda ()
        (require 'subr-x)
        ,(async-inject-variables
          "\\`\\(load-path\\|auth-sources\\|doom-modeline-now-playing-format\\|doom-modeline-now-playing-ignored-players\\)\\'")
        (string-trim
         (shell-command-to-string
          (format "playerctl metadata --ignore-player=%s --format '{{playerName}}|{{lc(status)}}|%s'"
                  (mapconcat #'identity doom-modeline-now-playing-ignored-players ",")
                  doom-modeline-now-playing-format))))
     (lambda (result)
       (let ((tokens (split-string result "|")))
         (setq doom-modeline-now-playing-status
               (now-playing-status-create :player (elt tokens 0)
                                          :status (elt tokens 1)
                                          :text   (elt tokens 2))))))))

(defvar doom-modeline-now-playing--timer nil)
(defun doom-modeline-now-playing-timer ()
  "Start/Stop the timer for now-playing update."
  (if (timerp doom-modeline-now-playing--timer)
      (cancel-timer doom-modeline-now-playing--timer))
  (setq doom-modeline-now-playing--timer
        (when doom-modeline-now-playing
          (run-with-timer
            1
           doom-modeline-now-playing-interval
           #'doom-modeline-now-playing--update))))

(doom-modeline-add-variable-watcher
 'doom-modeline-now-playing
 (lambda (_sym val op _where)
   (when (eq op 'set)
     (setq doom-modeline-now-playing val)
     (doom-modeline-now-playing-timer))))

(defun doom-modeline-now-playing-toggle-status ()
  "Toggle the current status (primarily used by the status icon)."
  (interactive)
  (let ((command (format "playerctl --player=%s play-pause"
                         (now-playing-status-player doom-modeline-now-playing-status))))
    (start-process-shell-command "playerctl" nil command)
  (doom-modeline-now-playing--update)))

(doom-modeline-def-segment now-playing
  "Current status of playerctl. Configurable via
variables for update interval, output format, etc."
  (when (and doom-modeline-now-playing
             (doom-modeline--active)
             doom-modeline-now-playing-status
             (not (string= (now-playing-status-player doom-modeline-now-playing-status) "No players found")))
    (let ((player (now-playing-status-player doom-modeline-now-playing-status))
          (status (now-playing-status-status doom-modeline-now-playing-status))
          (text   (now-playing-status-text   doom-modeline-now-playing-status)))
      (concat
       (doom-modeline-spc)
       (if (string= "spotify" player)
           (doom-modeline-icon 'faicon "spotify" "" "#"
                               :face 'doom-modeline-now-playing-icon
                               :v-adjust -0.0575)
         (doom-modeline-icon 'faicon "music" "" "#"
                             :face 'doom-modeline-now-playing-icon
                             :v-adjust -0.0575))
       (doom-modeline-spc)
       (propertize (if (equal status "playing")
                       (doom-modeline-icon 'faicon "play" "" ">"
                                           :v-adjust -0.0575)
                     (doom-modeline-icon 'faicon "pause" "" "||"
                                         :v-adjust -0.0575))
                   'mouse-face 'mode-line-highlight
                   'help-echo "mouse-1: Toggle player status"
                   'local-map (let ((map (make-sparse-keymap)))
                                (define-key map [mode-line mouse-1] 'doom-modeline-now-playing-toggle-status)
                                map))
       (doom-modeline-spc)
       (propertize
        (truncate-string-to-width text doom-modeline-now-playing-max-length nil nil "...")
        'face 'doom-modeline-now-playing-text)))))

(provide 'doom-modeline-now-playing)
;;; doom-modeline-now-playing.el ends here
