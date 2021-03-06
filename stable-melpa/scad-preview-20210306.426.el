;;; -*- lexical-binding: t -*-
;;; scad-preview.el --- Preview SCAD models in real-time within Emacs

;; Copyright (C) 2013-2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://zk-phi.gitub.io/
;; Package-Version: 20210306.426
;; Package-Commit: 8b2e7feb722ab2bde1ce050fe040f72ae0b05cad
;; Package-Requires: ((scad-mode "91.0") (emacs "24.4"))
;; Version: 0.1.2

;;; Commentary:

;; Install `scad-mode' and load this script:
;;
;;   (require 'scad-preview)
;;
;; then call `scad-preview-mode' in a `scad-mode' buffer.
;;
;; You can rotate the preview image with following keybinds:
;;
;; - <right>   scad-preview-rotz+
;; - <left>    scad-preview-rotz-
;; - <up>      scad-preview-dist-
;; - <down>    scad-preview-dist+
;; - C-<left>  scad-preview-roty+
;; - C-<right> scad-preview-roty-
;; - C-<up>    scad-preview-rotx+
;; - C-<down>  scad-preview-rotx-
;; - M-<left>  scad-preview-trnsx+
;; - M-<right> scad-preview-trnsx-
;; - M-<up>    scad-preview-trnsz-
;; - M-<down>  scad-preview-trnsz+
;; - r         scad-preview-reset-camera-parameters
;;
;; You can also use "hjkl" or "npbf" instead of arrow keys.

;;; Change Log:

;; 0.1.0 test release
;; 0.1.1 fix relative path issue
;; 0.1.2 Emacs 24.4 support

;;; Code:

