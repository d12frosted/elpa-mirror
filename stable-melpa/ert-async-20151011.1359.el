;;; ert-async.el --- Async support for ERT -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Johan Andersson

;; Author: Johan Andersson <johan.rejeep@gmail.com>
;; Maintainer: Johan Andersson <johan.rejeep@gmail.com>
;; Version: 0.1.2
;; Package-Version: 20151011.1359
;; Package-Commit: f64a7ed5b0d2900c9a3d8cc33294bf8a79bc8526
;; Keywords: test
;; URL: http://github.com/rejeep/ert-async.el

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(require 'ert)

(defvar ert-async-timeout 10
  "Number of seconds to wait for callbacks before failing.")

(defun ert-async-activate-font-lock-keywords ()
  "Activate font-lock keywords for `ert-deftest-async'."
  (font-lock-add-keywords
   nil
   '(("(\\(\\<ert-deftest\\(?:-async\\)?\\)\\>\\s *\\(\\(?:\\sw\\|\\s_\\)+\\)?"
      (1 font-lock-keyword-face nil t)
      (2 font-lock-function-name-face nil t)))))

(defmacro ert-deftest-async (name callbacks &rest body)
  "Like `ert-deftest' but with support for async.

NAME is the name of the test, which is the first argument to
`ert-deftest'.

CALLBACKS is a list of callback functions that all must be called
before `ert-async-timeout'.  If all callback functions have not
been called before the timeout, the test fails.

The callback functions should be called without any argument.  If
a callback function is called with a string as argument, the test
will fail with that error string.

BODY is the actual test."
  (declare (indent 2))
  (let ((varlist
         (cons
          'callbacked
          (mapcar
           (lambda (callback)
             (list
              callback
              `(lambda (&optional error-message)
                 (if error-message
                     (ert-fail (format "Callback %s invoked with argument: %s" ',callback error-message))
                   (if (member ',callback callbacked)
                       (ert-fail (format "Callback %s called multiple times" ',callback))
                     (push ',callback callbacked))))))
           callbacks))))
    `(ert-deftest ,name ()
       (let* ,varlist
         (with-timeout
             (ert-async-timeout
              (ert-fail (format "Timeout of %ds exceeded. Expected the functions [%s] to be called, but was [%s]."
                                ert-async-timeout
                                ,(mapconcat 'symbol-name callbacks " ")
                                (mapconcat 'symbol-name callbacked " "))))
           ,@body
           (while (not (equal (sort (mapcar 'symbol-name callbacked) 'string<)
                              (sort (mapcar 'symbol-name ',callbacks) 'string<)))
             (accept-process-output nil 0.05)))))))

(provide 'ert-async)

;;; ert-async.el ends here
