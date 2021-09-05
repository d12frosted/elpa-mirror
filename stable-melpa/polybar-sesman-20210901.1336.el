;;; polybar-sesman.el --- Display active sesman connections in polybar -*- lexical-binding: t -*-

;; Copyright © 2021 Mark Dawson <markgdawson@gmail.com>

;; Author: Mark Dawson <markgdawson@gmail.com>
;; URL: https://github.com/markgdawson/polybar-sesman.el
;; Package-Version: 20210901.1336
;; Package-Commit: 5175b8d641aad9576519717f69f858621892d5c7
;; Keywords: project, convenience
;; Version: 0.0.1-snapshot
;; Package-Requires: ((emacs "25.1") (dash "2.19.1") (sesman "0.3.0"))

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
;;
;; This library provides an interface to a polybar module which tracks
;; the current sesman connection and the connection status.
;;
;;; Code:

(require 'dash)
(require 'sesman)

(defgroup polybar-sesman nil
  "Manage polybar-sesman customization options."
  :prefix "polybar-sesman-"
  :group 'polybar-sesman)

(defcustom polybar-sesman-color-not-current
  "#4a4e4f"
  "Colour to display when connection is not used by the current buffer."
  :type 'color)

(defcustom polybar-sesman-color-busy
  "#d87e17"
  "Colour to display when connection is busy."
  :type 'color)

(defcustom polybar-sesman-color-current-idle "#839496"
  "Colour to display when connection is current and idle."
  :type 'color)

(defcustom polybar-sesman-connection-format-string "%%{F%s}%s%%{F-}"
  "Format string for polybar color and display name."
  :type 'string)

(defcustom polybar-sesman-polybar-msg "polybar-msg hook sesman-clj 1"
  "The message to send to polybar to request display update."
  :type 'string)

(defcustom polybar-sesman-separator-character "|"
  "Separator character between repl instances."
  :type 'character)

(defcustom polybar-sesman-separator-color "#4a4e4f"
  "Colour of separator character between repl instances."
  :type 'color)

(defcustom polybar-sesman-connection-name-patterns
  '((".*" . polybar-sesman-default-project-name))
  "Alist of regular expression and replacement to apply to the connection name.

If CDR is nil then return the project directory name."
  :type '(alist :key-type string)
  :options '((".*" . polybar-sesman-default-project-name)))

(defun polybar-sesman-separator ()
  "Return the polybar separator."
  (format "%%{F%s} %s %%{F-}"
          polybar-sesman-separator-color
          polybar-sesman-separator-character))

;; ---------------------------------------------------------
;; Store connections
;; ---------------------------------------------------------

(defvar polybar-sesman-connection-states (make-hash-table)
  "Hash table to store the busy state of connections.")

(defun polybar-sesman-set-connection-busy (connection)
  "Mark CONNECTION as busy."
  (puthash connection t polybar-sesman-connection-states))

(defun polybar-sesman-set-connection-idle (connection)
  "Mark CONNECTION as idle."
  (puthash connection nil polybar-sesman-connection-states))

(defun polybar-sesman-connection-busy-p (connection)
  "Return non-nil if CONNECTION is marked as busy."
  (gethash connection polybar-sesman-connection-states))

;; ---------------------------------------------------------
;; Store and update connection for current buffer
;; ---------------------------------------------------------

(defvar polybar-sesman--current-connection nil
  "Tracks the connection that the current buffer uses.")

(defun polybar-sesman--connection-buffer->connection (connection-buffer)
  "Return sesman connection for CONNECTION-BUFFER."
  (-find (lambda (connection)
           (equal (cadr connection) connection-buffer))
         (polybar-sesman--connections)))

(defun polybar-sesman--connection->connection-buffer (connection)
  "Return repl buffer for sesman connection CONNECTION."
  (cadr connection))

(defun polybar-sesman--current-buffer-connection ()
  "Return connection for the current buffer."
  (when sesman-system
    (sesman-current-session sesman-system)))

(defun polybar-sesman--update-current ()
  "Ensure the connection for the current buffer is up to date and call \
POLYBAR-SESMAN-POLYBAR-UPDATE on connection change.

This is usually called as a hook following an event that \
could change the current connection.  Does not record the minibuffer as a buffer change."
  (let ((buffer-connection (polybar-sesman--current-buffer-connection)))
    (unless (or (equal buffer-connection polybar-sesman--current-connection)
                (window-minibuffer-p))
      (setq polybar-sesman--current-connection buffer-connection)
      (polybar-sesman-polybar-update))))

;; ---------------------------------------------------------
;; Connection Display
;; ---------------------------------------------------------

(defun polybar-sesman--connection-current-p (connection)
  "Return non-nil if CONNECTION is the connection in the current buffer."
  (equal polybar-sesman--current-connection connection))

(defun polybar-sesman--connection-name-find-matcher (connection-name)
  "Find the first machine pattern in POLYBAR-SESMAN-CONNECTION-NAME-PATTERNS  \
for a given CONNECTION-NAME."
  (-find (-lambda (connection)
           (string-match-p (car connection) connection-name))
         polybar-sesman-connection-name-patterns))

(defun polybar-sesman-connection-display-name (connection)
  "Return current display name for CONNECTION."
  (-let ((action (cdr (polybar-sesman--connection-name-find-matcher (car connection)))))
    (if (stringp action)
        action
      (funcall action connection))))

(defun polybar-sesman-connection-display-color (connection)
  "Return current display colour for CONNECTION."
  (cond ((polybar-sesman-connection-busy-p connection) polybar-sesman-color-busy)
        ((polybar-sesman--connection-current-p connection) polybar-sesman-color-current-idle)
        (polybar-sesman-color-not-current)))

(defun polybar-sesman-connection-string (connection)
  "Format the display STRING for CONNECTION."
  (format polybar-sesman-connection-format-string
          (polybar-sesman-connection-display-color connection)
          (polybar-sesman-connection-display-name connection)))

;; ---------------------------------------------------------
;; Status string printing
;; ---------------------------------------------------------

(defvar polybar-sesman-sesman-systems '(CIDER))

(defun polybar-sesman--connections ()
  "Return list of all connections."
  (mapcan #'sesman-sessions polybar-sesman-sesman-systems))

(defun polybar-sesman-status-string ()
  "Return status string displayed by polybar."
  (if (bound-and-true-p polybar-sesman-mode)
      (string-join (mapcar #'polybar-sesman-connection-string
                           (polybar-sesman--connections))
                   (polybar-sesman-separator))
    "polybar-sesman-mode disabled"))

(defun polybar-sesman--project-dir (connection)
  "Return project root directory for CONNECTION or nil when no project."
  (when-let ((connection-buffer (polybar-sesman--connection->connection-buffer connection)))
    (expand-file-name (with-current-buffer connection-buffer
                        (sesman-project (sesman--system))))))

(defun polybar-sesman-default-project-name (connection)
  "Pick the default project name for connection in CONNECTION \
as the name of the sesman project root directory."
  (if-let (project (polybar-sesman--project-dir connection))
      (file-name-nondirectory (directory-file-name project))
    (buffer-name (polybar-sesman--connection->connection-buffer connection))))

;; ---------------------------------------------------------
;; Polybar Connections
;; ---------------------------------------------------------

(defun polybar-sesman-polybar-update ()
  "Force polybar to update the sesman component."
  (interactive)
  (start-process-shell-command "polybar-msg" nil polybar-sesman-polybar-msg))

(defun polybar-sesman-start-spinner (connection)
  "Called when CONNECTION becomes busy."
  (polybar-sesman-set-connection-busy connection)
  (polybar-sesman-polybar-update))

(defun polybar-sesman-stop-spinner (connection)
  "Called when CONNECTION becomes idle (may be called multiple times)."
  (polybar-sesman-set-connection-idle connection)
  (polybar-sesman-polybar-update))

;; ---------------------------------------------------------
;; nrepl integration
;; ---------------------------------------------------------

(defun polybar-sesman--around-advice--nrepl-send-request (fn request callback connection-buffer &optional tooling)
  "Around advice for wrapping `nrepl-send-request`.  \
FN is the unwrapped `nrepl-send-request` function.  \
REQUEST CALLBACK CONNECTION-BUFFER and TOOLING have the same \
meaning as `nrepl-send-request`."
  (let ((conn (polybar-sesman--connection-buffer->connection connection-buffer)))
    (polybar-sesman-start-spinner conn)
    (funcall fn request (lambda (response)
                          (funcall callback response)
                          (polybar-sesman-stop-spinner conn))
             connection-buffer
             tooling)))

;; ---------------------------------------------------------
;; Swap sessions in this buffer
;; ---------------------------------------------------------

(defun polybar-sesman--next-sesman-session ()
  "Get the next sesman session in cyclic order."
  (let ((sessions (polybar-sesman--connections)))
    (cadr (-drop-while
           (lambda (session)
             (not (equal polybar-sesman--current-connection session)))
           (append sessions sessions)))))

(defun polybar-sesman-cycle-sessions-buffer ()
  "Cycle through sesman sessions for current buffer."
  (interactive)
  (sesman-link-session (sesman--system) (polybar-sesman--next-sesman-session) 'buffer (current-buffer)))

(defun polybar-sesman--sesman-unlink-all-context ()
  "Unlink all sesman sessions in current context."
  (interactive)
  (mapc #'sesman--unlink
        (sesman-current-links (sesman--system)))
  (run-hooks 'sesman-post-command-hook))

(defun polybar-sesman-cycle-sessions-project ()
  "Cycle through sesman sessions for current projects."
  (interactive)
  (let ((next-session (polybar-sesman--next-sesman-session)))
    ;; note that unlinking can change the current session/connection.
    (polybar-sesman--sesman-unlink-all-context)
    (sesman-link-session (sesman--system) next-session 'project )))

;; ---------------------------------------------------------
;; Minor mode
;; ---------------------------------------------------------

(defun polybar-sesman-turn-on ()
  "Turn on polybar-sesman mode."
  (advice-add 'nrepl-send-request :around #'polybar-sesman--around-advice--nrepl-send-request)
  (add-hook 'buffer-list-update-hook #'polybar-sesman--update-current)
  (add-hook 'cider-connected-hook #'polybar-sesman-polybar-update)
  (add-hook 'cider-disconnected-hook #'polybar-sesman-polybar-update)
  (add-hook 'sesman-post-command-hook #'polybar-sesman--update-current)
  ;; update polybar when mode turned on
  (polybar-sesman--update-current)
  ;; this is to ensure that the polybar disabled message
  ;; disappears when polybar mode is turned on.
  (polybar-sesman-polybar-update))

(defun polybar-sesman-turn-off ()
  "Turn off polybar-sesman mode."
  (mapc #'polybar-sesman-stop-spinner (polybar-sesman--connections))
  (advice-remove 'nrepl-send-request #'polybar-sesman--around-advice--nrepl-send-request)
  (remove-hook 'buffer-list-update-hook #'polybar-sesman--update-current)
  (remove-hook 'cider-connected-hook #'polybar-sesman-polybar-update)
  (remove-hook 'cider-disconnected-hook #'polybar-sesman-polybar-update)
  (remove-hook 'sesman-post-command-hook #'polybar-sesman--update-current)
  (polybar-sesman-polybar-update))

;;;###autoload
(define-minor-mode polybar-sesman-mode
  "Toggle polybar-sesman mode."
  :lighter    " pb-clj"
  :init-value nil
  :global     t
  :group      'polybar-sesman
  (cond
   (noninteractive (setq polybar-sesman-mode nil))
   (polybar-sesman-mode (polybar-sesman-turn-on))
   (t (polybar-sesman-turn-off))))

(provide 'polybar-sesman)

;;; polybar-sesman.el ends here
