;;; svgo.el --- SVG optimization with SVGO -*- lexical-binding: t; -*-

;; Author: Mathis Hofer <mathis@fsfe.org>
;; Version: 1.0.3
;; Package-Version: 20220525.2059
;; Package-Commit: 9b01cc9eb1fdf2731cd2b931a7dfe1f601b70786
;; Package-Requires: ((emacs "26.2"))
;; Keywords: tools
;; URL: https://github.com/hupf/svgo.el/

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package uses the Node utility SVGO to optimize SVG files.  It
;; provides a command to reduce the size of the SVG contents in the
;; current Emacs buffer.
;;
;; To install this package you should use `use-package', like so:
;;
;; (use-package svgo
;;   :hook
;;   (nxml-mode . (lambda () (bind-key "M-o" 'svgo nxml-mode-map)))
;;   (image-mode . (lambda () (bind-key "M-o" 'svgo image-mode-map))))
;;
;; Also make sure you have Node/NPM installed on your machine.

;;; Code:

(require 'subr-x)
(require 'image-mode)

(defgroup svgo nil
  "SVG optimization within Emacs with SVGO."
  :group 'tools
  :prefix "svgo-"
  :link '(url-link :tag "Github" "https://github.com/hupf/svgo.el"))

(defcustom svgo-process-buffer "*svgo*"
  "Name of buffer used for process output."
  :type 'string)

;;;###autoload
(defun svgo ()
  "Optimize current buffer with SVGO."
  (interactive)
  ;; Use current buffer's Node version if nvm.el is present
  (when (fboundp 'nvm-use-for-buffer)
    (nvm-use-for-buffer))

  (when (svgo--ensure)
    (when (and (eq major-mode 'image-mode)
               (string-equal image-type "svg"))
      ;; Switch to nxml-mode, when image is displayed
      (image-toggle-display))
    (let* ((result (svgo--with-buffer-size-change
                    (lambda ()
                      (svgo--with-read-only-buffer
                       (shell-command-on-region
                        (point-min) (point-max)
                        "svgo -i -" svgo-process-buffer t svgo-process-buffer t)))))
           (exit-code (nth 0 result))
           (before-size (nth 1 result))
           (after-size (nth 2 result))
           (percentage (nth 3 result)))
      (if (= exit-code 0)
          (message "%s → %s (%s)" before-size after-size percentage)

        (undo))))) ;; If command failed, undo to make sure the region's content is recovered

(defun svgo--ensure ()
  "Ensure SVGO is present or install it if user agrees."
  (let ((svgo-bin (executable-find "svgo")))
    (if svgo-bin
        svgo-bin
      (if (executable-find "npm")
          (if (yes-or-no-p "No `svgo' command found, would you like to install it globally?")
              (if (> (svgo--with-read-only-buffer
                      (shell-command "npm install -g svgo" svgo-process-buffer svgo-process-buffer))
                     0)
                  (progn
                    (switch-to-buffer svgo-process-buffer)
                    (message "An error occurred installing `svgo' using NPM")
                    nil)
                (executable-find "svgo")))
        (message "No `svgo' command found and `npm' is not present")
        nil))))

(defun svgo--with-buffer-size-change (wrapped-function)
  "Call the WRAPPED-FUNCTION and measure the current buffer size before/after."
  (let ((before (buffer-size)))
    (let ((result (funcall wrapped-function)))
      (let* ((after (buffer-size))
             (factor (if (> after 0) (/ (float after) before) 0))
             (before-human (svgo--human-bytes before))
             (after-human (svgo--human-bytes after))
             (percentage (format "%.2f %%" (* factor 100.0))))
        (list
         result
         before-human
         after-human
         percentage)))))

(defun svgo--human-bytes (bytes)
  "Return given number of BYTES as human readable string with unit."
  (cond
   ((> bytes 1000000) (format "%.2f MB" (/ bytes 1000000.0)))
   ((> bytes 100000) (format "%.2f kB" (/ bytes 1000.0)))
   ((> bytes 1000) (format "%.2f kB" (/ bytes 1000.0)))
   (t (format "%d B" bytes))))

(defun svgo--with-read-only-buffer (result)
  "Mark the `svgo-process-buffer' read only and return RESULT."
  (let ((buffer (get-buffer svgo-process-buffer)))
    (when buffer (with-current-buffer buffer (special-mode))))
  result)

(provide 'svgo)
;;; svgo.el ends here