(require 'image-mode)
(require 'compile)
(require 'scad-mode)

(defconst scad-preview-version "0.1.2")

;; + customs

(defgroup scad-preview nil
  "Preview SCAD models in real-time within Emacs."
  :group 'emacs)

(defcustom scad-preview-default-camera-parameters '(0 0 0 50 0 20 500)
  "Default parameters for the Gimbal camera."
  :type '(list integer)
  :group 'scad-preview)

(defcustom scad-preview-refresh-delay 1.5
  "Delay in seconds until updating preview."
  :type 'number
  :group 'scad-preview)

(defcustom scad-preview-image-size '(450 . 450)
  "Size of preview image."
  :type '(cons integer integer)
  :group 'scad-preview)

(defcustom scad-preview-window-position 'right
  "Position of the preview window. The value can be either 'right,
  'left, 'below, or 'above."
  :type 'symbol
  :group 'scad-preview)

(defcustom scad-preview-window-size 65
  "Size in columns(lines) of the preview window."
  :type 'integer
  :group 'scad-preview)

(defcustom scad-preview-colorscheme "Cornfield"
  "Colorscheme for rendering preview."
  :type 'string
  :group 'scad-preview)

;; + core functions/variables

(defvar scad-preview-mode               nil)
(defvar scad-preview--buffer            nil)
(defvar scad-preview--source-buffer     nil)
(defvar scad-preview--camera-parameters nil)
(defvar scad-preview--timer-object      nil)
(defvar scad-preview--modified-flag     nil)
(defvar scad-preview--scad-process      nil)
(defvar scad-preview--scad-status       nil)

(defun scad-preview--after-change-function (&rest _)
  "Mark that the buffer is modified."
  (setq scad-preview--modified-flag t))

(defun scad-preview-reset-camera-parameters ()
  "Reset camera parameters and update the preview buffer."
  (interactive)
  (setq scad-preview--camera-parameters
        (copy-sequence scad-preview-default-camera-parameters))
  (scad-preview-refresh))

(defun scad-preview--increment-camera-parameter (index val)
  "Increment INDEX-th camera parameter by VAL and update the
preview buffer."
  (let ((cell (nthcdr index scad-preview--camera-parameters)))
    (setcar cell (+ (car cell) val))
    (scad-preview-refresh)))

(defun scad-preview--start ()
  "Turn `scad-preview-mode' on."
  (unless scad-preview-mode
    (setq scad-preview-mode           t
          scad-preview--buffer        (get-buffer-create "*SCAD Preview*")
          scad-preview--source-buffer (current-buffer)
          scad-preview--scad-status   "Ready"
          scad-preview--timer-object
          (run-with-idle-timer
           scad-preview-refresh-delay t
           (lambda ()
             (when scad-preview--modified-flag
               (setq scad-preview--modified-flag nil)
               (scad-preview-refresh)))))
    (with-selected-window (split-window (selected-window)
                                        (- scad-preview-window-size)
                                        scad-preview-window-position)
      (switch-to-buffer scad-preview--buffer)
      (scad-preview--image-mode)
      (add-hook 'kill-buffer-hook 'scad-preview--end nil t))
    (add-hook 'kill-buffer-hook 'scad-preview--end nil t)
    (add-hook 'after-change-functions 'scad-preview--after-change-function t)
    (scad-preview-reset-camera-parameters)))

(defun scad-preview--end ()
  "Turn `scad-preview-mode' off."
  (when scad-preview-mode
    (setq scad-preview-mode nil)
    (when (and scad-preview--scad-process
               (process-live-p scad-preview--scad-process))
      (set-process-sentinel scad-preview--scad-process nil)
      (delete-process scad-preview--scad-process))
    (when (timerp scad-preview--timer-object)
      (cancel-timer scad-preview--timer-object))
    (when (buffer-live-p scad-preview--buffer)
      (when (cdr (window-list))
        (mapc 'delete-window (get-buffer-window-list scad-preview--buffer)))
      (kill-buffer scad-preview--buffer))
    (when (buffer-live-p scad-preview--source-buffer)
      (with-current-buffer scad-preview--source-buffer
        (remove-hook 'kill-buffer-hook 'scad-preview--end t)
        (remove-hook 'after-change-functions 'scad-preview--after-change-function t)))))

(defvar scad-preview--temp-files nil)
(defun scad-preview-refresh ()
  "Update the preview buffer."
  (interactive)
  (with-current-buffer scad-preview--source-buffer
    (let* ((infile (concat default-directory
                           (if buffer-file-name
                               (concat "scadpreview_"
                                       (file-name-nondirectory buffer-file-name))
                             (make-temp-name "scadpreview_"))))
           (outfile (concat temporary-file-directory (make-temp-name "scad_")  ".png")))
      (push infile scad-preview--temp-files)
      (push outfile scad-preview--temp-files)
      (setq scad-preview--scad-status "Preparing...")
      (save-restriction
        (widen)
        (write-region (point-min) (point-max) infile nil 'nomsg))
      (when (and scad-preview--scad-process (process-live-p scad-preview--scad-process))
        (setq scad-preview--scad-status "Aborting...")
        (set-process-sentinel scad-preview--scad-process nil)
        (delete-process scad-preview--scad-process))
      (condition-case nil
          (progn
            (setq scad-preview--scad-status "Rendering..."
                  scad-preview--scad-process
                  (start-process
                   "scad process" nil scad-command
                   "-o" outfile
                   (concat "--imgsize="
                           (number-to-string (car scad-preview-image-size)) ","
                           (number-to-string (cdr scad-preview-image-size)))
                   (concat "--camera="
                           (mapconcat 'number-to-string scad-preview--camera-parameters ","))
                   (concat "--colorscheme=" scad-preview-colorscheme)
                   infile))
            (set-process-sentinel
             scad-preview--scad-process
             `(lambda (p _)
                (cond ((not (file-exists-p ,outfile))
                       (setq scad-preview--scad-status "Compile Error"))
                      (t
                       (setq scad-preview--scad-status "Success")
                       (with-current-buffer scad-preview--buffer
                         (fundamental-mode)
                         (erase-buffer)
                         (insert-file-contents ,outfile)
                         (scad-preview--image-mode))))
                (dolist (file scad-preview--temp-files)
                  (when (file-exists-p file)
                    (delete-file file))
                  (setq scad-preview--temp-files nil)))))
        (error (progn (setq scad-preview--scad-status "OpenSCAD not available")
                      (delete-file infile)
                      (scad-preview--end)))))))

(add-hook 'kill-emacs-hook
          (lambda ()
            (mapc (lambda (f) (when (file-exists-p f) (delete-file f)))
                  scad-preview--temp-files)))

;; + minor-mode for the preview buffer

(defvar scad-preview--image-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "r") 'scad-preview-reset-camera-parameters)
    (define-key keymap (kbd "<right>") 'scad-preview-rotz+)
    (define-key keymap (kbd "l") 'scad-preview-rotz+)
    (define-key keymap (kbd "f") 'scad-preview-rotz+)
    (define-key keymap (kbd "<left>") 'scad-preview-rotz-)
    (define-key keymap (kbd "h") 'scad-preview-rotz-)
    (define-key keymap (kbd "b") 'scad-preview-rotz-)
    (define-key keymap (kbd "<up>") 'scad-preview-dist-)
    (define-key keymap (kbd "k") 'scad-preview-dist-)
    (define-key keymap (kbd "p") 'scad-preview-dist-)
    (define-key keymap (kbd "<down>") 'scad-preview-dist+)
    (define-key keymap (kbd "n") 'scad-preview-dist+)
    (define-key keymap (kbd "j") 'scad-preview-dist+)
    (define-key keymap (kbd "C-<left>") 'scad-preview-roty+)
    (define-key keymap (kbd "C-h") 'scad-preview-roty+)
    (define-key keymap (kbd "C-b") 'scad-preview-roty+)
    (define-key keymap (kbd "C-<right>") 'scad-preview-roty-)
    (define-key keymap (kbd "C-l") 'scad-preview-roty-)
    (define-key keymap (kbd "C-f") 'scad-preview-roty-)
    (define-key keymap (kbd "C-<up>") 'scad-preview-rotx+)
    (define-key keymap (kbd "C-k") 'scad-preview-rotx+)
    (define-key keymap (kbd "C-p") 'scad-preview-rotx+)
    (define-key keymap (kbd "C-<down>") 'scad-preview-rotx-)
    (define-key keymap (kbd "C-n") 'scad-preview-rotx-)
    (define-key keymap (kbd "C-j") 'scad-preview-rotx-)
    (define-key keymap (kbd "M-<left>") 'scad-preview-trnsx+)
    (define-key keymap (kbd "M-h") 'scad-preview-trnsx+)
    (define-key keymap (kbd "M-b") 'scad-preview-trnsx+)
    (define-key keymap (kbd "M-<right>") 'scad-preview-trnsx-)
    (define-key keymap (kbd "M-l") 'scad-preview-trnsx-)
    (define-key keymap (kbd "M-f") 'scad-preview-trnsx-)
    (define-key keymap (kbd "M-<up>") 'scad-preview-trnsz-)
    (define-key keymap (kbd "M-k") 'scad-preview-trnsz-)
    (define-key keymap (kbd "M-p") 'scad-preview-trnsz-)
    (define-key keymap (kbd "M-<down>") 'scad-preview-trnsz+)
    (define-key keymap (kbd "M-n") 'scad-preview-trnsz+)
    (define-key keymap (kbd "M-j") 'scad-preview-trnsz+)
    keymap)
  "Keymap for SCAD preview buffers.")

(defun scad-preview-trnsx+ () (interactive) (scad-preview--increment-camera-parameter 0 10))
(defun scad-preview-trnsx- () (interactive) (scad-preview--increment-camera-parameter 0 -10))
(defun scad-preview-trnsz+ () (interactive) (scad-preview--increment-camera-parameter 2 10))
(defun scad-preview-trnsz- () (interactive) (scad-preview--increment-camera-parameter 2 -10))
(defun scad-preview-rotx+ () (interactive) (scad-preview--increment-camera-parameter 3 20))
(defun scad-preview-rotx- () (interactive) (scad-preview--increment-camera-parameter 3 -20))
(defun scad-preview-roty+ () (interactive) (scad-preview--increment-camera-parameter 4 20))
(defun scad-preview-roty- () (interactive) (scad-preview--increment-camera-parameter 4 -20))
(defun scad-preview-rotz+ () (interactive) (scad-preview--increment-camera-parameter 5 20))
(defun scad-preview-rotz- () (interactive) (scad-preview--increment-camera-parameter 5 -20))
(defun scad-preview-dist+ () (interactive) (scad-preview--increment-camera-parameter 6 100))
(defun scad-preview-dist- () (interactive) (scad-preview--increment-camera-parameter 6 -100))

(define-derived-mode scad-preview--image-mode fundamental-mode "SCADp"
  "Major mode for SCAD preview buffers."
  ;; suppress messages (http://qiita.com/itiut@github/items/d917eafd6ab255629346)
  (condition-case nil
      (let ((message-log-max nil))
        (with-temp-message (or (current-message) "")
          (image-mode)))
    (error (setq scad-preview--scad-status "Compile Error")))
  (setq-local mode-line-format
              '(" "
                (:eval (apply 'format "[%d %d %d] [%d %d %d] %d"
                              scad-preview--camera-parameters))
                " / "
                scad-preview--scad-status))
  (use-local-map scad-preview--image-mode-map))

;; + interface

(defun scad-preview-rotate ()
  "Rotate preview image interactively."
  (interactive)
  (message "Use arrow keys (+[CM]) to rotate image.")
  (set-transient-map scad-preview--image-mode-map t))

(defun scad-preview-export ()
  "Render and export current SCAD model."
  (interactive)
  (compile (concat scad-command
                   " -o " (expand-file-name (read-file-name "Export to: "))
                   " " buffer-file-name)))

;;;###autoload
(defun scad-preview-mode ()
  "Preview SCAD models in real-time within Emacs."
  (interactive)
  (if scad-preview-mode (scad-preview--end) (scad-preview--start)))

;; + provide

(provide 'scad-preview)

;;; scad-preview.el ends here
