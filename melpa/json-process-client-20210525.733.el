;;; json-process-client.el --- Interact with a TCP process using JSON  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Damien Cassou

;; Author: Nicolas Petton <nicolas@petton.fr>
;;         Damien Cassou <damien@cassou.me>,
;; Version: 1.0.0
;; Package-Version: 20210525.733
;; Package-Commit: 373b2cc7e3d26dc00594e0b2c1bb66815aad2826
;; Package-Requires: ((emacs "25.1"))
;; Url: https://gitlab.petton.fr/nico/json-process-client

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library starts a process and communicates with it through JSON
;; over TCP.  The process must output one JSON message per line.

;;; Code:

(require 'json)
(require 'map)
(require 'cl-lib)

;; Private variables

(cl-defstruct (json-process-client-application
               (:constructor json-process-client--application-create)
               (:conc-name json-process-client--application-))
  (name nil :read-only t)
  (process nil)
  (port nil :read-only t)
  (connection nil)
  (executable nil :read-only t)
  (args nil :read-only t)
  (tcp-started-callback nil :read-only t)
  (message-callbacks (make-hash-table) :read-only t)
  (debug-buffer nil :read-only t)
  (started-regexp nil :read-only t)
  (save-callback nil :read-only t)
  (exec-callback nil :read-only t)
  (delete-callback nil :read-only t)
  (write-id nil :read-only nil))

(defvar-local json-process-client--application nil
  "Buffer-local variable to store which application the buffer corresponds to.")

(defun json-process-client--save-callback (application callback message)
  "Save CALLBACK so we can call it when a response for MESSAGE arrives from APPLICATION."
  (funcall (json-process-client--application-save-callback application) callback message))

(defun json-process-client--exec-callback (application response)
  "Execute the callback suited to handle response RESPONSE for APPLICATION."
  (funcall (json-process-client--application-exec-callback application) response))

(defun json-process-client--delete-callback (application response)
  "Remove the callback suited to handle response RESPONSE for APPLICATION."
  (funcall (json-process-client--application-delete-callback application) response))


;; Private functions

(defun json-process-client--ensure-process (application)
  "Signal an error if the process for APPLICATION is not started."
  (unless (json-process-client-process-live-p application)
    (user-error "Process for application `%s' not started"
                (json-process-client--application-name application))))

(defun json-process-client--start-server (application)
  "Start a process for APPLICATION."
  (let* ((process (apply
                   #'start-process
                   (format "%s-process" (json-process-client--application-name application))
                   (generate-new-buffer "*json-process-client-process*")
                   (json-process-client--application-executable application)
                   (json-process-client--application-args application))))
    (setf (json-process-client--application-process application) process)
    (set-process-query-on-exit-flag process nil)
    (set-process-filter process (json-process-client-client--process-filter-function application))))

(defun json-process-client-client--process-filter-function (application)
  "Return a process filter function for APPLICATION."
  (lambda (process output)
    (with-current-buffer (process-buffer process)
      (goto-char (point-max))
      (insert output))
    ;; avoid opening TCP connections multiple times:
    (unless (process-live-p (json-process-client--application-connection application))
      (if (string-match-p (json-process-client--application-started-regexp application) output)
	  (json-process-client--open-network-stream application)
	(json-process-client-stop application)
        (error "Application process error: %s" output)))))

(defun json-process-client--open-network-stream (application)
  "Open a network connection to the TCP process for APPLICATION.
The APPLICATION's callback is evaluated once the connection is established."
  (let* ((application-name (json-process-client--application-name application))
         (connection-buffer (generate-new-buffer
                             (format "%s-connection" application-name)))
         (connection (open-network-stream
                      (format "%s-connection" application-name)
                      connection-buffer
                      "localhost"
                      (json-process-client--application-port application)))
         (callback (json-process-client--application-tcp-started-callback application)))
    (setf (json-process-client--application-connection application) connection)
    (with-current-buffer connection-buffer
      (setq-local json-process-client--application application))
    (set-process-filter connection #'json-process-client--connection-filter)
    (set-process-coding-system connection 'utf-8)
    (set-process-query-on-exit-flag connection nil)
    (when callback (funcall callback))))

(defun json-process-client--connection-filter (process output)
  "Filter function for handling the PROCESS OUTPUT."
  (let ((buf (process-buffer process)))
    (with-current-buffer buf
      (save-excursion
	(goto-char (point-max))
	(insert output)))
    (json-process-client--handle-data buf)))

(defun json-process-client--handle-data (buffer)
  "Handle process data in BUFFER.

Read all complete JSON messages from BUFFER and delete them."
  (with-current-buffer buffer
    (when (json-process-client--complete-message-p)
      (save-excursion
        (goto-char (point-min))
        (let ((application json-process-client--application)
              (data (json-read)))
          (delete-region (point-min) (point))
          ;; Remove the linefeed char
          (delete-char 1)
          (json-process-client--handle-message application data)
          (json-process-client--handle-data buffer))))))

(defun json-process-client--complete-message-p ()
  "Return non-nil if the current buffer has at least one complete message.
Messages end with a line feed."
  (save-excursion
    ;; start from (point-max) because the probability to find a \n
    ;; there is higher.
    (goto-char (point-max))
    (search-backward "\n" nil t)))

(defun json-process-client--handle-message (application data)
  "Handle a server message with DATA for APPLICATION."
  (let ((debug-buffer (json-process-client--application-debug-buffer application)))
    (when (bufferp debug-buffer)
      (with-current-buffer debug-buffer
        (goto-char (point-max))
        (insert (format "Received: %s\n\n" data)))))
  (unwind-protect
      (json-process-client--exec-callback application data)
    (json-process-client--delete-callback application data)))


;; Public functions

(cl-defun json-process-client-start (&key name executable port started-regexp tcp-started-callback save-callback exec-callback delete-callback debug args)
  "Start a process using EXECUTABLE.  Return an application object.

NAME is a short string describing the application.  It is used to
name processes and buffers.

PORT is a number indicating which TCP port to connect to reach
EXECUTABLE.

STARTED-REGEXP should match the process output when the process
is listening to TCP connections.

Evaluate TCP-STARTED-CALLBACK once the TCP connection is ready.

SAVE-CALLBACK, EXEC-CALLBACK and DELETE-CALLBACK should be three
functions used to associate callbacks to TCP messages and
responses.

If DEBUG is non-nil, send all messages to a debug buffer.  If
DEBUG is a string, use this as the name for the debug buffer.

ARGS are passed to EXECUTABLE."
  (let* ((executable-path (executable-find executable))
         (debug-buffer (when debug
                         (get-buffer-create
                          (if (stringp debug)
                              debug
                            (format "*json-process-client-%s*" name)))))
         (application (json-process-client--application-create
                       :name name
                       :executable executable-path
                       :port port
                       :args args
                       :tcp-started-callback tcp-started-callback
                       :save-callback save-callback
                       :exec-callback exec-callback
                       :delete-callback delete-callback
                       :started-regexp started-regexp
                       :debug-buffer debug-buffer)))
    (unless executable-path
      (user-error "Cannot find executable \"%s\"" executable))

    (when (bufferp debug-buffer)
      (with-current-buffer debug-buffer
        (erase-buffer)))

    (json-process-client--start-server application)

    application))

(cl-defun json-process-client-start-with-id (&key name executable port started-regexp tcp-started-callback exec-callback debug args)
  "Like `json-process-client-start' but maps responses to callbacks using ids.

The parameters NAME, EXECUTABLE, PORT, STARTED-REGEXP,
TCP-STARTED-CALLBACK, EXEC-CALLBACK, DEBUG, and ARGS are the same
as in `json-process-client-start'.

This function is simpler to use than `json-process-client-start'
because it doesn't require managing a response-to-callback
mapping manually.  Nevertheless, it can only be useful if the
process pointed to by EXECUTABLE reads ids from the messages and
writes them back in its responses."
  (let* ((callbacks (list))
         (application
          (json-process-client-start
           :name name
           :executable executable
           :port port
           :started-regexp started-regexp
           :tcp-started-callback tcp-started-callback
           :save-callback (lambda (callback message)
                            (map-put callbacks (map-elt message 'id) callback))
           :exec-callback (lambda (response)
                            (funcall
                             exec-callback
                             response
                             (map-elt callbacks (map-elt response 'id))))
           :delete-callback (lambda (response)
                              (map-delete callbacks (map-elt response 'id)))
           :debug debug
           :args args)))
    (let ((id 0))
      (setf (json-process-client--application-write-id application)
            (lambda ()
              (cl-incf id)
              `(id . ,id))))
    application))

(defun json-process-client-stop (application)
  "Stop the process and connection for APPLICATION."
  (when (json-process-client-application-p application)
    (let ((connection (json-process-client--application-connection application))
          (process (json-process-client--application-process application)))
      (when (process-live-p connection)
        (kill-buffer (process-buffer process))
        (kill-buffer (process-buffer connection))))
    (setf (json-process-client--application-connection application) nil)
    (setf (json-process-client--application-process application) nil)))

(defun json-process-client-send (application message &optional callback)
  "Send MESSAGE to APPLICATION.
When CALLBACK is non-nil, evaluate it with the process response."
  (json-process-client--ensure-process application)
  (let* ((message (if (json-process-client--application-write-id application)
                      (cons (funcall (json-process-client--application-write-id application)) message)
                    message))
         (json (json-encode message))
         (debug-buffer (json-process-client--application-debug-buffer application)))
    (json-process-client--save-callback application callback message)
    (when (bufferp debug-buffer)
      (with-current-buffer debug-buffer
        (goto-char (point-max))
        (insert (format "Sent: %s\n\n" message))))
    (process-send-string
     (json-process-client--application-connection application)
     (format "%s\n" json))))

(defun json-process-client-process-live-p (application)
  "Return non-nil if the process for APPLICATION is running."
  (and
   (json-process-client-application-p application)
   (process-live-p (json-process-client--application-process application))))

(provide 'json-process-client)
;;; json-process-client.el ends here
