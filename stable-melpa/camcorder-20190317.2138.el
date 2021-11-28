;;; camcorder.el --- Record screencasts in gif or other formats.  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/Bruce-Connor/camcorder.el
;; Package-Version: 20190317.2138
;; Package-Commit: b11ca61491a27681bb3131b72b51c105fd996bed
;; Keywords: multimedia screencast
;; Version: 0.2
;; Package-Requires: ((emacs "24") (names "20150000") (cl-lib "0.5"))

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
;;
;;   Tool for capturing screencasts directly from Emacs.
;;
;;   • To use it, simply call `M-x camcorder-record'.
;;   • A new smaller frame will popup and recording starts.
;;   • When you're finished, hit `F12' and wait for the conversion to
;;     finish.
;;
;;   Screencasts can be generated in any format understood by
;;   `imagemagick''s `convert' command. You can even pause the recording
;;   with `F11'!
;;
;;   If you want to record without a popup frame, use `M-x
;;   camcorder-mode'.
;;
;; Dependencies
;; ────────────
;;
;;   `camcorder.el' uses the [*Names*] package, so if you're installing
;;   manually you need to install that too.
;;
;;   For the recording, `camcorder.el' uses the following linux utilities.
;;   If you have these, it should work out of the box. If you use something
;;   else, you should still be able to configure `camcorder.el' work.
;;
;;   • recordmydesktop
;;   • mplayer
;;   • imagemagick
;;
;;   Do you know of a way to make it work with less dependencies? *Open an
;;   issue and let me know!*
;;
;;
;;   [*Names*] https://github.com/Bruce-Connor/names/
;;
;; Troubleshooting
;; ───────────────
;;
;;   If camcorder.el seems to pick an incorrect window id (differing from the
;;   one that `wminfo' returns), you can change `camcorder-window-id-offset' from its
;;   default value of 0.

;;; Code:

(require 'cl-lib)

;;;###autoload
(define-namespace camcorder-
:package camcorder
:version "0.1"
:group emacs


;;; Variables
(defcustom frame-parameters
  '((name . "camcorder.el Recording - F12 to Stop - F11 to Pause/Resume")
    (height . 20)
    (width . 65)
    (top .  80))
  "Parameters used on the recording frame.
See `make-frame'."
  :type '(alist :key-type symbol :value-type sexp))

(defcustom recording-command
  '("recordmydesktop" " --fps 20 --no-sound --windowid " window-id " -o " file)
  "Command used to start the recording.
This is a list where all elements are `concat'ed together (with no
separators) and passed to `shell-command'. Each element must be a
string or a symbol. The first string should be just the name of a
command (no args), so that we can identify it and SIGTERM it.

Options you may want to configure are \"--fps 10\" and \"--no-sound\".

Meaning of symbols:
   'file is the output file.
   'window-id is the window-id parameter of the recording frame.
   'temp-file and 'temp-dir are auto-generated file names in the
   temp directory."
  :type '(cons string
               (repeat
                (choice
                 string
                 (const :tag "window-id parameter of the recording frame" window-id)
                 (const :tag "Output file" file)
                 (const :tag "Temporary intermediate file" temp-file)
                 (const :tag "Temporary intermediate dir" temp-dir)))))

(defcustom gif-conversion-commands
  '(("ffmpeg"
     "mkdir -p " temp-dir
     " && cd " temp-dir
     " && ffmpeg -i " input-file " -vf palettegen input.palette.png"
     " && ffmpeg -i " input-file " -i input.palette.png -filter_complex paletteuse " gif-file
     "; rm -r " temp-dir)
    ("ffmpeg (small size, but with artifacts)"
     "ffmpeg -i " input-file " -pix_fmt rgb24 -r 30 " gif-file)
    ("mplayer + imagemagick"
     "mkdir -p " temp-dir
     " && cd " temp-dir
     " && mplayer -ao null " input-file " -vo jpeg"
     " && convert " temp-dir "* " gif-file
     "; rm -r " temp-dir)
    ("mplayer + imagemagick + optimize (slow)"
     "mkdir -p " temp-dir
     " && cd " temp-dir
     " && mplayer -ao null " input-file " -vo jpeg"
     " && convert " temp-dir "* " temp-gif-file
     " && convert " temp-gif-file " -fuzz 10% -layers Optimize " gif-file
     "; rm -r " temp-dir temp-gif-file))
  "Alist of commands used to convert ogv file to a gif.
This is a list where each element has the form
    (DESCRIPTOR STRING-OR-SYMBOL STRING-OR-SYMBOL ...)

DESCRIPTOR is a human-readable string, describing the ogvcommand.
STRING-OR-SYMBOL's are all concated together (with no separators)
and passed to `shell-command'. Strings are used literally, and
symbols are converted according to the following meanings:

   'file is the output file.
   'window-id is the window-id parameter of the recording frame.
   'temp-file, 'temp-dir, and 'temp-gif-file are auto-generated
       file names in the temp directory.

To increase compression at the cost of slower conversion, change
\"z=1\" to \"z=9\" (or something in between).  You may also use
completely different conversion commands, if you know any."
  :type '(alist :key-type (string :tag "Description for this command")
                :value-type (repeat
                             (choice
                              string
                              (const :tag "window-id parameter of the recording frame" window-id)
                              (const :tag "Output gif file" gif-file)
                              (const :tag "Input file" input-file)
                              (const :tag "Temporary intermediate gif file" temp-gif-file)
                              (const :tag "Temporary intermediate file" temp-file)
                              (const :tag "Temporary intermediate dir" temp-dir)))))

