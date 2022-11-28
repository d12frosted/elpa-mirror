;;; sixcolors-mode.el --- A customizable horizontal scrollbar

;; Author: Davide Mastromatteo <mastro35@gmail.com>
;; URL: https://github.com/mastro35/sixcolors-mode
;; Package-Version: 20221127.1208
;; Package-Commit: fbcf57749ebc74d7b77d148da6c021b1a8e0f650
;; Keywords: convenience, colors
;; Version: 1.0
;; Package-Requires: ((emacs "27.1"))
;; SPDX-License-Identifier: GPL-3.0-only

;;; Commentary:

;; *heavily based* on
;; nyan-mode.el by Jacek "TeMPOraL" Zlydach <temporal.pl@gmail.com>
;; 
;; ... I mean, this is basically Jacek's code with small modifications:
;; - no more cat
;; - no more animations
;; - no more music
;; - no more static XPM images for the rainbow and the outerspace
;; - the rainbow is now customizable using up to six custom colors

;;; Code:

(defconst sixcolors-directory (file-name-directory (or load-file-name buffer-file-name)))
(defconst sixcolors-size 3)
(defconst sixcolors-outerspace-image-data
"/* XPM */
static char * outerspace[] = {
\"8 18 1 1\",
\"0 c None\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\",
\"00000000\"};")

(defconst sixcolors-modeline-help-string "nmouse-1: Scroll buffer position")

(defgroup sixcolors nil
  "Customization group for `sixcolors-mode'."
  :group 'frames)

(defun sixcolors-get-rainbow-image-data-with-colors(colors)
  "Return the rainbow image made by COLORS in XPM format."
  
  (unless (> (length colors) 6)
    ;; create the header
    (let* ((rainbow-image-data (format "/* XPM */\nstatic char * rainbow[] = {\n\"8 %s %s 1\",\n"
                                       (* 3 (length colors))
                                       (length colors))))
      
       ;; create the color legends
       (dotimes (i (length colors))
         (setq rainbow-image-data (concat
                                   rainbow-image-data
                                   (format "\"%s c %s\",\n" i (nth i colors)))))
       
       ;; create the stripes
       (dotimes (i (length colors))
         (dotimes (k 3)
           (setq rainbow-image-data (concat
                                     rainbow-image-data
                                     (format "\"%s%s%s%s%s%s%s%s\"" i i i i i i i i)))
           (unless (and
                    (= i (- (length colors) 1))
                 (= k 2))
             (setq rainbow-image-data (concat rainbow-image-data ",\n")))))
       
       ;; return the final string
       (format "%s};" rainbow-image-data))))

(defun sixcolors-refresh ()
  "Refresh sixcolors mode.
Intended to be called when customizations were changed, to
reapply them immediately."
  (when (featurep 'sixcolors-mode)
    (when (and (boundp 'sixcolors-mode)
               sixcolors-mode)
      (sixcolors-mode -1)
      (sixcolors-mode 1))))

(defcustom sixcolors-minimum-window-width 64
  "Minimum width of the window, below which 'sixcolors-mode' will not be displayed.
This is important because 'sixcolors-mode' will push out all
informations from small windows."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (sixcolors-refresh))
  :group 'sixcolors)

(defcustom sixcolors-bar-length 35
  "Length of sixcolors bar in units.
Each unit is equal to an 8px image.
Minimum of 3 units are required for 'sixcolors-mode'."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (sixcolors-refresh))
  :group 'sixcolors)

(defcustom sixcolors-colors '("#61BB46" "#FDB827" "#F5821F" "#E03A3E" "#963D97" "#009DDC")
  "Colors of the rainbow, starting from the top.
Maximum 6 colors are permitted.
For transparent color use 'None'."
  :type 'list
  :set (lambda (sym val)
         (set-default sym val)
         (sixcolors-refresh))
  :group 'sixcolors)

(defvar sixcolors-old-car-mode-line-position nil)
(defvar-local sixcolors--rendered (sixcolors-get-rainbow-image-data-with-colors sixcolors-colors))

;;; Load the rainbow.

(defvar sixcolors-current-frame 0)

(defun sixcolors-scroll-buffer (percentage buffer)
  "Move point `BUFFER' to `PERCENTAGE' percent in the buffer."
  (interactive)
  (with-current-buffer buffer
    (goto-char (floor (* percentage (point-max))))))

(defun sixcolors-add-scroll-handler (string percentage buffer)
  "Propertize `STRING' to scroll `BUFFER' to `PERCENTAGE' on click."
  (let ((percentage percentage)
        (buffer buffer))
    (propertize string
                'keymap
                `(keymap (mode-line keymap
                                    (down-mouse-1 . ,(lambda ()
                                                       (interactive)
                                                       (sixcolors-scroll-buffer percentage buffer))))))))

(defun sixcolors-number-of-rainbows ()
  "Define how many rainbows images have to be displayed."
(+ 1 (round (/ (* (round (* 100
                         (/ (- (float (point))
                               (float (point-min)))
                            (float (point-max)))))
               sixcolors-bar-length)
          100))))


(defun sixcolors-create ()
  "Create the sixcolors bar in the modeline."
  (if (< (window-width) sixcolors-minimum-window-width)
      ""                                ; disabled for too small windows
    (let* ((rainbows (sixcolors-number-of-rainbows))
           (outerspaces (- sixcolors-bar-length rainbows -2))
           (rainbow-string "")
           (xpm-support (image-type-available-p 'xpm))
           (outerspace-string "")
           (buffer (current-buffer)))
      (dotimes (number rainbows)
        (setq rainbow-string (concat rainbow-string
                                     (sixcolors-add-scroll-handler
                                      (if xpm-support
                                          (propertize "|"
                                                      'display (create-image sixcolors--rendered
                                                                             'xpm t :ascent 'center))
                                        "|")
                                      (/ (float number) sixcolors-bar-length) buffer))))
      (dotimes (number outerspaces)
        (setq outerspace-string (concat outerspace-string
                                        (sixcolors-add-scroll-handler
                                         (if xpm-support
                                             (propertize "-"
                                                         'display (create-image sixcolors-outerspace-image-data 'xpm t :ascent 'center))
                                           "-")
                                         (/ (float (+ rainbows sixcolors-size number)) sixcolors-bar-length) buffer))))
      (propertize (concat rainbow-string
                        ;;  sixcolors-string
                        outerspace-string)
                  'help-echo sixcolors-modeline-help-string))))


;;;###autoload
(define-minor-mode sixcolors-mode
  "Use sixcolors bar to show buffer size and position in mode-line.

Note: If you turn this mode on then you probably want to turn off
option `scroll-bar-mode'."

  :global t
  :group 'sixcolors
  (cond (sixcolors-mode
         (unless sixcolors-old-car-mode-line-position
           (setq sixcolors-old-car-mode-line-position (car mode-line-position)))
         (setcar mode-line-position '(:eval (list (sixcolors-create)))))
        ((not sixcolors-mode)
         (setcar mode-line-position sixcolors-old-car-mode-line-position)
         (setq sixcolors-old-car-mode-line-position nil))))


(provide 'sixcolors-mode)

;;; sixcolors-mode.el ends here

