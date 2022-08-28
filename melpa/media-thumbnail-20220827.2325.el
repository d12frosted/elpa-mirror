;;; media-thumbnail.el --- Utility package to provide media icons -*- lexical-binding: t -*-

;; Copyright (C) 2022 James Nguyen

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/media-thumbnail
;; Package-Version: 20220827.2325
;; Package-Commit: 14e626fe7ee714ab45c9e636d00a26e89aa2832a
;; Version: 0.0.1
;; Package-Requires: ((emacs "28.1"))
;; Keywords: files, tools
;; HomePage: https://github.com/jojojames/media-thumbnail

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
;; This package provides a utility function that returns thumbnails for
;; various media files.
;; The entry point is `media-thumbnail-for-file'.

;;; Code:
(require 'image)
(require 'cl-lib)
(eval-when-compile (require 'subr-x))

(declare-function dired-hide-details-mode "dired")
(declare-function dired-get-filename "dired")
(declare-function dired-move-to-filename "dired")
(declare-function dired-do-redisplay "dired")

;;
;; (@* "Macros" )
;;

(defmacro media-thumbnail--log (&rest args)
  "Log ARGS only if `media-thumbnail-log' is enabled."
  `(when media-thumbnail-log
     (message ,@args)))

;;
;; (@* "Constants" )
;;

(defconst media-thumbnail-image-exts '("webp" "wmf" "pcx" "xif" "wbmp" "vtf" "tap" "s1j" "sjp" "sjpg" "s1g" "sgi" "sgif" "s1n" "spn" "spng" "xyze" "rgbe" "hdr" "b16" "mdi" "apng" "ico" "pgb" "rlc" "mmr" "fst" "fpx" "fbs" "dxf" "dwg" "djv" "uvvg" "uvg" "uvvi" "uvi" "azv" "psd" "tfx" "t38" "svgz" "svg" "pti" "btf" "btif" "ktx2" "ktx" "jxss" "jxsi" "jxsc" "jxs" "jxrs" "jxra" "jxr" "jxl" "jpf" "jpx" "jpgm" "jpm" "jfif" "jhc" "jph" "jpg2" "jp2" "jls" "hsj2" "hej2" "heifs" "heif" "heics" "heic" "fts" "fit" "fits" "emf" "drle" "cgm" "dib" "bmp" "hif" "avif" "avcs" "avci" "exr" "fax" "icon" "ief" "jpg" "macp" "pbm" "pgm" "pict" "png" "pnm" "ppm" "ras" "rgb" "tga" "tif" "tiff" "xbm" "xpm" "xwd" "jpe" "jpeg"))
(defconst media-thumbnail-video-exts '("ts" "f4v" "rmvb" "wvx" "wmx" "wmv" "wm" "asx" "mk3d" "mkv" "fxm" "flv" "axv" "webm" "viv" "yt" "s1q" "smo" "smov" "ssw" "sswf" "s14" "s11" "smpg" "smk" "bk2" "bik" "nim" "pyv" "m4u" "mxu" "fvt" "dvb" "uvvv" "uvv" "uvvs" "uvs" "uvvp" "uvp" "uvvu" "uvu" "uvvm" "uvm" "uvvh" "uvh" "ogv" "m2v" "m1v" "m4v" "mpg4" "mp4" "mjp2" "mj2" "m4s" "3gpp2" "3g2" "3gpp" "3gp" "avi" "mov" "movie" "mpe" "mpeg" "mpegv" "mpg" "mpv" "qt" "vbs"))

;;
;; (@* "Customizations" )
;;

(defcustom media-thumbnail-log nil
  "Enable debug logging."
  :type 'boolean
  :group 'media-thumbnail)

(defcustom media-thumbnail-size 0
  "The size of the icon when creating a video thumbnail.

0 is the original size of the video."
  :type 'number
  :group 'media-thumbnail)

(defcustom media-thumbnail-cache-dir (format "%scache/" user-emacs-directory)
  "Where thumbnails are located."
  :type 'string
  :group 'media-thumbnail)

(defcustom media-thumbnail-image-width 150
  "Width of images."
  :type 'float
  :group 'media-thumbnail)

(defcustom media-thumbnail-max-processes 20
  "Max number of processes to use when creating thumbnails."
  :type 'int
  :group 'media-thumbnail)

(defcustom media-thumbnail-image-margin 5
  "Padding to add to inserted thumbnails."
  :type 'int
  :group 'media-thumbnail)

(defcustom media-thumbnail-dired-should-hide-details-fn
  #'media-thumbnail-hide-in-some-media-directories
  "Function used to determine whether or not to call `dired-hide-details-mode'."
  :type `(choice
          (const :tag "Default"
                 ,#'media-thumbnail-hide-in-some-media-directories)
          (function :tag "Custom function"))
  :group 'media-thumbnail)

(defcustom media-thumbnail-special-refresh-commands
  '(dired-do-delete
    dired-do-rename
    dired-do-copy
    dired-do-flagged-delete
    dired-create-directory
    (delete-file . 2)
    (save-buffer . 2)
    magit-format-patch)
  "A list of commands that will trigger a refresh of `dired'.

