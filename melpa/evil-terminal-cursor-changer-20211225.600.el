;;; evil-terminal-cursor-changer.el --- Change cursor shape and color by evil state in terminal  -*- coding: utf-8; -*-
;;
;; Filename: evil-terminal-cursor-changer.el
;; Description: Change cursor shape and color by evil state in terminal.
;; Author: 7696122
;; Maintainer: 7696122
;; Created: Sat Nov  2 12:17:13 2013 (+0900)
;; Version: 0.0.4
;; Package-Commit: 3d7db4d6b4a3121ffd7e505b12ea94fcdb8c5df8
;; Package-Version: 20211225.600
;; Package-X-Original-Version: 20150819.907
;; Package-Requires: ((evil "1.0.8"))
;; Last-Updated: Wed Aug 26 23:21:36 2015 (+0900)
;;           By: 7696122
;;     Update #: 390
;; URL: https://github.com/7696122/evil-terminal-cursor-changer
;; Doc URL: https://github.com/7696122/evil-terminal-cursor-changer/blob/master/README.md
;; Keywords: evil, terminal, cursor
;; Compatibility: GNU Emacs: 24.x
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; [![MELPA](http://melpa.org/packages/evil-terminal-cursor-changer-badge.svg)](http://melpa.org/#/evil-terminal-cursor-changer)

;; ## Introduce ##
;;
;; evil-terminal-cursor-changer is changing cursor shape and color by evil state for evil-mode.
;;
;; When running in terminal, It's especially helpful to recognize evil's state.
;;
;; ## Install ##
;;
;; 1. Config melpa: http://melpa.org/#/getting-started
;;
;; 2. M-x package-install RET evil-terminal-cursor-changer RET
;;
;; 3. Add code to your emacs config file:（for example: ~/.emacs）：
;;
;;      (unless (display-graphic-p)
;;              (require 'evil-terminal-cursor-changer)
;;              (evil-terminal-cursor-changer-activate) ; or (etcc-on)
;;              )
;;
;; If want change cursor shape type, add below line. This is evil's setting.
;;
;;      (setq evil-motion-state-cursor 'box)  ; █
;;      (setq evil-visual-state-cursor 'box)  ; █
;;      (setq evil-normal-state-cursor 'box)  ; █
;;      (setq evil-insert-state-cursor 'bar)  ; ⎸
;;      (setq evil-emacs-state-cursor  'hbar) ; _
;;
;; Now, works in XTerm, Gnome Terminal(Gnome Desktop), iTerm(Mac OS
;; X), Konsole(KDE Desktop), dumb(etc. mintty), Apple
;; Terminal.app(restrictive supporting). If using Apple Terminal.app,
;; must install SIMBL(http://www.culater.net/software/SIMBL/SIMBL.php)
;; and MouseTerm
;; plus(https://github.com/saitoha/mouseterm-plus/releases) to use
;; evil-terminal-cursor-changer. That makes to support VT's DECSCUSR
;; sequence.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'evil)
(require 'color)

(defgroup evil-terminal-cursor-changer nil
  "Cursor changer for evil on terminal."
  :group 'cursor
  :prefix "etcc-")

(defcustom etcc-use-color nil
  "Whether to cursor color."
  :type 'boolean
  :group 'evil-terminal-cursor-changer)

(defcustom etcc-use-blink t
  "Whether to cursor blink."
  :type 'boolean
  :group 'evil-terminal-cursor-changer)

(defun etcc--in-dumb? ()
  "Running in dumb."
  (string= (getenv "TERM") "dumb"))

(defun etcc--in-iterm? ()
  "Running in iTerm."
  (string= (getenv "TERM_PROGRAM") "iTerm.app"))

(defun etcc--in-xterm? ()
  "Runing in xterm."
  (getenv "XTERM_VERSION"))

(defun etcc--in-gnome-terminal? ()
  "Running in gnome-terminal."
  (string= (getenv "COLORTERM") "gnome-terminal"))

(defun etcc--in-konsole? ()
  "Running in konsole."
  (getenv "KONSOLE_PROFILE_NAME"))

(defun etcc--in-apple-terminal? ()
  "Running in Apple Terminal"
  (string= (getenv "TERM_PROGRAM") "Apple_Terminal"))

(defun etcc--in-tmux? ()
  "Running in tmux."
  (getenv "TMUX"))

(defun etcc--get-current-gnome-profile-name ()
  "Return Current profile name of Gnome Terminal."
  ;; https://github.com/helino/current-gnome-terminal-profile/blob/master/current-gnome-terminal-profile.sh
  (if (etcc--in-gnome-terminal?)
      (let ((cmd "#!/bin/sh
FNAME=$HOME/.current_gnome_profile
gnome-terminal --save-config=$FNAME
ENTRY=`grep ProfileID < $FNAME`
rm $FNAME
TERM_PROFILE=${ENTRY#*=}
echo -n $TERM_PROFILE"))
        (shell-command-to-string cmd))
    "Default"))

(defun etcc--color-name-to-hex (color)
  "Convert color name to hex value."
  (apply 'color-rgb-to-hex (color-name-to-rgb color)))

(defun etcc--make-tmux-seq (seq)
  "Make escape sequence for tmux."
  ;; (let ((prefix "\ePtmux;\e")
  ;;       (suffix "\e\\"))
  ;;   (concat prefix seq suffix))
  seq
  )

(defun etcc--make-konsole-cursor-shape-seq (shape)
  "Make escape sequence for konsole."
  (let ((prefix  "\e]50;CursorShape=")
        (suffix  "\x7")
        (box     "0")
        (bar     "1")
        (hbar    "2")
        (seq     nil))
    (unless (member shape '(box bar hbar))
      (setq shape 'box))
    (cond ((eq shape 'box)
           (setq seq (concat prefix box suffix)))
          ((eq shape 'bar)
           (setq seq (concat prefix bar suffix)))
          ((eq shape 'hbar)
           (setq seq (concat prefix hbar suffix))))
    (if (etcc--in-tmux?)
        (etcc--make-tmux-seq seq)
      seq)))

(defun etcc--make-gnome-terminal-cursor-shape-seq (shape)
  "Make escape sequence for gnome terminal."
  (let* ((profile (etcc--get-current-gnome-profile-name))
         (prefix  (format "gconftool-2 --type string --set /apps/gnome-terminal/profiles/%s/cursor_shape "
                          profile))
         (box     "block")
         (bar     "ibeam")
         (hbar    "underline"))
    (unless (member shape '(box bar hbar))
      (setq shape 'box))
    (cond ((eq shape 'box)
           (concat prefix box))
          ((eq shape 'bar)
           (concat prefix bar))
          ((eq shape 'hbar) hbar))))

(defun etcc--make-xterm-cursor-shape-seq (shape)
  "Make escape sequence for XTerm."
  (let ((prefix      "\e[")
        (suffix      " q")
        (box-blink   "1")
        (box         "2")
        (hbar-blink  "3")
        (hbar        "4")
        (bar-blink   "5")
        (bar         "6")
        (seq        nil))
    (unless (member shape '(box bar hbar))
      (setq shape 'box))
    (cond ((eq shape 'box)
           (setq seq (concat prefix (if (and etcc-use-blink blink-cursor-mode) box-blink box) suffix)))
          ((eq shape 'bar)
           (setq seq (concat prefix (if (and etcc-use-blink blink-cursor-mode) bar-blink bar) suffix)))
          ((eq shape 'hbar)
           (setq seq (concat prefix (if (and etcc-use-blink blink-cursor-mode) hbar-blink hbar) suffix))))
    (if (etcc--in-tmux?)
        (etcc--make-tmux-seq seq)
        seq)))

(defun etcc--make-cursor-shape-seq (shape)
  "Make escape sequence for cursor shape."
  (cond ((or (etcc--in-xterm?)
             (etcc--in-apple-terminal?)
             (etcc--in-iterm?))
         (etcc--make-xterm-cursor-shape-seq shape))
        ((etcc--in-konsole?)
         (etcc--make-konsole-cursor-shape-seq shape))
        ((etcc--in-dumb?)
         (etcc--make-xterm-cursor-shape-seq shape))))

(defun etcc--make-cursor-color-seq (color)
  "Make escape sequence for cursor color."
  (let ((hex-color (etcc--color-name-to-hex color)))
    (if hex-color
        ;; https://www.iterm2.com/documentation-escape-codes.html
        (let ((prefix (if (etcc--in-iterm?)
                          "\e]Pl"
                        "\e]12;"))
              (suffix (if (etcc--in-iterm?)
                          "\e\\"
                        "\a")))
          (concat prefix
                  ;; https://www.iterm2.com/documentation-escape-codes.html
                  ;; Remove #, rr, gg, bb are 2-digit hex value for iTerm.
                  (if (and (etcc--in-iterm?)
                           (string-prefix-p "#" hex-color))
                      (substring hex-color 1)
                    hex-color)
                  suffix)))))

(defun etcc--apply-to-terminal (seq)
  "Send to escape sequence to terminal."
  (when (and seq
             (stringp seq)
             (not (display-graphic-p)))
    (send-string-to-terminal seq)))

(defun etcc--evil-set-cursor-color (color &rest _)
  "Set cursor color."
  (etcc--apply-to-terminal (etcc--make-cursor-color-seq color)))

(defun etcc--evil-set-cursor (&rest _)
  "Set cursor color type."
  (unless (or (display-graphic-p) noninteractive)
    (if (symbolp cursor-type)
        (etcc--apply-to-terminal (etcc--make-cursor-shape-seq cursor-type))
      (if (listp cursor-type)
          (etcc--apply-to-terminal (etcc--make-cursor-shape-seq (car cursor-type)))))))

;; (defadvice evil-set-cursor-color (after etcc--evil-set-cursor (arg) activate)
;;   (unless (display-graphic-p)
;;     (etcc--evil-set-cursor-color arg)))

;; (defadvice evil-set-cursor (after etcc--evil-set-cursor (arg) activate)
;;   (unless (display-graphic-p)
;;     (etcc--evil-set-cursor)))

;;;###autoload
(defun evil-terminal-cursor-changer-activate ()
  "Enable evil terminal cursor changer."
  (interactive)
  (if etcc-use-blink (add-hook 'blink-cursor-mode-hook #'etcc--evil-set-cursor))
  (advice-add 'evil-set-cursor :after #'etcc--evil-set-cursor)
  (advice-add 'evil-set-cursor-color :after #'etcc--evil-set-cursor-color)
  )

;;;###autoload
(defalias 'etcc-on 'evil-terminal-cursor-changer-activate)

;;;###autoload
(defun evil-terminal-cursor-changer-deactivate ()
  "Disable evil terminal cursor changer."
  (interactive)
  (if etcc-use-blink (remove-hook 'blink-cursor-mode-hook 'etcc--evil-set-cursor))
  (advice-remove 'evil-set-cursor #'etcc--evil-set-cursor)
  (advice-remove 'evil-set-cursor-color #'etcc--evil-set-cursor-color)
  )

;;;###autoload
(defalias 'etcc-off 'evil-terminal-cursor-changer-deactivate)

;;;###autoload
(define-minor-mode etcc-mode
  "Minor mode for changing cursor by mode for evil on terminal."
  :global t
  :lighter " etcc"
  (if etcc-mode
      (etcc-on)
    (etcc-off)))

(provide 'evil-terminal-cursor-changer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; evil-terminal-cursor-changer.el ends here
