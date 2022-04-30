;;; redis.el --- Redis integration                   -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/redis.el
;; Package-Version: 20220429.1758
;; Package-Commit: a6ad30d6a43b7be083c13f8725b45571d623001a
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;; [![Travis build status](https://travis-ci.org/emacs-pe/redis.el.svg?branch=master)](https://travis-ci.org/emacs-pe/redis.el)

;; `redis.el' offer a comint mode for `redis-cli'.
;;
;; Also offers a `redis-mode' for pseudo redis scripts which uses "#"
;; (number sign) as comment line. You can send the pseudo scripts to
;; redis removing the comments:
;;
;;      $ grep -v '^#' myscript.redis | nc 127.0.0.1 6379

;;; Code:
(eval-when-compile (require 'cl-lib))

(require 'json)
(require 'comint)

(defgroup redis nil
  "Redis integration."
  :prefix "redis-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/emacs-pe/redis.el")
  :link '(emacs-commentary-link :tag "Commentary" "redis"))

(defcustom redis-cli-executable "redis-cli"
  "Path to redis-cli executable path."
  :type 'file
  :group 'redis)

(defvar redis-process-buffer-name "*redis*")

(defconst redis-login-default-params '((host :default "127.0.0.1")
                                       (port :default 6379 :number t)
                                       (db :number t))
  "Default parameters needed to connect to Redis.")

(defconst redis-cli-prompt-regexp
  "^[a-zA-Z0-9_.-]+:[0-9]+\\(\\[[0-9]\\]\\)?> ")

(defconst redis-mode-ignore-regexp (rx (or (: bol (* space) eol)
                                           (: bol (* space) "#")))
  "Regex to ignore when send string to redis process.")

(defconst redis-commands-json-url
  "https://github.com/antirez/redis-doc/raw/master/commands.json"
  "Url of redis documentation json.")

;; (let* ((commands-json (with-current-buffer (url-retrieve-synchronously redis-commands-json-url)
;;                         (goto-char (point-min))
;;                         (re-search-forward "^$" nil t)
;;                         (json-read)))
;;        (keywords (mapcar (lambda (e) (split-string (symbol-name (car e)) "\s+" t))
;;                          commands-json)))
;;   (sort (delete-dups (apply 'append keywords)) 'string<))

(defconst redis-keywords
  '("ADDSLOTS" "APPEND" "AUTH" "BGREWRITEAOF" "BGSAVE" "BITCOUNT"
    "BITOP" "BITPOS" "BLPOP" "BRPOP" "BRPOPLPUSH" "CLIENT" "CLUSTER"
    "COMMAND" "CONFIG" "COUNT" "COUNT-FAILURE-REPORTS"
    "COUNTKEYSINSLOT" "DBSIZE" "DEBUG" "DECR" "DECRBY" "DEL"
    "DELSLOTS" "DISCARD" "DUMP" "ECHO" "EVAL" "EVALSHA" "EXEC"
    "EXISTS" "EXPIRE" "EXPIREAT" "FAILOVER" "FLUSH" "FLUSHALL"
    "FLUSHDB" "FORGET" "GET" "GETBIT" "GETKEYS" "GETKEYSINSLOT"
    "GETNAME" "GETRANGE" "GETSET" "HDEL" "HEXISTS" "HGET" "HGETALL"
    "HINCRBY" "HINCRBYFLOAT" "HKEYS" "HLEN" "HMGET" "HMSET" "HSCAN"
    "HSET" "HSETNX" "HSTRLEN" "HVALS" "INCR" "INCRBY" "INCRBYFLOAT"
    "INFO" "KEYS" "KEYSLOT" "KILL" "LASTSAVE" "LINDEX" "LINSERT"
    "LIST" "LLEN" "LOAD" "LPOP" "LPUSH" "LPUSHX" "LRANGE" "LREM"
    "LSET" "LTRIM" "MEET" "MGET" "MIGRATE" "MONITOR" "MOVE" "MSET"
    "MSETNX" "MULTI" "NODES" "OBJECT" "PAUSE" "PERSIST" "PEXPIRE"
    "PEXPIREAT" "PFADD" "PFCOUNT" "PFMERGE" "PING" "PSETEX"
    "PSUBSCRIBE" "PTTL" "PUBLISH" "PUBSUB" "PUNSUBSCRIBE" "QUIT"
    "RANDOMKEY" "RENAME" "RENAMENX" "REPLICATE" "RESET" "RESETSTAT"
    "RESTORE" "REWRITE" "ROLE" "RPOP" "RPOPLPUSH" "RPUSH" "RPUSHX"
    "SADD" "SAVE" "SAVECONFIG" "SCAN" "SCARD" "SCRIPT" "SDIFF"
    "SDIFFSTORE" "SEGFAULT" "SELECT" "SET" "SET-CONFIG-EPOCH" "SETBIT"
    "SETEX" "SETNAME" "SETNX" "SETRANGE" "SETSLOT" "SHUTDOWN" "SINTER"
    "SINTERSTORE" "SISMEMBER" "SLAVEOF" "SLAVES" "SLOTS" "SLOWLOG"
    "SMEMBERS" "SMOVE" "SORT" "SPOP" "SRANDMEMBER" "SREM" "SSCAN"
    "STRLEN" "SUBSCRIBE" "SUNION" "SUNIONSTORE" "SYNC" "TIME" "TTL"
    "TYPE" "UNSUBSCRIBE" "UNWATCH" "WAIT" "WATCH" "ZADD" "ZCARD"
    "ZCOUNT" "ZINCRBY" "ZINTERSTORE" "ZLEXCOUNT" "ZRANGE"
    "ZRANGEBYLEX" "ZRANGEBYSCORE" "ZRANK" "ZREM" "ZREMRANGEBYLEX"
    "ZREMRANGEBYRANK" "ZREMRANGEBYSCORE" "ZREVRANGE" "ZREVRANGEBYLEX"
    "ZREVRANGEBYSCORE" "ZREVRANK" "ZSCAN" "ZSCORE" "ZUNIONSTORE"))

(defun redis-complete-at-point ()
  "Complete at point in redis mode."
  (let* ((bounds (bounds-of-thing-at-point 'symbol))
         (start (or (car bounds) (point)))
         (end (or (cdr bounds) (point))))
    (list start end (append redis-keywords
                            (mapcar 'downcase redis-keywords)))))

(defconst redis-font-lock-keywords
  (list (regexp-opt redis-keywords 'symbols)))

(defun redis-read-args (&optional pipe)
  "Read the login params to redis-cli.

If PIPE is non nil add redis --pipe to the args list, only used
when send commands with redis protocol."
  (let ((host (redis-cli-get-login 'host (and current-prefix-arg "Hostname: ")))
        (port (redis-cli-get-login 'port (and current-prefix-arg "Port: ")))
        (db (redis-cli-get-login 'db (and current-prefix-arg "Database number: ")))
        (password (and current-prefix-arg (read-passwd "Password: "))))
    (append (and host (list "-h" host))
            (and port (list "-p" (number-to-string port)))
            (and db (list "-n" (number-to-string db)))
            (and (not (or (null password) (string= password "")))
                 (list "-a" password))
            (and pipe (list "--pipe")))))

(defun redis-cli-get-login (symbol &optional prompt)
  "Read a redis login SYMBOL with PROMPT."
  (let* ((plist (assoc-default symbol redis-login-default-params))
         (default (plist-get plist :default)))
    (if (null prompt)
        default
      (let ((prompt-def
             (if default
                 (if (string-match "\\(\\):[ \t]o*\\'" prompt)
                     (replace-match (format " (default \"%s\")" default) t t prompt 1)
                   (replace-regexp-in-string "[ \t]*\\'"
                                             (format " (default \"%s\") " default)
                                             prompt t t))
               prompt)))
        (cond
         ((plist-member plist :completion)
          (completing-read prompt-def (plist-get plist :completion) nil t
                           nil nil default))
         ((plist-get plist :number)
          (read-number prompt (or default nil 0)))
         (t
          (read-string prompt-def nil nil default)))))))

(defun redis-get-or-create-process ()
  "Get or create a redis-cli process."
  (unless (comint-check-proc redis-process-buffer-name)
    (call-interactively #'redis-cli))
  (get-buffer-process redis-process-buffer-name))


;;; redis commands
(defvar redis-commands nil
  "An alist of the documentation of redis commands.")

(defvar redis-commands-already-fetched nil)

(defun redis-fetch-commands ()
  "Fetch redis commands."
  (setq redis-commands-already-fetched t)
  (url-retrieve redis-commands-json-url
                #'redis-commands-http-callback nil t))

(defun redis-commands-http-callback (status)
  "Default http callback to set `redis-commands'.  Check STATUS is not erroed."
  (unless (plist-get status :error)
    (setq redis-commands
          (with-current-buffer (current-buffer)
            (goto-char (point-min))
            (re-search-forward "^$" nil 'move)
            (json-read)))))

(defun redis-eldoc-function ()
  "Return a docstring for eldoc mode."
  (unless redis-commands-already-fetched
    (redis-fetch-commands))
  (let* ((symbol  (symbol-at-point))
         (normsym (and symbol (intern (upcase (symbol-name symbol)))))
         (docentry (and normsym (assoc-default normsym redis-commands))))
    (and docentry
         (format "%s %s | %s %s"
                 normsym
                 (upcase (mapconcat (lambda (e) (assoc-default 'name e))
                                    (assoc-default 'arguments docentry) " "))
                 (assoc-default 'summary docentry)
                 (assoc-default 'complexity docentry)))))


;;; redis mode
(defvar redis-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\' "\"'" table)
    (modify-syntax-entry ?\" "\"\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    table)
  "Syntax table for redis mode files.")

(defvar redis-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" #'redis-send-buffer-content)
    (define-key map "\C-c\C-r" #'redis-send-region-content)
    (define-key map "\C-c\C-p" #'redis-send-buffer-with-protocol)
    (define-key map "\C-c\c-z" #'redis-switch-to-cli)
    (define-key map "\C-x\C-e" #'redis-send-current-line)
    map)
  "Keymap for redis mode.")

;;;###autoload
(define-derived-mode redis-mode prog-mode "redis"
  "Major mode for `redis' commands.

BEWARE: This is mode is for pseudo redis scripts which uses
\"#\" (number sign) as comment line. You can send the pseudo
scripts to redis removing the comments:

     $ grep -v '^#' myscript.redis | nc 127.0.0.1 6379

\\<redis-mode-map>"
  :syntax-table redis-mode-syntax-table
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "#+\\s-*")
  (set (make-local-variable 'font-lock-defaults)
       '(redis-font-lock-keywords nil t))
  (set (make-local-variable 'eldoc-documentation-function)
       #'redis-eldoc-function)
  (add-hook 'completion-at-point-functions
            #'redis-complete-at-point nil 'local))

;;;###autoload
(defun redis-send-buffer-with-protocol (&rest args)
  "Send the buffer content to redis-cli executable with ARGS.

If PROTOCOL is not nil it sends to using redis protocol.  See:
http://redis.io/topics/protocol"
  (interactive (redis-read-args t))
  (let ((command (mapconcat 'identity (cons redis-cli-executable args) " "))
        (temp-buffer (generate-new-buffer " *temp*")))
    (save-excursion
      (with-current-buffer (current-buffer)
        (goto-char (point-min))
        (cl-loop unless (re-search-forward redis-mode-ignore-regexp (point-at-eol) t)
                 do (let* ((line (thing-at-point 'line t))
                           (cmd (if (string-match "[ \t\n\r]+\\'" line)
                                    (replace-match "" t t line)
                                  line)))
                      ;; FIXME: This fails when a line contains quotes (e.g EVAL)
                      (with-current-buffer temp-buffer
                        (insert (apply #'redis-generate-proto
                                       (split-string cmd " " t)))))
                 until (eobp)
                 do (forward-line 1))))
    (unwind-protect
        (with-current-buffer temp-buffer
          (shell-command-on-region (point-min) (point-max) command "*redis-output*" nil "*redis-error*"))
      (kill-buffer temp-buffer))))

;;;###autoload
(defun redis-send-buffer-content (&optional process)
  "Send the contents of the current buffer to a redis PROCESS."
  (interactive)
  (let ((process (or process (redis-get-or-create-process))))
    (redis-send-region-content (point-min) (point-max) process)))

;;;###autoload
(defun redis-send-region-content (begin end &optional process)
  "Send the contents from region BEGIN to END to a redis PROCESS."
  (interactive "r")
  (let ((process (or process (redis-get-or-create-process)))
        (string (buffer-substring-no-properties begin end)))
    (redis-process-send-string process string)))

;;;###autoload
(defun redis-send-current-line (&optional process)
  "Send current line to redis PROCESS."
  (interactive)
  (let ((process (or process (redis-get-or-create-process)))
        (line (thing-at-point 'line t)))
    (redis-process-send-string process line)))

(defun redis-process-send-string (process string)
  "Send to a redis PROCESS a STRING."
  (dolist (line (split-string string "\n" t))
    (unless (string-match-p redis-mode-ignore-regexp line)
      (comint-send-string process line)
      (comint-send-string process "\n"))))

(defun redis-generate-proto (&rest args)
  "Generate redis protocol from ARGS."
  (format "*%s\r\n%s"
          (length args)
          (mapconcat (lambda (arg)
                       (format "$%s\r\n%s\r\n" (string-bytes arg) arg))
                     args "")))


;;; redis cli
;;;###autoload
(defun redis-cli-bookmark-jump (bookmark)
  "Restore redis-cli buffer according to BOOKMARK."
  (let ((default-directory (bookmark-prop-get bookmark 'path))
        (redis-process-buffer-name (bookmark-prop-get bookmark 'name))
        (redis-cli-executable (bookmark-prop-get bookmark 'executable))
        (args (bookmark-prop-get bookmark 'args)))
    (apply #'redis-cli args)))

(defun redis-cli-bookmark-make-record ()
  "Create bookmark for redis-cli buffer."
  (let* ((command (process-command (get-buffer-process (current-buffer))))
         (executable (car command))
         (args (cdr command)))
    (cons (buffer-name)
          `((name . ,(buffer-name))
            (path . ,default-directory)
            (executable . ,executable)
            (args . ,args)
            (handler . redis-cli-bookmark-jump)))))

;;;###autoload
(define-derived-mode redis-cli-mode comint-mode "redis-cli"
  "Major mode for `redis-cli'.

\\<redis-cli-mode-map>"
  (set (make-local-variable 'comint-prompt-regexp) redis-cli-prompt-regexp)
  (set (make-local-variable 'comint-prompt-read-only) t)
  (set (make-local-variable 'font-lock-defaults)
       '(redis-font-lock-keywords nil t))
  (set (make-local-variable 'eldoc-documentation-function)
       #'redis-eldoc-function)
  (set (make-local-variable 'bookmark-make-record-function)
       #'redis-cli-bookmark-make-record)
  (define-key redis-cli-mode-map "\t" 'completion-at-point)
  (add-hook 'completion-at-point-functions
            #'redis-complete-at-point nil 'local))

;;;###autoload
(defalias 'run-redis #'redis-cli)

;;;###autoload
(defun redis-cli (&rest args)
  "Run redis-cli process with ARGS."
  (interactive (redis-read-args))
  (let ((buffer (apply #'make-comint-in-buffer
                       "redis"
                       redis-process-buffer-name
                       redis-cli-executable
                       nil
                       args)))
    (with-current-buffer buffer
      (redis-cli-mode))
    (pop-to-buffer buffer t)))

(defun redis-switch-to-cli ()
  "Switch to redis-cli process."
  (interactive)
  (pop-to-buffer (process-buffer (redis-get-or-create-process)) t))

(provide 'redis)

;;; redis.el ends here
