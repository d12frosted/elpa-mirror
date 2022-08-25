;;; control-mode.el --- A "control" mode, similar to vim's "normal" mode

;; Copyright (C) 2013 Stephen Marsh

;; Author: Stephen Marsh <stephen.david.marsh@gmail.com>
;; Version: 0.1
;; Package-Version: 20160624.1710
;; Package-Commit: 6bf487144119b03f9cc54168f70e3d7d8d84e22b
;; URL: https://github.com/stephendavidmarsh/control-mode
;; Keywords: convenience emulations

;; Control mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Control mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Control mode.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Control mode is a minor mode for Emacs that provides a
;; "control" mode, similar in purpose to vim's "normal" mode. Unlike
;; the various vim emulation modes, the key bindings in Control mode
;; are derived from the key bindings already setup, usually by making
;; the control key unnecessary, e.g. "Ctrl-f" becomes "f". This
;; provides the power of a mode dedicated to controlling the editor
;; without needing to learn or maintain new key bindings. See
;; https://github.com/stephendavidmarsh/control-mode for complete
;; documentation.

;;; Code:

(defvar control-mode-overrideable-bindings '(nil self-insert-command org-self-insert-command undefined))

;; Ignore Control-m and Control-i
(defvar control-mode-ignore-events '(13 9))

;; This can't be control-mode-map because otherwise the
;; define-minor-mode will try to install it as the minor mode keymap,
;; despite being told the minor mode doesn't have a keymap.
(defvar control-mode-keymap (make-sparse-keymap))

(defvar control-mode-keymap-generation-functions)

(defvar control-mode-conversion-cache)

(defvar control-mode-emulation-alist nil)
(make-variable-buffer-local 'control-mode-emulation-alist)

(defvar control-mode-rebind-to-shift)

(defvar global-control-mode-exceptions)

(defun control-mode-create-alist ()
  (setq control-mode-emulation-alist
        (let* ((mode-key (cons major-mode (sort (mapcar (lambda (x) (car (rassq x minor-mode-map-alist))) (current-minor-mode-maps)) 'string<)))
               (value (assoc mode-key control-mode-conversion-cache)))
          (if value (cdr value)
            (let ((newvalue (mapcar (lambda (x) (cons t x)) (cons (control-mode-create-hook-keymap) (cons control-mode-keymap (mapcar (lambda (k) (control-mode-get-converted-keymap-for k (make-sparse-keymap) nil)) (current-active-maps)))))))
              (push (cons mode-key newvalue) control-mode-conversion-cache)
              newvalue)))))

(defun control-mode-create-hook-keymap ()
  (let ((keymap (make-sparse-keymap)))
    (run-hook-with-args 'control-mode-keymap-generation-functions keymap)
    keymap))

(defun control-mode-get-converted-keymap-for (keymap auto-keymap prefix)
  ;; Namespaces? Classes? Inner functions? What's that?
  (cl-flet*
      ((add-binding (e b) (define-key auto-keymap (vector e) b))
       (key-bindingv (e) (key-binding (vconcat (reverse (cons e prefix)))))
       (mod-modifiers (e f) (event-convert-list (append (funcall f (event-modifiers e)) (list (event-basic-type e)))))
       (remove-modifier (e mod) (mod-modifiers e (lambda (x) (remq mod x))))
       (add-modifier (e mod) (mod-modifiers e (lambda (x) (cons mod x))))
       (add-modifiers (e mod1 mod2) (mod-modifiers e (lambda (x) (cons mod2 (cons mod1 x)))))
       (is-mouse (mods) (or (memq 'click mods) (memq 'down mods)))
       (is-overrideable (b) (memq (key-bindingv b) control-mode-overrideable-bindings))
       (try-to-rebind (e b) (if (not (is-overrideable e)) nil
                              (add-binding e b)
                              t))
       (convert-keymap (e b) (if (not (keymapp b)) b
                               (let ((new-auto-keymap (make-sparse-keymap)))
                                 (set-keymap-parent new-auto-keymap b)
                                 (control-mode-get-converted-keymap-for
                                  b new-auto-keymap (cons e prefix)))))
       (handle-escape-binding
        (event binding)
        (unless (memq event control-mode-ignore-events)
          (let ((newbinding (convert-keymap event binding))
                (eventmods (event-modifiers event)))
            (unless (is-mouse eventmods)
              (if (keymapp binding) (add-binding (add-modifier event 'meta) newbinding))
              (if (memq 'control eventmods)
                  (let ((only-meta (add-modifier (remove-modifier event 'control) 'meta))
                        (only-shift (add-modifier (remove-modifier event 'control) 'shift)))
                    (try-to-rebind only-meta newbinding)
                    (try-to-rebind event newbinding)
                    (if (and control-mode-rebind-to-shift
                             (not (memq 'shift eventmods))
                             (not (key-bindingv (add-modifier only-shift 'control)))
                             (not (key-bindingv (add-modifier only-shift 'meta))))
                        (try-to-rebind only-shift newbinding)))
                (let ((control-instead (add-modifier event 'control)))
                  (when (and (is-overrideable event)
                             (or (not (key-bindingv control-instead))
                                 (memq control-instead control-mode-ignore-events)))
                    (add-binding event newbinding)
                    (if (not (memq control-instead control-mode-ignore-events))
                        (let* ((cmevent (add-modifiers event 'control 'meta))
                               (cmbinding (convert-keymap cmevent (key-bindingv cmevent))))
                          (when cmbinding
                            (add-binding (add-modifier event 'meta) cmbinding)
                            (add-binding control-instead cmbinding)))))))))))
       (handle-binding
        (event binding)
        (unless (memq event control-mode-ignore-events)
          (let ((eventmods (event-modifiers event)))
            (if (and (memq 'control eventmods) (not (is-mouse eventmods)))
                (if (and (eq event 27)
                         (keymapp binding))
                    (progn
                      (map-keymap (function handle-escape-binding) binding)
                      (try-to-rebind 91 binding))
                  (let ((newevent (remove-modifier event 'control))
                        (newbinding (convert-keymap event binding)))
                    (if (keymapp binding) (add-binding event newbinding))
                    (when (try-to-rebind newevent newbinding)
                      (unless (memq 'meta eventmods) ; Here to be safe, but Meta events should be inside Escape keymap
                        (let* ((cmevent (add-modifier event 'meta))
                               (cmbinding (convert-keymap cmevent (key-bindingv cmevent))))
                          (when cmbinding
                            (add-binding event cmbinding))))))))))))
    (map-keymap (function handle-binding) keymap)
    auto-keymap))

;;;###autoload
(define-minor-mode control-mode
  "Toggle Control mode.
With a prefix argument ARG, enable Control mode if ARG
is positive, and disable it otherwise.  If called from Lisp,
enable the mode if ARG is omitted or nil.

Control mode is a global minor mode."
  nil " Control" nil (if control-mode (control-mode-setup) (control-mode-teardown)))

;;;###autoload
(define-globalized-minor-mode global-control-mode control-mode
  (lambda ()
    (unless (apply 'derived-mode-p global-control-mode-exceptions)
      (control-mode))))

(add-hook 'emulation-mode-map-alists 'control-mode-emulation-alist)

(defun control-mode-setup ()
  (unless (string-prefix-p " *Minibuf" (buffer-name))
    (setq control-mode-emulation-alist nil)
    (control-mode-create-alist)))

(defun control-mode-teardown ()
  (setq control-mode-emulation-alist nil))

;;;###autoload
(defun control-mode-default-setup ()
  (define-key control-mode-keymap (kbd "C-z") 'global-control-mode)
  (global-set-key (kbd "C-z") 'global-control-mode)
  (add-hook 'control-mode-keymap-generation-functions
            'control-mode-ctrlx-hacks))

;;;###autoload
(defun control-mode-localized-setup ()
  (define-key control-mode-keymap (kbd "C-z") 'control-mode)
  (global-set-key (kbd "C-z") 'control-mode)
  (add-hook 'control-mode-keymap-generation-functions
            'control-mode-ctrlx-hacks))

(defun control-mode-ctrlx-hacks (keymap)
  (if (eq (key-binding (kbd "C-x f")) 'set-fill-column)
      (define-key keymap (kbd "x f") (lookup-key (current-global-map) (kbd "C-x C-f")))))

(defun control-mode-reload-bindings ()
  "Force Control mode to reload all generated keybindings."
  (interactive)
  (setq control-mode-conversion-cache nil)
  (mapc (lambda (buf)
          (with-current-buffer buf
            (if control-mode
                (control-mode-setup))))
        (buffer-list)))

(defcustom control-mode-rebind-to-shift nil
  "Allow rebinding Ctrl-Alt- to Shift-"
  :group 'control
  :type '(boolean)
  :set (lambda (x v)
         (setq control-mode-rebind-to-shift v)
         (control-mode-reload-bindings)))

(defcustom global-control-mode-exceptions '()
  "List of modes to exclude for `global-control-mode'."
  :group 'control
  :type '(repeat (function))
  :set (lambda (x v)
         (setq global-control-mode-exceptions v)))

(provide 'control-mode)

;;; control-mode.el ends here
