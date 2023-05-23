;;; baff.el --- Create a byte array from a file -*- lexical-binding: t -*-

;;; Copyright (C) 2020 Dave Footitt
;;;
;;; Author: Dave Footitt <dave.footitt@gmail.com>
;;; URL: https://github.com/dave-f/baff/
;;; Package-Requires: ((emacs "24.3") (f "0.20.0"))
;;; Version: 1.0
;;; Keywords: convenience, usability

;;; This file is not part of GNU Emacs.

;;; License:
;;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;;; Sometimes it is desirable to generate a byte array from a file for
;;; directly including into source code.
;;;
;;; `baff` provides this functionality via `M-x baff` and prompts for
;;; a filename, then creates a buffer containing that file's bytes as
;;; a byte array, eg:
;;;
;;; #include <array>
;;; // source : c:/dev/baff/README.md
;;; // sha256 : b2d9aa7ed942cf08d091f3cce3dd56603fef00f5082573cd8b8ad987d29d4351
;;;
;;; std::array<uint8_t,10> bytes = {
;;;     0x23, 0x20, 0x62, 0x61, 0x66, 0x66, 0x0d, 0x0a, 0x43, 0x72
;;; };
;;;
;;; This buffer can then be manipulated or saved how you wish.
;;;
;;; The default style is C++ but this can be changed to whatever style
;;; is desired via `M-x customize-group RET baff RET`

;;; Code:

(require 'f)

(defgroup baff nil
  "Make a byte array from a file"
  :group 'programming)

(defcustom baff-header-function (lambda (filename contents)
                                   (insert "#include <array>\n\n"
                                           "// source : " filename "\n"
                                           "// sha256 : "
                                           (secure-hash 'sha256 contents)
                                           "\n\nstd::array<uint8_t,"
                                           (number-to-string (length contents))
                                           "> bytes = {\n"))
  "Function to run before any bytes are inserted."
  :type 'function
  :group 'baff)

(defcustom baff-footer-function (lambda (filename contents) (ignore filename contents) (insert "\n};"))
  "Function to run after all bytes have been inserted."
  :type 'function
  :group 'baff)

(defcustom baff-indent-function (lambda () (insert "    "))
  "Function to indent each line."
  :type 'function
  :group 'baff)

(defcustom baff-bytes-per-line 16
  "Number of bytes per line before a line break."
  :type 'integer
  :group 'baff)

(defcustom baff-large-file 102400
  "If a file is larger than this value, baff asks for confirmation."
  :type 'integer
  :group 'baff)

;;;###autoload
(defun baff (arg)
  "Read file `ARG` into a buffer containing a byte array of its contents."
  (interactive "FFile to insert: ")
  (unless (f-file-p arg)
      (error "File open error"))
  (when (> (f-size arg) baff-large-file)
    (unless (y-or-n-p (format "File is large (%d bytes) - insert anyway? " (f-size arg)))
      (error "File considered too large")))
  (let* ((unibytes (f-read-bytes arg))
         (bytes (string-to-list unibytes))
         (count 0)
         (pr (make-progress-reporter "Working" 0 (length bytes))))
    (switch-to-buffer (get-buffer-create "*baff*"))
    (erase-buffer)
    (funcall baff-header-function arg unibytes)
    (funcall baff-indent-function)
    (while (< count (length bytes))
      (insert (format "0x%02x" (nth count bytes)) (if (= count (1- (length bytes))) "" ", "))
      (setq count (1+ count))
      (when (and (< count (length bytes)) (= (% count baff-bytes-per-line) 0))
        (progress-reporter-update pr count)
        (insert "\n")
        (funcall baff-indent-function)))
    (progress-reporter-done pr)
  (funcall baff-footer-function arg unibytes))
  t)

(provide 'baff)

;;; baff.el ends here
