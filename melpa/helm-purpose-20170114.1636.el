;;; helm-purpose.el --- Helm Interface for Purpose -*- lexical-binding: t -*-

;; Copyright (C) 2016 Bar Magal

;; Author: Bar Magal (2016)
;; Package: helm-purpose
;; Version: 0.1
;; Package-Version: 20170114.1636
;; Package-Commit: 9ff4c21c1e9ebc7afb851b738f815df7343bb287
;; Homepage: https://github.com/bmag/helm-purpose
;; Package-Requires: ((emacs "24") (helm "1.9.2") (window-purpose "1.4"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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
;;
;; Provide Helm commands and sources for Purpose.
;; Features:
;; - helmize all Purpose commands
;; - special helm commands:
;;   + `helm-purpose-switch-buffer-with-purpose': same as `helm-buffers-list',
;;     but only list buffers with a specific purpose (default: same purpose as
;;     current buffer).
;;   + `helm-purpose-switch-buffer-with-some-purpose': choose a purpose, then
;;     call `helm-purpose-switch-buffer-with-purpose'.
;;   + `helm-purpose-mini-ignore-purpose': same as `helm-mini', but
;;     ignore Purpose when displaying the buffer.
;;
;; Setup:
;; Call `helm-purpose-setup' in your init file.  It will helmize all Purpose
;; commands, but won't change any key bindings.
;; Alternatively, you can set `purpose-preferred-prompt' to `helm' instead.
;;
;; Key Bindings:
;; `helm-purpose' doesn't bind any keys, you are free to define your own
;; bindings as you please.

;;; Code:

(require 'helm-buffers)
(require 'window-purpose)

(defconst helm-purpose-version "0.1.1"
  "Version of helm-purpose.")

(defvar helm-purpose--current-purpose 'edit)

(defvar helm-source-purpose-buffers-list
  (helm-make-source "Purpose buffers" 'helm-source-buffers
    :buffer-list
    (lambda ()
      ;; return names of buffers with the same purpose as current buffer,
      ;; excluding current buffer
      (mapcar #'buffer-name
              (delq (current-buffer)
                    (purpose-buffers-with-purpose
                     helm-purpose--current-purpose)))))
  "Source for buffers with a specific purpose.
The purpose is decided by `helm-purpose--current-purpose'.")

;;;###autoload
(defun helm-purpose-mini-ignore-purpose ()
  "Same as `helm-mini', but disable window-purpose while the command executes."
  (interactive)
  (without-purpose (helm-mini)))

;;;###autoload
(defun helm-purpose-switch-buffer-with-purpose (&optional purpose)
  "Switch to buffer, choose from buffers with purpose PURPOSE.
PURPOSE defaults to the purpose of the current buffer."
  (interactive)
  (setq helm-purpose--current-purpose
        (or purpose (purpose-buffer-purpose (current-buffer))))
  (helm :sources '(helm-source-purpose-buffers-list helm-source-buffer-not-found)
        :buffer "*helm purpose*"
        :prompt "Buffer: "))

;;;###autoload
(defun helm-purpose-switch-buffer-with-some-purpose ()
  "Choose a purpose, then switch to a buffer with that purpose."
  (interactive)
  (helm-purpose-switch-buffer-with-purpose
   (purpose-read-purpose "Purpose: "
                         ;; don't show purposes that have no buffers
                         (cl-delete-if-not #'purpose-buffers-with-purpose
                                           (purpose-get-all-purposes))
                         t)))

;;;###autoload
(defun helm-purpose-setup ()
  "Setup Helm interface for Purpose.
Currently just sets `purpose-preferred-prompt' to 'helm.
Doesn't bind any keys."
  (setq purpose-preferred-prompt 'helm))

(provide 'helm-purpose)

;;; helm-purpose.el ends here
