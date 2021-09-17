;;; audacious.el --- Emacs interface to control audacious

;; Copyright (C) 2021 Hitoshi Uchida <hitoshi.uchida@gmail.com>

;; Author: Hitoshi Uchida <hitoshi.uchida@gmail.com>
;; Version: 1.0
;; Package-Version: 20210917.51
;; Package-Commit: 65c37f12a5c774a0ae434beee27ff7737006dd2f
;; Package-Requires: ((helm "3.6.2") (emacs "24.4"))
;; URL: https://github.com/shishimaru/audacious.el

;; This program is free software: you can redistribute it and/or modify
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
;;
;; audacious.el is an Emacs package to control the playback functions
;; of a music player, audacious.  It depends on a command audtool
;; installed with audacious.

;;; Code:

(require 'helm)

(defvar audacious-msg "" "Stores a message string.")
(defvar audacious-playlist-position nil "An index number of a playlist.")
(defvar audacious-playlist-length nil "A length of a playlist.")
(defvar audacious-playlist-name nil "A name of a playlist.")
(defvar audacious-song-title nil "A name of a song.")
(defvar audacious-song-position nil "An index number of a song.")
(defvar audacious-song-length nil "A length of a song.")

(defcustom audacious-command (executable-find "audtool")
  "CL interface of audacious."
  :type 'string
  :group 'audacious)

(defun audacious-run ()
  "Launch audacious with headless mode as daemon."
  (interactive)
  (call-process "audacious" nil 0 nil "-H" "2>/dev/null"))

(defun audacious-kill ()
  "Shutdown audacious process."
  (interactive)
  (when (yes-or-no-p "Quit Audacious ?")
    (call-process audacious-command nil 0 nil "--shutdown")))

(defun audacious-volume (vol)
  "Manually increase / decrease the volume by the specified VOL percent."
  (interactive "M[+|-]percent: ")
  (call-process audacious-command nil nil nil "--set-volume" vol))

(defun audacious-volume-up ()
  "Increase the volume by 10%."
  (interactive)
  (call-process audacious-command nil nil nil "--set-volume" "+10%")
  (message "%s" (string-trim (shell-command-to-string "audtool --get-volume"))))

(defun audacious-volume-down ()
  "Decrease the volume by 10%."
  (interactive)
  (call-process audacious-command nil nil nil "--set-volume" "-10%")
  (message "%s" (string-trim (shell-command-to-string "audtool --get-volume"))))

(defun audacious-play ()
  "Start to play."
  (interactive)
  (if (string-equal (shell-command-to-string "audtool --playback-status") "")
      (audacious-run))
  (call-process audacious-command nil nil nil "--playback-play")
  (sleep-for 0 20)
  (audacious-song-show-current-info))

(defun audacious-pause ()
  "Pause the playback."
  (interactive)
  (call-process audacious-command nil nil nil "--playback-pause")
  (audacious-status))

(defun audacious-stop ()
  "Stop the playback."
  (interactive)
  (call-process audacious-command nil nil nil "--playback-stop"))

(defun audacious-status ()
  "Show the current status of audacious."
  (interactive)
  (message "%s" (string-trim (shell-command-to-string "audtool --playback-status"))))

(defun audacious-song-next ()
  "Play the next song in the current playlist."
  (interactive)
  (call-process audacious-command nil nil nil "--playlist-advance")
  (sleep-for 0 20)
  (audacious-song-show-current-info))

(defun audacious-song-prev ()
  "Play the previous song in the current playlist."
  (interactive)
  (call-process audacious-command nil nil nil "--playlist-reverse")
  (sleep-for 0 20)
  (audacious-song-show-current-info))

(defun audacious-song-goto ()
  "Select a song with an inputted number."
  (interactive)
  (dolist (line (split-string (shell-command-to-string "audtool --playlist-display") "\n"))
    (if (string-match-p (regexp-quote "|") line)
        (setq audacious-msg (concat audacious-msg line "\n"))))
  (setq audacious-song-position (read-string (concat audacious-msg "Song No.: ")))
  (if (audacious-string-integer-p audacious-song-position)
    (progn
      (call-process audacious-command nil nil nil "--playlist-jump" audacious-song-position)
      (sleep-for 0 20)
      (audacious-song-show-current-info))
    (message "\"%s\" is not number." audacious-song-position)))

(defun audacious-song-goto-helm ()
  "Select a song with helm interface."
  (interactive)
  (let ((title (helm :sources (helm-build-sync-source "audacious"
                                :candidates (butlast (butlast (cdr (split-string (shell-command-to-string "audtool --playlist-display") "\n"))))
                                :fuzzy-match nil)
                     :buffer "*helm audacious*")))
    (if title
        (progn
          (setq audacious-song-position (string-trim (car (split-string title "|"))))
          (call-process audacious-command nil nil nil "--playlist-jump" audacious-song-position)
          (sleep-for 0 20)
          (audacious-song-show-current-info)))))

(defun audacious-song-seek (time)
  "Seek the song by TIME in seconds."
  (interactive "MSeek +- sec: ")
  (call-process audacious-command nil nil nil "--playback-seek-relative" time))

(defun audacious-song-seek-backward ()
  "Seek backward by 10 seconds."
  (interactive)
  (call-process audacious-command nil nil nil "--playback-seek-relative" "-10")
  (audacious-song-show-current-info))

(defun audacious-song-seek-forward ()
  "Seek forward by 10 seconds."
  (interactive)
  (call-process audacious-command nil nil nil "--playback-seek-relative" "+10")
  (audacious-song-show-current-info))

(defun audacious-song-show-current-info ()
  "Show information of the current song."
  (interactive)
  (setq audacious-playlist-position (string-trim (shell-command-to-string "audtool --playlist-position")))
  (setq audacious-playlist-length (string-trim (shell-command-to-string "audtool --playlist-length")))
  (setq audacious-song-title (string-trim (shell-command-to-string "audtool --current-song")))
  (setq audacious-song-position (string-trim (shell-command-to-string "audtool --current-song-output-length")))
  (setq audacious-song-length (string-trim (shell-command-to-string "audtool --current-song-length")))
  (message "[%s/%s]: %s [%s / %s]" audacious-playlist-position audacious-playlist-length audacious-song-title audacious-song-position audacious-song-length))

(defun audacious-random-toggle ()
  "Toggle the random playback."
  (interactive)
  (if (string-match "off" (shell-command-to-string "audtool --playlist-shuffle-status"))
    (message "Random: ON")
    (message "Random: OFF"))
  (call-process audacious-command nil nil nil "--playlist-shuffle-toggle"))

(defun audacious-repeat-toggle ()
  "Toggle the repeat playback."
  (interactive)
  (if (string-match "off" (shell-command-to-string "audtool --playlist-repeat-status"))
    (message "Repeat: ON")
    (message "Repeat: OFF"))
  (call-process audacious-command nil nil nil "--playlist-repeat-toggle"))

(defun audacious-playlist ()
  "Show the songs of the current playlist."
  (interactive)
  (setq audacious-msg "")
  (dolist (line (split-string (shell-command-to-string "audtool --playlist-display") "\n"))
    (if (string-match-p (regexp-quote "|") line)
        (setq audacious-msg (concat audacious-msg line "\n"))))
  (message "%s" audacious-msg))

(defun audacious-playlist-show-current-info ()
  "Show the name of the current playlist."
  (interactive)
  (setq audacious-playlist-name (string-trim (shell-command-to-string "audtool --current-playlist-name")))
  (setq audacious-playlist-position (string-trim (shell-command-to-string "audtool --current-playlist")))
  (setq audacious-playlist-length (string-trim (shell-command-to-string "audtool --number-of-playlists")))
  (message "[%s/%s] \"%s\"" audacious-playlist-position audacious-playlist-length audacious-playlist-name))

(defun audacious-playlist--goto (num)
  "Select a playlist by NUM."
  (call-process audacious-command nil nil nil "--set-current-playlist" num)
  (sleep-for 0 20)
  (call-process audacious-command nil nil nil "--play-current-playlist")
  (audacious-playlist-show-current-info))

(defun audacious-playlist-goto ()
  "Select a playlist with an inputted number."
  (interactive)
  (setq audacious-playlist-length (string-trim (shell-command-to-string "audtool --number-of-playlists")))
  (setq audacious-playlist-position (read-string (format "Playlist No. [1 - %s]: " audacious-playlist-length)))
  (if (not (audacious-string-integer-p audacious-playlist-position))
      (message "\"%s\" is not number." audacious-playlist-position)
    (call-process audacious-command nil nil nil "--set-current-playlist" audacious-playlist-position)
    (sleep-for 0 20)
    (call-process audacious-command nil nil nil "--play-current-playlist")
    (audacious-playlist-show-current-info)))

(defun audacious-playlist-next ()
  "Select a next playlist."
  (interactive)
  (setq audacious-playlist-name (string-trim (shell-command-to-string "audtool --current-playlist-name")))
  (setq audacious-playlist-position (string-to-number (string-trim (shell-command-to-string "audtool --current-playlist"))))
  (setq audacious-playlist-length (string-to-number (string-trim (shell-command-to-string "audtool --number-of-playlists"))))

  (let ((next-playlist-position (+ audacious-playlist-position 1)))
    (if (> next-playlist-position audacious-playlist-length)
        (message "Last playlist")
      (audacious-playlist--goto (number-to-string next-playlist-position))
      (message "[%s/%s] \"%s\"" audacious-playlist-position audacious-playlist-length audacious-playlist-name)
      (sit-for 2)
      (audacious-song-show-current-info))))

(defun audacious-playlist-prev ()
  "Select a previous playlist."
  (interactive)
  (setq audacious-playlist-name (string-trim (shell-command-to-string "audtool --current-playlist-name")))
  (setq audacious-playlist-position (string-to-number (string-trim (shell-command-to-string "audtool --current-playlist"))))
  (setq audacious-playlist-length (string-to-number (string-trim (shell-command-to-string "audtool --number-of-playlists"))))
  (let ((next-playlist-position (- audacious-playlist-position 1)))
    (if (< next-playlist-position 1)
        (message "First playlist")
      (audacious-playlist--goto (number-to-string next-playlist-position))
      (message "[%s/%s] \"%s\"" next-playlist-position audacious-playlist-length audacious-playlist-name)
      (sit-for 2)
      (audacious-song-show-current-info))))

(defun audacious-string-integer-p (string)
  "Test the STRING is number or not."
  (if (string-match "\\`[-+]?[0-9]+\\'" string)
      t
    nil))

(provide 'audacious)
;;; audacious.el ends here
