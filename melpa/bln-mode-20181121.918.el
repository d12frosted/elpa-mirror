;;; bln-mode.el --- binary line navigation minor mode for cursor movement in long lines

;; Copyright (C) 2016  Maarten Grachten

;;; Author: Maarten Grachten
;;; Keywords: motion, location, cursor, convenience
;; Package-Version: 20181121.918
;; Package-Commit: a601b0bf975dd1432f6552ab6afe3f4f71133b4a
;;; URL: https://github.com/mgrachten/bln-mode
;;; Version: 1.0.0

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
;; Navigating the cursor across long lines of text by keyboard in Emacs can be
;; cumbersome, since commands like `forward-char', `backward-char',
;; `forward-word', and `backward-word' move sequentially, and potentially
;; require a lot of repeated executions to arrive at the desired position.  This
;; package provides the binary line navigation minor-mode (`bln-mode'), to
;; address this issue.  It defines the commands `bln-forward-half' and
;; `bln-backward-half', which allow for navigating from any position in a line to
;; any other position in that line by recursive binary subdivision.

;; For instance, if the cursor is at position K, invoking `bln-backward-half' will
;; move the cursor to position K/2. Successively invoking `bln-forward-half'
;; (without moving the cursor in between invocations) will move the cursor to
;; K/2 + K/4, whereas a second invocation of `bln-backward-half' would move the
;; cursor to K/2 - K/4.

;; Below is an illustration of how you can use binary line navigation to reach
;; character `e' at column 10 from character `b' at column 34 in four steps:
;;
;;                   ________________|    bln-backward-half (\\[bln-backward-half])
;;          ________|                     bln-backward-half (\\[bln-backward-half])
;;         |___                           bln-forward-half  (\\[bln-forward-half])
;;            _|                          bln-backward-half (\\[bln-backward-half])
;; ..........e.......................b.....
;;
;; This approach requires at most log(N) invocations to move from any position
;; to any other position in a line of N characters.  Note that when you move in
;; the wrong direction---by mistakenly invoking `bln-backward-half' instead of
;; `bln-forward-half' or vice versa---you can interrupt the current binary
;; navigation sequence by moving the cursor away from its current position (for
;; example, by `forward-char'). You can then start the binary navigation again
;; from that cursor position.
;; 
;; In an analogous manner, `bln-mode` allows for vertical binary
;; navigation across the visible lines in the window, using the
;; `bln-backward-half-v` and `bln-forward-half-v` commands.
;; 
;; The default keybindings are as follows:
;; 
;; * `bln-backward-half`   (\\[bln-backward-half])
;; * `bln-forward-half`    (\\[bln-forward-half])
;; * `bln-backward-half-v` (\\[bln-backward-half-v])
;; * `bln-forward-half-v`  (\\[bln-forward-half-v])
;; 
;; Navigation using thse keybindings is rather cumbersome
;; however. Using the `hydra` package, the following bindings
;; provide a much more convenient interface:
;; 
;;     (defhydra hydra-bln ()
;;       \"Binary line navigation mode\"
;;       (\"j\" bln-backward-half \"Backward in line\")
;;       (\"k\" bln-forward-half \"Forward in line\")
;;       (\"u\" bln-backward-half-v \"Backward in window\")
;;       (\"i\" bln-forward-half-v \"Forward in window\"))
;;     (define-key bln-mode-map (kbd \"M-j\") 'hydra-bln/body)

;;; Code:

(defvar bln-beg-end '(-1 . -1))
(defvar bln-functions-list '(bln-backward-half
                             bln-forward-half))
(defvar bln-beg-end-v '(-1 . -1))
(defvar bln-functions-list-v '(bln-backward-half-v
                               bln-forward-half-v))
(defvar bln-column-v -1)

(defvar bln-beg-end-b '(-1 . -1))
(defvar bln-functions-list-b '(bln-backward-half-b
                               bln-forward-half-b))
(defvar bln-column-b -1)

;;;###autoload
(defun bln-backward-half ()
  "This function is used in combination with `bln-forward-half' to provide binary line navigation (see `bln-mode')."
  (interactive)
  (setq bln-beg-end
        (if (member last-command bln-functions-list)
            (cons (car bln-beg-end) (point))
          (cons (line-beginning-position) (point))))
  (goto-char (/ (+ (car bln-beg-end) (cdr bln-beg-end)) 2)))

