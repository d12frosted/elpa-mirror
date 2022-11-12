;;; info-beamer.el --- Utilities for working with info-beamer  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2021  Daniel Kraus

;; Author: Daniel Kraus <daniel@kraus.my>
;; Version: 0.1
;; Package-Version: 20210427.1033
;; Package-Commit: 6b4cc29f1aec72d8e23b2c25a99cdd84e6cdc92b
;; Package-Requires: ((emacs "24.4"))
;; Keywords: tools, processes, comm
;; URL: https://github.com/dakra/info-beamer.el
;; SPDX-License-Identifier: GPL-3.0-or-later

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

;; Utilities for working with info-beamer
;;
;; Run your info-beamer node
;; Lookup documentation
;; Send data to your info-beamer node via TCP/UDP/OSC
;;
;; Install the osc package (available from gnu elpa) if you
;; want to send OSC messages to your node.

;;; Code:

(require 'easymenu)
(require 'thingatpt)


;;; Customization

(defgroup info-beamer nil
  "info-beamer"
  :prefix "info-beamer"
  :group 'tools)

(defcustom info-beamer-binary-path "info-beamer"
  "Path to the info-beamer executable."
  :type 'file)

(defcustom info-beamer-keymap-prefix (kbd "C-c '")
  "Info-beamer keymap prefix."
  :type 'key-sequence)

(defcustom info-beamer-udp-host "127.0.0.1"
  "Info beamer UDP host."
  :type 'string
  :safe #'stringp)

(defcustom info-beamer-udp-port 4444
  "Info beamer UDP port."
  :type 'integer
  :safe #'integerp)

(defcustom info-beamer-tcp-host "127.0.0.1"
  "Info beamer TCP host."
  :type 'string
  :safe #'stringp)

(defcustom info-beamer-tcp-port 4444
  "Info beamer TCP port."
  :type 'integer
  :safe #'integerp)


;;; Variables

(defvar info-beamer-udp-process nil
  "UDP process to the info-beamer.")

(defvar info-beamer-tcp-process nil
  "TCP process to the info-beamer.")

(defvar info-beamer-data-history nil
  "Input history for `info-beamer-data'.")

(defvar info-beamer-input-history nil
  "Input history for `info-beamer-input'.")

(defvar info-beamer-osc-history nil
  "Input history for `info-beamer-osc'.")


;;; Functions

(defun info-beamer-get-current-node ()
  "Return current directory."
  (file-name-nondirectory (directory-file-name default-directory)))

(defun info-beamer-get-udp-process ()
  "Get info-beamer UDP network connection."
  (if (and info-beamer-udp-process (process-live-p info-beamer-udp-process))
      info-beamer-udp-process
    (setq info-beamer-udp-process
          (make-network-process
           :name "info-beamer-udp-process"
           :host info-beamer-udp-host
           :service info-beamer-udp-port
           :type 'datagram))))

(defun info-beamer-delete-udp-process ()
  "Deletes UDP process to info-beamer."
  (interactive)
  (when (and info-beamer-udp-process (process-live-p info-beamer-udp-process))
    (delete-process info-beamer-udp-process)))

(defun info-beamer-get-tcp-process ()
  "Get info-beamer TCP network connection."
  (if (and info-beamer-tcp-process (process-live-p info-beamer-tcp-process))
      info-beamer-tcp-process
    (setq info-beamer-tcp-process
          (make-network-process
           :name "info-beamer-tcp-process"
           :host info-beamer-tcp-host
           :service info-beamer-tcp-port
           :filter #'info-beamer-tcp-listen-filter))))

(defun info-beamer-tcp-listen-filter (_proc str)
  "Log output STR from info-beamer TCP connection."
  (message "Info-beamer: %s" str))

(defun info-beamer-disconnect ()
  "Deletes TCP process to info-beamer."
  (interactive)
  (when (and info-beamer-tcp-process (process-live-p info-beamer-tcp-process))
    (delete-process info-beamer-tcp-process)))

;;;###autoload
(defun info-beamer-connect (&optional node)
  "Connect to info-beamer node NODE."
  (interactive)
  (let ((node (or node (info-beamer-get-current-node))))
    (info-beamer-input node)))

(defun info-beamer-input (line)
  "Send LINE via TCP to info-beamer."
  (interactive
   (list (read-from-minibuffer
          "Send line to info beamer: " nil nil nil 'info-beamer-input-history)))
  (let ((process (info-beamer-get-tcp-process)))
    (process-send-string process (concat line "\n"))))

;;;###autoload
(defun info-beamer-data (data &optional node)
  "Send DATA via UDP to info-beamer NODE.
If NODE is NIL use current directory."
  (interactive
   (list (read-from-minibuffer
          "Send data to info beamer: " nil nil nil 'info-beamer-data-history)))
  (let* ((process (info-beamer-get-udp-process))
         (node (or node (info-beamer-get-current-node)))
         (path (format "%s:%s" node data)))
    (process-send-string process path)))

;;;###autoload
(defun info-beamer-osc (suffix &optional node &rest args)
  "Send OSC packet with ARGS to path /NODE/SUFFIX."
  (interactive
   (list (read-from-minibuffer
          "Send OSC packet to path: " nil nil nil 'info-beamer-osc-history)))
  (if (require 'osc nil t)
      (let* ((process (info-beamer-get-udp-process))
             (node (or node (info-beamer-get-current-node)))
             (path (format "/%s/%s" node suffix)))
        (message "Sending OSC message to %s" path)
        (apply 'osc-send-message process path args))
    (error "You need to install OSC to send OSC packets")))

;;;###autoload
(defun info-beamer-run (&optional node)
  "Run info-beamer NODE or current directory."
  (interactive)
  (let* ((path (or node "."))
         (command (format "%s %s" info-beamer-binary-path path))
         (buf-name (format "*info-beamer %s%s*"
                           (info-beamer-get-current-node)
                           (if node (format "/%s" node) ""))))
    (compilation-start command nil (lambda (_mode) buf-name))))

;;;###autoload
(defun info-beamer-doc (&optional anchor)
  "Open info-beamer documentation for ANCHOR or symbol under cursor."
  (interactive)
  (let* ((symbol (or anchor (thing-at-point 'filename)))
         (anchor (if symbol (concat "#" symbol) ""))
         (url (format "https://info-beamer.com/doc/info-beamer%s" anchor)))
    (browse-url url)))


;;; info-beamer-mode

(defvar info-beamer-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "!") 'info-beamer-run)
    (define-key map (kbd "r") 'info-beamer-run)

    (define-key map (kbd "h") 'info-beamer-doc)
    (define-key map (kbd "?") 'info-beamer-doc)

    (define-key map (kbd "c") 'info-beamer-connect)
    (define-key map (kbd "t") 'info-beamer-input)
    (define-key map (kbd "i") 'info-beamer-input)

    (define-key map (kbd "u") 'info-beamer-data)
    (define-key map (kbd "d") 'info-beamer-data)

    (define-key map (kbd "o") 'info-beamer-osc)
    map))

(defvar info-beamer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map info-beamer-keymap-prefix info-beamer-command-map)
    map))

(easy-menu-define info-beamer-mode-menu info-beamer-mode-map
  "Menu for working with info-beamer nodes."
  '("Info-Beamer"
    ["Run" info-beamer-run
     :help "Run current directory as info-beamer node"]
    ["Lookup documentation" info-beamer-doc
     :help "Open info-beamer documentation for the current word in a browser."]
    ["Connect" info-beamer-connect
     :help "Connect to an info-beamer node."]
    ["Send TCP input line" info-beamer-input
     :help "Send a line via TCP to an info-beamer node."]
    ["Send UDP data" info-beamer-data
     :help "Send data via UDP to an info-beamer node."]
    ["Send OSC (open sound control) packet" info-beamer-osc
     :help "Send OSC (open sound control) packet to an info-beamer node."]))

;;;###autoload
(define-minor-mode info-beamer-mode
  "Minor mode to interact with info-beamer nodes.

\\{info-beamer-mode-map}"
  :lighter " info-beamer"
  :keymap info-beamer-mode-map)

(provide 'info-beamer)
;;; info-beamer.el ends here
