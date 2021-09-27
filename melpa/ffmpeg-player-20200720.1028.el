;;; ffmpeg-player.el --- Play video using ffmpeg  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-11-20 13:28:20

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Play video using ffmpeg.
;; Keyword: video ffmpeg buffering images
;; Version: 0.2.1
;; Package-Version: 20200720.1028
;; Package-Commit: 3d524dd404862de1a40ec5834cc1b85137a1acd2
;; Package-Requires: ((emacs "24.4") (s "1.12.0") (f "0.20.0"))
;; URL: https://github.com/jcs-elpa/ffmpeg-player

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Play video using ffmpeg.
;;

;;; Code:

(require 'f)
(require 's)
(require 'subr-x)

(defgroup ffmpeg-player nil
  "Play video using ffmpeg."
  :prefix "ffmpeg-player-"
  :group 'tool
  :link '(url-link :tag "Github" "https://github.com/jcs-elpa/ffmpeg-player"))

(defcustom ffmpeg-player-buffer-name "*ffmpeg-player*: %s"
  "Buffer name of the video player."
  :type 'string
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-display-width 864
  "Display width."
  :type 'integer
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-display-height 486
  "Display height."
  :type 'integer
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-loop t
  "Loop when the video end."
  :type 'boolean
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-image-prefix "snap"
  "Prefix when output images."
  :type 'string
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-image-extension "jpg"
  "Image extension when output from ffmpeg."
  :type 'string
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-fixed-id "%09d"
  "Fixed id for the images."
  :type 'string
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-mode-hook nil
  "Hook called by `ffmpeg-player-mode'."
  :type 'hook
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-no-message nil
  "No message print out when using video buffer."
  :type 'boolean
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-before-insert-image-hook nil
  "Hook called before inserting image."
  :type 'hook
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-after-insert-image-hook nil
  "Hook called after inserting image."
  :type 'hook
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-before-insert-string-hook nil
  "Hook called before inserting string."
  :type 'hook
  :group 'ffmpeg-player)

(defcustom ffmpeg-player-after-insert-string-hook nil
  "Hook called after inserting string."
  :type 'hook
  :group 'ffmpeg-player)

(defconst ffmpeg-player--command-video-to-images
  "ffmpeg -i %s %s \"%s%s%s.%s\""
  "Command that convert video to image source.")

(defconst ffmpeg-player--command-play-audio
  "ffplay %s %s"
  "Command that convert video to audio source.")

(defconst ffmpeg-player--as-video-buffer-name "*Async Shell Command*: Video"
  "Name of the async shell buffer for video output.")

(defconst ffmpeg-player--as-audio-buffer-name "*Async Shell Command*: Audio"
  "Name of the async shell buffer for audio output.")

(defvar ffmpeg-player--img-dir ""
  "Current image directory.")

(defvar ffmpeg-player--img-dir-index 0
  "Current image directory index to point to `ffmpeg-player--img-dir-lst'.")

(defvar ffmpeg-player--img-dir-lst
  (list (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-0/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-1/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-2/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-3/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-4/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-5/"))
        (expand-file-name (format "%s%s" user-emacs-directory "ffmpeg-player/images-6/")))
  "List of image directories so we can split the delete directory processes.")

(defvar ffmpeg-player--current-path ""
  "Record of the current video path.")

(defvar ffmpeg-player--pause nil
  "Flag for pausing video.")

(defvar ffmpeg-player--frame-regexp nil
  "Frame regular expression for matching length.")

(defvar ffmpeg-player--current-duration 0.0 "Current video length/duration.")

(defvar ffmpeg-player--current-fps 0.0 "Current FPS that are being used.")
(defvar ffmpeg-player--first-frame-time 0.2 "Time to check if the first frame exists.")
(defvar ffmpeg-player--buffer-time 0.0 "Time to update buffer frame, calculate with FPS.")

(defvar ffmpeg-player--video-timer 0.0 "Time to record delta time.")

(defvar ffmpeg-player--last-time 0.0
  "Record last time for each frame, used for calculate delta time.")
(defvar ffmpeg-player--delta-time 0.0
  "Record delta time for each frame.")

(defvar ffmpeg-player--frame-index 0 "Current frame index/counter.")

(defvar ffmpeg-player--first-frame-timer nil "Timer that find out the first frame.")

(defvar ffmpeg-player--buffer nil "Buffer that displays video.")
(defvar ffmpeg-player--buffer-timer nil "Timer that will update the image buffer.")

(defvar ffmpeg-player--resolve-clip-info-timer nil "Timer that tries to resolve FPS.")
(defvar ffmpeg-player--resolve-clip-info-time 0.2 "Time to check if fps could be resolved.")

(defvar ffmpeg-player--mute nil "Flag to check if nil.")
(defvar ffmpeg-player--volume 75 "Current audio volume.")

;;; Command

(defun ffmpeg-player--form-command-list (lst)
  "Form the command by LST."
  (let ((output ""))
    (dolist (cmd lst)
      (setq output (concat output cmd " ")))
    output))

(defun ffmpeg-player--form-command-video (path source)
  "From the command for video by needed parameters.
PATH is the input video file.  SOURCE is the output image directory."
  (format ffmpeg-player--command-video-to-images
          (shell-quote-argument path)
          (ffmpeg-player--form-command-list
           (list (format "-filter:v \"scale=w=%s:h=%s\""  ; Width & Height
                         (ceiling ffmpeg-player-display-width)
                         (ceiling ffmpeg-player-display-height))))
          source
          ffmpeg-player-image-prefix
          ffmpeg-player-fixed-id
          ffmpeg-player-image-extension))

(defun ffmpeg-player--form-command-audio (path time volume)
  "From the command for audio by needed parameters.
PATH is the input audio/video file.  TIME is the start time.
VOLUME of the sound from 0 ~ 100."
  (format ffmpeg-player--command-play-audio
          (shell-quote-argument path)
          (ffmpeg-player--form-command-list
           (list "-nodisp"  ; Don't display
                 (format "-ss %s" time)
                 (format "-volume %s" volume)))))

;;; Util

(defun ffmpeg-player--message (fmt &rest args)
  "Message FMT and ARGS."
  (unless ffmpeg-player-no-message
    (apply #'message fmt args)))

(defun ffmpeg-player--inhibit-sentinel-messages (fun &rest args)
  "Inhibit messages in all sentinels started by FUN with ARGS."
  (cl-letf* ((old-set-process-sentinel (symbol-function 'set-process-sentinel))
             ((symbol-function 'set-process-sentinel)
              (lambda (process sentinel)
                (funcall
                 old-set-process-sentinel
                 process
                 `(lambda (&rest args)
                    (cl-letf (((symbol-function 'message) #'ignore))
                      (apply (quote ,sentinel) args)))))))
    (apply fun args)))

(defun ffmpeg-player--round-to-digit (val digit)
  "Round VAL to DIGIT."
  (let ((ten-digit (expt 10.0 digit)))
    (/ (ceiling (* val ten-digit)) ten-digit)))

(defun ffmpeg-player--count-windows ()
  "Total window count."
  (let ((count 0))
    (dolist (fn (frame-list))
      (setq count (+ (length (window-list fn)) count)))
    count))

(defun ffmpeg-player--walk-through-all-windows-once (fnc)
  "Walk through all the windows once and execute callback FNC."
  (save-selected-window
    (let ((cur-frame (selected-frame)) (index 0))
      (while (< index (ffmpeg-player--count-windows))
        (when fnc (funcall fnc))
        (other-window 1 t)
        (setq index (+ index 1)))
      (select-frame-set-input-focus cur-frame))))

(defun ffmpeg-player--bury-buffer (buf-name)
  "Bury BUF-NAME by walking through all the windows."
  ;; NOTE: Regular `walk-windows' function wouldn't work.
  ;; TBH, I don't know why.
  (ffmpeg-player--walk-through-all-windows-once
   (lambda ()
     (when (string= (buffer-name) buf-name)
       (bury-buffer)))))

(defun ffmpeg-player--safe-path (path)
  "Check if safe PATH."
  (unless (file-exists-p path) (setq path (expand-file-name path)))
  (if (file-exists-p path) path nil))

(defun ffmpeg-player--ensure-video-directory-exists ()
  "Ensure the video directory exists so we can put our image files."
  (unless (file-directory-p ffmpeg-player--img-dir)
    (make-directory ffmpeg-player--img-dir t)))

(defun ffmpeg-player--async-delete-directory (path)
  "Async delete directory by PATH."
  (let ((command (car command-line-args)))
    (start-process "ffmpeg-player--async-delete-directory"
                   nil command "-Q" "--batch" "--eval"
                   (format "(delete-directory %s t)" (shell-quote-argument path)))))

(defun ffmpeg-player--clean-video-images ()
  "Clean up current video images."
  (unless (string-empty-p ffmpeg-player--img-dir)
    (ffmpeg-player--async-delete-directory ffmpeg-player--img-dir)))

;;; Buffer

(defun ffmpeg-player--buffer-name (path)
  "Return current ffmpeg play buffer name by PATH."
  (format ffmpeg-player-buffer-name (f-filename path)))

(defun ffmpeg-player--create-video-buffer (path)
  "Create a new video buffer with PATH."
  (let* ((name (ffmpeg-player--buffer-name path))
         (buf (if (get-buffer name) (get-buffer name) (generate-new-buffer name))))
    (setq ffmpeg-player--buffer buf)
    (with-current-buffer buf (ffmpeg-player-mode))
    (ffmpeg-player--update-frame-by-string "[Nothing to display yet...]")
    buf))

(defun ffmpeg-player--buffer-alive-p ()
  "Check if the video buffer alive."
  (buffer-name (get-buffer ffmpeg-player--buffer)))

;;; Delta Time

(defun ffmpeg-player--calc-delta-time ()
  "Calculate the delta time."
  (if ffmpeg-player--pause
      (setq ffmpeg-player--delta-time 0.0)
    (setq ffmpeg-player--delta-time (- (float-time) ffmpeg-player--last-time)))
  (setq ffmpeg-player--last-time (float-time)))

;;; Clip Info

(defun ffmpeg-player--set-resolve-clip-info-timer ()
  "Set the resolve clip information timer task."
  (ffmpeg-player--kill-resolve-clip-info-timer)
  (setq ffmpeg-player--resolve-clip-info-timer
        (run-with-timer ffmpeg-player--resolve-clip-info-time nil #'ffmpeg-player--check-resolve-clip-info)))

(defun ffmpeg-player--kill-resolve-clip-info-timer ()
  "Kill the resolve clip information timer."
  (when (timerp ffmpeg-player--resolve-clip-info-timer)
    (cancel-timer ffmpeg-player--resolve-clip-info-timer)
    (setq ffmpeg-player--resolve-clip-info-timer nil)))

(defun ffmpeg-player--video-shell-output-p ()
  "Check if output available."
  (save-window-excursion
    (switch-to-buffer (get-buffer ffmpeg-player--as-video-buffer-name))
    (not (string-empty-p (buffer-string)))))

(defun ffmpeg-player--get-fps ()
  "Get the FPS from async shell command output buffer."
  (with-current-buffer (get-buffer ffmpeg-player--as-video-buffer-name)
    (goto-char (point-min))
    (let ((end-pt -1))
      (search-forward "fps,")
      (search-backward " ")
      (setq end-pt (1- (point)))
      (search-backward " ")
      (substring (buffer-string) (point) end-pt))))

(defun ffmpeg-player--get-duration ()
  "Get the duration from async shell command output buffer."
  (with-current-buffer (get-buffer ffmpeg-player--as-video-buffer-name)
    (goto-char (point-min))
    (search-forward "Duration: ")
    (let ((start-pt (1- (point))))
      (search-forward ",")
      (substring (buffer-string) start-pt (- (point) 2)))))

(defun ffmpeg-player--string-to-number-time (str-time)
  "Convert STR-TIME to number time."
  (let* ((split-time (split-string str-time ":"))
         (time-arg (1- (length split-time)))
         (float-time 0.0))
    (dolist (st split-time)
      (setq st (string-to-number st))
      (setq float-time (+ float-time (* st (expt 60 time-arg))))
      (setq time-arg (1- time-arg)))
    float-time))

(defun ffmpeg-player--number-to-string-time (time)
  "Convert TIME to string time."
  (let* ((hr 0.0) (min 0.0) (sec 0.0) (ms 0.0)
         (time-arg 2) (unit-time 0.0) (unit-product 0))
    (while (not (= -2 time-arg))
      (setq unit-time (expt 60 time-arg))
      (cond ((= time-arg 2)
             (setq hr (floor (/ time unit-time)))
             (setq unit-product hr))
            ((= time-arg 1)
             (setq min (floor (/ time unit-time)))
             (setq unit-product min))
            ((= time-arg 0)
             (setq sec (floor (/ time unit-time)))
             (setq unit-product sec))
            ((= time-arg -1)
             (setq ms (floor (* time 100)))))
      (setq time (- time (* unit-time unit-product)))
      (setq time-arg (1- time-arg)))
    (format "%02d:%02d:%02d.%02d" hr min sec ms)))

(defun ffmpeg-player--resolve-clip-info ()
  "Resolve clip's information."
  (setq ffmpeg-player--current-duration
        (ffmpeg-player--string-to-number-time (ffmpeg-player--get-duration)))
  (setq ffmpeg-player--current-fps (ffmpeg-player--get-fps))
  (setq ffmpeg-player--current-fps (string-to-number ffmpeg-player--current-fps))
  (setq ffmpeg-player--buffer-time (/ 1.0 ffmpeg-player--current-fps)))

(defun ffmpeg-player--check-resolve-clip-info ()
  "Check if resolved clip information."
  (if (not (ffmpeg-player--video-shell-output-p))
      (progn
        (message "[INFO] Waiting to resolve clip information")
        (ffmpeg-player--set-resolve-clip-info-timer))
    (ffmpeg-player--resolve-clip-info)
    (ffmpeg-player--check-first-frame)))

;;; First frame

(defun ffmpeg-player--set-first-frame-timer ()
  "Set the first frame timer task."
  (ffmpeg-player--kill-first-frame-timer)
  (setq ffmpeg-player--first-frame-timer
        (run-with-timer ffmpeg-player--first-frame-time nil 'ffmpeg-player--check-first-frame)))

(defun ffmpeg-player--kill-first-frame-timer ()
  "Kill the first frame timer.
Information about first frame timer please see variable `ffmpeg-player--first-frame-timer'."
  (when (timerp ffmpeg-player--first-frame-timer)
    (cancel-timer ffmpeg-player--first-frame-timer)
    (setq ffmpeg-player--first-frame-timer nil)))

(defun ffmpeg-player--form-file-extension-regexp ()
  "Form regular expression for search image file."
  (format "\\.%s$" ffmpeg-player-image-extension))

(defun ffmpeg-player--check-first-frame ()
  "Core function to check first frame image is ready."
  (if (f-empty? ffmpeg-player--img-dir)
      (ffmpeg-player--set-first-frame-timer)
    (let ((images (directory-files ffmpeg-player--img-dir nil (ffmpeg-player--form-file-extension-regexp)))
          (first-frame nil))
      (setq first-frame (nth 0 images))
      (setq first-frame (s-replace ffmpeg-player-image-prefix "" first-frame))
      (setq first-frame (s-replace-regexp (ffmpeg-player--form-file-extension-regexp) "" first-frame))
      (setq ffmpeg-player--frame-regexp (format "%s%sd" "%0" (length first-frame)))
      (setq ffmpeg-player--last-time (float-time))  ; Update the first frame time.
      (ffmpeg-player--play-sound-at-current-time)  ; Start the audio
      (ffmpeg-player--update-frame))))

;;; Frame

(defun ffmpeg-player--set-buffer-timer ()
  "Set the buffer timer task."
  (ffmpeg-player--kill-buffer-timer)
  (setq ffmpeg-player--buffer-timer
        (run-with-timer ffmpeg-player--buffer-time nil #'ffmpeg-player--update-frame)))

(defun ffmpeg-player--kill-buffer-timer ()
  "Kill the buffer timer."
  (when (timerp ffmpeg-player--buffer-timer)
    (cancel-timer ffmpeg-player--buffer-timer)
    (setq ffmpeg-player--buffer-timer nil)))

(defun ffmpeg-player--form-frame-filename ()
  "Form the frame filename."
  (format "%s%s.%s"
          ffmpeg-player-image-prefix
          (format ffmpeg-player--frame-regexp ffmpeg-player--frame-index)
          ffmpeg-player-image-extension))

(defun ffmpeg-player--update-frame-by-image-path (path)
  "Update the frame by image PATH."
  (if (not (ffmpeg-player--buffer-alive-p))
      (ffmpeg-player--clean-up)
    (with-current-buffer ffmpeg-player--buffer
      (erase-buffer)
      (run-hooks 'ffmpeg-player-before-insert-image-hook)
      (insert-image-file path)
      (run-hooks 'ffmpeg-player-after-insert-image-hook))))

(defun ffmpeg-player--update-frame-by-string (str)
  "Update the frame by STR."
  (if (not (ffmpeg-player--buffer-alive-p))
      (ffmpeg-player--clean-up)
    (with-current-buffer ffmpeg-player--buffer
      (erase-buffer)
      (run-hooks 'ffmpeg-player-before-insert-string-hook)
      (insert str)
      (run-hooks 'ffmpeg-player-after-insert-string-hook))))

(defun ffmpeg-player--update-frame-index ()
  "Calculate then update the frame index by time."
  ;; Calculate the time passed.
  (setq ffmpeg-player--video-timer (+ ffmpeg-player--video-timer ffmpeg-player--delta-time))
  ;; Calculate the frame index.
  (setq ffmpeg-player--frame-index (ceiling (* ffmpeg-player--current-fps ffmpeg-player--video-timer))))

(defun ffmpeg-player--update-frame-info ()
  "Update display image and audio by timeline."
  (if (ffmpeg-player--done-playing-p)
      (if (not ffmpeg-player-loop)
          (ffmpeg-player--update-frame-by-string "[INFO] Done display...")
        ;; Do loop.
        (ffmpeg-player-replay)
        (ffmpeg-player--set-buffer-timer))
    (let ((frame-file (concat ffmpeg-player--img-dir (ffmpeg-player--form-frame-filename))))
      (if (not (file-exists-p frame-file))
          (ffmpeg-player--update-frame-by-string "[INFO] Frame not ready")
        (ffmpeg-player--update-frame-by-image-path frame-file))
      (ffmpeg-player--set-buffer-timer))))

(defun ffmpeg-player--update-frame ()
  "Core logic to update frame."
  (if (not (ffmpeg-player--buffer-alive-p))
      (progn
        (ffmpeg-player--kill-sound-process)
        (user-error "[WARNING] Display buffer no longer live"))
    (ffmpeg-player--calc-delta-time)
    (ffmpeg-player--update-frame-index)
    (ffmpeg-player--update-frame-info)))

;;; Core

(defun ffmpeg-player--kill-async-shell-buffer ()
  "Kill all async shell buffers."
  (when (get-buffer ffmpeg-player--as-video-buffer-name)
    (kill-buffer (get-buffer ffmpeg-player--as-video-buffer-name)))
  (ffmpeg-player--kill-sound-process))

(defun ffmpeg-player--bury-async-shell-buffer ()
  "Bury all the async shell buffers."
  ;; NOTE: Regular `bury-buffer' wouldn't work.
  (ffmpeg-player--bury-buffer ffmpeg-player--as-video-buffer-name)
  (ffmpeg-player--bury-buffer ffmpeg-player--as-audio-buffer-name))

(defun ffmpeg-player--rename-async-shell (new-name)
  "Rename the async shell output buffer to NEW-NAME."
  (with-current-buffer (get-buffer "*Async Shell Command*")
    (rename-buffer new-name))
  (ffmpeg-player--bury-async-shell-buffer))

(defun ffmpeg-player--done-playing-p ()
  "Check if done playing the clip."
  (<= ffmpeg-player--current-duration
      (ffmpeg-player--round-to-digit ffmpeg-player--video-timer 2)))

(defun ffmpeg-player--kill-display-buffer ()
  "Clean up display buffer."
  (when ffmpeg-player--buffer
    (kill-buffer ffmpeg-player--buffer)
    (setq ffmpeg-player--buffer nil)))

(defun ffmpeg-player--clean-up ()
  "Reset/Clean up some variable before we play a new video."
  (progn  ; Change to new image directory.
    (setq ffmpeg-player--img-dir-index (1+ ffmpeg-player--img-dir-index))
    (setq ffmpeg-player--img-dir-index
          (% ffmpeg-player--img-dir-index (length ffmpeg-player--img-dir-lst)))
    (setq ffmpeg-player--img-dir
          (nth ffmpeg-player--img-dir-index ffmpeg-player--img-dir-lst)))
  (ffmpeg-player--kill-first-frame-timer)
  (ffmpeg-player--kill-resolve-clip-info-timer)
  (ffmpeg-player--kill-buffer-timer)
  (setq ffmpeg-player--current-path "")
  (ffmpeg-player--kill-display-buffer)
  (progn  ; Clean delta time
    (setq ffmpeg-player--last-time 0.0)
    (setq ffmpeg-player--delta-time 0.0))
  (setq ffmpeg-player--video-timer 0.0)
  (setq ffmpeg-player--current-duration 0.0)
  (setq ffmpeg-player--current-fps 0.0)
  (setq ffmpeg-player--frame-index 0)
  (setq ffmpeg-player--frame-regexp nil)
  (progn  ; User settings
    (setq ffmpeg-player--pause nil))
  (ffmpeg-player--kill-async-shell-buffer))

;;;###autoload
(defun ffmpeg-player-clean ()
  "Clean all the data, like images cache."
  (interactive)
  (dolist (cache-dir ffmpeg-player--img-dir-lst)
    (unless (string-empty-p cache-dir)
      (ffmpeg-player--async-delete-directory cache-dir))))

;;;###autoload
(defun ffmpeg-player-video (path)
  "Play the video with PATH."
  (setq path (ffmpeg-player--safe-path path))
  (if (not path)
      (user-error "[ERROR] Input video file doesn't exists: %s" path)
    (ffmpeg-player--clean-video-images)
    (ffmpeg-player--clean-up)
    (ffmpeg-player--ensure-video-directory-exists)
    (setq ffmpeg-player--current-path path)
    (progn  ; Extract video
      (ffmpeg-player--inhibit-sentinel-messages
       #'async-shell-command
       (ffmpeg-player--form-command-video path ffmpeg-player--img-dir))
      (ffmpeg-player--rename-async-shell ffmpeg-player--as-video-buffer-name)
      (ffmpeg-player--create-video-buffer path))
    (switch-to-buffer-other-window ffmpeg-player--buffer)
    (ffmpeg-player--check-resolve-clip-info)))

;;; Sound

(defun ffmpeg-player--kill-sound-process ()
  "Kill the current sound process if available."
  (when (get-buffer ffmpeg-player--as-audio-buffer-name)
    (kill-buffer (get-buffer ffmpeg-player--as-audio-buffer-name))))

(defun ffmpeg-player--play-sound (&optional time)
  "Play the sound at the TIME."
  (cond ((not time) (setq time "00:00:00.0"))  ; Default to 00:00:00.0
        ((or (floatp time) (integerp time))
         (setq time (ffmpeg-player--number-to-string-time time))))
  (if (string-empty-p ffmpeg-player--current-path)
      (user-error "[ERROR] Can't play with this path: %s" ffmpeg-player--current-path)
    (ffmpeg-player--kill-sound-process)
    (ffmpeg-player--inhibit-sentinel-messages
     #'async-shell-command
     (ffmpeg-player--form-command-audio ffmpeg-player--current-path
                                        time
                                        ffmpeg-player--volume))
    (ffmpeg-player--rename-async-shell ffmpeg-player--as-audio-buffer-name)))

(defun ffmpeg-player--play-sound-at-current-time ()
  "Play the sound at current timeline."
  (when (and (not ffmpeg-player--pause) (not ffmpeg-player--mute))
    (ffmpeg-player--play-sound ffmpeg-player--video-timer)))

(defun ffmpeg-player-mute-or-unmute ()
  "Mute/Unmute the sound."
  (interactive)
  (if ffmpeg-player--mute (ffmpeg-player-unmute) (ffmpeg-player-mute)))

(defun ffmpeg-player-unmute ()
  "Unmute the sound."
  (interactive)
  (setq ffmpeg-player--mute nil)
  (ffmpeg-player--play-sound-at-current-time)
  (ffmpeg-player--message "[INFO] Unmute audio"))

(defun ffmpeg-player-mute ()
  "Mute the sound."
  (interactive)
  (setq ffmpeg-player--mute t)
  (ffmpeg-player--kill-sound-process)
  (ffmpeg-player--message "[INFO] Mute audio"))

(defun ffmpeg-player--move-volume (n)
  "Move audio volume by N value."
  (setq ffmpeg-player--volume (+ ffmpeg-player--volume n))
  (cond ((< ffmpeg-player--volume 0)
         (setq ffmpeg-player--volume 0))
        ((> ffmpeg-player--volume 100)
         (setq ffmpeg-player--volume 100)))
  (ffmpeg-player--play-sound-at-current-time)
  (ffmpeg-player--message "[INFO] Current audio: %s" ffmpeg-player--volume))

(defun ffmpeg-player-volume-dec-5 ()
  "Decrease volume by 5."
  (interactive)
  (ffmpeg-player--move-volume -5))

(defun ffmpeg-player-volume-inc-5 ()
  "Increase volume by 5."
  (interactive)
  (ffmpeg-player--move-volume 5))

;;; Mode

(defun ffmpeg-player-replay ()
  "Play video from the start."
  (interactive)
  (setq ffmpeg-player--video-timer 0.0)
  (ffmpeg-player-unpause)
  (ffmpeg-player--message "[INFO] Replaying '%s'" ffmpeg-player--current-path))

(defun ffmpeg-player-unpause ()
  "Unpause the video."
  (interactive)
  (setq ffmpeg-player--pause nil)
  (ffmpeg-player--play-sound-at-current-time)
  (ffmpeg-player--message "[INFO] Unpause video"))

(defun ffmpeg-player-pause ()
  "Pause the video."
  (interactive)
  (setq ffmpeg-player--pause t)
  (ffmpeg-player--kill-sound-process)
  (ffmpeg-player--message "[INFO] Pause video"))

(defun ffmpeg-player-pause-or-unpause ()
  "Pause or unpause video."
  (interactive)
  (if ffmpeg-player--pause (ffmpeg-player-unpause) (ffmpeg-player-pause)))

(defun ffmpeg-player--move-timeline (n)
  "Move video timeline by N seconds."
  (setq ffmpeg-player--video-timer (+ ffmpeg-player--video-timer n))
  (cond ((< ffmpeg-player--video-timer 0.0)
         (setq ffmpeg-player--video-timer 0.0))
        ((> ffmpeg-player--video-timer ffmpeg-player--current-duration)
         (setq ffmpeg-player--video-timer ffmpeg-player--current-duration)))
  (ffmpeg-player--play-sound-at-current-time)
  (ffmpeg-player--message "[INFO] Current time: %s" ffmpeg-player--video-timer))

(defun ffmpeg-player-backward-10 ()
  "Backward time 10 seconds."
  (interactive)
  (ffmpeg-player--move-timeline -10.0))

(defun ffmpeg-player-forward-10 ()
  "Forward time 10 seconds."
  (interactive)
  (ffmpeg-player--move-timeline 10.0))

(defvar ffmpeg-player-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "SPC") #'ffmpeg-player-pause-or-unpause)
    (define-key map (kbd "<up>") #'ffmpeg-player-volume-inc-5)
    (define-key map (kbd "<down>") #'ffmpeg-player-volume-dec-5)
    (define-key map (kbd "<left>") #'ffmpeg-player-backward-10)
    (define-key map (kbd "<right>") #'ffmpeg-player-forward-10)
    (define-key map (kbd "m") #'ffmpeg-player-mute-or-unmute)
    (define-key map (kbd "r") #'ffmpeg-player-replay)
    map)
  "Keymap used in `ffmpeg-player-mode'.")

(define-derived-mode ffmpeg-player-mode fundamental-mode "ffmpeg-player"
  "Major mode for play ffmpeg video."
  :group 'ffmpeg-player
  (buffer-disable-undo)
  (use-local-map ffmpeg-player-mode-map))

(provide 'ffmpeg-player)
;;; ffmpeg-player.el ends here