;;;###autoload
(defun bln-forward-half ()
  "This function is used in combination with `bln-backward-half' to provide binary line navigation (see `bln-mode')."
  (interactive)
  (setq bln-beg-end
        (if (member last-command bln-functions-list)
            ;; (/= (point) bln-prev-point))
            (cons (point) (cdr bln-beg-end))
          (cons (point) (1+ (line-end-position)))))
  (goto-char (/ (+ (car bln-beg-end) (cdr bln-beg-end)) 2)))

;;;###autoload
(defun bln-backward-half-v ()
  "This function is used in combination with `bln-forward-half' to provide binary line navigation (see `bln-mode')."
  (interactive)
  (if (member last-command bln-functions-list-v)
      (setq bln-beg-end-v
            (cons (car bln-beg-end-v) (line-number-at-pos (point))))
    (setq bln-beg-end-v
          (cons (line-number-at-pos (window-start)) (line-number-at-pos (point)))
          bln-column-v (- (point) (line-beginning-position))))
  (forward-line (/ (- (car bln-beg-end-v) (cdr bln-beg-end-v)) 2))
  (if (< bln-column-v (- (line-end-position) (line-beginning-position)))
      (forward-char bln-column-v)
    (move-end-of-line 1)))

;;;###autoload
(defun bln-forward-half-v ()
  "This function is used in combination with `bln-backward-half' to provide binary line navigation (see `bln-mode')."
  (interactive)
  (if (member last-command bln-functions-list-v)
      (setq bln-beg-end-v
            (cons (line-number-at-pos (point)) (cdr bln-beg-end-v)))
    (setq bln-beg-end-v
          (cons (line-number-at-pos (point)) (line-number-at-pos (window-end)))
          bln-column-v (- (point) (line-beginning-position))))
  (forward-line (/ (- (cdr bln-beg-end-v) (car bln-beg-end-v)) 2))
  (if (< bln-column-v (- (line-end-position) (line-beginning-position)))
      (forward-char bln-column-v)
    (move-end-of-line 1)))

;;;###autoload
(defun bln-backward-half-b ()
  "This function is used in combination with `bln-forward-half-b' to provide binary line navigation in the buffer (see `bln-mode')."
  (interactive)
  (if (member last-command bln-functions-list-b)
      (setq bln-beg-end-b
            (cons (car bln-beg-end-b) (line-number-at-pos (point))))
    (setq bln-beg-end-b
          (cons (line-number-at-pos (point-min)) (line-number-at-pos (point)))
          bln-column-b (- (point) (line-beginning-position))))
  (forward-line (/ (- (car bln-beg-end-b) (cdr bln-beg-end-b)) 2))
  (if (< bln-column-b (- (line-end-position) (line-beginning-position)))
      (forward-char bln-column-b)
    (move-end-of-line 1)))

;;;###autoload
(defun bln-forward-half-b ()
  "This function is used in combination with `bln-backward-half-b' to provide binary line navigation in the buffer (see `bln-mode')."
  (interactive)
  (if (member last-command bln-functions-list-b)
      (setq bln-beg-end-b
            (cons (line-number-at-pos (point)) (cdr bln-beg-end-b)))
    (setq bln-beg-end-b
          (cons (line-number-at-pos (point)) (line-number-at-pos (point-max)))
          bln-column-b (- (point) (line-beginning-position))))
  (forward-line (/ (- (cdr bln-beg-end-b) (car bln-beg-end-b)) 2))
  (if (< bln-column-b (- (line-end-position) (line-beginning-position)))
      (forward-char bln-column-b)
    (move-end-of-line 1)))

