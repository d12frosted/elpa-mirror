;;; use-proxy.el --- Enable/Disable proxies respecting your HTTP/HTTPS env  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Ray Wang <ray.hackmylife@gmail.com>

;; Author: Ray Wang <ray.hackmylife@gmail.com>
;; Package-Requires: ((exec-path-from-shell "1.12") (emacs "26.2"))
;; Package-Commit: 31d8bbec16eff342bd4c02b0cb12ea31dd31bf19
;; Package-Version: 20201209.853
;; Package-X-Original-Version: 0
;; Keywords: proxy, comm
;; URL: https://github.com/rayw000/use-proxy

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;; With this package you can easily enable/disable proxies per protocol in you Emacs.
;; You could also use this package to provide proxy settings for a group of s-expressions.
;; All the package does to your environment is operating the global variable `url-proxy-services',
;; Every time you enable/disable proxies, `url-proxy-services' will be saved into your `custom.el'.
;;
;; Similar packages:
;; https://github.com/stardiviner/proxy-mode, https://github.com/twlz0ne/with-proxy.el

;; Usage:
;;
;;   Require package:
;;
;;     (require 'use-proxy) ;; if not using the ELPA package
;;     (use-proxy-mode) ;; globally enable `use-proxy-mode' to handle proxy settings
;;
;;   Customization:
;;
;;     This package provides these following variables you could customize:
;;
;;     `use-proxy-http-proxy'
;;     HTTP proxy you could use.
;;     If not set, the value of $HTTP_PROXY in your environment will be used
;;
;;     `use-proxy-https-proxy'
;;     HTTPS proxy you could use.
;;     If not set, the value of $HTTPS_PROXY in your environment will be used.
;;
;;     `use-proxy-no-proxy'
;;     A regular expression matches hosts you don't want to connect through proxy
;;     If not set, the value of $NO_PROXY in your environment will be used.
;;
;;     `use-proxy-display-in-global-mode-string'
;;     Boolean indicates whether display proxy states in `global-mode-string' when %M is enabled in your `mode-line-format'.
;;
;;     NOTICE: Do not forget to load your `custom-file' if you customized these variables.
;;
;;   Macros and functions:
;;
;;     `use-proxy-toggle-proto-proxy'
;;
;;     Toggle specified proxy by protocol
;;
;;     (use-proxy-toggle-proto-proxy)
;;     ;; Running this command will prompt you available protocols
;;     ;; to choose to enable the corresponding proxy.
;;     ;; Enabled proxies will be shown in the minor mode lighter.
;;
;;     `use-proxy-toggle-proxies-global'
;;
;;     Toggle proxies global or not (respecting "no_proxy" settings or not)
;;
;;     (use-proxy-toggle-proxies-global)
;;     ;; if using proxies globally, a "g" will be appended to lighter.
;;
;;     `use-proxy-toggle-all-proxies'
;;
;;     Toggle all proxies on/off.
;;
;;     (use-proxy-toggle-all-proxies)
;;     ;; toggle all proxies on/off.
;;
;;     `use-proxy-with-custom-proxies'
;;
;;     Temporarily enable proxies for a batch of s-expressions.
;;     You are only required to provide a protocol list which you want to enable proxies for.
;;     This macro will read corresponding proxy settings from your customization variables.
;;
;;     (use-proxy-with-custom-proxies '("http" "https")
;;       (browse-url-emacs "https://www.google.com"))
;;
;;     `use-proxy-with-specified-proxies'
;;
;;     Temporarily enable proxies for a batch of s-expression.
;;     You are required to provide a proxy setting association list.
;;
;;     (use-proxy-with-specified-proxies '(("http" . "localhost:8080")
;;                                         ("https" . "localhost:8081"))
;;       (browse-url-emacs "https://www.google.com"))

;;; Code:
;; TODO Proxy auto-config support