(defcustom window-id-offset 0
  "Difference between Emacs' and X's window-id.
This variable should be mostly irrelevant; it was more useful
when camcorder.el relied on `window-id' instead of
`outer-window-id'."
  :type 'integer)

(defcustom output-directory (expand-file-name "~/Videos")
  "Directory where screencasts are saved."
  :type 'directory)

(defcustom gif-output-directory output-directory
  "Directory where screencasts are saved."
  :type 'directory)

(defvar temp-dir
  (if (fboundp 'temp-directory)
      (temp-directory)
    (if (boundp 'temporary-file-directory)
        temporary-file-directory
      "/tmp/"))
  "Directory to store intermediate conversion files.")

(defvar recording-frame nil
  "Frame created for recording.
Used by `camcorder--start-recording' to decide on the dimensions.")

(defvar -process nil "Recording process PID.")

(defvar -output-file-name nil
  "Bound to the filename chosen by the user.")

(defvar -gif-file-name nil
  "Gif output file.")


;;; User Functions
(defun stop () "Stop recording." (interactive) (mode -1))

:autoload
(defun record ()
  "Open a new Emacs frame and start recording.
You can customize the size and properties of this frame with
`camcorder-frame-parameters'."
  (interactive)
  (select-frame
   (if (frame-live-p recording-frame)
       recording-frame
     (setq recording-frame
           (make-frame frame-parameters))))
  (mode))

:autoload
(defalias 'camcorder-start #'record)

:autoload
(define-minor-mode mode
  nil nil "sc"
  '(([f12] . camcorder-stop)
    ([f11] . camcorder-pause))
  :global t
  (if mode
      (progn
        (setq -output-file-name
              (expand-file-name
               (read-file-name "Output file (out.ogv): "
                               (file-name-as-directory output-directory)
                               "out.ogv")
               output-directory))
        (-start-recording)
        (add-hook 'delete-frame-functions #'-stop-recording-if-frame-deleted))
    (remove-hook 'delete-frame-functions #'-stop-recording-if-frame-deleted)
    (when (-is-running-p)
      (signal-process -process 'SIGTERM))
    (setq -process nil)
    (when (frame-live-p recording-frame)
      (delete-frame recording-frame))
    (setq recording-frame nil)
    (pop-to-buffer "*camcorder output*")
    (message "OGV file saved. Use `M-x %s' to convert it to a gif."
             #'convert-to-gif)))

(defun -clear-message ()
  (message " "))

(add-hook 'camcorder-mode-hook #'-clear-message)

(defun -is-running-p ()
  "Non-nil if the recording process is running."
  (and (integerp -process)
       (memq -process (list-system-processes))))

(defun pause ()
  "Pause or resume recording."
  (interactive)
  (when (-is-running-p)
    (signal-process -process 'SIGUSR1)))

(defvar -input-file nil "")

(defun convert-to-gif ()
  "Convert the ogv file to gif."
  (interactive)
  (let* ((-input-file
          (expand-file-name
           (read-file-name "File to convert: "
                           (or (file-name-directory (or -output-file-name ""))
                               output-directory)
                           nil t
                           (file-name-nondirectory (or -output-file-name "")))))
         (-file-base (file-name-base (file-name-nondirectory -input-file)))
         (-gif-file-name
          (expand-file-name
           (read-file-name "Output gif: "
                           gif-output-directory nil nil
                           (concat -file-base ".gif"))
           output-directory))
         (command
          (cdr (assoc
                (completing-read "Command to use (TAB to see options): "
                                 (mapcar #'car gif-conversion-commands)
                                 nil t)
                gif-conversion-commands))))
    (setq command (mapconcat #'-convert-args command ""))
    (when (y-or-n-p (format "Execute the following command? %s" command))
      (shell-command (format "(%s) &" command)
                     "*camcorder output*")
      (pop-to-buffer "*camcorder output*"))))


;;; Internal
(defun -stop-recording-if-frame-deleted (frame)
  "Stop recording if FRAME matches `camcorder-recording-frame'.
Meant for use in `delete-frame-functions'."
  (when (equal frame camcorder-recording-frame)
    (stop)))

(defun -announce-start-recording ()
  "Countdown from 3."
  (message "Will start recording in 3..")
  (sleep-for 0.7)
  (message "Will start recording in .2.")
  (sleep-for 0.7)
  (message "Will start recording in ..1")
  (sleep-for 0.7)
  (message nil))

(defun -start-recording ()
  "Start recording process.
Used internally. You should call `camcorder-record' or
`camcorder-mode' instead."
  (if (-is-running-p)
      (error "Recording process already running %s" -process)
    (setq -process nil)
    (-announce-start-recording)
    (let ((display-buffer-overriding-action
           (list (lambda (_x _y) t))))
      (shell-command
       (format "(%s) &"
               (mapconcat #'-convert-args recording-command ""))
       "*camcorder output*"))
    (while (null -process)
      (sleep-for 0.1)
      (let* ((name (car recording-command))
             (process
              (car
               (cl-member-if
                (lambda (x) (string= name (cdr (assoc 'comm (process-attributes x)))))
                (list-system-processes)))))
        (setq -process process)))))

(defun -convert-args (arg)
  "Convert recorder argument ARG into values.
Used on `camcorder-recording-command'."
  (cond
   ((stringp arg) arg)
   ((eq arg 'file) -output-file-name)
   ((eq arg 'input-file) -input-file)
   ((eq arg 'gif-file)   -gif-file-name)
   ((eq arg 'window-id)
    (-frame-window-id
     (if (frame-live-p recording-frame)
         recording-frame
       (selected-frame))))
   ((eq arg 'temp-dir)
    (expand-file-name "camcorder/" temp-dir))
   ((eq arg 'temp-file)
    (expand-file-name "camcorder.ogv" temp-dir))
   ((eq arg 'temp-gif-file)
    (expand-file-name "camcorder.gif" temp-dir))
   (t (error "Don't know this argument: %s" arg))))

(defun -frame-window-id (frame)
  "Return FRAME's window-id in hex.
Increments the actual value by `window-id-offset'."
  (format "0x%x"
          (+ (string-to-number
              (frame-parameter frame 'outer-window-id))
             window-id-offset)))

)

(provide 'camcorder)
;;; camcorder.el ends here
