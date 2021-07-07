;;; wn-mode.el --- numeric window switching shortcuts -*- lexical-binding: t -*-

;; URL: https://github.com/luismbo/wn-mode
;; Package-Version: 20150121.2115
;; Package-Commit: 6e7029b0d5773a79914a289937be068784931cad
;; Author: Anonymous
;; Maintainer: Luís Oliveira <luismbo@gmail.com>
;; Package-Requires: ((emacs "24"))
;; Keywords: buffers windows switching-windows

;; This library was found at the Emacs Wiki and is probably in the
;; public domain.

;;; Commentary:

;; This library defines a global minor mode called `wn-mode' that adds
;; keyboard shortcuts to quickly switch between visible windows within
;; the current Emacs frame.
;;
;; To activate, simply add
;;   (wn-mode)
;; to your `~/.emacs'.
;;
;; By default, the shortcuts are M-1, ..., M-9 for selecting windows
;; #1 through #9. M-0 selects the minibuffer, if active. M-#
;; interactively asks which window to select.
;;
;; Customize `wn-keybinding-format' if you wish to use different key
;; bindings, e.g.:
;;   (setq wn-keybinding-format "C-c %s")
;;
;; Re-enable `wn-mode' and the new keybindings will take effect.

;;; Code:

(defun wn--window-list ()
  "Return a list of ordered windows on the current frame."
  (window-list (selected-frame) t (minibuffer-window)))

;;;###autoload
(defun wn-select-nth (n)
  "Select window number N in current frame."
  (interactive "nWindow number: ")
  (let ((window (nth n (wn--window-list))))
    (cond ((null window)
           (message "No such window."))
          ((and (zerop n) (not (active-minibuffer-window)))
           (message "Minibuffer is inactive."))
          (t
           (select-window window)))))

(defun wn--selected-window-number ()
  "Return the number of the selected window"
  ;; this strange implementation avoids a dependency on cl-position!
  (1- (length (memq (selected-window) (reverse (wn--window-list))))))

(defun wn--selected-window-modeline ()
  "Return the string for the current window modeline."
  (propertize (format " #%s" (wn--selected-window-number))
              'face 'wn-modeline-face))

(defvar wn-keybinding-format "M-%s"
  "Define how the numeric keybindings should be set up.

By default we use M-0, M-1, ..., M-9, M-# which has the advantage
of being convenient but overrides built-in Emacs keybindings.")

(defvar wn--previous-keybinding-format wn-keybinding-format
  "Used by `wn--setup-keymap' to clear previous key bindings.")

(defun wn--define-keys (keymap format-string set)
  "Define or undefine wn-mode's key bindings."
  (dotimes (i 10)
    (define-key keymap (kbd (format format-string i))
      (when set (lambda () (interactive) (wn-select-nth i)))))
  (define-key keymap (kbd (format format-string "#"))
    (when set 'wn-select-nth))
  keymap)

(defun wn--setup-keymap (keymap)
  "Clear `keymap' and define new key bindings according to
`wn-keybinding-format'."
  (wn--define-keys keymap wn--previous-keybinding-format nil)
  (setq wn--previous-keybinding-format wn-keybinding-format)
  (wn--define-keys keymap wn-keybinding-format t))

;;;###autoload
(define-minor-mode wn-mode
  "A minor mode that enables quick selection of windows."
  :group 'windows
  :global t
  :init-value nil
  :keymap (wn--setup-keymap (make-sparse-keymap))
  :lighter (:eval (wn--selected-window-modeline))
  ;; recompute the keymap each time wn-mode is activated.
  (wn--setup-keymap wn-mode-map))

(defface wn-modeline-face
  '((t nil))
  "wn-mode modeline face."
  :group 'faces)

(provide 'wn-mode)

;;; wn-mode.el ends here