The command can be an alist with the CDR of the alist being the amount of time
to wait to refresh the sidebar after the CAR of the alist is called.

Set this to nil or set `media-thumbnail-special-refresh-commands' to nil
to disable automatic refresh when a special command is triggered."
  :type 'list
  :group 'media-thumbnail)

(defcustom media-thumbnail-ignore-aspect-ratio nil
  "If true, ignore aspect ratio when creating thumbnails."
  :type 'boolean
  :group 'media-thumbnail)

(defcustom media-thumbnail-ffmpegthumbnailer-executable "ffmpegthumbnailer"
  "Location of ffmpegthumbnailer."
  :type 'string
  :group 'media-thumbnail)

(defcustom media-thumbnail-dired-animate-thumbnails t
  "Whether or not `dired' animates thumbnails/gifs."
  :type 'boolean
  :group 'media-thumbnail)

;;
;; (@* "Variables" )
;;

(defvar media-thumbnail--handled-files '()
  "Files already processed by `media-thumbnail'.")

(defvar media-thumbnail--queue '()
  "To be processed by `media-thumbnail'.")

(defvar-local media-thumbnail--redisplay-timer nil
  "Timer used after converting for redisplay.")

(defvar-local media-thumbnail--specs-to-flush nil
  "Image specs to flush to refresh images upon convert finish.")

;;
;; (@* "Implementation" )
;;

(defun media-thumbnail-get-cache-path (file)
  "Return the cached image path for FILE."
  (format "%s%s.jpg" (expand-file-name media-thumbnail-cache-dir)
          (file-name-base file)))

(defun media-thumbnail-ffmpegthumbnailer-cmd (file)
  "Return a command to generate a thumbnail for FILE."
  (mapconcat
   (lambda (x) x)
   `(,media-thumbnail-ffmpegthumbnailer-executable
     "-m"
     ,@(when media-thumbnail-ignore-aspect-ratio '("-a"))
     "-i"
     ,(shell-quote-argument file)
     "-o"
     ,(shell-quote-argument (media-thumbnail-get-cache-path file))
     "-q" "10" ;; Max quality for jpeg
     "-s"
     ,(number-to-string media-thumbnail-size))
   " "))

;;;###autoload
(defun media-thumbnail-for-file (file)
  "Return image spec for FILE."
  (unless (file-exists-p media-thumbnail-cache-dir)
    (make-directory media-thumbnail-cache-dir))
  (cond
   ((or (string-match-p "^\\._" (file-name-base file))
        (not (file-name-extension file)))
    nil)
   ((member (downcase (file-name-extension file))
            media-thumbnail-image-exts)
    (media-thumbnail--create-image file))
   ((equal (downcase (file-name-extension file)) "gif")
    (media-thumbnail--create-image file))
   ((member (downcase (file-name-extension file))
            media-thumbnail-video-exts)
    (let ((cache-path (media-thumbnail-get-cache-path file)))
      (if (or (member file media-thumbnail--handled-files)
              (file-exists-p cache-path))
          (media-thumbnail--create-image cache-path)
        (push file media-thumbnail--handled-files)
        (let* ((command (media-thumbnail-ffmpegthumbnailer-cmd file))
               (image-spec (media-thumbnail--create-image cache-path)))
          (add-to-list 'media-thumbnail--queue
                       `(
                         :command ,command
                         :image-spec ,image-spec
                         :file ,file)
                       :append)
          image-spec))))
   (t nil)))

