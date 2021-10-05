;;; proc-net.el --- network process tools

;; Copyright (C) 2013  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: processes
;; Package-Version: 20130322.12
;; Package-Commit: 10861112a1f3994c8e6374d6c5bb5d734cfeaf73
;; Version: 0.0.1
;; Url: http://github.com/nicferrier/emacs-procnet

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

;; Tools for doing stuff with network processes.

;;; Code:

(require 'tabulated-list)

(defun process-network-show-function (button)
  "Find the filter for the specified net proc."
  (let ((handler-name (button-get button 'process-filter)))
    (find-file (symbol-file handler-name))
    (find-function handler-name)))

(defun process-network/list-entries ()
  "List of processes in `tabulated-list-mode' format."
  (loop for proc in (process-list)
     with addr
     do (setq addr (process-contact proc))
     if (not (eq addr 't))
     collect
       (list (process-name proc)
             (vector (process-name proc)
                     (let* ((stat (process-status proc))
                            (txtstat (format "%S" stat)))
                       (if (eq stat 'listen)
                           `(,txtstat
                             face link
                             help-echo ,(format
                                         "Visit filter `%s'"
                                         (process-contact proc :filter))
                             follow-link t
                             process-filter ,(process-contact proc :filter)
                             action process-network-show-function)
                           txtstat))
                     (let ((buf (process-buffer proc)))
                       (if (buffer-live-p buf)
                           `(,(buffer-name buf)
                              face link
                              help-echo ,(format
                                          "Visit buffer `%s'"
                                          (buffer-name buf))
                              follow-link t
                              process-buffer ,buf
                              action process-menu-visit-buffer)
                           "--"))
                     (format "%s:%s" (or (car addr) "*") (cadr addr))))))

(define-derived-mode
    process-network-list-mode tabulated-list-mode "Network process list"
    "Major mode for listing Emacs network processes."
    (setq tabulated-list-entries 'process-network/list-entries)
    (setq tabulated-list-format
          [("Process Name" 30 nil)
           ("Status" 10 nil)
           ("Buffer" 20 nil)
           ("Address" 10 nil)])
    (tabulated-list-init-header))

;;;###autoload
(defun process-network-list-processes ()
  "List running network processes."
  (interactive)
  (with-current-buffer (get-buffer-create "*network-processes*")
    (process-network-list-mode)
    (tabulated-list-print)
    (switch-to-buffer (current-buffer))))

;;;###autoload
(defalias 'list-network-processes 'process-network-list-processes)

(provide 'proc-net)

;;; proc-net.el ends here
