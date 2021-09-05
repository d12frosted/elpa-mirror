;;; mpdmacs.el --- A lightweight MPD client  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Michael Herstine <sp1ff@pobox.com>

;; Author: Michael Herstine <sp1ff@pobox.com>
;; Version: 0.2.2
;; Package-Version: 20210904.35
;; Package-Commit: 334b066dc5bb82d9ccb6cc30d63afed0f7610fe8
;; Package-Requires: ((emacs "25.1") (elmpd "0.1"))
;; Keywords: comm
;; URL: https://github.com/sp1ff/mpdmacs

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

;; "Music Player Daemon (MPD) is a flexible, powerful, server-side
;; application for playing music."  <https://www.musicpd.org/>.
;; mpdmacs is a lightweight MPD client for Emacs.

;; See also mpdel <https://gitea.petton.fr/mpdel/mpdel >, as well as
;; the mpc package which ships with Emacs beginning with version 23.2.

;; mpdmacs requires elmpd <https://github.com/sp1ff/elmpd>, a
;; lightweight asynchronous library for building MPD clients.  My goal
;; is to have Emacs never freeze or pause while running this package.

;; Communications Model:

;; mpd encourages "throwaway" connections; i.e. a pattern in which a
;; connection to the server is made, one or a few commands are issued,
;; and the connection then closed down (the default server-side
;; timeout is 60 seconds).

;; The one exception is the "idle" command, which clients can use
;; to receive notifications of server-side changes.  When a client
;; issues the "idle" command, server-side timeouts are disabled.

;; mpdmacs uses a single `elmpd-connection' (which itself uses a
;; socket over which it will talk to MPD along with a callback for
;; servicing server-side changes).  The connection will immediately be
;; put into "idle" mode.  Commands issued through this package will
;; cause a "noidle" command to be issued on that connection before the
;; commands are issued; after the commands complete, the connection
;; will again be placed into "idle" mode.

;;; Code:

(require 'cl-lib)
(require 'elmpd)

(defconst mpdmacs-version "0.2.2")

(defgroup mpdmacs nil
  "A lightweight MPD client for Emacs."
  :group 'comm)

;; Per
;; <https://www.gnu.org/software/emacs/manual/html_mono/elisp.html#Keymaps-and-Minor-Modes>,
;; "Minor modes may bind commands to key sequences consisting of C-c
;; followed by a punctuation character. However, sequences consisting
;; of C-c followed by one of {}<>:;, or a control character or digit,
;; are reserved for major modes. Also, C-c letter is reserved for
;; users."

;; I chose "C-c $" because '$' looks vaguely like a musical note on
;; sheet music.
(defcustom mpdmacs-prefix-keys "C-c $"
  "`kbd'-compliant description of the prefix for the `mpdmacs' keymap.

Like many minor-modes, `mpdmacs' defines a keymap that is
activated when the mode is turned on.  Use this custom variable
to choose the prefix key chord."
  :type 'string)

(defcustom mpdmacs-connection-name "mpdmacs"
  "Default connection name.

The name of any particular connection will be modified to make it
unique."
  :group 'mpdmacs
  :type 'string)

(defcustom mpdmacs-host "localhost"
  "Default `mpd' server name."
  :group 'mpdmacs
  :type 'string)

