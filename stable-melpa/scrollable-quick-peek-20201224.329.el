;;; scrollable-quick-peek.el --- Display scrollable overlays  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Pablo Barrantes

;; Homepage: https://github.com/jpablobr/scrollable-quick-peek
;; Author: Pablo Barrantes <xjpablobrx@gmail.com>
;; Keywords: convenience, extensions, help, tools
;; Package-Version: 20201224.329
;; Package-Commit: 3e3492145a61831661d6e97fdcb47b5b66c73287
;; Version: 0.1.0
;; Package-Requires: ((quick-peek "1.0") (emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package adds the command `scrollable-quick-peek-show' which
;; extends `quick-peek-show' to allow for scrolling within the
;; quick-peek overlay.
;;
;; Up/Down arrows are the keys for scrolling
;;
;; <up>: `scrollable-quick-peek-scroll-up'
;; <down>: `scrollable-quick-peek-scroll-down'
;;
;; Any command other than those two will close the overlay.
;;
;; Other than that, is should behave in the same way as `quick-peek-show'.
;;
;; See M-x `customize-group' RET `quick-peek' for customisation.

;;; Code:

(require 'cl-lib)

(require 'quick-peek)

(cl-defstruct scrollable-quick-peek
  "Struct to store the overlay meta data."
  str
  str-lines-total
  qp-min-h
  qp-max-h
  qp-position)

(defvar scrollable-quick-peek nil
  "Variable to hold the `scrollable-quick-peek' struct.")

(defvar scrollable-quick-peek-scroll-offset 0
  "Start of the offset range.

`scrollable-quick-peek-scroll-up' and
`scrollable-quick-peek-scroll-down' increment or decrement its
value by one on each call.")

(defvar scrollable-quick-peek-keymap
  (let ((map (make-keymap)))
    (define-key map (kbd "<down>") #'scrollable-quick-peek-scroll-down)
    (define-key map (kbd "<up>") #'scrollable-quick-peek-scroll-up)
    map)
  "Keymap for when `scrollable-quick-peek' overlay is active.")

(defun scrollable-quick-peek--display ()
  "Display quick-peek and set the transient keymap for scrolling."
  (when scrollable-quick-peek
    (quick-peek-show
     (scrollable-quick-peek--visible-str)
     (scrollable-quick-peek-qp-position scrollable-quick-peek)
     (scrollable-quick-peek-qp-min-h scrollable-quick-peek)
     (scrollable-quick-peek-qp-max-h scrollable-quick-peek))
    (set-transient-map
     scrollable-quick-peek-keymap
     (lambda ()
       (or (eq
            this-command
            (lookup-key
             scrollable-quick-peek-keymap
             (this-single-command-keys)))
           (and (scrollable-quick-peek--destroy) nil))))))

(defun scrollable-quick-peek--destroy ()
  "Hide `quick-peek' overlay and reset all variables."
  (when scrollable-quick-peek
    (quick-peek-hide
     (scrollable-quick-peek-qp-position scrollable-quick-peek)))
  (setq scrollable-quick-peek nil)
  (setq scrollable-quick-peek-scroll-offset 0))

(defun scrollable-quick-peek--visible-str ()
  "Get the visible data for the displayed overlay."
  (let* ((offset-start scrollable-quick-peek-scroll-offset)
         (str (scrollable-quick-peek-str
               scrollable-quick-peek))
         (qp-max-h (scrollable-quick-peek-qp-max-h
                    scrollable-quick-peek))
         (offset-end (+ offset-start (- qp-max-h 1)))
         (lines (split-string str "\n"))
         (visible-str ""))
    (cl-loop for x from offset-start to offset-end do
             (setq visible-str (concat visible-str (elt lines x) "\n")))
    (replace-regexp-in-string "\n\\'" "" visible-str)))

;;;###autoload
(defun scrollable-quick-peek-scroll-up ()
  "Scroll up in the currently displayed overlay."
  (interactive)
  (when scrollable-quick-peek
    (unless (< scrollable-quick-peek-scroll-offset 1)
      (cl-decf scrollable-quick-peek-scroll-offset))
    (scrollable-quick-peek--display)))

;;;###autoload
(defun scrollable-quick-peek-scroll-down ()
  "Scroll down in the currently displayed overlay."
  (interactive)
  (when scrollable-quick-peek
    (let ((offset scrollable-quick-peek-scroll-offset)
          (total-lines (scrollable-quick-peek-str-lines-total
                        scrollable-quick-peek))
          (qp-max-h (scrollable-quick-peek-qp-max-h
                     scrollable-quick-peek)))
      (unless (>= offset (- total-lines qp-max-h))
        (cl-incf scrollable-quick-peek-scroll-offset)))
    (scrollable-quick-peek--display)))

;;;###autoload
(defun scrollable-quick-peek-show (str &optional pos min-h max-h)
  "Show STR in an inline scrollable window at POS.
MIN-H (default: 4) and MAX-H (default: 16) are passed directly to
`quick-peek'. `quick-peek' also accepts a `'none' option for MIN-H
and MAX-H but these will not get passed given these don't make
sense for `scrollale-quick-peek'."
  (interactive)
  (when (and min-h (not (integerp min-h)))
    (error "MIN-H %s is not an integer" min-h))
  (when (and max-h (not (integerp max-h)) )
    (error "MAX-H %s is not an integer" max-h))

  (setq scrollable-quick-peek-scroll-offset 0)
  (let* ((qp-min-h (or min-h 4))
         (qp-max-h (or max-h 16))
         (qp-position (or pos (point)))
         (str-lines-total (with-temp-buffer
                            (insert str)
                            (goto-char (point-max))
                            (line-number-at-pos))))
    (setq scrollable-quick-peek
          (make-scrollable-quick-peek
           :str str
           :str-lines-total str-lines-total
           :qp-min-h qp-min-h
           :qp-max-h qp-max-h
           :qp-position qp-position))
    (scrollable-quick-peek--display)))

(provide 'scrollable-quick-peek)

;;; scrollable-quick-peek.el ends here
