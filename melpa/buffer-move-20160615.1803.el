;;; buffer-move.el --- easily swap buffers

;; Copyright (C) 2004-2014  Lucas Bonnet <lucas@rincevent.net>
;; Copyright (C) 2014  Mathis Hofer <mathis@fsfe.org>
;; Copyright (C) 2014-2015  Geyslan G. Bem <geyslan@gmail.com>

;; Authors: Lucas Bonnet <lucas@rincevent.net>
;;          Geyslan G. Bem <geyslan@gmail.com>
;;          Mathis Hofer <mathis@fsfe.org>
;; Keywords: lisp,convenience
;; Package-Version: 20160615.1803
;; Package-Commit: cb517ecf8409b5fdcda472d7190c6021f0c49751
;; Version: 0.6.2
;; URL : https://github.com/lukhas/buffer-move

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;; This file is for lazy people wanting to swap buffers without
;; typing C-x b on each window. This is useful when you have :

;; +--------------+-------------+
;; |              |             |
;; |    #emacs    |    #gnus    |
;; |              |             |
;; +--------------+-------------+
;; |                            |
;; |           .emacs           |
;; |                            |
;; +----------------------------+

;; and you want to have :

;; +--------------+-------------+
;; |              |             |
;; |    #gnus     |   .emacs    |
;; |              |             |
;; +--------------+-------------+
;; |                            |
;; |           #emacs           |
;; |                            |
;; +----------------------------+

;; With buffer-move, just go in #gnus, do buf-move-left, go to #emacs
;; (which now should be on top right) and do buf-move-down.

;; To use it, simply put a (require 'buffer-move) in your ~/.emacs and
;; define some keybindings. For example, i use :

;; (global-set-key (kbd "<C-S-up>")     'buf-move-up)
;; (global-set-key (kbd "<C-S-down>")   'buf-move-down)
;; (global-set-key (kbd "<C-S-left>")   'buf-move-left)
;; (global-set-key (kbd "<C-S-right>")  'buf-move-right)

;; Alternatively, you may let the current window switch back to the previous
;; buffer, instead of swapping the buffers of both windows. Set the
;; following customization variable to 'move to activate this behavior:

;; (setq buffer-move-behavior 'move)


;;; Code:


(require 'windmove)


(defconst buffer-move-version "0.6.1"
  "Version of buffer-move.el")

(defgroup buffer-move nil
  "Swap buffers without typing C-x b on each window"
  :group 'tools)

(defcustom buffer-move-behavior 'swap
  "If set to 'swap (default), the buffers will be exchanged
  (i.e. swapped), if set to 'move, the current window is switch back to the
  previously displayed buffer (i.e. the buffer is moved)."
  :group 'buffer-move
  :type 'symbol)

(defcustom buffer-move-stay-after-swap nil
  "If set to non-nil, point will stay in the current window
  so it will not be moved when swapping buffers. This setting
  only has effect if `buffer-move-behavior' is set to 'swap."
  :group 'buffer-move
  :type 'boolean)

(defun buf-move-to (direction)
  "Helper function to move the current buffer to the window in the given
   direction (with must be 'up, 'down', 'left or 'right). An error is
   thrown, if no window exists in this direction."
  (let* ((other-win (windmove-find-other-window direction))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No window in this direction")
      (if (window-dedicated-p other-win)
	  (error "The window in this direction is dedicated"))
      (if (string-match "^ \\*Minibuf" (buffer-name (window-buffer other-win)))
	  (error "The window in this direction is the Minibuf"))
      (if (eq buffer-move-behavior 'move)
          ;; switch selected window to previous buffer (moving)
          (switch-to-prev-buffer (selected-window))

        ;; switch selected window to buffer of other window (swapping)
        (set-window-buffer (selected-window) (window-buffer other-win))
        )

      ;; switch other window to this buffer
      (set-window-buffer other-win buf-this-buf)

      (when (or (null buffer-move-stay-after-swap)
                (eq buffer-move-behavior 'move))
        (select-window other-win)))))

;;;###autoload
(defun buf-move-up ()
  "Swap the current buffer and the buffer above the split.
   If there is no split, ie now window above the current one, an
   error is signaled."
  ;;  "Switches between the current buffer, and the buffer above the
  ;;  split, if possible."
  (interactive)
  (buf-move-to 'up))

;;;###autoload
(defun buf-move-down ()
  "Swap the current buffer and the buffer under the split.
   If there is no split, ie now window under the current one, an
   error is signaled."
  (interactive)
  (buf-move-to 'down))

;;;###autoload
(defun buf-move-left ()
  "Swap the current buffer and the buffer on the left of the split.
   If there is no split, ie now window on the left of the current
   one, an error is signaled."
  (interactive)
  (buf-move-to 'left))

;;;###autoload
(defun buf-move-right ()
  "Swap the current buffer and the buffer on the right of the split.
   If there is no split, ie now window on the right of the current
   one, an error is signaled."
  (interactive)
  (buf-move-to 'right))

;;;###autoload
(defun buf-move ()
  "Begin moving the current buffer to different windows.

Use the arrow keys to move in the desired direction.  Pressing
any other key exits this function."
  (interactive)
  (let ((map (make-sparse-keymap)))
    (dolist (x '(("<up>" . buf-move-up)
                 ("<left>" . buf-move-left)
                 ("<down>" . buf-move-down)
                 ("<right>" . buf-move-right)))
      (define-key map (read-kbd-macro (car x)) (cdr x)))
    (set-transient-map map t)))

(provide 'buffer-move)
;;; buffer-move.el ends here