(defvar bln-mode-map (make-sparse-keymap) "Keymap for bln-mode.")
(define-key bln-mode-map (kbd "C-c . j") 'bln-backward-half)
(define-key bln-mode-map (kbd "C-c . k") 'bln-forward-half)
(define-key bln-mode-map (kbd "C-c , j") 'bln-backward-half-v)
(define-key bln-mode-map (kbd "C-c , k") 'bln-forward-half-v)
(define-key bln-mode-map (kbd "C-c . h") 'bln-backward-half-b)
(define-key bln-mode-map (kbd "C-c . l") 'bln-forward-half-b)

;;;###autoload
(define-minor-mode bln-mode
  "Toggle binary line navigation mode.

Interactively with no argument, this command toggles the mode. A
positive prefix argument enables the mode, any other prefix
argument disables it. From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

Navigating the cursor across long lines of text by keyboard in
Emacs can be cumbersome, since commands like `forward-char',
`backward-char', `forward-word', and `backward-word' move the
cursor linearly, and potentially require a lot of repeated
executions to arrive at the desired position. `bln-mode'
addresses this issue. It defines the commands `bln-forward-half' and
`bln-backward-half' that allow for navigating from any position in a
line to any other position in that line by recursive binary
subdivision.

For instance, if the cursor is at position K, invoking
`bln-backward-half' will move the cursor to position
K/2. Successively invoking `bln-forward-half' will move the cursor to
K/2 + K/4, whereas a second invocation of `bln-backward-half' would
move the cursor to K/2 - K/4.

Below is an illustration of how you can use binary line navigation
to reach character `e' at column 10 from character `b' at column
34 in four steps:

                   ________________|    bln-backward-half (\\[bln-backward-half])
          ________|                     bln-backward-half (\\[bln-backward-half])
         |___                           bln-forward-half  (\\[bln-forward-half])
            _|                          bln-backward-half (\\[bln-backward-half])
..........e.......................b.....

This approach requires at most log(N) invocations to move from
any position to any other position in a line of N
characters. Note that when you move in the wrong direction---by
mistakenly invoking `bln-backward-half' instead of `bln-forward-half' or
vice versa---you can interrupt the current binary navigation
sequence by moving the cursor away from its current position (for
example, by `forward-char'). You can then start the binary
navigation again from that cursor position.

In an analogous manner, `bln-mode` allows for vertical binary
navigation across the visible lines in the window, using the
`bln-backward-half-v` and `bln-forward-half-v` commands.

Similarly, vertical binary navigation across the entire buffer is
possible using the `bln-backward-half-b' and `bln-forward-half-b' commands.

The default keybindings are as follows:

* `bln-backward-half`   (\\[bln-backward-half])
* `bln-forward-half`    (\\[bln-forward-half])
* `bln-backward-half-v` (\\[bln-backward-half-v])
* `bln-forward-half-v`  (\\[bln-forward-half-v])
* `bln-backward-half-b` (\\[bln-backward-half-b])
* `bln-forward-half-b`  (\\[bln-forward-half-b])

Navigation using thse keybindings is rather cumbersome
however. Using the `hydra` package, the following bindings
provide a much more convenient interface:

    (defhydra hydra-bln ()
      \"Binary line navigation mode\"
      (\"j\" bln-backward-half \"Backward in line\")
      (\"k\" bln-forward-half \"Forward in line\")
      (\"u\" bln-backward-half-v \"Backward in window\")
      (\"i\" bln-forward-half-v \"Forward in window\")
      (\"h\" bln-backward-half-b \"Backward in buffer\")
      (\"l\" bln-forward-half-b \"Forward in buffer\"))
    (define-key bln-mode-map (kbd \"M-j\") 'hydra-bln/body)
"
  :lighter " bln"
  :global
  :keymap bln-mode-map
  :group 'bln
  )

(provide 'bln-mode)
;;; bln-mode.el ends here
