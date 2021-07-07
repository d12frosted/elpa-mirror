;;; elscreen-fr.el --- Use frame title as screen tab

;; Copyright (C) 2016 Francesc Rocher

;; Author: Francesc Rocher <francesc.rocher@gmail.com>
;; URL: http://github.com/rocher/elscreen-fr
;; Package-Version: 20160920.953
;; Package-Commit: 6dc77e1d3f17b3f76da5ccf92b715572aa55fb85
;; Version: 0.0.3
;; Package-Requires: ((elscreen "0") (seq "1.11"))

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

;; This code is an extension of the `elscreen' mode that uses your
;; window title (Emacs frame name) to show the tabs/screens of
;; `elscreen`.

;; Usage, mostly the same as `elscreen':

;;    (require 'elscreen-fr)   ;; was (require 'elscreen)
;;    (elscreen-fr-start)      ;; was (elscreen-start)

;; Keep the same `elscreen' customization variables as usual, but take
;; into account that some of them will no take effect.  These
;; variables are: `elscreen-display-screen-number',
;; `elscreen-display-tab', `elscreen-tab-display-control' and
;; `elscreen-tab-display-kill-screen'.  All are set to nil when
;; `elscreen-fr' is started.

;; Useful keys to change from tab to tab, as in most user interfaces
;; using tabs:

;;    (global-set-key [(control prior)] 'elscreen-previous)
;;    (global-set-key [(control next)] 'elscreen-next)

;; The customization group lets you tweak few parameters.

;; Tested only under Linux / Gnome.  Feedback welcome!

;;; Code:

(require 'elscreen)
(require 'seq)

(defgroup elscreen-fr nil
  "ElScreen-fr -- ElScreen Manager with frame extensions"
  :tag "elscreen-fr"
  :group 'environment)

(defcustom elscreen-fr-screen-max-length nil
  "Limit the length of the screen name shown in the window title.

This limit is only used when there is no nickname assigned to a
screen and the screen name is the concatenation of the buffer
names shown in the window."
  :tag "Max length of screen names."
  :type '(choice
          (const :tag "unlimited" nil)
          (integer :tag "limited" :value 24
                   :validate
                   (lambda(widget)
                     (when (or (null (integerp (widget-value widget)))
                               (< (widget-value widget)  1))
                       (widget-put
                        widget :error
                        (format-message
                         "Invalid value, must be an integer greater than 0"))
                       widget))))
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (elscreen-notify-screen-modification 'force))
  :group 'elscreen-fr)

(defcustom elscreen-fr-use-screen-numbers nil
  "Use screen numbers or nicknames instead of default names."
  :tag "Use screen numbers"
  :type '(boolean)
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (elscreen-notify-screen-modification 'force))
  :group 'elscreen-fr)

(defcustom elscreen-fr-window-title-prefix nil
  "Prefix to be used in the window title."
  :tag "Window title prefix"
  :type '(choice
          (const :tag "default frame name" nil)
          (string :tag "literal text"))
  :set (lambda (symbol value)
         (custom-set-default symbol value)
         (elscreen-notify-screen-modification 'force))
  :group 'elscreen-fr)

(defvar elscreen-fr-frame-name (frame-parameter nil 'name))

(defun elscreen-fr-create-name ()
  "Create the name of the recently created tab."
  (let ((frame-screen-names (or (frame-parameter nil 'elscreen-fr-screen-names) ["0"])))
    (while (< (length frame-screen-names) (+ 1 (elscreen-get-number-of-screens)))
      (let* ((i (elscreen-get-number-of-screens))
             (s (vector (format "%s" i))))
        (setq frame-screen-names
              (seq-concatenate 'vector frame-screen-names s))))
    (aset frame-screen-names
          (elscreen-get-number-of-screens)
          (format "%s" (elscreen-get-number-of-screens)))
    (modify-frame-parameters nil `((elscreen-fr-screen-names . ,frame-screen-names)))))

(defun elscreen-fr-set-nickname (nickname)
  "Set NICKNAME for current screen."
  (let ((frame-screen-names (or (frame-parameter nil 'elscreen-fr-screen-names) ["0"])))
    (aset frame-screen-names (elscreen-get-current-screen) nickname)
    (modify-frame-parameters nil `((elscreen-fr-screen-names . ,frame-screen-names)))))

(defun elscreen-fr-get-screen-name(screen-number is-current-screen)
  "Computes the screen name of SCREEN-NUMBER."
  (let* ((frame-screen-names-list (or (frame-parameter nil 'elscreen-fr-screen-names) ["0"]))
         (frame-screen-name (elt frame-screen-names-list screen-number))
         (elscreen-name (assoc-default screen-number (elscreen-get-screen-to-name-alist)))
         ; (max-length (max (length elscreen-name) elscreen-fr-screen-max-length))
         (screen-name
          (if (or elscreen-fr-use-screen-numbers
                  (> (length frame-screen-name) 1))
              frame-screen-name
            (if elscreen-fr-screen-max-length
                (substring elscreen-name
                           0 (min (length elscreen-name) elscreen-fr-screen-max-length))
              elscreen-name))))
    (if is-current-screen
        (format "[ %s ]" screen-name)
      (format "- %s -" screen-name))))

(defun elscreen-fr-update-frame-title ()
  "Update the frame title of the current frame."
  (let* ((title (concat
                 (or elscreen-fr-window-title-prefix
                     elscreen-fr-frame-name)
                 "   -"))
         (frame-screen-names (or (frame-parameter nil 'elscreen-fr-screen-names) ["0"]))
         (current-screen (elscreen-get-current-screen))
         (screen-list (sort (elscreen-get-screen-list) '<))
         (screen-to-name-alist (elscreen-get-screen-to-name-alist))
         (screen-name "")
         (screen-title
          '(lambda (s)
             (setq screen-name (elscreen-fr-get-screen-name s (eq s current-screen)))
             (setq title (concat title screen-name)))))
    (dolist (screen screen-list)
      (funcall screen-title screen))
    (concat title "-")))

;;;###autoload
(defun elscreen-fr-start ()
  "Start `elscreen-fr' mode.
This is exactly the same as `elscreen-start', but screen titles
are put in the frame title."
  (interactive)
  (frame-parameter nil 'elscreen-fr-screen-names)
  (modify-frame-parameters nil '((elscreen-fr-screen-names . ["0"])))
  (setq elscreen-display-tab nil)
  (elscreen-start)

  (add-function :before
                (symbol-function 'elscreen-create-internal)
                #'elscreen-fr-create-name)

  (add-function :before
                (symbol-function 'elscreen-screen-nickname)
                #'elscreen-fr-set-nickname)

  (add-hook 'elscreen-goto-hook
            (lambda ()
              (set-frame-name (elscreen-fr-update-frame-title))))
  (add-hook 'elscreen-screen-update-hook
            (lambda ()
              (set-frame-name (elscreen-fr-update-frame-title))))
  (elscreen-notify-screen-modification 'force)

  (setq elscreen-display-screen-number nil)
  (setq elscreen-display-tab nil)
  (setq elscreen-tab-display-control nil)
  (setq elscreen-tab-display-kill-screen nil))

(provide 'elscreen-fr)
;;; elscreen-fr.el ends here