(require 'exec-path-from-shell)

(defgroup use-proxy nil
  "Use proxy globally or limited to single S-expression."
  :prefix "use-proxy-"
  :group 'comm)

(exec-path-from-shell-copy-envs '("HTTP_PROXY" "HTTPS_PROXY" "NO_PROXY"))

(defcustom use-proxy-http-proxy (or (getenv "HTTP_PROXY")
                                    "proxy.not.set")
  "HTTP proxy in HOST:PORT format, default is the value of $HTTP_PROXY."
  :type '(string)
  :group 'use-proxy)

(defcustom use-proxy-https-proxy (or (getenv "HTTPS_PROXY")
                                     (getenv "HTTP_PROXY")
                                     "proxy.not.set")
  "HTTPS proxy in HOST:PORT format.
If not set, it will first try to
use the value of $HTTPS_PROXY, and then $HTTP_PROXY"
  :type '(string)
  :group 'use-proxy)

(defcustom use-proxy-no-proxy (or (getenv "NO_PROXY")
                                  "^\\(localhost\\|10\\..*\\|192\\.168\\..*\\)")
  "Regular expression described hosts you don't want to access through a proxy.
If not set, it will first try to use the value of $NO_PROXY,
and then\"^\\(localhost\\|10\\..*\\|192\\.168\\..*\\)\""
  :type '(string)
  :group 'use-proxy)

(defvar use-proxy--available-protocols '("http" "https"))

(defcustom use-proxy-display-in-global-mode-string t
  "If non-nil, proxy states will also be added into `global-mode-string'.
In which case even if you turn off minor mode list or work with `diminish',
proxy states would still be visible in your mode line if you enable %M substitution."
  :type 'boolean)

(add-to-list 'global-mode-string
             '(:eval (when (and (bound-and-true-p use-proxy-mode)
                                use-proxy-display-in-global-mode-string)
                       (use-proxy--proxy-states)))
             'APPEND)

(defun use-proxy--valid-proxy-p (proxy)
  "Check if PROXY is valid."
  (and (stringp proxy)
       (string-match-p "^\\([0-9a-zA-Z_-]+\\.\\)*[0-9a-zA-Z_-]+\\(:[0-9]+\\)?$" proxy)))

(defun use-proxy--trim-proxy-address (address)
  "Trim proxy ADDRESS from '<scheme>://<host>:<port>' into '<host>:<port>'.
Because the former may lead name resolving errors."
  (if (stringp address)
      (car (last (split-string address "//")))
    address))

(defun use-proxy--get-custom-proxy-var-by-proto (proto)
  "Get proxy setting by protocol.
Argument PROTO protocol which you want to get proxy of."
  (if (member proto use-proxy--available-protocols)
      (use-proxy--trim-proxy-address
       (symbol-value (intern-soft (format "use-proxy-%s-proxy" proto))))
    (error "%s proxy is not supported yet" proto)))

(defun use-proxy--proxy-states ()
  (format "[%s]%s"
          (string-join
           (mapcar #'car
                   (seq-filter
                    (lambda (x)
                      (and (not (string= (car x) "no_proxy"))
                           (use-proxy--valid-proxy-p (cdr x))))
                    url-proxy-services)) ",")
          (if (assoc "no_proxy" url-proxy-services) "" "g")))

(defun use-proxy--modeline-string ()
  (format " proxy%s"
          (use-proxy--proxy-states)))

;;;###autoload
(define-minor-mode use-proxy-mode
  "Toggle proxy mode."
  :init-value nil
  :lighter (:eval (use-proxy--modeline-string))
  :group 'use-proxy
  :global t
  :after-hook (dolist (proto use-proxy--available-protocols)
                (let* ((proxy (use-proxy--get-custom-proxy-var-by-proto proto)))
                  (unless (use-proxy--valid-proxy-p proxy)
                    (warn "The value of `use-proxy-%s-proxy' is not a valid proxy. Got %s" proto proxy)))))

;;;###autoload
(defun use-proxy-toggle-proxies-global ()
  "Toggle proxies globally by set/unset no_proxy key in `url-proxy-services'."
  (interactive)
  (let ((no-proxy use-proxy-no-proxy))
    (if (assoc "no_proxy" url-proxy-services)
        (progn (setq url-proxy-services
                     (assoc-delete-all "no_proxy" url-proxy-services))
               (customize-save-variable 'url-proxy-services url-proxy-services)
               (message "Global proxy mode on"))
      (progn
        (add-to-list 'url-proxy-services `("no_proxy" . ,no-proxy))
        (customize-save-variable 'url-proxy-services url-proxy-services)
        (message "Global proxy mode off")))))

;;;###autoload
(defun use-proxy-toggle-proto-proxy (proto)
  "Toggle proxy on/off.
You can toggle proxy per protocol, and proxy status will show on mode-line.
This function will set/unset `url-proxy-services' to enable/disable proxies.
Argument PROTO protocol which you want to enable/disable proxy for."
  (interactive "P")
  (let* ((proto (if proto proto
                  (completing-read
                   "Toggle proxy for: "
                   use-proxy--available-protocols
                   nil t "")))
         (proxy (use-proxy--get-custom-proxy-var-by-proto proto)))
    (if (not (assoc proto url-proxy-services))
        (if (not (use-proxy--valid-proxy-p proxy))
            (warn "Invalid `use-proxy-%s-proxy' value %s" proto proxy)
          (add-to-list 'url-proxy-services `(,proto . ,proxy))
          (customize-save-variable 'url-proxy-services url-proxy-services)
          (message "%s proxy enabled" proto))
      (setq url-proxy-services
            (assoc-delete-all proto url-proxy-services))
      (customize-save-variable 'url-proxy-services url-proxy-services)
      (message "%s proxy disabled" proto))))

;;;###autoload
(defun use-proxy-toggle-all-proxies ()
  "Toggle all proxies on/off."
  (interactive)
  (if url-proxy-services
      (setq url-proxy-services '())
    (dolist (proto use-proxy--available-protocols)
      (let ((proxy (use-proxy--get-custom-proxy-var-by-proto proto)))
        (push `(,proto . ,proxy) url-proxy-services)))
    (push `("no_proxy" . ,use-proxy-no-proxy) url-proxy-services)))

;;;###autoload
(defmacro use-proxy-with-custom-proxies (protos &rest body)
  "Use proxies on a group of S-expressions.
This function respects `use-proxy-<protocol>-proxy' variables,
and provide a local `url-proxy-services' to argument `BODY'.
Argument PROTOS protocol list such as '(\"http\" \"https\")."
  `(let ((url-proxy-services
          (mapcar (lambda (proto)
                    (cons proto (use-proxy--get-custom-proxy-var-by-proto proto)))
                  ,protos)))
     ,@body))

;;;###autoload
(defmacro use-proxy-with-specified-proxies (protos-assoc &rest body)
  "Use proxies on a group of S-expressions.
This function doesn't respect custom `use-proxy-<protocol>-proxy' variables.
It provides a local `url-proxy-services' to argument `BODY'.
Argument PROTOS-ASSOC protocol association list in the form of
'((\"http\" . \"localhost:1234\") (\"https\" . \"localhost:2345\"))."
  `(let ((url-proxy-services ,protos-assoc))
     ,@body))

(provide 'use-proxy)
;;; use-proxy.el ends here
