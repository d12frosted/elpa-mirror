;;; timecop.el --- Freeze Time for testing

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 19 May 2016
;; Version: 0.0.1
;; Package-Version: 20160520.1052
;; Package-Commit: 3a1871613facc928ff250ed8f12fbc7073e46b75
;; Package-Requires: ((cl-lib "0.5") (datetime-format "0.0.1"))
;; Keywords: datetime testing
;; Homepage: https://github.com/zonuexe/emacs-datetime

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Inspired by Timecop gem https://github.com/travisjeffery/timecop
;;
;; (datetime-format 'atom nil :timezone "America/New_York") ;=> now "2016-05-20 06:05:50-04:00"
;;
;; (timecop 1234567890
;;     (datetime-format 'atom nil :timezone "America/New_York")) ;=> "2009-02-13 18:02:30-05:00"
;;

;;; Code:
(require 'cl-lib)
(require 'datetime-format)


;;;; Utils
(defvar timecop--freezetime nil)

(defalias 'timecop--real-fts (symbol-function 'format-time-string))
(defun timecop--format-time-string (format-string &optional time universal)
  "Wrapper function `(FORMAT-TIME-STRING FORMAT-STRING TIME UNIVERSAL)'."
  (timecop--real-fts format-string (or time timecop--freezetime) universal))

;;;###autoload
(defmacro timecop (freeze-time &rest body)
  "Freeze time at `FREEZE-TIME' and execute `BODY'."
  (declare (indent 4))
  `(cl-letf (((symbol-function 'format-time-string)
              #'timecop--format-time-string))
     (let ((timecop--freezetime (datetime-format-convert-timestamp-dwim ,freeze-time)))
       ,@body)))

(provide 'timecop)
;;; timecop.el ends here
