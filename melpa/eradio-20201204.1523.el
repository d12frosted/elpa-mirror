;;; eradio.el --- A simple Internet radio player                       -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Olav Fosse

;; Author: Olav Fosse <mail@olavfosse.no>
;; Version: 0.1
;; Package-Version: 20201204.1523
;; Package-Commit: 357f473ba8d280b4ab4763521220079401ad3093
;; URL: https://github.com/olav35/eradio
;; Package-Requires: ((emacs "24.1"))

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

;; A simple Internet radio player

;;; Code:

;;;###autoload
(defcustom eradio-channels '()
  "Eradio's radio channels."
  :type '(repeat (cons (string :tag "Name") (string :tag "URL")))
  :group 'eradio)

(defcustom eradio-player '("vlc" "--no-video" "-I" "rc")
  "Eradio's player.
This is a list of the program and its arguments.  The url will be appended to the list to generate the full command."
  :type '(choice
	  (const :tag "vlc"
		 ("vlc" "--no-video" "-I" "rc"))
	  (const :tag "vlc-mac"
		 ("/Applications/VLC.app/Contents/MacOS/VLC" "--no-video" "-I" "rc"))
	  (const :tag "mpv"
		 ("mpv" "--no-video" "--no-terminal")))
  :group 'eradio)

(defvar eradio--process nil "The process running the radio player.")

(defun eradio-alist-keys (alist)
  "Get the keys from an ALIST."
  (mapcar #'car alist))

(defun eradio-stop ()
  "Stop the radio player."
  (interactive) (when eradio--process (delete-process eradio--process)))

(defun eradio-play-low-level (url)
  "Play radio channel URL in a new process."
  (setq eradio--process
	(apply #'start-process
	       `("eradio--process" nil ,@eradio-player ,url))))

(defun eradio-get-url ()
  "Get a radio channel URL from the user."
  (let ((eradio-channel (completing-read
                       "Channel: "
                       (eradio-alist-keys eradio-channels)
                       nil nil)))
  (or (cdr (assoc eradio-channel eradio-channels)) eradio-channel)))

;;;###autoload
(defun eradio-play ()
  "Play a radio channel, do what I mean."
  (interactive)
  (eradio-stop)
  (let ((url (eradio-get-url)))
    (eradio-play-low-level url)))

(provide 'eradio)
;;; eradio.el ends here
