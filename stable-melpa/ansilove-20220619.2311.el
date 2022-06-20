;;; ansilove.el --- Display buffers as PNG images using ansilove -*- lexical-binding: t -*-


;; This file is part of emacs-ansilove.

;; emacs-ansilove is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, version 3.

;; emacs-ansilove is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with emacs-ansilove.  If not, see <https://www.gnu.org/licenses/>.

;; Copyright (c) 2022, Maciej Barć <xgqt@riseup.net>
;; Licensed under the GNU GPL v3 License
;; SPDX-License-Identifier: GPL-3.0-only


;; Author: Maciej Barć <xgqt@riseup.net>
;; Homepage: https://gitlab.com/xgqt/emacs-ansilove/
;; Version: 0.3.1
;; Package-Version: 20220619.2311
;; Package-Commit: d558e8fc3bed5163f3eadcacc474e59071a17929
;; Keywords: multimedia
;; Package-Requires: ((emacs "26.1"))



;;; Commentary:


;; Display buffers as PNG images using ansilove.

;; This package provides some integration with the ansilove tool,
;; which is a ANSI and ASCII art to PNG converter.

;; ansilove repository: https://github.com/ansilove/ansilove/

;; There are three non-ELisp dependencies of this library:
;; - ansilove
;;   to convert files to PNG images,
;; - Emacs built with ImageMagick support
;;   to display PNG images created by ansilove,
;; - ImageMagick with PNG file support
;;   to display PNG files.