(defcustom mpdmacs-port 6600
  "Default `mpd' port."
  :group 'mpdmacs
  :type 'int)

(defcustom mpdmacs-socket "/var/run/mpd/socket"
  "Default local (Unix) socket on which mpd is listening."
  :group 'mpdmacs
  :type 'string)

(defcustom mpdmacs-password nil
  "Default `mpd' password (nil to indicate none)."
  :group 'mpdmacs
  :type 'string)

(defcustom  mpdmacs-current-song-buffer "*Current Song*"
  "Buffer for displaying the current song."
  :group 'mpdmacs
  :type 'string)

(defvar mpdmacs-mode-line-update-function #'mpdmacs--update-mode-line)

(defvar mpdmacs-player-state-changed-hook '()
  "Hooks invoked on change in player state.")

(defvar mpdmacs-sticker-change-hook '()
  "Hooks invoked on changes to the sticker database.")

(defvar mpdmacs-show-current-song-hook '()
  "Hooks invoked when displaying the current song.")

;; We'll re-use the elmpd logging feature, but with our own, dedicated facility.
(defun mpdmacs-log (level fmt &rest objects)
  "Log FMT at level LEVEL & facility 'mpdmacs."
  (apply #'elmpd-log level 'mpdmacs fmt objects))

(defvar mpdmacs--current-song-label nil
  "Short string describing the current track (if any).

Takes the form of ARTIST - TITLE.  Updated automatically
whenever `mpdmacs--connection' is informed of a change in player
state.")

(defun mpdmacs--update-mode-line ()
  "Add the current track to the mode-line."
  (setq global-mode-string (list (if mpdmacs--current-song-label mpdmacs--current-song-label "N/A"))))

;;; State

(defvar mpdmacs--connection nil
  "Persistent \"idle\" connection.

`mpdmacs' will setup a long-lived connection to monitor updates
on the server.")

(defvar mpdmacs--current-song-file nil
  "File corresponding to the current track (if any).

Will be nil if the player is stopped.")

(defvar mpdmacs--stored-playlists nil
  "List of last-known stored playlists.

Updated automatically whenever `mpdmacs--connection' is informed
of a change in the stored playlists.")

(defvar mpdmacs--player-options
  '((repeat           . unknown)
    (random           . unknown)
    (single           . unknown)
    (consume          . unknown)
    (state            . unknown)
    (crossfade        . unknown)
    (replay-gain-mode . unknown)
    (volume           . unknown))
  "Association list mapping player options to values.

Updated automatically by `mpdmacs--connection' when it is
informed of any change on the server side.")

(defvar mpdmacs-mode-keymap
  (let  ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "P"))   #'mpdmacs-play)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "DEL")) #'mpdmacs-replay)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "/"))   #'mpdmacs-send-to-playlist)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "s"))   #'mpdmacs-stop)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " ">"))   #'mpdmacs-next)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "<"))   #'mpdmacs-previous)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "c"))   #'mpdmacs-clear)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "v"))   #'mpdmacs-set-volume)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "+"))   #'mpdmacs-inc-volume)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "-"))   #'mpdmacs-dec-volume)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "l"))   #'mpdmacs-load-playlist)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "p"))   #'mpdmacs-toggle-pause)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "r"))   #'mpdmacs-toggle-random)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "R"))   #'mpdmacs-toggle-consume)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "."))   #'mpdmacs-show-current-song)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "X"))   #'mpdmacs-set-crossfade)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "y"))   #'mpdmacs-rotate-single)
    (define-key keymap (kbd (concat mpdmacs-prefix-keys " " "Y"))   #'mpdmacs-rotate-replay-gain)
    keymap)
  "Keymap for `mpdmacs-mode' commands.")

;;;###autoload
(define-minor-mode mpdmacs-mode
  "Global minor mode enabling a minimal MPD client.

When mpdmacs-mode is enabled, Emacs becomes a lightweight MPD
client.  Basic playback and playback options (random, consume &c)
are all available, and extensions are supported through hooks
that will be invoked on assorted player events.

`mpdmacs-mode-hook' is run whenever `mpdmacs-mode' is enabled or
disabled.

Key bindings:
\\{mpdmacs-mode-keymap}"
  :group 'mpdmacs
  :lighter " mpd"
  :keymap mpdmacs-mode-keymap
  :global t
  :init-value nil
  (if mpdmacs-mode
      (progn
        (setq
         mpdmacs--connection
         (elmpd-connect
          :name mpdmacs-connection-name
          :host mpdmacs-host
          :port mpdmacs-port
          :local mpdmacs-socket
          :subsystems '((player stored options mixer sticker) . mpdmacs--watcher)))
        (mpdmacs--update-player-state)
        (mpdmacs--update-stored-playlists)
        (mpdmacs--update-player-options)
        (mpdmacs-log 'info "mpdmacs-mode enabled."))
    (if mpdmacs--connection
        (delete-process (elmpd-connection--fd mpdmacs--connection)))
    (setq mpdmacs--connection nil)
    (mpdmacs-log 'info "mpdmacs unloaded.")))

(defun mpdmacs--update-player-state ()
  "Update `mpdmacs--current-song-label' & `mpdmacs--current-file'."
  (elmpd-send
   mpdmacs--connection
   "currentsong"
   (lambda (_conn ok text)
     (if (not ok)
         (progn
           (mpdmacs-log 'error "Failed to get current track: %s" text)
           (setq mpdmacs--current-song-label "N/A"))
       (let ((artist
              (if (string-match "^Artist: \\(.*\\)" text)
                  (substring text (match-beginning 1) (match-end 1))))
             (file
                (if (string-match "^file: \\(.*\\)$" text)
                    (substring text (match-beginning 1) (match-end 1))))
             (title
              (if (string-match "^Title: \\(.*\\)" text)
                  (substring text (match-beginning 1) (match-end 1)))))
         (setq
          mpdmacs--current-song-label
          (cond
           ((and artist title)
            (format "%s - %s" artist title))
           (artist (format "%s - N/A" artist))
           (title (format "N/A - %s" title))
           (t "Untitled track"))
          mpdmacs--current-song-file file)
         (mpdmacs-log 'debug "Updated current track to %s" mpdmacs--current-song-label)))
     (if mpdmacs-mode-line-update-function (funcall mpdmacs-mode-line-update-function))
     (if mpdmacs-player-state-changed-hook (run-hooks 'mpdmacs-player-state-changed-hook)))))

(defun mpdmacs--update-stored-playlists ()
  "Update `mpdmacs--stored-playlists'."
  (elmpd-send
   mpdmacs--connection
   "listplaylists"
   (lambda (_conn ok text)
     (if (not ok)
         (mpdmacs-log 'error "`Failed to get playlists: %s" text)
       (setq
        mpdmacs--stored-playlists
        (sort
         (cl-mapcar
          (lambda (x) (substring x 10))
          (cl-remove-if-not
           (lambda (x) (string-prefix-p "playlist: " x))
           (split-string text "\n" t)))
         'string-lessp))))))

(defun mpdmacs--intern-boolean-value (text)
  "Convert TEXT for boolean value to a symbol.

MPD maintains assorted values defined to be boolean in nature.
This is a convenience function for mapping the wire value (text
in the case of MPD) to LISP symbols.  If TEXT cannot be
interpreted as per the MPD protocol, the symbol 'unknown will be
returned."

  (cond
   ((string= text "0") nil)
   ((string= text "1") t)
   (t 'unknown)))

(defun mpdmacs--intern-number (text)
  "Convert TEXT to a numeric value."
  (if (string-match "[.0-9]+" text)
      (string-to-number text)
    'unknown))

(defun mpdmacs--update-player-options ()
  "Updated `mpdmacs--player-options'."
  (elmpd-send
   mpdmacs--connection
   "status"
   (lambda (_conn ok text)
     (if (not ok)
         ;; Set all options to 'unknown?
         (mpdmacs-log 'error "Failed to get player status: %s" text)
       (cl-mapc
        (lambda (line)
          (cond
           ((string-prefix-p "repeat: " line)
            (setf (alist-get 'repeat mpdmacs--player-options) (mpdmacs--intern-boolean-value (substring line 8))))
           ((string-prefix-p "random: " line)
            (setf (alist-get 'random mpdmacs--player-options) (mpdmacs--intern-boolean-value (substring line 8))))
           ((string-prefix-p "single: " line)
            (setf (alist-get 'single mpdmacs--player-options)
                  (let ((value (substring line 8)))
                    (cond
                     ((string= value "0") nil)
                     ((string= value "1") t)
                     ((string= value "oneshot") 'oneshot)
                     (t 'unknown)))))
           ((string-prefix-p "consume: " line)
            (setf (alist-get 'consume mpdmacs--player-options) (mpdmacs--intern-boolean-value (substring line 9))))
           ((string-prefix-p "state: " line)
            (setf (alist-get 'state mpdmacs--player-options)
                  (let ((value (substring line 7)))
                    (cond
                     ((string= "play" value) 'play)
                     ((string= "stop" value) 'stop)
                     ((string= "pause" value) 'pause)
                     (t 'unknown)))))
           ((string-prefix-p "xfade: " line)
            (setf
             (alist-get 'crossfade mpdmacs--player-options)
             (mpdmacs--intern-number (substring line 7))))
           ((string-prefix-p "volume: " line)
            (setf
             (alist-get 'volume mpdmacs--player-options)
             (mpdmacs--intern-number (substring line 8))))))
        (split-string text "\n" t))
       ;; replay gain status isn't included in the output of the
       ;; "status" command, so we have to go back to the server for
       ;; that:
       (elmpd-send
        mpdmacs--connection
        "replay_gain_status"
        (lambda (_conn ok text)
          ;; We expect a single line (of the form "replay_gain_mode:
          ;; XXX", but just in case the protocol changes out from
          ;; under us, be ready to process multiple lines.
          (if (not ok)
              ;; Set this option to 'unknown?
              (mpdmacs-log 'error "Failed to get replay-gain-mode: %s" text)
            (cl-mapc
             (lambda (line)
               (cond
                ((string-prefix-p "replay_gain_mode: " line)
                 (setf (alist-get 'replay-gain-mode mpdmacs--player-options)
                       (let ((value (substring line 18)))
			                   (cond
                          ((string= value "off") 'off)
                          ((string= value "track") 'track)
                          ((string= value "album") 'album)
                          ((string= value "auto") 'auto)
                          (t 'unknown)))))))
             (split-string text "\n" t)))))))))

(defun mpdmacs--watcher (_conn subsys)
  "Idle-mode callback; SUBSYS is a list of subsystems..

This function will be invoked when any subsystem in which we have
registered an interest changes on the server.  The particular
subsystems will be listed in SUBSYS (a list of symbols)."
  (cl-mapc
   (lambda (x)
     (cond
      ((or (eq x 'mixer) (eq x 'player))
       (mpdmacs-log 'info "idle event: player/mixer")
       (mpdmacs--update-player-state)
       (mpdmacs--update-player-options))
      ((eq x 'stored)
       (mpdmacs-log 'info "idle event: stored_playlists")
       (mpdmacs--update-stored-playlists))
      ((eq x 'options)
       (mpdmacs-log 'info "idle event: options")
       (mpdmacs--update-player-options))
      ((eq x 'sticker)
       ;; This package doesn't care about stickers; it just provides a
       ;; hook for other packages that build on it.
       (mpdmacs-log 'info "idle event: sticker")
       (run-hooks 'mpdmacs-sticker-change-hook))
      (t
       (mpdmacs-log 'error (format "Unknown idle event %s" x)))))
   subsys))

(defun mpdmacs-get-current-song-file ()
  "Retrieve the file URI to the current track (may be nil)."
  mpdmacs--current-song-file)

;;; Commands

(defun mpdmacs-send (command &optional callback)
  "Send an arbitrary COMMAND with CALLBACK over the mpdmacs connection."
  (when mpdmacs-mode
    (elmpd-send mpdmacs--connection command callback)))

(defun mpdmacs-play ()
  "Start `mpd' playback."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "play")))

(defun mpdmacs-replay ()
  "Re-play the current song from the beginning."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "seekcur 0")))

(defun mpdmacs-send-to-playlist (playlist)
  "Send the current track to PLAYLIST."
  (interactive
   (list
    (completing-read "Playlist: " mpdmacs--stored-playlists)))
  (when mpdmacs-mode
    (let ((f (mpdmacs-get-current-song-file)))
      (mpdmacs-send
       (format "playlistadd \"%s\" \"%s\"" playlist f)
       (lambda (_conn ok text)
         (if ok
             (mpdmacs-log 'info "Sent \"%s\" to playlist %s." f playlist)
           (mpdmacs-log 'error "Failed to send \"%s\" to playlist %s: %s" f playlist text)))))))

(defun mpdmacs-stop ()
  "Stop `mpd' playback."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "stop")))

(defun mpdmacs-next ()
  "Skip ahead to the next track."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "next")))

(defun mpdmacs-previous ()
  "Skip back to the previous track."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "previous")))

(defun mpdmacs-clear ()
  "Clear the play queue."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "clear")))

(defvar mpdmacs--volume-completion-list
  (cl-mapcar (lambda (x) (format "%d" x)) (number-sequence 0 100))
  "Precomputed list of permissible volume settings.")

(defun mpdmacs-set-volume (vol)
  "Set the MPD volume to VOL (0-100)."
  (interactive
   (list
    (completing-read
     "Volume: "
     mpdmacs--volume-completion-list nil t
     (let ((curvol (alist-get 'volume mpdmacs--player-options)))
       (if (eq curvol 'unknown) nil (format "%d" curvol))))))
  (when mpdmacs-mode
    (mpdmacs-send (format "setvol %d" vol))))

(defun mpdmacs--modify-volume (inc)
  "Change the MPD server volume by INC."
  (let ((curvol (alist-get 'volume mpdmacs--player-options)))
    (if (eq curvol 'unknown)
        (user-error "Can't increment the volume when the current volume is unknown")
      (let ((vol (+ curvol inc)))
        (mpdmacs-send (format "setvol %d" vol))
        (message "Volume is now %d" vol)))))

(defun mpdmacs-inc-volume (inc)
  "Increment the current volume by INC."
  (interactive "p")
  (when mpdmacs-mode
    (mpdmacs--modify-volume inc)))

(defun mpdmacs-dec-volume (dec)
  "Decrement the current volume by DEC."
  (interactive "p")
  (when mpdmacs-mode
    (mpdmacs--modify-volume (- dec))))

(defun mpdmacs-load-playlist (playlist)
  "Load PLAYLIST into the queue."
  (interactive
   (list
    (completing-read "Playlist: " mpdmacs--stored-playlists nil 'confirm)))
  (when mpdmacs-mode
    (mpdmacs-send (format "load \"%s\"" playlist))))

(defmacro mpdmacs--def-player-opts-viewer (attr)
  "Define a function retrieving player option ATTR."
  `(defun ,(intern (format "mpdmacs-get-%s" attr)) ()
     (interactive)
     (when mpdmacs-mode
       (let ((val (alist-get (quote ,attr) mpdmacs--player-options)))
         (if (called-interactively-p 'interactive)
             (message "%s: %s" (quote ,attr) val))
         val))))

(mpdmacs--def-player-opts-viewer repeat)
(mpdmacs--def-player-opts-viewer random)
(mpdmacs--def-player-opts-viewer single)
(mpdmacs--def-player-opts-viewer consume)
(mpdmacs--def-player-opts-viewer state)
(mpdmacs--def-player-opts-viewer crossfade)
(mpdmacs--def-player-opts-viewer replay-gain-mode)
(mpdmacs--def-player-opts-viewer volume)

(defmacro mpdmacs--def-player-opts-toggle (attr)
  "Define a function toggling a player option ATTR."
  `(defun ,(intern (format "mpdmacs-toggle-%s" attr)) ()
     (interactive)
     (when mpdmacs-mode
       (let ((val (alist-get (quote ,attr) mpdmacs--player-options)))
         (if (eq val 'unknown)
             (user-error ,(format "Can't toggle %s when the player is stopped" attr))
           (mpdmacs-send (format ,(format "%s %%s" attr) (if val "0" "1"))
                         (lambda (_conn ok text)
                           (if ok
                               (message ,(format "%s mode is %%s." attr) (if val "off" "on"))
                             (mpdmacs-log 'error?,(format "Failed to turn %%s %s mode: %%s" attr)
                                          (if val "off" "on") text)))))))))

(mpdmacs--def-player-opts-toggle repeat)
(mpdmacs--def-player-opts-toggle random)
(mpdmacs--def-player-opts-toggle consume)

(defun mpdmacs-set-crossfade (arg)
  "Set crossfading between songs to ARG, in seconds."
  (interactive "NCrossfade (sec): ")
  ;; We could validate ARG here, but I'd prefer to ask forgiveness
  ;; than permission (i.e. let's just send the value on to MPD & let
  ;; the server validate the argument, rather than do it here & perhaps
  ;; get it wrong).
  (when mpdmacs-mode
    (mpdmacs-send
     (format "crossfade %d" arg)
     (lambda (_conn ok text)
       (if ok
           (message "Crossfade is now %d seconds." arg)
         (mpdmacs-log 'error (format "Failed to set crossfade to %d: %s" arg text)))))))

(defun mpdmacs--single-to-string (x)
  "Convert X to text."
  (cond
   ((not x) "0")
   ((eq x 'oneshot) "oneshot")
   (t "1")))

(defun mpdmacs-rotate-single ()
  "Rotate single mode from off to on to oneshot."
  (interactive)
  (when mpdmacs-mode
    (let* ((curr (mpdmacs-get-single))
           (single
            (cond
             ((eq curr 'oneshot) nil)
             ((not curr) t)
             (t 'oneshot))))
      (mpdmacs-send
       (format "single %s" (mpdmacs--single-to-string single))
       (lambda (_conn ok text)
         (if ok
             (message "Single is now %s." single)
           (mpdmacs-log 'error "Failed to set single to %s: %s" single text)))))))

(defun mpdmacs--replay-gain-mode-to-string (x)
  "Convert X to text."
  (cond
   ((eq x 'off) "off")
   ((eq x 'track) "track")
   ((eq x 'album) "album")
   ((eq x 'auto) "auto")
   (t "unknown")))

(defun mpdmacs-rotate-replay-gain ()
  "Rotate replay gain mode among off, track, album & auto."
  (interactive)
  (when mpdmacs-mode
    (let* ((curr (mpdmacs-get-replay-gain-mode))
           (mode
            (cond
             ((eq curr 'off) 'track)
             ((eq curr 'track) 'album)
             ((eq curr 'album) 'auto)
             ((eq curr 'auto) 'off)
             (t (user-error "Current replay gain mode is unknown")))))
      (mpdmacs-send
       (format "replay_gain_mode %s" (mpdmacs--replay-gain-mode-to-string mode))
       (lambda (_conn ok text)
         (if ok
             (message "Replay gain mode is now %s." mode)
           (mpdmacs-log 'error "Failed to set replay gain mode to %s: %s" mode text)))))))

(defun mpdmacs-toggle-pause ()
  "Toggle the MPD server pause status.

Pause is handled differently since we can toggle at the protocol
level (i.e. we don't have to say \"pause 0\" or \"pause 1\")."
  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send "pause")))

(defun mpdmacs-current-song-buffer ()
  "Return the `mpdmacs' current song buffer, creating it if need be."
  (let ((buffer (get-buffer mpdmacs-current-song-buffer)))
    (if buffer
        buffer
      (with-current-buffer (generate-new-buffer mpdmacs-current-song-buffer)
        (special-mode)
        (current-buffer)))))

(defun mpdmacs-show-current-song ()
  "Display information about the current song."

  (interactive)
  (when mpdmacs-mode
    (mpdmacs-send
     "currentsong"
     (lambda (_conn ok text)
       (if (not ok)
           (error "Failed to retrieve current song: %s" text)
         (let ((inhibit-read-only t))
           (with-current-buffer (mpdmacs-current-song-buffer)
             (goto-char (point-max))
             (insert (concat (propertize (make-string 70 ?~) 'face 'all-the-icons-pink) "\n"))
             (insert text)
             (run-hooks 'mpdmacs-show-current-song-hook)
             (switch-to-buffer (mpdmacs-current-song-buffer)))))))))

(provide 'mpdmacs)

;;; mpdmacs.el ends here
