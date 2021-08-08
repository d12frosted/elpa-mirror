;;; tubestatus.el --- Get the London Tube service status -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Matthieu Petiteau

;; Author: Matthieu Petiteau <matt@smallwat3r.com>
;; URL: https://github.com/smallwat3r/tubestatus.el
;; Package-Version: 20210801.1522
;; Package-Commit: eeda4c2647cfdb910de776398037183f48e3fa72
;; Package-Requires: ((emacs "26.1") (request "0.3.2"))
;; Version: 0.0.1

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package allows you to get the live service status of the London
;; Tube using the TfL API (https://api.tfl.gov.uk).

;;; Code:

(require 'cl-lib)
(require 'request)

(defvar tubestatus-tfl-api-url "https://api.tfl.gov.uk/line/%s/status"
  "TfL line status API endpoint.")

(defvar tubestatus-tfl-lines
  '(("Bakerloo"             . "bakerloo")
    ("Central"              . "central")
    ("Circle"               . "circle")
    ("District"             . "district")
    ("DLR"                  . "dlr")
    ("Hammersmith and City" . "hammersmith-city")
    ("Jubilee"              . "jubilee")
    ("Overground"           . "london-overground")
    ("Metropolitan"         . "metropolitan")
    ("Nothern"              . "northern")
    ("Picadilly"            . "piccadilly")
    ("TfL rail"             . "tfl-rail")
    ("Victoria"             . "victoria")
    ("Waterloo and City"    . "waterloo-city"))
  "Association list of TfL Tube lines.")

(defface tubestatus-good-service-face
  '((t :foreground "LimeGreen"))
  "The tubestatus face used when there is a good service on a line."
  :group 'tubestatus-faces)

(defface tubestatus-minor-delay-face
  '((t :foreground "gold"))
  "The tubestatus face used when there is minor delays on a line."
  :group 'tubestatus-faces)

(defface tubestatus-major-delay-face
  '((t :foreground "OrangeRed"))
  "The tubestatus face used when there is major delays on a line."
  :group 'tubestatus-faces)

(defface tubestatus-line-closed-face
  '((t :foreground "SlateGrey"))
  "The tubestatus face used when a line is closed."
  :group 'tubestatus-faces)

(defface tubestatus-special-service-face
  '((t :foreground "DodgerBlue"))
  "The tubestatus face used when a line runs with a special service."
  :group 'tubestatus-faces)

(defun tubestatus--render (data buffer)
  "Render DATA in the tubestatus BUFFER."
  (switch-to-buffer-other-window buffer)
  (setq buffer-read-only nil)
  (erase-buffer)
  (let* ((content (elt data 0))
         (status-content (elt (assoc-default 'lineStatuses content) 0))
         (reason (assoc-default 'reason status-content))
         (sev (assoc-default 'statusSeverity status-content)))
    (insert (concat
             (format "*%s* (Last update: %s)\n\nStatus:\n    "
                     (assoc-default 'name content) (assoc-default 'modified content))
             (cond ((eql sev 10) (propertize "●" 'face 'tubestatus-good-service-face))
                   ((eql sev 20) (propertize "●" 'face 'tubestatus-line-closed-face))
                   ((eql sev 0)  (propertize "●" 'face 'tubestatus-special-service-face))
                   ((>=  sev 8)  (propertize "●" 'face 'tubestatus-minor-delay-face))
                   (t            (propertize "●" 'face 'tubestatus-major-delay-face)))
             (format " %s" (assoc-default 'statusSeverityDescription status-content))
             (if reason
                 (format "\n\nDetails:\n    %s" reason)))))
  (goto-char (point-min))
  (setq buffer-read-only t))

(defun tubestatus--query (line)
  "Get data from the TfL API for a specific LINE."
  (request (format tubestatus-tfl-api-url line)
           :parser 'json-read
           :success
           (cl-function
            (lambda (&key data &allow-other-keys)
              (let ((buffer (get-buffer-create "*tubestatus*")))
                (tubestatus--render data buffer))))
           :error
           (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "An error has occurred while reaching the TfL API: %s"
                       error-thrown)))))

;;;###autoload
(defun tubestatus ()
  "Get the current service status of a London Tube line."
  (interactive)
  (tubestatus--query
   (cdr (assoc (completing-read "Select a line: " tubestatus-tfl-lines)
               tubestatus-tfl-lines))))

(provide 'tubestatus)

;;; tubestatus.el ends here