(defun media-thumbnail--create-image (filename)
  "Helper method to create and return an image given FILENAME."
  (if (equal (file-name-extension filename) "png")
      (create-image filename 'png nil
                    :width media-thumbnail-image-width
                    :margin media-thumbnail-image-margin
                    :ascent 'center)
    (create-image filename 'jpeg nil
                  :width media-thumbnail-image-width
                  :margin media-thumbnail-image-margin
                  :ascent 'center)))

(defun media-thumbnail--convert ()
  "Pop and run tasks in `media-thumbnail--queue'."
  (when (and media-thumbnail--queue
             (< (length (process-list))
                media-thumbnail-max-processes))
    (pcase-let* ((convert-request (pop media-thumbnail--queue))
                 (`(:command ,command :image-spec ,image-spec :file ,_)
                  convert-request))
      (media-thumbnail--log
       "-----\nCalling: %s\n %S\n-----" command image-spec)
      (call-process-shell-command command nil 0)
      (push convert-request media-thumbnail--specs-to-flush)
      (unless media-thumbnail--redisplay-timer
        (media-thumbnail--log "Setting up redisplay!")
        (setq-local
         media-thumbnail--redisplay-timer
         (run-with-timer 3 nil 'media-thumbnail--redisplay))))))

(defun media-thumbnail--redisplay (&rest _)
  "Call `redisplay' and reset `media-thumbnail--redisplay-timer'."
  (media-thumbnail--log "Calling redisplay!")
  (while media-thumbnail--specs-to-flush
    (pcase-let* ((`(:command ,_ :image-spec ,image-spec :file ,file)
                  (car media-thumbnail--specs-to-flush)))
      (media-thumbnail--log
       "-----\nFlushing: %S\nFile: %s\n-----" image-spec file)
      (image-flush image-spec))
    (setq-local media-thumbnail--specs-to-flush
                (cdr media-thumbnail--specs-to-flush)))
  ;; Might have to loop through the modes instead?
  ;; Otherwise, this doesn't update if we're not on the buffer.
  (when (derived-mode-p 'dired-mode)
    ;; When deleting/moving at the end of the buffer, `dired-do-redisplay'
    ;; doesn't clean up the extraneous thumbnail.
    (if (eobp)
        (save-mark-and-excursion
          (forward-line -1)
          (dired-do-redisplay))
      (dired-do-redisplay)))
  (setq-local media-thumbnail--redisplay-timer nil))

;;
;; (@* "User Facing" )
;;

;;;###autoload
(defun media-thumbnail-clear-all ()
  "Reset everything related to `media-thumbnail'."
  (interactive)
  (message "Clearing `media-thumbnail'...")
  (clear-image-cache)
  (setq media-thumbnail--specs-to-flush nil)
  (setq media-thumbnail--redisplay-timer nil)
  (setq media-thumbnail--queue nil)
  (setq media-thumbnail--handled-files nil)
  (when (file-exists-p media-thumbnail-cache-dir)
    (message "Deleting %s directory." media-thumbnail-cache-dir)
    (delete-directory media-thumbnail-cache-dir t t)))

(defun media-thumbnail-hide-in-some-media-directories ()
  "Determine if we're looking at a media directory."
  (when default-directory
    (let ((f (downcase (file-name-directory default-directory))))
      (and
       (or
        (string-match-p "videos" f)
        (string-match-p "pictures" f)
        (string-match-p "photos" f))
       'media-thumbnail--directory-has-media))))

(defun media-thumbnail--directory-has-media (directory)
  "Return if current DIRECTORY has media files.

If DIRECTORY is nil, use `default-directory'."
  (cl-find-if (lambda (x)
                (when-let ((ext (file-name-extension x)))
                  (or
                   (member (downcase ext) media-thumbnail-video-exts)
                   (member (downcase ext) media-thumbnail-image-exts))))
              (directory-files (or directory default-directory))))

;;
;; (@* "Dired" )
;;

(defun media-thumbnail-dired--display ()
  "Display the icons of files in a Dired buffer."
  (interactive)
  (remove-images (point-min) (point-max))
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (when (dired-move-to-filename nil)
          (dired-move-to-filename)
          (unless (member (dired-get-filename 'verbatim t) '("." ".."))
            (let ((filename (dired-get-filename nil t)))
              (when-let ((image (media-thumbnail-for-file filename)))
                (put-image image (point))
                (when (and media-thumbnail-dired-animate-thumbnails
                           (equal (file-name-extension filename) "gif"))
                  (image-animate image 0 t))))))
        (forward-line 1)))))

(define-minor-mode media-thumbnail-dired-mode
  "Toggle `media-thumbnail-dired-mode'."
  :lighter " Dired-Thumbnails"
  (if media-thumbnail-dired-mode
      (progn
        (when (funcall media-thumbnail-dired-should-hide-details-fn)
          (dired-hide-details-mode +1))
        (setq-local media-thumbnail--timer
                    (run-with-timer 0 0.25 #'media-thumbnail--convert))
        (add-hook 'dired-after-readin-hook
                  #'media-thumbnail-dired--display :append :local)
        (mapc
         (lambda (x)
           (if (consp x)
               (let ((command (car x))
                     (delay (cdr x)))
                 (advice-add
                  command
                  :after
                  (defalias (intern
                             (format "media-thumbnail-refresh-after-%S"
                                     command))
                    (function
                     (lambda (&rest _)
                       (let ((timer-symbol
                              (intern
                               (format
                                "media-thumbnail-refresh-%S-timer" command))))
                         (when (and (boundp timer-symbol)
                                    (timerp (symbol-value timer-symbol)))
                           (cancel-timer (symbol-value timer-symbol)))
                         (setf
                          (symbol-value timer-symbol)
                          (run-with-idle-timer
                           delay
                           nil
                           #'media-thumbnail--redisplay))))))))
             (advice-add x :after #'media-thumbnail--redisplay)))
         media-thumbnail-special-refresh-commands))
    (when (funcall media-thumbnail-dired-should-hide-details-fn)
      (dired-hide-details-mode -1))
    (setq-local media-thumbnail--timer nil)
    (remove-hook 'dired-after-readin-hook
                 #'media-thumbnail-dired--display :local)
    (mapc
     (lambda (x)
       (if (consp x)
           (let ((command (car x)))
             (advice-remove
              command
              (intern
               (format "media-thumbnail-refresh-after-%S"
                       command))))
         (advice-remove x 'media-thumbnail--redisplay)))
     media-thumbnail-special-refresh-commands)))

(provide 'media-thumbnail)
;;; media-thumbnail.el ends here
