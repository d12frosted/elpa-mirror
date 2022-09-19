;;; pixelblaze.el --- Interact with a Pixelblaze via Websocket    -*- lexical-binding: t -*-

;; Copyright (c) 2020-2022 Mark Grosen

;; Author: Mark Grosen <mark@grosen.org>
;; Maintainer: Mark Grosen <mark@grosen.org>
;; Created: 15 Mar 2020
;; Version: 0.3
;; Package-Version: 20220918.1925
;; Package-Commit: 564a093f700a3292cbffb3887dd3a8d789f54e6d
;; Package-Requires: ((emacs "27.1") (websocket "1.13"))
;; Keywords: games, pixelblaze, neopixel, ws2812, sk6812
;; URL: https://github.com/mgsb/emacs-pixelblaze

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the gnu general public license as
;; published by the free software foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  see the gnu
;; general public license for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Interact with a Pixelblaze LED controller using the Websocket API
;; (Reference: https://www.bhencke.com/pixelblaze-advanced#Websocket-API)
;; Set display pattern, brightness, controls and variables.
;; Query configuration, set of patterns, controls and variables.

;; Example:
;;
;; (let ((pb pixelblaze-open "pixelblaze.local"))
;;   (pixelblaze-set-pattern pb "rainbow fonts")
;;   (pixelblaze-set-brightness pb 0.25)
;;   (pixelblaze-close pb))
;;

;;; Code:

(require 'websocket)

(defgroup pixelblaze nil
  "Interact with a Pixelblaze LED controller."
  :group 'misc)

(defcustom pixelblaze-default-address "pixelblaze.lan"
  "Hostname or IP address default of Pixelblaze."
  :type 'string
  :group 'pixelblaze)

(defcustom pixelblaze-default-id "none"
  "ID of default pattern for Pixelblaze."
  :type 'string
  :group 'pixelblaze)

(defun pixelblaze--poll-timeout (pred timeout)
  "Poll a predicate PRED until t or TIMEOUT."
  (let ((begin (current-time)))
    (while (and (not (funcall pred))
                (< (float-time (time-subtract (current-time) begin)) timeout))
      (sleep-for 0.05)))
  (funcall pred))

(defun pixelblaze--make-request (pb msg &optional response-handler)
  "Send MSG to PB with response processed by RESPONSE-HANDLER.
The Pixelblaze has three return types from requests (by observation):
  1. Nothing
  2. JSON string
  3. Binary header string tables
Since most requests return JSON, the default (nil) handler will
return a hash from 'json-parse-string' of the response
The 'pixelblaze--nop' utility is used for the nothing returned case."
  (if (not response-handler)
      (let ((response nil))
        (setf (websocket-on-message pb)
              (lambda (_ws frame)
                (setq response (json-parse-string (websocket-frame-text frame)))))
        (websocket-send-text pb msg)
        (pixelblaze--poll-timeout (lambda () (or response)) 2)
        response)
    (setf (websocket-on-message pb) response-handler)
    (websocket-send-text pb msg)))

(defun pixelblaze--nop (_ws frame)
  "Empty message response utility function to warn about unused FRAME."
  (message "pixelblaze: unused msg response: %s" (websocket-frame-text frame)))

;; Undocumented request:
;; https://forum.electromage.com/t/pixelblaze-client-python-3-library-for-pixelblaze/756/6
(defun pixelblaze--sync (pb)
  "Wait for all queued requests to be done on PB."
  (pixelblaze--make-request pb "{\"ping\": true}"))

(defun pixelblaze-open (&optional address)
  "Open connection to Pixelblaze board at ADDRESS and return websocket."
  (let ((ws (websocket-open
             (concat "ws://" (or address pixelblaze-default-address) ":81")
             :on-error (lambda (ws method error)
                         (message "pixelblaze - websocket error: %s %s" method error)
                         (websocket-close ws)))))
    (if (pixelblaze--poll-timeout (lambda () (websocket-openp ws)) 2) ws nil)))

(defun pixelblaze-close (pb)
  "Close connection to Pixelblaze PB."
  (pixelblaze--sync pb)
  (websocket-close pb))

(defun pixelblaze-set-brightness (pb brightness)
  "Set BRIGHTNESS for Pixelblaze PB to specified value (0.0 - 1.0)."
  (pixelblaze--make-request pb (format "{\"brightness\": %f}" brightness)
                            'pixelblaze--nop))

(defun pixelblaze-get-controls (pb id)
  "Get controls and values for pattern ID from PB returned as hash."
  (gethash id (gethash "controls"
                       (pixelblaze--make-request pb (format "{\"getControls\": \"%s\"}" id)))))

(defun pixelblaze-set-controls (pb values &optional save)
  "Set controls' VALUES (hash) for current pattern on PB and optionally SAVE."
  (pixelblaze--make-request pb (format "{\"setControls\": %s}, \"save\": %s}"
                                       (json-serialize values) (if save "true" "false"))
                            'pixelblaze--nop))

(defun pixelblaze-get-vars (pb)
  "Get variables and values from PB for current pattern returned as hash."
  (gethash "vars" (pixelblaze--make-request pb "{\"getVars\": true}")))

(defun pixelblaze-set-vars (pb vars)
  "Set values of PB's current pattern's variables from hash VARS."
  (pixelblaze--make-request pb (format "{\"setVars\": %s}" (json-serialize vars))
                            'pixelblaze--nop))

(defun pixelblaze-get-patterns (pb)
  "Get the set of pattern names and ids from PB returned as hash."
  (or (websocket-client-data pb)
      (let ((patterns (make-hash-table :test 'equal)) (done nil))
        (pixelblaze--make-request pb "{\"listPrograms\": true}"
                                  (lambda (_ws frame)
                                    (let ((ftext (websocket-frame-text frame)))
                                      (dolist (row (split-string (substring ftext 2 nil) "\n"))
                                        (if (> (length row) 0)
                                            (let ((prog (split-string row "\t")))
                                              (puthash (car (cdr prog)) (car prog) patterns))))

                                      (if (< 0 (compare-strings (substring ftext 0 2)
                                                                0 2 "" 0 2))
                                          (setq done t)))))
        (pixelblaze--poll-timeout (lambda () (or done)) 3)
        (setf (websocket-client-data pb) patterns))))

(defun pixelblaze-set-pattern (pb pattern)
  "Set PATTERN for PB and return id and controls as hash."
  (pixelblaze-set-pattern-id pb (gethash pattern (pixelblaze-get-patterns pb))))

(defun pixelblaze-set-pattern-id (pb &optional id)
  "Set pattern for PB to ID and return id and controls as hash."
  (gethash "activeProgram"
           (pixelblaze--make-request pb (format "{\"activeProgramId\": \"%s\"}"
                                                (or id pixelblaze-default-id)))))

(defun pixelblaze-get-config (pb)
  "Get current operating configuration of PB returned as hash."
  (pixelblaze--make-request pb "{\"getConfig\": true}"))

(defun pixelblaze-with (func &optional address)
  "Call FUNC with auto opened and closed Pixelblaze at ADDRESS."
  (let ((pb (pixelblaze-open address)))
    (funcall func pb)
    (pixelblaze-close pb)))

;;;###autoload
(defun pixelblaze-choose-pattern (&optional address)
  "Choose pattern to display from all patterns on Pixelblaze at ADDRESS."
  (interactive)
  (let ((ip-address address))
    (if current-prefix-arg
        (setq ip-address (read-string "Address: " pixelblaze-default-address)))
    (pixelblaze-with
     (lambda (pb)
       (let ((patterns (pixelblaze-get-patterns pb)))
         (pixelblaze-set-pattern-id pb (format "%s"
                                               (gethash (completing-read "Pattern: "
                                                                         patterns)
                                                        patterns)))))
     ip-address)))

(provide 'pixelblaze)

;;; pixelblaze.el ends here
