;;; ob-uart.el --- org-babel support for UART communication

;; Copyright (C) Andreas Müller

;; Author: Andreas Müller
;; Keywords: tools, comm, org-mode, UART, literate programming, reproducible development
;; Package-Version: 20170521.858
;; Package-Commit: 90daeac90a9e75c20cdcf71234c67b812110c50e
;; Homepage: https://www.0x7.ch
;; Version: 0.0.1

;; code inspired by ob-restclient.el - https://github.com/alf/ob-restclient.el

;;; License:

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
;;

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)

(defgroup ob-uart nil
  "UART support for org babel."
  :group 'org-babel)

(defcustom ob-uart-debug t
  "Whether to notify in case of new commits."
  :package-version '(ob-uart . "0.0.1")
  :group 'ob-uart
  :type 'boolean)

(defvar org-babel-default-header-args:uart
  `((:ienc . "raw")
    (:oenc . "raw")
    (:port . "/dev/ttyUSB0")
    (:speed . 9600)
    (:bytesize . 8)
    (:parity . nil)
    (:stopbits . 1)
    (:flowcontrol . nil)
    (:timeout . 1)
    (:lineend . "\n"))
  "Default arguments for evaluating a UART block.")

;;;###aut
(defun org-babel-execute:uart (body params)
  "Execute a block of Lemonbeat code with org-babel.
This function is called by `org-babel-execute-src-block'
Argument BODY content to send.
Argument PARAMS UART communication parameters."
  (message "executing UART source code block")
  (let* ((ienc (cdr (assoc :ienc params)))
	 (oenc (cdr (assoc :oenc params)))
	 (port (cdr (assoc :port params)))
	 (speed (cdr (assoc :speed params)))
	 (bytesize (cdr (assoc :bytesize params)))
	 (parity (cdr (assoc :parity params)))
	 (stopbits (cdr (assoc :stopbits params)))
	 (flowcontrol (cdr (assoc :flowcontrol params)))
	 (timeout (cdr (assoc :timeout params)))
	 (lineend (cdr (assoc :lineend params)))
	 (process (format "ob-uart-%s" port))
	 (process-buffer (format "*ob-uart-%s*" port)))

    (make-serial-process
     :name process
     :buffer process-buffer
     :speed 115200
     :port port
     :speed speed
     :bytesize bytesize
     :parity parity
     :stopbits stopbits
     :flowcontrol flowcontrol
     :filter 'ob-uart-listen-filter)

    (when (string= "hex" ienc)
	(setq body (mapconcat (lambda (x) (byte-to-string (string-to-number x 16))) (split-string body) "")))

    (process-send-string process (concat body lineend))
    (with-current-buffer process-buffer
      (erase-buffer))

    (sleep-for timeout)

    (let ((result))
      (with-current-buffer process-buffer
	(setq result (buffer-string)))
      (delete-process process)
      (kill-buffer process-buffer)

      (when (string= "hex" oenc)
	  (setq result (mapconcat (lambda (x) (format "%02x" x)) (string-to-list result) " ")))

      (when (string= "HEX" oenc)
	  (setq result (mapconcat (lambda (x) (format "%02X" x)) (string-to-list result) " ")))

      (with-temp-buffer
	(insert result)
	(when (not (string= "raw" oenc))
	    (fill-region (point-min) (point-max)))
	(buffer-string)))))

(defun ob-uart-listen-filter (proc string)
  "Filter to process response.
Argument PROC process.
Argument STRING response string."
  (when ob-uart-debug
      (message (format "ob-uart got %d bytes" (string-bytes string))))
  (with-current-buffer (format "*%s*" (process-name proc))
    (insert string)))

(provide 'ob-uart)
;;; ob-uart.el ends here
