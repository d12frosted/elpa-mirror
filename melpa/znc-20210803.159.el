;;; znc.el --- ZNC + ERC 
;;; 

;; Author: Yaroslav Shirokov
;; URL: https://github.com/sshirokov/ZNC.el
;; Package-Version: 20210803.159
;; Package-Commit: 6f0949c393b7778a96033716787d152ada32f705
;; Version: 0.0.4
;; Package-Requires: ((cl-lib "0.2"))
;; Also available via Marmalade http://marmalade-repo.org/
;;;;;;
(require 'cl)
(require 'erc)

(defgroup znc nil
  "ZNC IRC Bouncer assistance and opinions.

This is a thin wrapper around `erc' that makes using
the ZNC (http://en.znc.in/) IRC bouncer and irons out
some of the quirks that arise from using it with a naive ERC. "
  :group 'erc)

;; Default vars
(defvar *znc-server-default-host* "localhost" "Default host to use in `*znc-server-default*'")
(defvar *znc-server-default-port* 12533 "Default port to use in `*znc-server-default*'")

;; Types
(defconst *znc-server-accounts-type* '((cons :tag "Account"
                                        (symbol :tag "Network Slug"        :value network-slug)
                                        (group (string :tag "Username"     :value "znc-username")
                                               (string :tag "Password"     :value "znc-password"))))
  "A group describing an account belonging to a server")

(defconst *znc-server-type* `(group (string  :tag "Host" :value ,*znc-server-default-host*)
                                    (integer :tag "Port" :value ,*znc-server-default-port*)
                                    (boolean :tag "SSL"  :value nil)
                                    (repeat :tag "Accounts on server" ,@*znc-server-accounts-type*))
  "A group describing a ZNC server endpoint and the accounts on it")

;; Customizations
(defcustom znc-servers nil
  "List of ZNC servers"
  :tag "ZNC Servers"
  :group 'znc
  :type `(repeat ,*znc-server-type*))

(defcustom znc-erc-connector 'erc
  "The ERC connection function, must be compatible with `erc'"
  :group 'znc
  :type 'symbol)

(defcustom znc-erc-ssl-connector 'erc-tls
  "The ERC SSL connection function, must be compatible with `erc'"
  :group 'znc
  :type 'symbol)

(defcustom znc-detatch-on-kill t
  "Detach from, rather than /part from channels when you a buffer is killed"
  :group 'znc
  :type 'boolean)

;; Interactive
;;;###autoload
(defun znc-erc (&optional network)
  "Connect to a configured znc network"
  (interactive)
  (let* ((networks (znc-walk-all-servers :each 'znc-endpoint-slug-name))
         (network (or (and network (format "%s" network))
                      (when networks
                        (znc-prompt-string-or-nil "Network" networks (car networks) t))))
         (endpoint (when network
                     (znc-walk-all-servers :first t :pred (znc-walk-slugp (read network))))))
        (if endpoint
            (znc-erc-connect endpoint)
          (message "Network %s not defined. Try M-x customize-group znc."
                   (symbol-name network)))))

(defun znc-discard (&optional network)
  ;; (interactive) ;;TODO: Abstract asking for anetwork, and interactive this
  (let* ((buffer (znc-network-server-buffer network))
         (proc (and buffer
                   (znc-network-server-process network)))
         (pending (and buffer proc
                       (erc-with-all-buffers-of-server proc
                         (lambda () (not (equal (current-buffer) (erc-server-buffer))))
                         (current-buffer)))))
    (if buffer
        (loop for kidbuffer in pending
              do (znc-kill-buffer-always kidbuffer)
              initially (znc-kill-buffer-always buffer)
              finally return `(buffer ,@pending))
      (message "%s is unknown or not currently running"))))

;;;###autoload
(defun znc-all (&optional disconnect)
  "Connect to all known networks"
  (interactive "P")
  (loop for network in (znc-walk-all-servers :each 'znc-endpoint-slug)
        do
          (message "Connecting to: %s" network)
          (if disconnect
              (znc-discard network)
            (znc-erc network))
        collecting network))


;; Advice
(defadvice erc-server-reconnect (after znc-erc-rename last nil activate)
  "Maybe rename the buffer we create"
  (let* ((wants-name (and (local-variable-p 'znc-buffer-name (erc-server-buffer))
                          (buffer-local-value 'znc-buffer-name (erc-server-buffer))))
         (current (erc-server-buffer))
         (returning ad-return-value))
    (if wants-name
        (progn
          (ignore-errors (znc-kill-buffer-always wants-name))
          (with-current-buffer returning
            (znc-set-name wants-name)
            (rename-buffer wants-name))
	  returning))))

(defadvice erc-kill-channel (around znc-maybe-dont-part first nil activate)
  "Maybe don't let `erc-kill-channel' run"
  (let ((is-znc (and (local-variable-p 'znc-buffer-name (erc-server-buffer))
                     (buffer-local-value 'znc-buffer-name (erc-server-buffer)))))
    (if is-znc 
        (unless znc-detatch-on-kill ad-do-it)
      ad-do-it)))

;; Hooks
(add-hook 'erc-kill-channel-hook (defun znc-kill-channel-hook ()
  "Hook that handles ZNC-specific channel killing behavior"
  (and (local-variable-p 'znc-buffer-name (erc-server-buffer))
       znc-detatch-on-kill
       (znc-detach-channel))))

;;; Traversal
(defun* znc-walk-all-servers (&key (each (lambda (&rest r) (mapcar 'identity r)))
                                   (pred (lambda (&rest _) t))
                                   (first nil))
  "Walk every defined server and user pair calling `each' every time `pred' is non-nil

Both functions are called as: (apply f slug host port user pass)
`each' defaults to (mapcar 'identity ..)
`pred' is a truth function
`first' if non-nil, return the car of the result"
    (funcall (if first 'car 'identity)
             (loop for (host port ssl users) in znc-servers
                   appending (loop for (slug user pass) in users collecting
                     `(,slug ,host ,port ,ssl ,user ,pass)) into endpoints
                   finally return (loop for endpoint in endpoints
                     if (apply pred endpoint)
                     collect (apply each endpoint)))))

;;; Traversal helpers
(defun znc-walk-slugp (slug)
  (lexical-let ((slug slug))
    (lambda (s &rest _) (eq s slug))))

(defun znc-endpoint-slug-name (&rest args)
  (symbol-name (apply 'znc-endpoint-slug args)))

(defun znc-endpoint-slug (s &rest _) s)

;;; Helper Macro(s)
(defmacro with-endpoint (endpoint &rest forms)
  "Wraps the remainder in a binding in which
`slug' `host' `port' `ssl' `user' `pass' are bound 
to the matching values for the endpoint"
  (let ((sympoint (gensym "endpoint")))
    `(let ((,sympoint ,endpoint))
       (destructuring-bind (slug host port ssl user pass) ,sympoint
         ,@forms))))

;;; Helpers
(defun znc-network-buffer-name (network)
  "Formats a buffer name for a given `network'"
  (format "*irc-%s*" network))

(defun znc-network-has-buffer (network)
  (and
   (znc-walk-all-servers :first t :pred (znc-walk-slugp network))
   (get-buffer (znc-network-buffer-name network))))

(defun znc-network-server-process (network)
  (let ((buffer (znc-network-server-buffer network)))
    (when buffer
      (with-current-buffer buffer erc-server-process))))

(defun znc-network-server-buffer (network)
  "Returns a server buffer for `network' or nil"
  (let ((buffer (znc-network-has-buffer network)))
    (when buffer
         (with-current-buffer buffer
           (erc-server-buffer)))))

(defun znc-kill-buffer-always (&optional buffer)
  "Murderface a buffer, don't listen to nobody, son!"
  (let ((buffer (or buffer (current-buffer)))
        (kill-buffer-query-functions nil))
    (kill-buffer buffer)))

(defun znc-detach-channel ()
    (when (erc-server-process-alive)
    (let ((tgt (erc-default-target)))
      (erc-server-send (format "DETACH %s" tgt)
		       nil tgt))))

(defun znc-set-name (znc-name &optional buffer)
  "Set the znc-buffer-name buffer local to znc-name in buffer or (current-buffer)"
  (let ((buffer (get-buffer (or buffer (current-buffer)))))
    (with-current-buffer buffer
      (make-local-variable 'znc-buffer-name)
      (setf znc-buffer-name znc-name))))

(defun znc-erc-connect (endpoint)
  (let ((message-endpoint (append (butlast endpoint) '("***password***"))))
    (message "Called with: %s" message-endpoint)
    (with-endpoint endpoint
                   (message "Have endpoint: %s" message-endpoint)
                   (let* ((buffer (znc-network-buffer-name slug))
                          (erc-fun (if ssl znc-erc-ssl-connector znc-erc-connector))
                          (erc-args `(:server ,host :port ,port
                                              :nick ,user :password ,(format "%s:%s" user pass)))
                          (erc-buffer (apply erc-fun erc-args)))
                     (when (get-buffer buffer)
                       (znc-kill-buffer-always buffer))
                     (znc-set-name buffer erc-buffer)
                     (with-current-buffer erc-buffer
                       (rename-buffer buffer))))))

(defun znc-prompt-string-or-nil (prompt &optional completions default require-match)
  (let* ((string (completing-read (concat prompt ": ") completions nil require-match nil nil default))
         (string (if (equal string "") nil string)))
    string))


;;;;;;;;;;;;;;;;;;;
;; Provide!     ;;;
(provide 'znc)  ;;;
;;;;;;;;;;;;;;;;;;;
;;; znc.el ends here