;; To test this library out open one of files from ansilove's examples
;; (https://github.com/ansilove/ansilove/tree/master/examples/)
;; and call `ansilove' (M-x ansilove).



;;; Code:


;; Custom variables

(defgroup ansilove nil
  "Ansilove integration."
  :group 'external
  :group 'image
  :group 'text)

(defcustom ansilove-executable "ansilove"
  "Path or name to the \"ansilove\" executable."
  :safe 'stringp
  :type 'file
  :group 'ansilove)

(defcustom ansilove-temporary-directory
  (file-name-as-directory
   (expand-file-name (concat "." user-full-name "_Emacs_ansilove")
                     temporary-file-directory))
  "Temporary directory path used for file conversion via \"ansilove\"."
  :safe 'stringp
  :type 'file
  :group 'ansilove)

(defcustom ansilove-clean-temporary-directory-before-conversion nil
  "Non-nil to clean ‘ansilove-temporary-directory’ at `ansilove' start."
  :type 'boolean
  :group 'ansilove)

(defcustom ansilove-quick-test-example-url
  "https://github.com/ansilove/ansilove/raw/master/examples/burps/bs-alove.ans"
  "File URL to download for `ansilove-quick-example-test'."
  :safe 'stringp
  :type 'url
  :group 'ansilove)


;; Helper functions

(defun ansilove--init-temporary-directory ()
  "Ensure ‘ansilove-temporary-directory’ is writable."
  (when (not (file-exists-p ansilove-temporary-directory))
    (with-temp-buffer
      (make-directory ansilove-temporary-directory)))
  (when (not (file-writable-p ansilove-temporary-directory))
    (user-error "Fatal error: The directory %s is not writable!"
                ansilove-temporary-directory)))

;; TODO: Completion-read of conversion method
;;       before calling `ansilove--convert-file-to-png'.

(defun ansilove--convert-file-to-png (input-file output-file)
  "Wrapper for calling ‘ansilove-executable’.
Calls ‘ansilove-executable’ given INPUT-FILE as input and
OUTPUT-FILE as output."
  (let ((output-buffer (get-buffer-create "*Ansilove-Output*")))
    (call-process-shell-command
     (format "%s -o %s %s" ansilove-executable output-file input-file)
     nil
     output-buffer)))

(defun ansilove--buffer-to-png (buffer)
  "Convert BUFFER contents to a PNG file.
If BUFFER is associated with a file take the BUFFER's file as input,
else save BUFFER to a temporary file and
feed that file to `ansilove--convert-file-to-png'.
Returns a path to a PNG file created by \"ansilove\"
inside the ‘ansilove-temporary-directory’."
  (ansilove--init-temporary-directory)
  (let* ((buffer-file-path (buffer-file-name buffer))
         (temporary-name
          (concat "ansilove_" (number-to-string (abs (random)))))
         (temporary-output
          (expand-file-name (concat temporary-name ".png")
                            ansilove-temporary-directory)))
    (cond
     (buffer-file-path
      (ansilove--convert-file-to-png buffer-file-path temporary-output))
     (t
      (let* ((temporary-input-name (concat temporary-name ".txt"))
             (temporary-input-buffer (get-buffer-create temporary-input-name))
             (temporary-input
              (expand-file-name temporary-input-name
                                ansilove-temporary-directory))
             (temporary-input-contents
              (with-current-buffer buffer
                (buffer-string))))
        (with-current-buffer temporary-input-buffer
          (insert temporary-input-contents)
          (write-file temporary-input))
        ;; CONSIDER: Call "ansilove" with Emacs's frame/window width?
        ;;           Right now output PNG's text is sometimes wrapped.
        (ansilove--convert-file-to-png temporary-input temporary-output)
        (kill-buffer temporary-input-buffer)
        (delete-file temporary-input))))
    temporary-output))

(defun ansilove--check-executable ()
  "Check if ‘ansilove-executable’ is usable.
Return t if true and nil if false."
  (or (executable-find ansilove-executable)
      (file-executable-p ansilove-executable)))

(defun ansilove--turn-to-editable-mode ()
  "Turn current buffer to a editable mode."
  (interactive)
  (setq buffer-read-only nil)
  (fundamental-mode)
  (message "Warning: Entered editable mode."))


;; Mode

(defvar ansilove-mode-hook nil
  "Hook for ansilove major mode.")

(defvar ansilove-mode-map
  (let ((ansilove-mode-map (make-keymap)))
    (define-key ansilove-mode-map (kbd "?") 'describe-mode)
    (define-key ansilove-mode-map (kbd "C-c C-c") 'ansilove)
    (define-key ansilove-mode-map (kbd "a") 'ansilove)
    (define-key ansilove-mode-map (kbd "e") 'ansilove--turn-to-editable-mode)
    (define-key ansilove-mode-map (kbd "h") 'describe-mode)
    (define-key ansilove-mode-map (kbd "q") 'quit-window)
    ansilove-mode-map)
  "Key map for ansilove major mode.")

;;;###autoload
(define-derived-mode ansilove-mode fundamental-mode "ansilove"
  "Major mode for ANSI image files."
  (setq buffer-read-only t)
  (run-hooks 'ansilove-mode-hook)
  (use-local-map ansilove-mode-map)
  (message "Press the \"a\" key to view this buffer as a PNG image.")
  (unless (image-type-available-p 'imagemagick)
    (message
     "Warning: ImageMagick support is missing from this version of Emacs."))
  (unless (display-images-p)
    (message
     "Warning: Currently used display does not support displaying images."))
  (unless (ansilove--check-executable)
    (message "Warning: The required executable %s is unusable!"
             ansilove-executable)))

;;;###autoload
(defvar ansilove-supported-file-extensions
  '("adf" "ans" "bin" "idf" "pcb" "tnd" "xb")
  "List of file extensions supported by \"ansilove\".")

;;;###autoload
(when (boundp 'ansilove-supported-file-extensions)
  (mapc (lambda (ext)
          (add-to-list 'auto-mode-alist
                       `(,(format "\\.%s\\'" ext) . ansilove-mode)))
        ansilove-supported-file-extensions))


;; Main provided features

;; TODO: Add a special mode: before buffer is closed, delete the file it holds.

(defun ansilove-clean-temporary-directory ()
  "Remove lingering temporary files form ‘ansilove-temporary-directory’."
  (interactive)
  (cond
   ((file-exists-p ansilove-temporary-directory)
    (mapc (lambda (file) (delete-file file))
          (directory-files-recursively ansilove-temporary-directory
                                       ".*\\.\\(png\\|txt\\)$")))
   (t
    (message "Warning: The directory %s does not exist."
             ansilove-temporary-directory))))

;; The function `ansilove-convert-and-disply-now' is automatically loaded
;; mainly for development and testing purposes.

;;;###autoload
(defun ansilove-convert-and-display-now ()
  "Convert current buffer using `ansilove--buffer-to-png'.
Display the results by visiting the a temporarily created file."
  (interactive)
  (cond
   ((ansilove--check-executable)
    (find-file (ansilove--buffer-to-png (current-buffer))))
   (t
    (user-error "Fatal error: The required executable %s is unusable!"
                ansilove-executable))))

;;;###autoload
(defun ansilove ()
  "Display current buffer as a PNG image.
If ‘ansilove-clean-temporary-directory-before-conversion’ is non-nil
call `ansilove-clean-temporary-directory' before starting conversion."
  (interactive)
  (ansilove--init-temporary-directory)
  (when ansilove-clean-temporary-directory-before-conversion
    (ansilove-clean-temporary-directory))
  (ansilove-convert-and-display-now))

;;;###autoload
(defun ansilove-quick-test-example ()
  "Library showcase on one of the examples from \"ansilove\" repository.
Download a file specified by ‘ansilove-quick-example-test-url’ and open it."
  (interactive)
  (let ((test-file (expand-file-name "test.txt" ansilove-temporary-directory))
        (ansilove-clean-temporary-directory-before-conversion nil))
    (ansilove--init-temporary-directory)
    (unless (file-exists-p test-file)
      (url-copy-file ansilove-quick-test-example-url test-file))
    (with-current-buffer (find-file-noselect test-file)
      (ansilove-mode)
      (ansilove))))


(provide 'ansilove)



;;; ansilove.el ends here
