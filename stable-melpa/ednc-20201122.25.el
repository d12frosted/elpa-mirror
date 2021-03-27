;;; ednc.el --- Emacs Desktop Notification Center -*- lexical-binding: t; -*-
;; Copyright (C) 2020 Simon Nicolussi

;; Author: Simon Nicolussi <sinic@sinic.name>
;; Version: 0.1
;; Package-Version: 20201122.25
;; Package-Commit: 537e2e165984b53b45cf760ea9e4b86794b8a09d
;; Package-Requires: ((emacs "26.1"))
;; Keywords: unix
;; Homepage: https://github.com/sinic/ednc

;; This program is free software: you can redistribute it and/or modify
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
;; The Emacs Desktop Notification Center (EDNC) is an Emacs package
;; written in pure Lisp that implements a Desktop Notifications service
;; according to the freedesktop.org specification.  EDNC aspires to be
;; a small, but flexible drop-in replacement of standalone daemons like
;; Dunst.  A global minor mode `ednc-mode' tracks active notifications,
;; which users can access by calling the function `ednc-notifications'.
;; They are also free to add their own functions to the (abnormal) hook
;; `ednc-notification-amendment-functions' to amend arbitrary data and
;; to the (abnormal) hook `ednc-notification-presentation-functions' to
;; present notifications as they see fit.  To be useful out of the box,
;; default hooks record all notifications in an interactive log buffer
;; `*ednc-log*'.

;;; Code:
(require 'cl-lib)
(require 'dbus)
(require 'image)
(require 'subr-x)

(defconst ednc-log-name "*ednc-log*")

(defconst ednc--path "/org/freedesktop/Notifications")
(defconst ednc--service (subst-char-in-string ?/ ?. (substring ednc--path 1)))
(defconst ednc--interface ednc--service)

(cl-defstruct (ednc-notification (:constructor ednc--notification-create)
                                 (:copier nil))
  id app-name app-icon summary body actions hints client timer parent
  amendments)

;;;###autoload
(define-minor-mode ednc-mode
  "Act as a Desktop Notifications server and track notifications."
  :global t :lighter " EDNC"
  (if (not ednc-mode)
      (ednc--stop-server)
    (with-current-buffer (get-buffer-create ednc-log-name) (ednc-view-mode))
    (ednc--start-server)))

(defvar ednc-notification-amendment-functions
  (list #'ednc--amend-mouse-controls #'ednc--amend-log-mouse-controls
        #'ednc--amend-icon)
  "Functions in this list are called to amend data to notifications.

Their only argument is the newly added notification.")

(defvar ednc-notification-presentation-functions #'ednc--update-log-buffer
  "Functions in this list are called to present notifications.

Their arguments are the removed notification, if any,
followed by the newly added notification, if any.")

(defvar ednc--state (list 0)
  "The minor mode tracks all active desktop notifications here.

This object is currently implemented as a cons cell: its car is the
count of distinct IDs assigned so far, its cdr is a list of currently
active notifications, newest first.")

(defvar ednc-view-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "RET") #'ednc-invoke-action)
    (define-key map (kbd "TAB") #'ednc-toggle-expanded-view)
    (define-key map "d" #'ednc-dismiss-notification)
    map)
  "Keymap for the EDNC-View major mode.")

(define-derived-mode ednc-view-mode special-mode "EDNC-View"
  "Major mode for viewing desktop notifications."
  (use-local-map ednc-view-mode-map))

(defun ednc-notifications ()
  "Return the list of currently active notifications."
  (cdr ednc--state))

(defun ednc-invoke-action (notification &optional action)
  "Invoke ACTION of the NOTIFICATION.

ACTION defaults to the key \"default\"."
  (interactive (list (get-text-property (point) 'ednc-notification)))
  (unless (and notification (ednc-notification-parent notification))
    (user-error "No active notification at point"))
  (dbus-send-signal :session (ednc-notification-client notification)
                    ednc--path ednc--interface "ActionInvoked"
                    (ednc-notification-id notification) (or action "default")))

(defun ednc-dismiss-notification (notification)
  "Dismiss the NOTIFICATION."
  (interactive (list (get-text-property (point) 'ednc-notification)))
  (unless (and notification (ednc-notification-parent notification))
    (user-error "No active notification at point"))
  (ednc--close-notification notification 2))

(defun ednc-toggle-expanded-view (position &optional prefix)
  "Toggle visibility of further details of notification at POSITION.

With a non-nil PREFIX, make those details visible unconditionally."
  (interactive "d\nP")
  (let ((prop 'ednc-notification))
    (unless (or (get-text-property position prop)
                (when (> position 1)
                  (get-text-property (cl-decf position) prop)))
      (user-error "No notification at or before position"))
    (let* ((end (or (next-single-property-change position prop) (point-max)))
           (begin (or (previous-single-property-change end prop) (point-min)))
           (eol (save-excursion (goto-char begin) (line-end-position)))
           (current (or prefix (get-text-property eol 'invisible)))
           (inhibit-read-only t))
      (when (< eol end) (put-text-property eol end 'invisible (not current))))))

(defun ednc--close-notification-by-id (id)
  "Close the notification identified by ID."
  (if-let* ((found (cl-find id (cdr ednc--state)
                            :test #'eq :key #'ednc-notification-id)))
      (ednc--close-notification found 3)
    (signal 'dbus-error nil))
  :ignore)

(defun ednc--close-notification (notification reason)
  "Close the NOTIFICATION for REASON."
  (run-hook-with-args 'ednc-notification-presentation-functions
                      (ednc--delete-notification notification) nil)
  (dbus-send-signal :session (ednc-notification-client notification)
                    ednc--path ednc--interface "NotificationClosed"
                    (ednc-notification-id notification) reason))

(defun ednc-format-notification (notification &optional expand-flag)
  "Return propertized description of NOTIFICATION.

If EXPAND-FLAG is nil, make details invisible by default."
  (let* ((hints (ednc-notification-hints notification))
         (urgency (or (ednc--get-hint hints "urgency") 1))
         (inherit (if (<= urgency 0) 'shadow (when (>= urgency 2) 'bold))))
    (format (propertize " %s[%s: %s]%s" 'face (list :inherit inherit)
                        'ednc-notification notification)
            (alist-get 'icon (ednc-notification-amendments notification) "")
            (ednc-notification-app-name notification)
            (ednc--format-summary notification)
            (propertize (concat "\n" (ednc-notification-body notification) "\n")
                        'invisible (not expand-flag)))))

(defun ednc--format-summary (notification)
  "Return propertized summary of NOTIFICATION."
  (let ((summary (ednc-notification-summary notification))
        (controls (alist-get 'controls
                             (ednc-notification-amendments notification))))
    (propertize summary 'mouse-face 'mode-line-highlight 'keymap
                `(keymap (header-line keymap . ,controls)
                         (mode-line keymap . ,controls) . ,controls))))

