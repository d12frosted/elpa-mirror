;;; zoom-window.el --- Zoom window like tmux -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-zoom-window
;; Package-Version: 20201205.1038
;; Package-Commit: 474ca4723517d95356145950b134652d5dc0c7f7
;; Version: 0.06
;; Package-Requires: ((emacs "24.3"))

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

;; zoom-window.el provides functions which zooms specific window in frame and
;; restore original window configuration.  This is like tmux's zoom/unzoom
;; features.

;;; Code:

(require 'cl-lib)

;; for byte-compile warnings
(declare-function elscreen-get-screen-property "elscreen")
(declare-function elscreen-get-current-screen "elscreen")
(declare-function elscreen-set-screen-property "elscreen")
(declare-function elscreen-get-conf-list "elscreen")
(declare-function safe-persp-name "persp-mode")
(declare-function get-frame-persp "persp-mode")

(defgroup zoom-window nil
  "zoom window like tmux"
  :group 'windows)

(defcustom zoom-window-use-elscreen nil
  "Non-nil means using elscreen."
  :type 'boolean
  :group 'zoom-window)

(defcustom zoom-window-use-persp nil
  "Non-nil means using persp-mode."
  :type 'boolean
  :group 'zoom-window)

(defvar zoom-window-persp-alist nil
  "Association list for working with persp-mode.")

(defcustom zoom-window-mode-line-color "green"
  "Color of mode-line when zoom-window is enabled."
  :type 'string
  :group 'zoom-window)

(defvar zoom-window--window-configuration (make-hash-table :test #'equal))
(defvar zoom-window--orig-color nil)

(defun zoom-window--put-alist (key value alist)
  "Not documented."
  (let ((elm (assoc key alist)))
    (if elm
        (progn
          (setcdr elm value)
          alist)
      (cons (cons key value) alist))))

(defsubst zoom-window--elscreen-current-property ()
  "Not documented."
  (elscreen-get-screen-property (elscreen-get-current-screen)))

(defsubst zoom-window--elscreen-current-tab-property (prop)
  "Not documented."
  (let ((property (zoom-window--elscreen-current-property)))
    (assoc-default prop property)))

(defun zoom-window--elscreen-update ()
  "Not documented."
  (let* ((property (zoom-window--elscreen-current-property))
         (orig-background (assoc-default 'zoom-window-saved-color property))
         (is-zoomed (assoc-default 'zoom-window-is-zoomed property))
         (curframe (window-frame nil)))
    (if is-zoomed
        (set-face-background 'mode-line zoom-window-mode-line-color curframe)
      (when orig-background
        (set-face-background 'mode-line orig-background curframe)))
    (force-mode-line-update)))

(defun zoom-window--elscreen-set-zoomed ()
  "Not documented."
  (let* ((current-screen (elscreen-get-current-screen))
         (prop (elscreen-get-screen-property current-screen))
         (orig-mode-line (face-background 'mode-line)))
    (setq prop (zoom-window--put-alist 'zoom-window-saved-color orig-mode-line prop))
    (elscreen-set-screen-property current-screen prop)))

(defun zoom-window--elscreen-set-default ()
  "Not documented."
  (let* ((history (elscreen-get-conf-list 'screen-history))
         (current-screen (car (last history)))
         (prop (elscreen-get-screen-property current-screen)))
    (setq prop (zoom-window--put-alist 'zoom-window-is-zoomed nil prop))
    (setq prop (zoom-window--put-alist 'zoom-window-saved-color zoom-window--orig-color prop))
    (elscreen-set-screen-property current-screen prop)))

(defun zoom-window--persp-before-switch-hook (persp-name _frame-or-window)
  "Hook to run when do persp switching.
PERSP-NAME: name of a perspective to switch.
FRAME-OR-WINDOW: a frame or a window for which the switching takes place."
  (let* ((property (assoc-default persp-name zoom-window-persp-alist))
         (orig-background (assoc-default 'zoom-window-saved-color property))
         (is-zoomed (assoc-default 'zoom-window-is-zoomed property))
         (curframe (window-frame nil)))
    (if is-zoomed
        (set-face-background 'mode-line zoom-window-mode-line-color curframe)
      (if orig-background
          (set-face-background 'mode-line orig-background curframe)
        (set-face-background 'mode-line zoom-window--orig-color curframe)))

    (if (and is-zoomed
             orig-background)
        (force-mode-line-update))))

(defun zoom-window--persp-before-kill-hook (persp)
  "Hook to run when do persp killing.
PERSP: the perspective to be killed."
  (let ((persp-name (safe-persp-name persp)))
    (setq zoom-window-persp-alist
          (delq (assoc persp-name zoom-window-persp-alist)
                zoom-window-persp-alist))))

;;;###autoload
(defun zoom-window-setup ()
  "To work with elscreen or persp-mode."
  (cond
   ;; to work with elscreen
   (zoom-window-use-elscreen
    (setq zoom-window--orig-color (face-background 'mode-line))

    (add-hook 'elscreen-create-hook 'zoom-window--elscreen-set-default)
    (add-hook 'elscreen-screen-update-hook 'zoom-window--elscreen-update)
    ;; for first tab
    (zoom-window--elscreen-set-default))

   ;; to work with persp
   (zoom-window-use-persp
    (setq zoom-window--orig-color (face-background 'mode-line))

    (add-hook 'persp-before-switch-functions
              'zoom-window--persp-before-switch-hook)
    (add-hook 'persp-before-kill-functions 'zoom-window--persp-before-kill-hook))

   ;; do nothing else
   (t nil)))

(defun zoom-window--init-persp-property (persp-name)
  "Initialize property of PERSP-NAME in `zoom-window-persp-alist'."
  (let ((property '(('zoom-window-is-zoomed nil)
                    ('zoom-window-saved-color zoom-window--orig-color))))
    (setq zoom-window-persp-alist
          (zoom-window--put-alist persp-name property zoom-window-persp-alist))
    property))

(defun zoom-window--save-mode-line-color ()
  "Not documented."
  (cond (zoom-window-use-elscreen
         (zoom-window--elscreen-set-zoomed))

        (zoom-window-use-persp
         (let* ((persp-name (safe-persp-name (get-frame-persp)))
                (property (or (assoc-default
                               persp-name zoom-window-persp-alist)
                              (zoom-window--init-persp-property persp-name))))
           (setq property (zoom-window--put-alist
                           'zoom-window-saved-color
                           (face-background 'mode-line)
                           property))
           (setq zoom-window-persp-alist (zoom-window--put-alist
                                          persp-name
                                          property
                                          zoom-window-persp-alist))))

        (t (setq zoom-window--orig-color (face-background 'mode-line)))))

(defun zoom-window--save-buffers ()
  "Not documented."
  (let ((buffers (cl-loop for window in (window-list)
                          collect (window-buffer window))))
    (cond (zoom-window-use-elscreen
           (let* ((curprops (zoom-window--elscreen-current-property))
                  (props (zoom-window--put-alist 'zoom-window-buffers buffers curprops)))
             (elscreen-set-screen-property (elscreen-get-current-screen) props)))
          (zoom-window-use-persp
           (let* ((persp-name (safe-persp-name (get-frame-persp)))
                  (property (or (assoc-default persp-name zoom-window-persp-alist)
                                (zoom-window--init-persp-property persp-name))))
             (setq property (zoom-window--put-alist
                             'zoom-window-buffers buffers property))
             (setq zoom-window-persp-alist (zoom-window--put-alist
                                            persp-name property zoom-window-persp-alist))))
          (t
           (set-frame-parameter
            (window-frame nil) 'zoom-window-buffers buffers)))))

(defun zoom-window--get-buffers ()
  (cond (zoom-window-use-elscreen
         (let ((props (zoom-window--elscreen-current-property)))
           (assoc-default 'zoom-window-buffers props)))
        (zoom-window-use-persp
         (let* ((persp-name (safe-persp-name (get-frame-persp)))
                (property (assoc-default persp-name zoom-window-persp-alist)))
           (assoc-default 'zoom-window-buffers property)))
        (t
         (frame-parameter (window-frame nil) 'zoom-window-buffers))))

(defun zoom-window--restore-mode-line-face ()
  "Not documented."
  (let ((color
         (cond (zoom-window-use-elscreen
                (zoom-window--elscreen-current-tab-property
                 'zoom-window-saved-color))

               (zoom-window-use-persp
                (let* ((persp-name (safe-persp-name (get-frame-persp)))
                       (property (assoc-default persp-name
                                                zoom-window-persp-alist)))
                  (assoc-default 'zoom-window-saved-color property)))

               (t zoom-window--orig-color))))
    (set-face-background 'mode-line color (window-frame nil))))

(defun zoom-window--configuration-key ()
  "Not documented."
  (cond (zoom-window-use-elscreen
         (format "zoom-window-%d" (elscreen-get-current-screen)))
        (zoom-window-use-persp
         (let ((persp-name (safe-persp-name (get-frame-persp))))
           (format "perspective-%s" persp-name)))
        (t (let ((parent-id (frame-parameter (window-frame nil) 'parent-id)))
             (if (not parent-id)
                 :zoom-window ;; not support multiple frame
               (format ":zoom-window-%d" parent-id))))))

(defun zoom-window--save-window-configuration ()
  "Not documented."
  (let ((key (zoom-window--configuration-key))
        (window-conf (list (current-window-configuration) (point-marker))))
    (puthash key window-conf zoom-window--window-configuration)))

(defun zoom-window--restore-window-configuration ()
  "Not documented."
  (let* ((key (zoom-window--configuration-key))
         (window-context (gethash key zoom-window--window-configuration 'not-found)))
    (when (eq window-context 'not-found)
      (error "window configuration is not found"))
    (let ((window-conf (cl-first window-context))
          (marker (cl-second window-context)))
      (set-window-configuration window-conf)
      (when (marker-buffer marker)
        (goto-char marker))
      (remhash key zoom-window--window-configuration))))

(defun zoom-window--toggle-enabled ()
  "Not documented."
  (cond
   (zoom-window-use-elscreen
    (let* ((current-screen (elscreen-get-current-screen))
           (prop (elscreen-get-screen-property current-screen))
           (val (assoc-default 'zoom-window-is-zoomed prop)))
      (setq prop (zoom-window--put-alist 'zoom-window-is-zoomed (not val) prop))
      (elscreen-set-screen-property current-screen prop)))

   (zoom-window-use-persp
    (let* ((persp-name (safe-persp-name (get-frame-persp)))
           (property (or (assoc-default persp-name
                                        zoom-window-persp-alist)
                         (zoom-window--init-persp-property persp-name)))
           (value (assoc-default 'zoom-window-is-zoomed property)))
      (setq property (zoom-window--put-alist
                      'zoom-window-is-zoomed (not value) property))
      (setq zoom-window-persp-alist
            (zoom-window--put-alist persp-name
                                    property
                                    zoom-window-persp-alist))))

   (t (let* ((curframe (window-frame nil))
             (status (frame-parameter curframe 'zoom-window-enabled)))
        (set-frame-parameter curframe 'zoom-window-enabled (not status))))))

(defun zoom-window--enable-p ()
  "Not documented."
  (cond
   (zoom-window-use-elscreen
    (zoom-window--elscreen-current-tab-property 'zoom-window-is-zoomed))

   (zoom-window-use-persp
    (let* ((persp-name (safe-persp-name (get-frame-persp)))
           (property (assoc-default persp-name zoom-window-persp-alist)))
      (and property (assoc-default 'zoom-window-is-zoomed property))))

   (t (frame-parameter (window-frame nil) 'zoom-window-enabled))))

(defsubst zoom-window--goto-line (line)
  "Not documented."
  (goto-char (point-min))
  (forward-line (1- line)))

(defun zoom-window--do-unzoom ()
  "Not documented."
  (let ((current-line (line-number-at-pos))
        (current-column (current-column))
        (current-buf (current-buffer)))
    (zoom-window--restore-mode-line-face)
    (zoom-window--restore-window-configuration)
    (pop-to-buffer current-buf)
    (zoom-window--goto-line current-line)
    (move-to-column current-column)))

;;;###autoload
(defun zoom-window-zoom ()
  "Zoom the current window."
  (interactive)
  (let ((enabled (zoom-window--enable-p))
        (curframe (window-frame nil)))
    (if (and (one-window-p) (not enabled))
        (message "There is only one window!!")
      (if enabled
          (with-demoted-errors "Warning: %S"
            (zoom-window--do-unzoom))
        (zoom-window--save-mode-line-color)
        (zoom-window--save-buffers)
        (zoom-window--save-window-configuration)
        (delete-other-windows)
        (set-face-background 'mode-line zoom-window-mode-line-color curframe))
      (force-mode-line-update)
      (zoom-window--toggle-enabled))))

(defun zoom-window-next ()
  "Switch to next buffer which is in zoomed frame/screen/perspective."
  (interactive)
  (let* ((buffers (zoom-window--get-buffers))
         (targets (member (current-buffer) buffers)))
    (if targets
        (if (cdr targets)
            (switch-to-buffer (cadr targets))
          (switch-to-buffer (car buffers)))
      (switch-to-buffer (car buffers)))))

(provide 'zoom-window)

;;; zoom-window.el ends here
