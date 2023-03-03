;;; proxy-mode.el --- A minor mode to toggle proxy.

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25"))
;; Package-Commit: eca6f0b8a17fcf9eb961ed0426f57a5b7ca4e1f6
;; Package-Version: 20230303.706
;; Package-X-Original-Version: 0.1
;; Keywords: comm proxy
;; homepage: https://repo.or.cz/proxy-mode.git

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

(defvar proxy-mode-proxy-types
  '(("Set Emacs url.el library HTTP request proxy" . emacs-url-proxy)
    ("Set Emacs socks.el library proxy" . emacs-socks-proxy)
    ("Set environment variable HTTP_PROXY" . env-http-proxy))
  "A list of `proxy-mode' supported proxy types.")

(defvar proxy-mode-proxy-type nil
  "Currently enabled proxy type.")

;; Privoxy
(defcustom proxy-mode-env-http-service
  (unless (getenv "HTTP_PROXY") "http://localhost:7980")
  "Customize HTTP_PROXY environment variable value."
  :type 'string
  :safe #'stringp
  :group 'proxy-mode)

(defcustom proxy-mode-url-proxy-services
  (unless (default-value 'url-proxy-services)
    '(("http"  . "127.0.0.1:7890")
      ("https" . "127.0.0.1:7890")
      ("ftp"   . "127.0.0.1:7890")
      ;; don't use `localhost', avoid robe server (For Ruby) can't response.
      ("no_proxy" . "127.0.0.1")
      ("no_proxy" . "^.*\\(baidu\\|sina)\\.com")))
  "Customize usual Emacs network http request through `url-proxy-services' proxy rules."
  :type 'alist
  :safe #'nested-alist-p
  :group 'proxy-mode)

(defcustom proxy-mode-socks-proxy-server
  (unless (default-value 'socks-server) '("Default server" "127.0.0.1" 1080 5))
  "Customize the `socks-server' value for Emacs library `socks'."
  :type 'list
  :safe #'listp
  :group 'proxy-mode)

(defun proxy-mode-lighter-func ()
  (format " proxy[%s]" proxy-mode-proxy-type))

;;; ----------------------- environment variable HTTP_PROXY proxy ----------------------------

(defun proxy-mode-env-proxy-enable ()
  "Enable HTTP proxy."
  ;; `setenv' works by modifying ‘process-environment’.
  (setenv "HTTP_PROXY"  proxy-mode-env-http-service)
  (setenv "HTTPS_PROXY" proxy-mode-env-http-service)
  (setq proxy-mode-proxy-type 'env-http-proxy)

  ;; TODO: how to `setenv' buffer locally?
  ;; this will make `proxy-mode-env-proxy-enable' invalid.
  ;; (make-local-variable 'process-environment)
  ;; (add-to-list 'process-environment (format "HTTP_PROXY=%s" ))
  ;; (add-to-list 'process-environment (format "HTTPS_PROXY=%s" ))

  (message
   (format
    "[proxy-mode] environment variable \"HTTP_PROXY\", \"HTTPS_PROXY\" proxy %s enabled."
    (getenv "HTTP_PROXY"))))

(defun proxy-mode--env-proxy-disable ()
  "Disable HTTP proxy."
  (setenv "HTTP_PROXY" nil)
  (setenv "HTTPS_PROXY" nil)
  (setq proxy-mode-proxy-type nil)
  (message (format "[proxy-mode] environment variable \"HTTP_PROXY\", \"HTTPS_PROXY\" proxy disabled.")))

;;; -------------------------- url.el HTTP request proxy --------------------------------------

(defun proxy-mode-url-proxy-enable ()
  "Enable url.el proxy by set `url-proxy-services'."
  (setq url-proxy-services proxy-mode-url-proxy-services)
  (setq proxy-mode-proxy-type 'emacs-url-proxy)
  (message (format "[proxy-mode] url.el proxy %s enabled." (car proxy-mode-url-proxy-services))))

(defun proxy-mode-url-proxy-disable ()
  "Disable url.el proxy by unset `url-proxy-services'."
  (setq url-proxy-services nil)
  (setq proxy-mode-proxy-type nil)
  (message (format "[proxy-mode] url.el proxy disabled.")))

;;; ---------------------------- socks.el proxy -----------------------------------------------

(defun proxy-mode-socks-proxy-enable ()
  "Enable socks.el proxy.
NOTE: it only works for http:// connections. Not work for https:// connections."
  (require 'url-gw)
  (require 'socks)
  (setq url-gateway-method 'socks)
  (setq socks-noproxy '("localhost" "192.168.*" "10.*"))
  (setq socks-server proxy-mode-socks-proxy-server)
  (setq proxy-mode-proxy-type 'emacs-socks-proxy)
  (message "[proxy-mode] socks.el proxy %s enabled." proxy-mode-socks-proxy-server))

(defun proxy-mode-socks-proxy-disable ()
  "Disable socks.el proxy."
  (setq url-gateway-method 'native)
  (setq proxy-mode-proxy-type nil)
  (message "[proxy-mode] socks.el proxy disabled."))

;;; ------------------------------------------------------------------------------------------

(defun proxy-mode-select-proxy ()
  "Select proxy type."
  (if proxy-mode-proxy-type
      (message "proxy-mode is already enabled.")
    (setq proxy-mode-proxy-type
          (cdr (assoc
                (completing-read "Select proxy service to enable: "
                                 (mapcar 'car proxy-mode-proxy-types))
                proxy-mode-proxy-types)))))

(defun proxy-mode-enable ()
  "Enable proxy-mode."
  (cl-case proxy-mode-proxy-type
    (emacs-url-proxy (proxy-mode-url-proxy-enable))
    (emacs-socks-proxy (proxy-mode-socks-proxy-enable))
    (env-http-proxy (proxy-mode-env-proxy-enable))))

(defun proxy-mode-disable ()
  "Disable proxy-mode."
  (cl-case proxy-mode-proxy-type
    (emacs-url-proxy (proxy-mode-url-proxy-disable))
    (emacs-socks-proxy (proxy-mode-socks-proxy-disable))
    (env-http-proxy (proxy-mode--env-proxy-disable))))

(defvar proxy-mode-map nil)

;;;###autoload
(define-minor-mode proxy-mode
  "A minor mode to set variable proxy for Emacs."
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



(provide 'proxy-mode)

;;; proxy-mode.el ends here