(defun ednc--amend-mouse-controls (new)
  "Amend default mouse controls to NEW notification."
  (setf (alist-get 'controls (ednc-notification-amendments new))
        (nconc `((mouse-1 . ,(lambda () (interactive) (ednc-invoke-action new)))
                 (C-down-mouse-1 . ,(ednc--get-actions-keymap new))
                 (mouse-3 . ,(lambda () (interactive)
                               (ednc-dismiss-notification new))))
               (alist-get 'controls (ednc-notification-amendments new)))))

(defun ednc--amend-log-mouse-controls (new)
  "Amend mouse controls for log navigation to NEW notification."
  (push `(mouse-2 . ,(lambda () (interactive)
                       (ednc-pop-to-notification-in-log-buffer new)))
        (alist-get 'controls (ednc-notification-amendments new))))

(defun ednc--get-actions-keymap (notification)
  "Return keymap for actions of NOTIFICATION."
  (cl-loop with in = (ednc-notification-actions notification) and out for i by 1
           while in do (push (let ((key (pop in)))
                               (list i 'menu-item (pop in)
                                     (lambda () (interactive)
                                       (ednc-invoke-action notification key))))
                             out)
           finally return (cons 'keymap (nreverse (cons "Actions" out)))))

(defun ednc--start-server ()
  "Register server to keep track of notifications in `ednc--state'."
  (dolist (args `(("Notify" ,#'ednc--notify t)
                  ("CloseNotification" ,#'ednc--close-notification-by-id t)
                  ("GetServerInformation"
                   ,(lambda () (list "EDNC" "sinic" "0.1" "1.2")) t)
                  ("GetCapabilities" ,(lambda () '(("body" "actions"))) t)))
    (apply #'dbus-register-method :session
           ednc--service ednc--path ednc--interface args))
  (dbus-register-service :session ednc--service))

(defun ednc--stop-server ()
  "Dismiss all notifications, then unregister server."
  (mapc #'ednc-dismiss-notification (cdr ednc--state))
  (dbus-unregister-service :session ednc--service))

(defun ednc--notify (app-name replaces-id app-icon summary body actions
                              hints expire-timeout)
  "Handle call by introducing a new notification and return its ID.

APP-NAME, REPLACES-ID, APP-ICON, SUMMARY, BODY, ACTIONS, HINTS, EXPIRE-TIMEOUT
are the received values as described in the Desktop Notification standard."
  (let* ((old (when (> replaces-id 0)
                (cl-find replaces-id (cdr ednc--state)
                         :test #'eq :key #'ednc-notification-id)))
         (id (if old replaces-id (cl-incf (car ednc--state))))
         (new (ednc--notification-create
               :id id :app-name app-name :app-icon app-icon
               :summary summary :body body :actions actions :hints hints
               :client (dbus-event-service-name last-input-event))))
    (when old (ednc--delete-notification old))
    (ednc--push-notification new ednc--state (/ expire-timeout 1000.0))
    (run-hook-with-args 'ednc-notification-amendment-functions new)
    (run-hook-with-args 'ednc-notification-presentation-functions old new)
    id))

(defun ednc--amend-icon (new)
  "Set icon string created from NEW notification.

This function modifies the notification's hints."
  (catch 'invalid
    (let* ((hints (ednc-notification-hints new))
           (image
            (or (ednc--data-to-image (ednc--get-hint hints "image-data" t))
                (ednc--path-to-image (ednc--get-hint hints "image-path"))
                (ednc--path-to-image (ednc-notification-app-icon new))
                (ednc--data-to-image (ednc--get-hint hints "icon_data" t)))))
      (when image
        (setf (image-property image :max-height) (line-pixel-height)
              (image-property image :ascent) 90)
        (push (cons 'icon (propertize " " 'display image))
              (ednc-notification-amendments new))))))

(defun ednc--get-hint (hints key &optional remove-flag)
  "Return and delete from HINTS the value specified by KEY.

The returned value is removed from HINTS if REMOVE-FLAG is non-nil."
  (let* ((pair (assoc key hints))
         (tail (cdr pair)))
    (when (and remove-flag pair) (setcdr pair nil))
    (caar tail)))

(defun ednc--path-to-image (image-path)
  "Return image descriptor created from file URI IMAGE-PATH."
  (when-let* ((image-path (unless (string-empty-p image-path)
                            (string-remove-prefix "file://" image-path))))
    (if (eq (aref image-path 0) ?/)
        (with-temp-buffer
          (set-buffer-multibyte nil)
          (ignore-errors (insert-file-contents-literally image-path))
          (unless (string-empty-p (buffer-string))
            (create-image (buffer-string) nil t)))
      (throw 'invalid (message "unsupported image path: %s" image-path)))))

(defun ednc--data-to-image (image-data)
  "Return image descriptor created from raw (iiibiiay) IMAGE-DATA.

This function is destructive."
  (when (and image-data (image-type-available-p 'pbm))
    (cl-destructuring-bind (width height row-stride _ bit-depth channels data)
        image-data
      (if (not (and (= bit-depth 8) (<= 3 channels 4)))
          (throw 'invalid (message "unsupported image parameters"))
        (ednc--delete-padding data (* channels width) row-stride)
        (ednc--delete-padding data 3 channels)
        (let ((header (format "P6\n%d %d\n255\n" width height)))
          (create-image (apply #'unibyte-string (append header data))
                        'pbm t))))))

(defun ednc--delete-padding (list payload total)
  "Delete LIST elements between multiples of PAYLOAD and TOTAL.

This function is destructive."
  (when (< payload total)
    (let ((cell (cons nil list))
          (delete (if (and (= payload 3) (= total 4)) #'cddr  ; fast opcode
                    (apply-partially #'nthcdr (- total payload -1))))
          (keep (if (= payload 3) #'cdddr (apply-partially #'nthcdr payload))))
      (while (cdr cell)
        (setcdr (setq cell (funcall keep cell)) (funcall delete cell))))))

(defun ednc--push-notification (notification state expiry)
  "Push NOTIFICATION to STATE (expiring in EXPIRY seconds)."
  (setf (ednc-notification-parent notification) state)
  (when (> expiry 0)
    (setf (ednc-notification-timer notification)
          (run-at-time expiry nil #'ednc--close-notification notification 1)))
  (let ((next (cadr state)))
    (push notification (cdr state))
    (if next (setf (ednc-notification-parent next) (cdr state)))))

(defun ednc--delete-notification (notification)
  "Delete NOTIFICATION from state it was pushed to and return it."
  (let ((suffix (ednc-notification-parent notification)))
    (setf (ednc-notification-parent notification) nil)
    (when-let* ((timer (ednc-notification-timer notification)))
      (cancel-timer timer))
    (when-let* ((next (caddr suffix)))
      (setf (ednc-notification-parent next) suffix))
    (pop (cdr suffix))))

(defun ednc-pop-to-notification-in-log-buffer (notification)
  "Pop to NOTIFICATION in its log buffer, if it exists."
  (cl-destructuring-bind (buffer . position)
      (alist-get 'logged (ednc-notification-amendments notification) '(nil))
    (if (not (buffer-live-p buffer))
        (user-error "Log buffer no longer exists")
      (pop-to-buffer buffer)
      (ednc-toggle-expanded-view (goto-char position) t))))

(defun ednc--remove-old-notification-from-log-buffer (old)
  "Remove OLD notification from its log buffer, if it exists."
  (cl-destructuring-bind (buffer . position)
      (alist-get 'logged (ednc-notification-amendments old) '(nil))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (save-excursion
          (add-text-properties (goto-char position) (line-end-position)
                               '(face (:strike-through t))))))))

(defun ednc--append-new-notification-to-log-buffer (new)
  "Append NEW notification to log buffer."
  (with-current-buffer (get-buffer-create ednc-log-name)
    (unless (derived-mode-p #'ednc-view-mode) (ednc-view-mode))
    (save-excursion
      (push `(logged ,(current-buffer) . ,(goto-char (point-max)))
            (ednc-notification-amendments new))
      (insert (ednc-format-notification new) ?\n))))

(defun ednc--update-log-buffer (old new)
  "Remove OLD notification from and add NEW one to log buffer."
  (let ((inhibit-read-only t))
    (when old (ednc--remove-old-notification-from-log-buffer old))
    (when new (ednc--append-new-notification-to-log-buffer new))))

(provide 'ednc)
;;; ednc.el ends here
