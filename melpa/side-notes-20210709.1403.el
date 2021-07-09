;;; side-notes.el --- Easy access to a directory notes file  -*- lexical-binding: t; -*-

;; Copyright (c) 2019-2021  Paul W. Rankin

;; Author: Paul W. Rankin <pwr@bydasein.com>
;; Keywords: convenience
;; Package-Version: 20210709.1403
;; Package-Commit: 41fe8544661a772f764a0924e04080f258053955
;; Version: 0.4.1
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/rnkn/side-notes

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Side Notes
;; ==========

;; Quickly display your quick side notes in quick side window.

;; Side notes live in a plain text file, called notes.txt by default, in
;; the current directory or any parent directory (i.e. when locating notes,
;; we first look in the current directory, then one directory up, then two
;; directories up, and so forth.)

;; Side notes are displayed in a side window with the command
;; side-notes-toggle-notes.

;; The filename is defined by user option side-notes-file.

;; To really mix things up, there's the user option
;; side-notes-secondary-file, which defaults to notes-2.txt, and will
;; display a separate notes file in a lower side window when the command
;; side-notes-toggle-notes is prefixed with an argument (C-u).

;; By default a notes file found in any parent directory will open that
;; file rather than visit a non-existing file in the current directory, but
;; you can override this by prefixing side-notes-toggle-notes with...

;;  - C-u C-u to force visiting side-notes-file within the current
;;    directory.
;;  - C-u C-u C-u to force visiting side-notes-secondary-file within
;;    the current directory.

;; Of course, you can use Markdown or Org Mode or whatever by changing the
;; file extensions of side-notes-file and/or side-notes-secondary-file.

;; For more information on how to change the way the side window is
;; displayed, see (info "(elisp) Side Windows").


;; Installation
;; ------------

;; Install from [MELPA stable][1] then add something like the following to
;; your init file:

;;     (define-key (current-global-map) (kbd "M-s n") #'side-notes-toggle-notes)


;; Bugs and Feature Requests
;; -------------------------

;; Send me an email (address in the package header). For bugs, please
;; ensure you can reproduce with:

;;     $ emacs -Q -l side-notes.el

;; Known issues are tracked with FIXME comments in the source.


;; [1]: https://stable.melpa.org/#/side-notes
;; [2]: https://melpa.org/#/side-notes


;;; Code:

(defgroup side-notes ()
  "Display a notes file."
  :group 'convenience)

(defcustom side-notes-hook
  nil
  "Hook run after showing notes buffer."
  :type 'hook
  :group 'side-notes)

(defcustom side-notes-file
  "notes.txt"
  "Name of the notes file.

This file lives in the current directory or any parent directory
thereof, which allows you to keep a notes file in the top level
of a multi-directory project.

If you would like to use a file-specific notes file, specify a
string with `add-file-local-variable'. Likewise you can specify a
directory-specific notes file with `add-dir-local-variable'."
  :type 'string
  :safe 'stringp
  :group 'side-notes)
(make-variable-buffer-local 'side-notes-file)

(defcustom side-notes-secondary-file
  "notes-2.txt"
  "Name of an optional secondary notes file.

Like `side-notes-file' but displayed when `side-notes-toggle-notes'
is prefixed with \\[universal-argument].

If you would like to use a file-specific notes file, specify a
string with `add-file-local-variable'. Likewise you can specify a
directory-specific notes file with `add-dir-local-variable'."
  :type 'string
  :safe 'stringp
  :group 'side-notes)
(make-variable-buffer-local 'side-notes-secondary-file)

(defcustom side-notes-select-window
  t
  "If non-nil, switch to notes window upon displaying it."
  :type 'boolean
  :safe 'booleanp
  :group 'side-notes)

(defcustom side-notes-display-alist
  '((side . right)
    (window-width . 35))
  "Alist used to display notes buffer.

n.b. the special symbol `slot' added automatically to ensure that
`side-notes-file' is displayed above `side-notes-secondary-file'."
  :type 'alist
  :link '(info-link "(elisp) Buffer Display Action Alists")
  :group 'side-notes)

(defface side-notes
  '((t nil))
  "Default face for notes buffer."
  :group 'side-notes)

(defvar-local side-notes-buffer-identify
  nil
  "Buffer local variable to identify a notes buffer.")

(defun side-notes-locate-notes (&optional arg)
  "Look up directory hierachy for file `side-notes-file'.

Return nil if no notes file found."
  (cond ((and side-notes-secondary-file (= arg 64))
         (expand-file-name side-notes-secondary-file default-directory))
        ((= arg 16)
         (expand-file-name side-notes-file default-directory))
        ((and side-notes-secondary-file (= arg 4))
         (expand-file-name side-notes-secondary-file
                           (locate-dominating-file default-directory
                                                   side-notes-secondary-file)))
        (t
         (expand-file-name side-notes-file
                           (locate-dominating-file default-directory
                                                   side-notes-file)))))

;;;###autoload
(defun side-notes-toggle-notes (arg)
  "Pop up a side window containing `side-notes-file'.

When prefixed with...

  1. \\[universal-argument], locate `side-notes-secondary-file' instead.
  2. \\[universal-argument] \\[universal-argument], force visiting `side-notes-file' within current directory.
  3. \\[universal-argument] \\[universal-argument] \\[universal-argument], force visiting `side-notes-secondary-file' within
     current directory.

See `side-notes-display-alist' for options concerning displaying
the notes buffer."
  (interactive "p")
  (if side-notes-buffer-identify
      (quit-window)
    (let ((display-buffer-mark-dedicated t)
          (buffer (find-file-noselect (side-notes-locate-notes arg))))
      (if (get-buffer-window buffer (selected-frame))
          (delete-windows-on buffer (selected-frame))
        (display-buffer-in-side-window
         buffer (cons (cons 'slot (if (or (= arg 4) (= arg 64)) 1 -1))
                      side-notes-display-alist))
        (with-current-buffer buffer
          (setq side-notes-buffer-identify t)
          (face-remap-add-relative 'default 'side-notes)
          (run-hooks 'side-notes-hook))
        (if side-notes-select-window
            (select-window (get-buffer-window buffer (selected-frame))))
        (message "Showing `%s'; %s to hide" buffer
                 (key-description (where-is-internal this-command
                                                     overriding-local-map t)))))))

(provide 'side-notes)
;;; side-notes.el ends here

;; Local Variables:
;; coding: utf-8-unix
;; fill-column: 80
;; require-final-newline: t
;; sentence-end-double-space: nil
;; indent-tabs-mode: nil
;; End:
