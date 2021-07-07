;;; gnome-screencast.el --- Use Gnome screen recording functionality using elisp  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2021  Jürgen Hötzel

;; Version: 1.2
;; Package-Version: 20210125.2001
;; Package-Commit: 6450ee470e84ff14a15c5c3c0489c79ff593f165
;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; Keywords: tools, multimedia
;; Package-Requires: ((emacs "25"))
;; URL: https://github.com/juergenhoetzel/emacs-gnome-screencast

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

;; Gnome screen recording integration in Emacs

;;; Code:

(require 'dbus)


(defun gnome-screencast-available-p ()
  "Return t if Gnome Screencast is available."
  (dbus-ping :session "org.gnome.Shell.Screencast"))

(defun gnome-screencast--make-options (&optional draw-cursor framerate pipeline)
					; checkdoc-params: (draw-cursor framerate pipeline)
  "Create a dbus dictionary of optional parameters."
  (let ((options `((:dict-entry "draw-cursor" (:variant :boolean ,draw-cursor)))))
    (when framerate
      (push `(:dict-entry "framerate" (:variant :int32 ,framerate)) options))
    (when pipeline
      (push `(:dict-entry "pipeline" (:variant :string ,pipeline)) options))
    options))

;;;###autoload
(defun gnome-screencast (prefix &optional draw-cursor framerate pipeline)
  "Records a screencast.
PREFIX specifies the template for the filename to use.  The set of
optional parameters consists of:

DRAW-CURSOR Whether the cursor should be included (nil)
FRAMERATE   The number of frames per second that should be recorded (30)
PIPELINE    The GStreamer pipeline used to encode recordings

Returns the filename of the screencast or nil if the start of recording failed."
  (interactive "sTemplate filename: ")
  (pcase (dbus-call-method
	  :session "org.gnome.Shell.Screencast"
	  "/org/gnome/Shell/Screencast"
	  "org.gnome.Shell.Screencast"
	  "Screencast"
	  prefix
	  (gnome-screencast--make-options draw-cursor framerate pipeline))
    (`(t ,filename) filename)))

(defun gnome-screencast-area
    (prefix x y width height &optional draw-cursor framerate pipeline)
					; checkdoc-params: (prefix draw-cursor framerate pipeline)"
  "Record a screencast.
X and Y specifies coordinates of the area to capture, WIDTH and HEIGHT
specifies area to capture.

The other arguments have the same meaning as with `gnome-screencast'."
  (pcase (dbus-call-method
	  :session "org.gnome.Shell.Screencast"
	  "/org/gnome/Shell/Screencast"
	  "org.gnome.Shell.Screencast"
	  "ScreencastArea"
	  :int32 x :int32 y :int32 width :int32 height
	  prefix
	  (gnome-screencast--make-options draw-cursor framerate pipeline))
    (`(t ,filename) filename)))

(defun gnome-screencast-stop ()
  "Stop the recording.
Recording may be started by either `gnome-screencast' or `gnome-screencast-area'."
  (interactive)
  (dbus-call-method
   :session "org.gnome.Shell.Screencast"
   "/org/gnome/Shell/Screencast"
   "org.gnome.Shell.Screencast"
   "StopScreencast"))

(provide 'gnome-screencast)
;;; gnome-screencast.el ends here
