;;; proxy-mode.el --- A minor mode to toggle proxy.

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25"))
;; Package-Commit: dbf163413e9e404c652cc0ea7185c623016a38e1
;; Package-Version: 20201214.727
;; Package-X-Original-Version: 0.1
;; Keywords: comm proxy
;; homepage: https://github.com/stardiviner/proxy-mode

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; toggle proxy-mode to use proxy.
;;; [M-x proxy-mode RET]

;;; Code:

(require 'url-gw)
(require 'socks)
(require 'cl-lib)

(defgroup proxy-mode nil
  "A minor mode to toggle proxy."
  :prefix "proxy-mode-"
  :group 'proxy)

(defcustom proxy-mode-rules-alist nil
  "A list of rules for proxy."
  :type 'alist
  :group 'proxy-mode)

(defvar proxy-mode-types

  '(("Environment HTTP Proxy" . env-http)
    ("Emacs Socks Proxy" . emacs-socks)
    ("Emacs HTTP proxy" . emacs-http))
  "A list of `proxy-mode' supported proxy types.")

(defvar proxy-mode-proxy-type nil
  "Currently enabled proxy type.")

;; Privoxy
(defcustom proxy-mode-env-http-proxy "http://localhost:8118"
  "Default HTTP_PROXY environment variable value."
  :type 'string
  :safe #'stringp
  :group 'proxy-mode)

(defcustom proxy-mode-emacs-http-proxy '(("http"  . "127.0.0.1:8118")
                                  ("https" . "127.0.0.1:8118")
                                  ("ftp"   . "127.0.0.1:8118")
                                  ;; don't use `localhost', avoid robe server (For Ruby) can't response.
                                  ("no_proxy" . "127.0.0.1")
                                  ("no_proxy" . "^.*\\(baidu\\|sina)\\.com"))
  "A list of rules for `url-proxy-services'."
  :type 'alist
  :safe #'nested-alist-p
  :group 'proxy-mode)

(defcustom proxy-mode-emacs-socks-proxy '("Default server" "127.0.0.1" 1080 5)
  "Default `socks-server' value."
  :type 'list
  :safe #'listp
  :group 'proxy-mode)

(defun proxy-mode-lighter-func ()
  (format " Proxy[%s]" proxy-mode-proxy-type))

;;; ------------------------------ HTTP Proxy ---------------------------------------------------

(defun proxy-mode-env-http-enable ()
  "Enable HTTP proxy."
  ;; `setenv' works by modifying ‘process-environment’.
  (setenv "HTTP_PROXY"  proxy-mode-env-http-proxy)
  (setenv "HTTPS_PROXY" proxy-mode-env-http-proxy)
  (setq-local proxy-mode-proxy-type "http")
  (getenv "HTTP_PROXY")

  ;; TODO: how to `setenv' buffer locally?
  ;; this will make `proxy-mode-env-http-enable' invalid.
  ;; (make-local-variable 'process-environment)
  ;; (add-to-list 'process-environment (format "HTTP_PROXY=%s" ))
  ;; (add-to-list 'process-environment (format "HTTPS_PROXY=%s" ))
  )

(defun proxy-mode--env-http-disable ()
  "Disable HTTP proxy."
  (setenv "HTTP_PROXY" nil)
  (setenv "HTTPS_PROXY" nil)
  (setq-local proxy-mode-proxy-type nil))

;;; ------------------------------ URL Proxy --------------------------------------------------

(defun proxy-mode-emacs-http-enable ()
  "Enable URL proxy."
  (setq-local url-proxy-services proxy-mode-emacs-http-proxy)
  (setq-local proxy-mode-proxy-type "url")
  (message (format "Proxy-mode %s url proxy enabled." (car proxy-mode-emacs-http-proxy))))

(defun proxy-mode--emacs-http-disable ()
  "Disable URL proxy."
  (setq-local url-proxy-services nil)
  (setq-local proxy-mode-proxy-type nil))

;;; ------------------------------ Socks Proxy --------------------------------------------------

(defun proxy-mode-emacs-socks-enable ()
  "Enable Socks proxy.
NOTE: it only works for http:// connections. Not work for https:// connections."
  (require 'url-gw)
  (require 'socks)
  (setq-local url-gateway-method 'socks)
  (setq-local socks-noproxy '("localhost" "192.168.*" "10.*"))
  (setq-local socks-server proxy-mode-emacs-socks-proxy)
  (setq-local proxy-mode-proxy-type "socks")
  (message "Proxy-mode socks proxy %s enabled." proxy-mode-emacs-socks-proxy))

(defun proxy-mode--emacs-socks-disable ()
  "Disable Socks proxy."
  (setq-local url-gateway-method 'native)
  (setq-local proxy-mode-proxy-type nil))

;;; ------------------------------------------------------------------------------------------

(defun proxy-mode-select-proxy ()
  "Select proxy type."
  (if proxy-mode-proxy-type
      (message "proxy-mode is already enabled.")
    (setq proxy-mode-proxy-type
          (cdr (assoc
                (completing-read "Select proxy service to enable: "
                                 (mapcar 'car proxy-mode-types))
                proxy-mode-types)))))

(defun proxy-mode-enable ()
  "Enable proxy-mode."
  (cl-case proxy-mode-proxy-type
    ('env-http (proxy-mode-env-http-enable))
    ('emacs-socks (proxy-mode-emacs-socks-enable))
    ('emacs-http (proxy-mode-emacs-http-enable))))

(defun proxy-mode-disable ()
  "Disable proxy-mode."
  (pcase proxy-mode-proxy-type
    ('env-http (proxy-mode--env-http-disable))
    ('emacs-socks (proxy-mode--emacs-socks-disable))
    ('emacs-http (proxy-mode--emacs-http-disable))))

(defvar proxy-mode-map nil)

;;;###autoload
(define-minor-mode proxy-mode
  "A minor mode to toggle `proxy-mode' buffer locally.

This minor mode supports buffer-local proxy: Emacs http, and Emacs socks.
Not support buffer-locally shell environment variable HTTP_PROXY.

If you want use proxy-mode globally, use command ‘global-proxy-mode’."
  :require 'proxy-mode
  :init-value nil
  :lighter (:eval (proxy-mode-lighter-func))
  :group 'proxy-mode
  :keymap proxy-mode-map
  (if proxy-mode
      (progn
        (proxy-mode-select-proxy)
        (proxy-mode-enable))
    (proxy-mode-disable)))

(defun proxy-mode-enable-global ()
  "Enable proxy in Emacs globally."
  (proxy-mode-select-proxy)
  (cl-case proxy-mode-proxy-type
    ('env-http
     (setenv "HTTP_PROXY"  proxy-mode-env-http-proxy)
     (setenv "HTTPS_PROXY" proxy-mode-env-http-proxy)
     (getenv "HTTP_PROXY")
     (message "Proxy-mode environment http proxy enabled globally."))
    ('emacs-socks
     (require 'url-gw)
     (require 'socks)
     (setq url-gateway-method 'socks)
     (setq socks-noproxy '("localhost" "192.168.*" "10.*"))
     (setq socks-server proxy-mode-emacs-socks-proxy)
     (message "Proxy-mode socks proxy %s enabled globally." proxy-mode-emacs-socks-proxy))
    ('emacs-http
     (setq url-proxy-services proxy-mode-emacs-http-proxy)
     (message (format "Proxy-mode %s url proxy enabled globally." (car proxy-mode-emacs-http-proxy))))))

(defun proxy-mode-disable-global ()
  "Disable proxy in Emacs globally."
  (cl-case proxy-mode-proxy-type
    ('env-http
     (setenv "HTTP_PROXY"  nil)
     (setenv "HTTPS_PROXY" nil)
     (getenv "HTTP_PROXY"))
    ('emacs-socks
     (setq url-gateway-method 'native))
    ('emacs-http
     (setq url-proxy-services nil)))
  (setq proxy-mode-proxy-type nil))

;;;###autoload
(define-minor-mode global-proxy-mode
  "A minor mode to set proxy in Emacs globally."
  :require 'proxy-mode
  :init-value nil
  :global t
  :lighter (:eval (proxy-mode-lighter-func))
  :group 'proxy-mode
  :keymap proxy-mode-map
  (if global-proxy-mode
      (proxy-mode-enable-global)
    (proxy-mode-disable-global)))



(provide 'proxy-mode)

;;; proxy-mode.el ends here
