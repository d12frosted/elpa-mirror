;;; mqtt-mode.el --- client for interaction with MQTT servers  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Andreas Müller

;; Author: Andreas Müller <code@0x7.ch>
;; Keywords: tools
;; Package-Version: 20180611.1735
;; Package-Commit: 613e70e9b9940e635e779994b5c83f86eb62c8e6
;; Version: 0.1.0
;; URL: https://github.com/andrmuel/mqtt-mode
;; Package-Requires: ((emacs "25") (dash "2.12.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; mqtt-mode provides a wrapper around mosquitto_sub and mosquitto_pub
;; to interact with MQTT servers from within Emacs.

;;; Code:

(require 'comint)
(require 'subr-x)
(require 'dash)

(defgroup mqtt nil
  "MQTT support."
  :group 'tools)

(defconst mqtt-pub-bin "mosquitto_pub")

(defconst mqtt-sub-bin "mosquitto_sub")

(defcustom mqtt-host "localhost"
  "MQTT server host name."
  :group 'mqtt
  :type 'string)

(defcustom mqtt-port 1883
  "Port number of MQTT server."
  :group 'mqtt
  :type 'integer)

(defcustom mqtt-username nil
  "User name for MQTT server."
  :group 'mqtt
  :type '(choice string (const nil)))

(defcustom mqtt-password nil
  "Password for MQTT server."
  :group 'mqtt
  :type '(choice string (const nil)))

(defcustom mqtt-subscribe-topic "#"
  "Topic to subscribe to."
  :group 'mqtt
  :type 'string)

(defcustom mqtt-publish-topic "emacs"
  "Topic to publish to."
  :group 'mqtt
  :type 'string)

(defcustom mqtt-subscribe-qos-level 0
  "Topic to publish to."
  :group 'mqtt
  :type 'integer)

(defcustom mqtt-publish-qos-level 0
  "Topic to publish to."
  :group 'mqtt
  :type 'integer)

(defcustom mqtt-mosquitto-pub-arguments '()
  "Additional arguments to mosquitto_pub."
  :group 'mqtt
  :type '(repeat string))

(defcustom mqtt-mosquitto-sub-arguments '("-v")
  "Additional arguments to mosquitto_sub."
  :group 'mqtt
  :type '(repeat string))

(defcustom mqtt-timestamp-format "[%y-%m-%d %H:%M:%S]\n"
  "Format for timestamps for incoming messages.

Used as input for 'format-time-string'."
  :group 'mqtt
  :type 'string)

(defcustom mqtt-comint-prompt "---> "
  "Promt string for comint based interface."
  :group 'mqtt
  :type 'string)

(defcustom mqtt-message-receive-functions '()
  "List of functions to run when a new message is received.

The message is passed as first argument (message is passed as
argument).

Note: if both the mqtt-client and mqtt-consumer is active, each
function will be run twice (which may be desirable if client and
consumer are active for different topics, or undesirable).

Example: `(add-to-list 'mqtt-message-receive-functions (lambda (msg) (alert msg)))`"
  :group 'mqtt
  :type '(repeat function))

(define-derived-mode mqtt-mode comint-mode "MQTT Mode"
  "Major mode for MQTT interaction.

\\<mqtt-mode-map>"
  (setq-local comint-prompt-regexp (regexp-quote mqtt-comint-prompt))
  (setq-local comint-prompt-read-only t)
  (comint-output-filter (get-buffer-process (current-buffer)) mqtt-comint-prompt) ; fake initial prompt
  (add-hook 'comint-preoutput-filter-functions 'mqtt-comint-output-filter t t)
  (setq-local comint-input-sender 'mqtt-comint-input-sender))

(defun mqtt-comint-output-filter (string)
  "Filter for incoming messages (to add timestamp and fake prompt).

The message is passed as STRING."
  (run-hook-with-args 'mqtt-message-receive-functions string)
  (concat "\n"
          (propertize (format-time-string mqtt-timestamp-format) 'read-only t 'font-lock-face 'font-lock-comment-face)
          (string-trim string)
          "\n"
          mqtt-comint-prompt))

(defun mqtt-comint-input-sender (proc string)
  "Function to send STRING messages from PROC."
  (ignore proc)
  (mqtt-publish-message string))

;;;###autoload
(defun mqtt-run ()
  "Start comit based MQTT client.

Runs an inferior instance of 'mosquitto_sub' inside Emacs to receive
MQTT messages and uses 'mosquitto_pub' to publish messages."
  (interactive)
  (let* ((args (append `("mqtt-client" ,nil ,mqtt-sub-bin ,nil)
                       (-flatten `(,mqtt-mosquitto-sub-arguments
                                   "-h" ,mqtt-host
                                   "-p" ,(int-to-string mqtt-port)
                                   ,(if (and mqtt-username mqtt-password)
                                        `("-u" ,mqtt-username
                                          "-P" ,mqtt-password))
                                   "-t" ,mqtt-subscribe-topic
                                   "-q" ,(int-to-string mqtt-subscribe-qos-level)))))
         (buffer (apply #'make-comint-in-buffer args)))
    (with-current-buffer buffer
      (display-buffer (current-buffer))
      (mqtt-mode)
      (set-process-query-on-exit-flag (get-buffer-process (current-buffer)) nil)
      (setq-local header-line-format
                  (format "server: %s:%d topic: '%s' / '%s' qos level: %d / %d"
                          mqtt-host
                          mqtt-port
                          mqtt-subscribe-topic
                          mqtt-publish-topic
                          mqtt-subscribe-qos-level
                          mqtt-publish-qos-level)))))

;;;###autoload
(defun mqtt-start-consumer ()
  "Start MQTT consumer.

The consumer subscribes to 'mqtt-subscribe-topic' and shows incoming
messages."
  (interactive)
  (let ((command (-flatten `(,mqtt-sub-bin
                             ,mqtt-mosquitto-sub-arguments
                             "-h" ,mqtt-host
                             "-p" ,(int-to-string mqtt-port)
                             ,(if (and mqtt-username mqtt-password)
                                  `("-u" ,mqtt-username
                                    "-P" ,mqtt-password))
                             "-t" ,mqtt-subscribe-topic
                             "-q" ,(int-to-string mqtt-subscribe-qos-level))))
        (name "mqtt-consumer")
        (buffer "*mqtt-consumer*"))
    (let ((process
           (make-process
            :name name
            :buffer buffer
            :command command
            :filter 'mqtt-consumer-filter)))
      (set-process-query-on-exit-flag process nil)
      (with-current-buffer (process-buffer process)
        (display-buffer (current-buffer))
        (read-only-mode 1)
        (setq-local header-line-format (format "server: %s:%d subscribe topic: '%s'" mqtt-host mqtt-port mqtt-subscribe-topic))))))

(defun mqtt-consumer-filter (proc string)
  "Input filter for mqtt-consumer (filters STRING messages from PROC)."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((moving (= (point) (process-mark proc)))
            (inhibit-read-only t))
        (save-excursion
          ;; Insert the text, advancing the process marker.
          (goto-char (process-mark proc))
          (insert (concat (propertize (format-time-string mqtt-timestamp-format) 'face 'font-lock-comment-face)
                          string))
          (set-marker (process-mark proc) (point)))
        (when moving
          (goto-char (process-mark proc))
          (when (get-buffer-window)
            (set-window-point (get-buffer-window) (process-mark proc))))))
    (run-hook-with-args 'mqtt-message-receive-functions string)))

;;;###autoload
(defun mqtt-publish-message (message &optional topic)
  "Publish given MESSAGE to given TOPIC (default: use 'mqtt-publish-topic')."
  (let* ((topic (if topic topic mqtt-publish-topic))
         (command (-flatten `(,mqtt-pub-bin
                              ,mqtt-mosquitto-pub-arguments
                              "-h" ,mqtt-host
                              "-p" ,(int-to-string mqtt-port)
                              ,(if (and mqtt-username mqtt-password)
                                   `("-u" ,mqtt-username
                                     "-P" ,mqtt-password))
                              "-t" ,topic
                              "-q" ,(int-to-string mqtt-publish-qos-level)
                              "-m" ,message))))
    (make-process
     :name "mqtt-publisher"
     :command command
     :buffer "*mqtt-publisher*")))

;;;###autoload
(defun mqtt-publish-region (start end)
  "Publish region contents (START to END) as MQTT message."
  (interactive "r")
  (mqtt-publish-message (buffer-substring start end)))

(provide 'mqtt-mode)
;;; mqtt-mode.el ends here
