;;; services.el --- Services database access functions.
;; Copyright 2000-2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.7
;; Package-Version: 20170802.1130
;; Package-Commit: 04c7986041a33dfa0b0ae57c7d6fbd600548c596
;; Keywords: convenience, net, services
;; URL: https://github.com/davep/services.el
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
;; services.el provides a set of functions for accessing the services
;; details list.
;;
;; The latest services.el is always available from:
;;
;;   <URL:https://github.com/davep/services.el>

;;; BUGS:
;;
;; o Large parts of this code look like large parts of the code you'll find
;;   in protocols.el, this is unfortunate and makes me cringe. However, I
;;   also wanted them to be totally independant of each other. Suggestions
;;   of how to sweetly remedy this situation are welcome.

;;; Code:

;; Things we need:

(eval-when-compile
  (require 'cl-lib))

;; Customisable variables.

(defvar services-file "/etc/services"
  "*Name of the services file.")

;; Non-customize variables.

(defvar services-cache nil
  "\"Cache\" of services.")

(defvar services-name-cache nil
  "\"Cache\" of service names.")

;; Main code:

(defsubst services-name (service)
  "Get the name of service SERVICE."
  (car service))

(defsubst services-port (service)
  "Get the port of service SERVICE."
  (cadr service))

(defsubst services-protocols (service)
  "Get the protocols of service SERVICE."
  (car (cddr service)))

(defsubst services-aliases (service)
  "Get the aliases for service SERVICE."
  (cadr (cddr service)))

(defun services-line-to-list (line)
  "Convert LINE from a string into a structured service list."
  (let* ((words (split-string line))
         (port (split-string (cadr words) "/")))
    (list
     (car words)
     (string-to-number (car port))
     (list (cadr port))
     (cl-loop for s in (cddr words)
              while (not (= (aref s 0) ?#))
              collect s))))

(cl-defun services-read (&optional (file services-file))
  "Read the services list from FILE.

If FILE isn't supplied the value of `services-file' is used."
  (or services-cache
      (setq services-cache
            (when (file-readable-p file)
              (with-temp-buffer
                (insert-file-contents file)
                (setf (point) (point-min))
                (let ((services (list)))
                  (cl-loop for service in
                           (cl-loop until (eobp)
                                    do (setf (point) (line-beginning-position))
                                    unless (or (looking-at "^[ \t]*#") (looking-at "^[ \t]*$"))
                                    collect (services-line-to-list (buffer-substring (line-beginning-position) (line-end-position)))
                                    do (forward-line))
                           do (let ((hit (assoc (services-name service) services)))
                                (if (and hit (= (services-port hit) (services-port service)))
                                    (setf (cdr hit) (list
                                                     (services-port hit)
                                                     (append (services-protocols hit) (services-protocols service))
                                                     (services-aliases hit)))
                                  (push service services)))
                           finally return (reverse services))))))))

(cl-defun services-find-by-name (name &optional (protocol "tcp") (services (services-read)))
  "Find the service whose name is NAME."
  (cl-loop for service in services
           when (and (string= (services-name service) name)
                     (member protocol (services-protocols service)))
           return service))

(cl-defun services-find-by-port (port &optional (protocol "tcp") (services (services-read)))
  "Find the service whose port is PORT."
  (cl-loop for service in services
           when (and (= (services-port service) port)
                     (member protocol (services-protocols service)))
           return service))

(cl-defun services-find-by-alias (alias &optional (protocol "tcp") (services (services-read)))
  "Find a the service whose with an alias of ALIAS."
  (cl-loop for service in services
           when (and (member alias (services-aliases service))
                     (member protocol (services-protocols service)))
           return service))

;;;###autoload
(defun services-lookup (search protocol)
  "Find a service given by SEARCH and PROTOCOL and display its details."
  (interactive (list
                (completing-read "Service Search: "
                                 (or services-name-cache
                                     (setq services-name-cache
                                           (cl-loop for service in (services-read)
                                                    collect (list (services-name service))
                                                    append (cl-loop for alias in (services-aliases service)
                                                                    collect (list alias)))))
                                 nil nil "" nil)
                (completing-read "Protocol: " '(("tcp") ("udp")) nil nil "tcp" nil)))
  (let* ((services (services-read))
         (service (or (when (string-match "^[0-9]+$" search)
                        (services-find-by-port (string-to-number search) protocol services))
                      (services-find-by-name search protocol services)
                      (services-find-by-name (downcase search) protocol services)
                      (services-find-by-name (upcase search) protocol services)
                      (services-find-by-alias search protocol services)
                      (services-find-by-alias (downcase search) protocol services)
                      (services-find-by-alias (upcase search) protocol services))))
    (if service
        (let ((aliases (services-aliases service))
              (protocols (services-protocols service)))
          (message "Service: %s  Port: %d  %s%s"
                   (services-name service)
                   (services-port service)
                   (if aliases
                       (format "Aliases: %s"
                               (with-output-to-string
                                   (cl-loop for alias in (services-aliases service)
                                            do (princ alias) (princ " "))))
                     "")
                   (if protocols
                       (format "%sProtocols: %s"
                               (if aliases " " "")
                               (with-output-to-string
                                   (cl-loop for protocol in protocols
                                            do (princ protocol) (princ " "))))
                     "")))
      (error "No service matching \"%s\" using protocol %s" search protocol))))

;;;###autoload
(defun services-clear-cache ()
  "Clear the services \"cache\"."
  (interactive)
  (setq services-cache      nil
        services-name-cache nil))

(provide 'services)

;;; services.el ends here
