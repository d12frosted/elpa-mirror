;;; omni-scratch.el --- Easy and mode-specific draft buffers

;; Copyright (C) 2014-2017  Adrien Becchis

;; Author: Adrien Becchis <adriean.khisbe@live.fr>
;; Created:  2014-07-27
;; Version: 0.6.0
;; Package-Version: 20171009.2151
;; Package-Commit: 9eee3161e5cb6df58618548a2173f4da7d194814
;; Keywords: convenience, languages, tools
;; Url: https://github.com/AdrieanKhisbe/omni-scratch.el

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

;; Easily create scratch buffer to edit in the curreny major mode you are using.
;; Some features like custom scratch buffer with specific minor-modes,
;; copy on quit, etc, might be added over time.

;;; Code:
(require 'color)

(defcustom omni-scratch-default-mode 'fundamental-mode
  "Default omni-scratch mode for the scratch buffer."
  :type 'symbol :group 'omni-scratch)

(defcustom omni-scratch-lighter " β"
  "Lighter of omni-scratch-mode."
  :type 'string :group 'omni-scratch)

(defcustom omni-scratch-pale-background t
  "If true, scratch buffer are more pale than standard buffer."
  :type 'boolean :group 'omni-scratch)

(defcustom omni-scratch-pale-percent 10
  "Percent more pale are scratch buffer."
  :type 'integer :group 'omni-scratch)


(defvar omni-scratch-latest-scratch-buffer (get-buffer "*scratch*")
  "The Latest scratch buffer used.")

(defvar omni-scratch-origin-buffer nil
  "The last normal buffer from which command was invoked.")

(defvar omni-scratch-buffers-list '()
  "List of scratch buffers.")

(defun omni-scratch-create-scratch-buffer (name mode text)
  "Create or switch to NAME buffer in specified MODE with TEXT as content."
  ;; §later: option noselect?
  ;; §maybe: create or also switch to?
  ;; §TODO: rename?, kill interactive?
  (let ((buffer (get-buffer-create name)))
    (with-current-buffer buffer
      (setq omni-scratch-latest-scratch-buffer buffer)
      (when (> (length text) 0)
        (erase-buffer)
        (insert text))
      (funcall mode)
      (when omni-scratch-pale-background
        (omni-scratch--set-pale-color))
      (omni-scratch-mode))
      ;; §later: apply eventual modification to local modes.
      ;; [and var: maybe identify the scratch buffer]: local var and register in alist or so
    buffer))

(defun omni-scratch-goto-latest ()
  "Switch to the `omni-scratch-latest-scratch-buffer' used."
  (interactive)
  (setq omni-scratch-origin-buffer (current-buffer))
  ;; §note: improve using ring. (so that handle dead buffer)
  (switch-to-buffer omni-scratch-latest-scratch-buffer))
(defalias 'omni-scratch-goto-last 'omni-scratch-goto-latest)

;; §todo: default mode
;; §maybe: specific background

(defun omni-scratch--interactive-arguments ()
  (if (mark)                  ; was active-region-p but not working wwith ecukes
      (list current-prefix-arg (region-beginning) (region-end))
    (list current-prefix-arg)))

(defun omni-scratch--buffer-switch (buffer-name mode universal-arg &optional point mark)
  "Create a new scratch buffer and switch to. Unless if in scratch buffer already"
  (if (bound-and-true-p omni-scratch-mode)
      (progn (switch-to-buffer omni-scratch-origin-buffer)
             (setq omni-scratch-origin-buffer nil))
    (let ((current-buffer (current-buffer))
          (buffer (omni-scratch-create-scratch-buffer
                   buffer-name mode
                   (if point (buffer-substring point mark) ""))))
      (setq omni-scratch-origin-buffer current-buffer)
      (if (equal universal-arg '(4))
          (switch-to-buffer-other-window buffer)
        (switch-to-buffer buffer)))))

;;;###autoload
(defun omni-scratch (universal-arg &optional point mark)
  "Create a new scratch buffer and switch to. Unless if in scratch buffer already"
  (interactive (omni-scratch--interactive-arguments))
  (omni-scratch--buffer-switch "*scratch:draft*" omni-scratch-default-mode
                               universal-arg point mark))

;; ¤note: for now just one scratch buffer.
;; §todo: later many different?
;;;###autoload
(defun omni-scratch-major (universal-arg &optional point mark)
  "Create a new scratch buffer and switch to with current major mode."
  (interactive (omni-scratch--interactive-arguments))
  (omni-scratch--buffer-switch
   (replace-regexp-in-string "\\(.*\\)-mode" "*scratch:\\1*" (symbol-name major-mode))
   major-mode universal-arg point mark))

;; §later: scratch minor modefor this buffer: quick exist, copy content. save to file.
;; §later: filter mode where not applyable: ibuffer and others..

;;;###autoload
(defun omni-scratch-buffer (universal-arg &optional point mark)
  "Create a new scratch buffer associated with current buffer."
  (interactive (omni-scratch--interactive-arguments))
  (omni-scratch--buffer-switch (format "*scratch:%s*" (buffer-name))
                               major-mode universal-arg point mark))

(defun omni-scratch-quit ()
  "Quit the current omni-buffer."
  ;; §Todo: protection to not being call in a non omni-scratch buffer
  (interactive)
  (kill-ring-save (buffer-end -1) (buffer-end 1))
  (setq omni-scratch-buffers-list
        (remove (buffer-name) omni-scratch-buffers-list))
  (kill-buffer))

(defun omni-scratch-buffers ()
  "Helm select the scratch buffer."
  (interactive)
  (let ((buffer-name
         (helm :sources (list
                         (helm-build-sync-source "default"
                           :candidates '("*scratch:draft*" "*scratch*"))
                         (helm-build-sync-source "major mode"
                           :candidates omni-scratch-buffers-list))
               :buffer "*omni-scratch-buffers*")))
    (switch-to-buffer (get-buffer buffer-name))))

(defun omni-scratch--set-pale-color ()
  (face-remap-add-relative
   'default
   `((:slant italic
             :background ,(pcase (frame-parameter nil 'background-mode)
                            (`dark (omni-scratch--pale-light (face-attribute 'default :background) omni-scratch-pale-percent))
                            (`light (omni-scratch--pale-dark (face-attribute 'default :background) omni-scratch-pale-percent))
                            (_ nil))))))

(defun omni-scratch--pale-dark (color percent)
  "Give PERCENT darker and desature COLOR."
  (when (and color (not (equal "unspecified-bg" color)))
    (color-darken-name
     (color-desaturate-name color percent)
     percent)))

(defun omni-scratch--pale-light (color percent)
  "Give PERCENT lighter and desature COLOR."
  (when (and color (not (equal "unspecified-bg" color)))
    (color-lighten-name
     (color-desaturate-name color percent)
     percent)))

(define-minor-mode omni-scratch-mode
  "Scratch buffer mode."
  :lighter omni-scratch-lighter
  :keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-s $ w") 'write-file)
    (define-key map (kbd "M-s $ e") 'erase-buffer)
    (define-key map (kbd "M-s $ b") 'omni-scratch-buffers)
    (define-key map (kbd "M-s $ q") 'omni-scratch-quit)
    (if (fboundp 'spacemacs/paste-transient-state/body)
        (define-key map (kbd "M-s $ p") 'spacemacs/paste-transient-state/body)
      (define-key map (kbd "M-s $ p") 'yank))
    map))


(provide 'omni-scratch)
;;; omni-scratch.el ends here
