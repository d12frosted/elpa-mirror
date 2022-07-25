;;; with-proxy.el --- Evaluate expressions with proxy -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Gong Qijian <gongqijian@gmail.com>

;; Author: Gong Qijian <gongqijian@gmail.com>
;; Created: 2019/02/25
;; Version: 0.1.0
;; Package-Version: 20200510.414
;; Package-Commit: 93b1ed2f3060f305009fa71f4fb5bb10173a10e3
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/twlz0ne/with-proxy.el
;; Keywords: comm

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

;; Evaluate expressions with proxy
;;
;; ,---
;; | (with-proxy
;; |   ...)
;; |
;; | ;; equals to:
;; | (with-proxy
;; |   :http-server "127.0.0.1:1081"
;; |   :no-proxy '("localhost" "127.0.0.1" "192.168.*" "10.*")
;; |   ...)
;; |
;; | ;; equals to:
;; | (with-proxy-url
;; |   :http-server "127.0.0.1:1081"
;; |   :no-proxy '("localhost" "127.0.0.1" "192.168.*" "10.*")
;; |   (with-proxy-shell
;; |     :http-server "127.0.0.1:1081"
;; |     ...))
;; `---
;;
;; See README for more information.

;;; Change Log:

;;  0.1.0  2019/02/25  Initial version.

;;; Code:

(require 'cl-lib)

(defvar with-proxy-http-server "127.0.0.1:1081")
(defvar with-proxy-no-proxy '("localhost"
                              "127.0.0.1"
                              "192.168.*"
                              "10.*"))

(defun with-proxy--cl-args-body (args)
  "Remove key-value pair from ARGS."
  (let ((it args))
    (catch 'break
      (while t
        (if (keywordp (car it))
            (setq it (cddr it))
          (throw 'break it))))))

(cl-defmacro with-proxy-url (&rest body &key http-server no-proxy &allow-other-keys)
  "Execute BODY with only url proxy.
If HTTP-SERVER is nil, use `with-proxy-http-server' as default.
If NO-PROXY is nil, use `with-proxy-no-proxy' as default."
  (declare (indent 0) (debug t))
  (let ((http-server1 (or http-server with-proxy-http-server))
        (no-proxy1 (or no-proxy with-proxy-no-proxy))
        (body1 (with-proxy--cl-args-body body)))
    `(with-temp-buffer
       (let ((url-proxy-services
              '(("http" . ,http-server1)
                ("https" . ,http-server1)
                ("ftp" . ,http-server1)
                ("no_proxy" . ,(concat "^\\(" (mapconcat #'identity no-proxy1 "\\|") "\\)")))))
         ,@body1))))

(cl-defmacro with-proxy-shell (&rest body &key http-server &allow-other-keys)
  "Execute BODY with only shell proxy.
If HTTP-SERVER is nil, use `with-proxy-http-server' as default."
  (declare (indent 0) (debug t))
  (let ((http-server1 (or http-server with-proxy-http-server))
        (body1 (with-proxy--cl-args-body body)))
    `(with-temp-buffer
       (let ((process-environment (cl-copy-list process-environment)))
         (setenv "http_proxy" ,http-server1)
         (setenv "https_proxy" ,http-server1)
         ,@body1))))

(cl-defmacro with-proxy (&rest body &key http-server no-proxy &allow-other-keys)
  "Execute BODY with both url and shell proxy.
If HTTP-SERVER is nil, use `with-proxy-http-server' as default.
If NO-PROXY is nil, use `with-proxy-no-proxy' as default."
  (declare (indent defun) (debug t))
  `(with-proxy-url :http-server ,http-server :no-proxy ,no-proxy
                   (with-proxy-shell :http-server ,http-server
                                     ,@body)))

(provide 'with-proxy)

;;; with-proxy.el ends here
