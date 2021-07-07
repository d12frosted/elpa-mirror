;;; protocols.el --- Protocol database access functions.
;; Copyright 2000-2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.6
;; Package-Version: 20170802.1132
;; Package-Commit: d0f7c4acb05465f1a0d4be54363bbd2802647e77
;; Keywords: convenience, net, protocols
;; URL: https://github.com/davep/protocols.el
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; protocols.el provides a set of functions for accessing the protocol
;; details list.
;;
;; The latest protocols.el is always available from:
;;
;;   <URL:https://github.com/davep/protocols.el>

;;; BUGS:
;;
;; o Large parts of this code look like large parts of the code you'll find
;;   in services.el, this is unfortunate and makes me cringe. However, I
;;   also wanted them to be totally independant of each other. Suggestions
;;   of how to sweetly remedy this situation are welcome.

;;; Code:

;; Things we need:

(eval-when-compile
  (require 'cl-lib))

;; Customisable variables.

(defvar protocols-file "/etc/protocols"
  "*Name of the protocols file.")

;; Non-customize variables.

(defvar protocols-cache nil
  "\"Cache\" of protocols.")

(defvar protocols-name-cache nil
  "\"Cache\" of protocol names.")

;; Main code.

(defsubst protocols-name (proto)
  "Return the name of protocol PROTO."
  (car proto))

(defsubst protocols-number (proto)
  "Return the number of protocol PROTO."
  (cadr proto))

(defsubst protocols-aliases (proto)
  "Return the alias list of protocol PROTO."
  (cadr (cdr proto)))

(defun protocols-line-to-list (line)
  "Convert LINE from a string into a structured protocol list."
  (let ((words (split-string line)))
    (list
     (car words)
     (string-to-number (cadr words))
     (cl-loop for s in (cddr words)
              while (not (= (aref s 0) ?#))
              collect s))))

(cl-defun protocols-read (&optional (file protocols-file))
  "Read the protocol list from FILE.

If FILE isn't supplied the value of `protocols-file' is used."
  (or protocols-cache
      (setq protocols-cache (when (file-readable-p file)
                              (with-temp-buffer
                                (insert-file-contents file)
                                (setf (point) (point-min))
                                (cl-loop until (eobp)
                                         do (setf (point) (line-beginning-position))
                                         unless (or (looking-at "^[ \t]*#") (looking-at "^[ \t]*$"))
                                         collect (protocols-line-to-list (buffer-substring (line-beginning-position) (line-end-position)))
                                         do (forward-line)))))))

(cl-defun protocols-find-by-name (name &optional (protocols (protocols-read)))
  "Find the protocol whose name is NAME."
  (assoc name protocols))

(cl-defun protocols-find-by-number (number &optional (protocols (protocols-read)))
  "Find the protocol whose number is NUMBER."
  (cl-loop for protocol in protocols
           when (= (protocols-number protocol) number) return protocol))

(cl-defun protocols-find-by-alias (alias  &optional (protocols (protocols-read)))
  "Find the protocol that has an alias of ALIAS."
  (cl-loop for protocol in protocols
           when (member alias (protocols-aliases protocol)) return protocol))

;;;###autoload
(defun protocols-lookup (search)
  "Find a protocol SEARCH and display its details."
  (interactive (list
                (completing-read "Protocol search: "
                                 (or protocols-name-cache
                                     (setq protocols-name-cache
                                           (cl-loop for protocol in (protocols-read)
                                                    collect (list (protocols-name protocol))
                                                    append (cl-loop for alias in (protocols-aliases protocol)
                                                                    collect (list alias))))))))
  (let* ((protocols (protocols-read))
         (protocol (or (when (string-match "^[0-9]+$" search)
                         (protocols-find-by-number (string-to-number search) protocols))
                       (protocols-find-by-name search protocols)
                       (protocols-find-by-name (downcase search) protocols)
                       (protocols-find-by-name (upcase search) protocols)
                       (protocols-find-by-alias search protocols)
                       (protocols-find-by-alias (downcase search) protocols)
                       (protocols-find-by-alias (upcase search) protocols))))
    (if protocol
        (message "Protocol: %s  ID: %d  Aliases: %s"
                 (protocols-name protocol)
                 (protocols-number protocol)
                 (with-output-to-string
                     (cl-loop for alias in (protocols-aliases protocol)
                              do (princ alias) (princ " "))))
      (error "Can't find a protocol matching \"%s\"" search))))

;;;###autoload
(defun protocols-clear-cache ()
  "Clear the protocols \"cache\"."
  (interactive)
  (setq protocols-cache      nil
        protocols-name-cache nil))

(provide 'protocols)

;;; protocols.el ends here
