;;; home-end.el ---  Smart multi-purpose home / end keys

;; Copyright 2018 Boruch Baum <boruch_baum@gmx.com>,
;;   and available for assignment to the Free Software Foundation, Inc.
;;   for inclusion in GNU Emacs.

;; Author:           Boruch Baum <boruch_baum@gmx.com>
;; Name:             home-end
;; Package-Version: 20180817.855
;; Package-X-Original-Version:  1.0
;; Package-requires: ((emacs "24.3") (keypress-multi-event "1.0"))
;; Package-Commit: fbddad2c1268720ce17662a232b48f666e489526
;; Keywords:         abbrev, convenience, wp, keyboard
;; URL:              https://www.github.com/Boruch_Baum/emacs-home-end

;; This is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your
;; option) any later version.

;; This software is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;;   This package makes HOME/END keys smartly cycle to the beginning/end
;;   of a line, the beginning/end of the window, the beginning/end of
;;   the buffer, and back to POINT. With a prefix argument, behaves as
;;   functions `beginning-of-buffer'/`end-of-buffer'.
;;
;;   A first keypress moves POINT to the beginning/end of a line, or if
;;   already there, to the beginning/end of the window, or if already
;;   there, to the beginning/end of the buffer. Subsequent keypresses
;;   cycle through those operations until returning POINT to its start
;;   position. Invoking a PREFIX ARGUMENT prior to the keypress moves
;;   POINT consistent with PREFIX ARG M-x beginning-of-buffer /
;;   end-of-buffer.
;;
;;   Usage example:
;;
;;     (global-set-key [home] 'home-end-home)
;;     (global-set-key [end]  'home-end-end)
;;
;;   Note that some devices may define the HOME and END keys
;;   differently. For example, we have seen the END key defined as
;;   'select'.

;;; History:
;;
;; This is a total re-write of an identically-named package that had been bundled
;; into debian's `emacs-goodies-el'. In 2018, that package was marked for
;; 'retirement' due to seeming "to need substantial maintainance and have no
;; upstream home"[1]. The original version had been Copyright 1996 Kai Grossjohann and
;; Toby Speight, and Copyright 2002-2011 Toby Speight, both under GPL3.
;;
;;   [1] https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=759721#13


;;; Code:
(require 'keypress-multi-event)

(defvar-local home-end--point nil)

(defconst home-end--home
 '((lambda() (if (not (bolp))
               (beginning-of-line)
              (setq keypress-multi-event--state 1)
              (goto-char (window-start))))
   (lambda() (if (not (eq (point) (point-min)))
               (goto-char (window-start))
              (setq keypress-multi-event--state 3)
              (goto-char home-end--point)))
   (lambda() (if (not (eq (point) (point-min)))
               (goto-char (point-min))
              (setq keypress-multi-event--state 3)
              (goto-char home-end--point)))
   (lambda() (goto-char home-end--point))))

(defconst home-end--end
 '((lambda() (if (not (eolp))
               (end-of-line)
              (setq keypress-multi-event--state 1)
              (if (not (eq (window-end) (point-max)))
                (goto-char (1- (window-end)))
               (goto-char (point-max)))))
   (lambda() (cond
              ((eq (point) (point-max))
                (setq keypress-multi-event--state 3)
                (goto-char home-end--point))
              (t
                (if (not (eq (window-end) (point-max)))
                  (goto-char (1- (window-end)))
                 (goto-char (point-max))))))
   (lambda() (if (not (eq (point) (point-max)))
               (goto-char (point-max))
              (setq keypress-multi-event--state 3)
              (goto-char home-end--point)))
   (lambda() (goto-char home-end--point))))

;;;###autoload
(defun home-end-home (&optional arg)
  "React uniquely to repeated presses of the `home' key.

A first key-press moves the point to the beginning of the current
line; a second key-press moves the point to the beginning of the
current visible window, and; a third key-press moves the point to
the beginning of the buffer.

Additionally, with numeric ARG, this command calls function
`beginning-of-buffer' to move the point to the (N*10)% position
of the buffer.

Finally, the original point is pushed onto the `mark ring', so
one can easily return there using <prefix> `set-mark' ( (\\[set-mark]).

Recommended usage is to bind this function to the `home' key by,
for instance, placing the following in the .emacs file:
  `(global-set-key [home] \'home-end-home)'"
  (interactive "P")
  (if arg
    (beginning-of-buffer arg)
   (let (start-at)
    (when (not (eq this-command last-command))
      (push-mark (copy-marker (point)) t)
      (setq home-end--point (point))
      (cond
       ((eq (point) (point-min))
         (error "Nowhere to go. Already at point-min"))
     ; Never possible because emacs will scroll to prevent this
     ; ((eq (point) (window-start))
     ;   (setq start-at 1))
       ((bolp)
         (setq start-at 1))))
     (keypress-multi-event home-end--home start-at))))

;;;###autoload
(defun home-end-end (&optional arg)
  "React uniquely to repeated presses of the `end' key.

A first key-press moves the point to the end of the current line;
a second key-press moves the point to the end of the current
visible window, and; a third key-press moves the point to the end
of the buffer.

Additionally, with numeric ARG, this command calls function
`end-of-buffer' to move the point to the (100-N*10)% position of
the buffer.

Finally, the original point is pushed onto the `mark ring', so
one can easily return there using <prefix> `set-mark' (\\[set-mark]).

Recommended usage is to bind this function to the `end' key by,
for instance, placing the following in the .emacs file:
  `(global-set-key [end] \'home-end-end)'"
  (interactive "P")
  (if arg
    (end-of-buffer arg)
   (let (start-at)
    (when (not (eq this-command last-command))
      (push-mark (copy-marker (point)) t)
      (setq home-end--point (point))
      (cond
       ((eq (point) (point-max))
         (error "Nowhere to go. Already at point-max"))
     ; Never possible because emacs will scroll to prevent this
     ; ((eq (point) (window-end))
     ;   (setq start-at 1))
       ((eolp)
         (setq start-at 1))))
     (keypress-multi-event home-end--end start-at))))

(provide 'home-end)
;;; home-end.el ends here
