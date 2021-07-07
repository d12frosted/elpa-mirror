;;; friendly-tramp-path.el --- Human-friendly TRAMP path construction -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Jordan Besly
;;
;; Version: 0.1.0
;; Package-Version: 20200502.1032
;; Package-Commit: be572b8953b9e5a3a35c30bb64c2936d3e9802ba
;; URL: https://github.com/p3r7/prf-tramp
;; Package-Requires: ((cl-lib "0.6.1"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; More friendly (permissive) TRAMP path constructions for us humans.
;;
;; Provides function `friendly-tramp-path-disect` that is a drop-in replacement
;; for `tramp-dissect-file-name`. It behaves the same but allows the following
;; formats:
;;
;;  - `/<method>:[<user>[%<domain>]@]<host>[%<port>][:<localname>]` (regular TRAMP format)
;;  - `[<user>[%<domain>]@]<host>[%<port>][:<localname>]` (permissive format)
;;
;; For detailed instructions, please look at the README.md at https://github.com/p3r7/friendly-tramp-path/blob/master/README.md


;;; Code:



;; REQUIRES

(require 'tramp)
(require 'cl-lib)



;; COMPLETE PARSING

(defun friendly-tramp-path-dissect (path)
  "Convert PATH into a TRAMP VEC.
More permissive version of `tramp-dissect-file-name'.

PATH can be in on of the following formats:
 - \"/<method>:[<user>[%<domain>]@]<host>[%<port>][:<localname>]\" (regular TRAMP format)
 - \"[<user>[%<domain>]@]<host>[%<port>][:<localname>]\" (permissive format)
"
  (if (file-remote-p path)
      (tramp-dissect-file-name path)
    (let* ((parsed (friendly-tramp-path--parse-char-loop path))
           (method (plist-get parsed :method))
           (user (plist-get parsed :user))
           (domain (plist-get parsed :domain))
           (host (plist-get parsed :host))
           (port (plist-get parsed :port))
           (localname (plist-get parsed :localname)))
      (if (eq (length user) 0)
          (setq user tramp-default-user))
      (setq method (tramp-find-method method user host))
      (if (eq (length localname) 0)
          (setq localname "/"))
      `(tramp-file-name ,method ,user ,domain ,host ,port ,localname))))



;; INDIVIDUAL PARTS

(defun friendly-tramp-path-method (path)
  "Extract method part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :method))

(defun friendly-tramp-path-user (path)
  "Extract user part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :user))

(defun friendly-tramp-path-domain (path)
  "Extract domain part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :domain))

(defun friendly-tramp-path-host (path)
  "Extract host part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :host))

(defun friendly-tramp-path-port (path)
  "Extract port part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :port))

(defun friendly-tramp-path-localname (path)
  "Extract localname part from friendly PATH."
  (plist-get
   (friendly-tramp-path--parse-char-loop path)
   :localname))



;; UTILS: TRAMP PATH PARSING

(defun friendly-tramp-path--parse-char-loop (path)
  "Parse PATH and return a list of TRAMP components."
  (let (method user domain host port localname)
    (cl-loop

     with last-at = nil
     with at = :first
     with current = nil

     for e in (delete "" (split-string path ""))

     if (eq at :first)
     do
     (setq last-at :first)
     (if (string= e "/")
         (setq at :method)
       (setq at nil))

     if (string= e "%")
     do
     (setq user (apply #'concat (reverse current))
           current nil
           last-at :user
           at :domain)
     else if (string= e "#")
     do
     (setq host (apply #'concat (reverse current))
           current nil
           last-at :host
           at :port)
     else if (string= e "@")
     do
     (cond
      ((eq at :domain)
       (setq domain (apply #'concat (reverse current))
             current nil
             last-at :domain
             at :host))
      (t
       (setq user (apply #'concat (reverse current))
             current nil
             last-at :user
             at :host)))
     else if (string= e ":")
     do
     (cond
      ((eq at :method)
       (setq method (apply #'concat (reverse current))
             current nil
             last-at :method
             at nil))
      ((eq at :port)
       (setq port (apply #'concat (reverse current))
             current nil
             last-at :port
             at :localname))
      ((or (eq at :host)
           (and (eq at nil)
                (eq last-at :first)))
       (setq host (apply #'concat (reverse current))
             current nil
             last-at :host
             at :localname)))
     else
     do
     (unless (and (eq at :method)
                  (string= e "/"))
       (setq current (cons e current)))

     finally
     do
     (cond
      ((member at '(:host nil))
       (setq host (apply #'concat (reverse current))))
      ((eq at :port)
       (setq port (apply #'concat (reverse current))))
      ((eq at :localname)
       (setq localname (apply #'concat (reverse current))))))

    (list
     :method method
     :user user
     :domain domain
     :host host :port port
     :localname (friendly-tramp-path--empty-as-nil localname))))



;; UTILS: SANITIZATION

(defun friendly-tramp-path--empty-as-nil (v)
  "Convert V to nil if empty."
  (if (eq (length v) 0)
      nil
    v))




(provide 'friendly-tramp-path)

;;; friendly-tramp-path.el ends here
