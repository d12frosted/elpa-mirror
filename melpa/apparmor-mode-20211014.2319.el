;;; apparmor-mode.el --- Major mode for editing AppArmor policy files         -*- lexical-binding: t; -*-

;; Copyright (c) 2018 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/apparmor-mode
;; Package-Version: 20211014.2319
;; Package-Commit: 9d1937af52cd8ecfeec27185644ea8cbf0dc1c08
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; The following documentation sources were used:
;; https://gitlab.com/apparmor/apparmor/wikis/QuickProfileLanguage
;; https://gitlab.com/apparmor/apparmor/wikis/ProfileLanguage

;; TODO:
;; - do smarter completion syntactically via regexps
;; - decide if to use entire line regexp for statements or
;;   - not (ie just a subset?)  if we use regexps above then
;;   - should probably keep full regexps here so can reuse
;; - expand highlighting of mount rules (options=...) similar to dbus
;; - add flymake support via "apparmor_parser -Q -K </path/to/profile>"
;; - add tests via ert etc

;;;; Setup

;; (require 'apparmor-mode)

;;; Code:

;; for flycheck integration
(declare-function flycheck-define-command-checker "ext:flycheck.el"
                  (symbol docstring &rest properties))
(declare-function flycheck-valid-checker-p "ext:flycheck.el")
(defvar flycheck-checkers)

(defgroup apparmor nil
  "Major mode for editing AppArmor policies."
  :group 'tools)

(defcustom apparmor-mode-indent-offset 2
  "Indentation offset in `apparmor-mode' buffers."
  :type 'integer
  :group 'apparmor)

(defvar apparmor-mode-keywords '("audit" "capability" "chmod" "delegate" "dbus"
                                 "deny" "flags" "include" "include if exists" "link"
                                 "mount" "network" "on" "owner" "pivot_root"
                                 "profile" "quiet" "remount" "rlimit" "safe"
                                 "subset" "to" "umount" "unsafe"))

(defvar apparmor-mode-profile-flags '("enforce" "complain" "debug" "kill"
                                      "chroot_relative" "namespace_relative"
                                      "attach_disconnected" "no_attach_disconnected"
                                      "chroot_attach" "chroot_no_attach"))

(defvar apparmor-mode-capabilities '("audit_control" "audit_write" "chown"
                                     "dac_override" "dac_read_search" "fowner"
                                     "fsetid" "ipc_lock" "ipc_owner" "kill"
                                     "lease" "linux_immutable" "mac_admin"
                                     "mac_override" "mknod" "net_admin"
                                     "net_bind_service" "net_broadcast"
                                     "net_raw" "setfcap" "setgid" "setpcap"
                                     "setuid" "syslog" "sys_admin" "sys_boot"
                                     "sys_chroot" "sys_module" "sys_nice"
                                     "sys_pacct" "sys_ptrace" "sys_rawio"
                                     "sys_resource" "sys_time"
                                     "sys_tty_config"))

(defvar apparmor-mode-network-permissions '("create" "accept" "bind" "connect"
                                            "listen" "read" "write" "send"
                                            "receive" "getsockname" "getpeername"
                                            "getsockopt" "setsockopt" "fcntl"
                                            "ioctl" "shutdown" "getpeersec"))

(defvar apparmor-mode-network-domains '("inet" "ax25" "ipx" "appletalk" "netrom"
                                        "bridge" "atmpvc" "x25" "inet6" "rose"
                                        "netbeui" "security" "key" "packet"
                                        "ash" "econet" "atmsvc" "sna" "irda"
                                        "pppox" "wanpipe" "bluetooth" "unix"))

(defvar apparmor-mode-network-types '("stream" "dgram" "seqpacket" "raw" "rdm"
                                      "packet" "dccp"))

;; TODO: this is not complete since is not fully documented
(defvar apparmor-mode-network-protocols '("tcp" "udp" "icmp"))

(defvar apparmor-mode-dbus-permissions '("r" "w" "rw" "send" "receive"
                                         "acquire" "bind" "read" "write"))

(defvar apparmor-mode-rlimit-types '("fsize" "data" "stack" "core" "rss" "as"
                                     "memlock" "msgqueue" "nofile" "locks"
                                     "sigpending" "nproc" "rtprio" "cpu"
                                     "nice"))

(defvar apparmor-mode-abi-regexp "^\\s-*\\(#?abi\\)\\s-+\\([<\"][[:graph:]]+[\">]\\)")

(defvar apparmor-mode-include-regexp "^\\s-*\\(#?include\\( if exists\\)?\\)\\s-+\\([<\"][[:graph:]]+[\">]\\)")

(defvar apparmor-mode-capability-regexp (concat  "^\\s-*\\(capability\\)\\s-+\\("
                                                 (regexp-opt apparmor-mode-capabilities)
                                                 "\\s-*\\)*"))

(defvar apparmor-mode-variable-name-regexp "@{[[:alpha:]]+}")

(defvar apparmor-mode-variable-regexp
  (concat "^\\s-*\\(" apparmor-mode-variable-name-regexp "\\)\\s-*\\(\\+?=\\)\\s-*\\([[:graph:]]+\\)\\(\\s-+\\([[:graph:]]+\\)\\)?\\s-*\\(#.*\\)?$"))

(defvar apparmor-mode-profile-name-regexp "[[:alnum:]]+")

(defvar apparmor-mode-profile-attachment-regexp "[[:alnum:]*@/_{},-]+")

(defvar apparmor-mode-profile-flags-regexp
  (concat  "\\(flags\\)=(\\(" (regexp-opt apparmor-mode-profile-flags) "\\s-*\\)*)") )

(defvar apparmor-mode-profile-regexp
  (concat "^\\s-*\\(\\(profile\\)\\s-+\\(\\(" apparmor-mode-profile-name-regexp "\\)\\s-+\\)?\\)?\\(\\^?" apparmor-mode-profile-attachment-regexp "\\)\\(\\s-+" apparmor-mode-profile-flags-regexp "\\)?\\s-+{\\s-*$"))

(defvar apparmor-mode-file-rule-regexp
  (concat "^\\s-*\\(\\(audit\\|owner\\|deny\\)\\s-+\\)*"
          "\\(" apparmor-mode-profile-attachment-regexp "\\)\\s-+\\([CPUacilmpruwx]+\\)\\s-*"
          "\\(->\\s-+\\(" apparmor-mode-profile-attachment-regexp "\\)\\)?\\s-*"
          ","))

(defvar apparmor-mode-network-rule-regexp
  (concat
   "^\\s-*\\(\\(audit\\|quiet\\|deny\\)\\s-+\\)*network\\s-*"
   "\\(" (regexp-opt apparmor-mode-network-permissions 'words) "\\)?\\s-*"
   "\\(" (regexp-opt apparmor-mode-network-domains 'words) "\\)?\\s-*"
   "\\(" (regexp-opt apparmor-mode-network-types 'words) "\\)?\\s-*"
   "\\(" (regexp-opt apparmor-mode-network-protocols 'words) "\\)?\\s-*"
   ;; TODO: address expression
   "\\(delegate to\\s-+\\(" apparmor-mode-profile-attachment-regexp "\\)\\)?\\s-*"
   ","))

(defvar apparmor-mode-dbus-rule-regexp
  (concat
   "^\\s-*\\(\\(audit\\|deny\\)\\s-+\\)?dbus\\s-*"
   "\\(\\(bus\\)=\\(system\\|session\\)\\)?\\s-*"
   "\\(\\(dest\\)=\\([[:alpha:].]+\\)\\)?\\s-*"
   "\\(\\(path\\)=\\([[:alpha:]/]+\\)\\)?\\s-*"
   "\\(\\(interface\\)=\\([[:alpha:].]+\\)\\)?\\s-*"
   "\\(\\(method\\)=\\([[:alpha:]_]+\\)\\)?\\s-*"
   ;; permissions - either a single permission or multiple permissions in
   ;; parentheses with commas and whitespace separating
   "\\("
   (regexp-opt apparmor-mode-dbus-permissions 'words)
   "\\|"
   "("
   (regexp-opt apparmor-mode-dbus-permissions 'words)
   "\\("
   (regexp-opt apparmor-mode-dbus-permissions 'words) ",\\s-+"
   "\\)"
   "\\)?\\s-*"
   ","))

(defvar apparmor-mode-font-lock-defaults
  `(((,(regexp-opt apparmor-mode-keywords 'words) . font-lock-keyword-face)
     (,(regexp-opt apparmor-mode-rlimit-types 'words) . font-lock-type-face)
     ;; comma at end-of-line
     (",\\s-*$" . 'font-lock-builtin-face)
     ;; TODO be more specific about where these are valid
     ("->" . 'font-lock-builtin-face)
     ("[=\\+()]" . 'font-lock-builtin-face)
     ("+=" . 'font-lock-builtin-face)
     ("<=" . 'font-lock-builtin-face) ; rlimit
     ;; abi
     (,apparmor-mode-abi-regexp 1 font-lock-preprocessor-face t)
     (,apparmor-mode-abi-regexp 2 font-lock-string-face t)
     ;; includes
     (,apparmor-mode-include-regexp 1 font-lock-preprocessor-face t)
     (,apparmor-mode-include-regexp 3 font-lock-string-face t)
     ;; variables
     (,apparmor-mode-variable-name-regexp 0 font-lock-variable-name-face t)
     ;; profiles
     (,apparmor-mode-profile-regexp 4 font-lock-function-name-face t t)
     (,apparmor-mode-profile-regexp 5 font-lock-variable-name-face t t)
     ;; capabilities
     (,apparmor-mode-capability-regexp 2 font-lock-type-face t)
     ;; file rules
     (,apparmor-mode-file-rule-regexp 4 font-lock-constant-face t) ; permissions
     (,apparmor-mode-file-rule-regexp 5 font-lock-function-name-face t t) ; profile
     ;; network rules
     (,apparmor-mode-network-rule-regexp 3 font-lock-constant-face t t) ;permissions
     (,apparmor-mode-network-rule-regexp 4 font-lock-function-name-face t t) ;domain
     (,apparmor-mode-network-rule-regexp 5 font-lock-variable-name-face t t) ;type
     (,apparmor-mode-network-rule-regexp 6 font-lock-type-face t t) ; protocol
     ;; dbus rules
     (,apparmor-mode-dbus-rule-regexp 4 font-lock-variable-name-face t) ;bus
     (,apparmor-mode-dbus-rule-regexp 5 font-lock-constant-face t) ;system/session
     (,apparmor-mode-dbus-rule-regexp 7 font-lock-variable-name-face t) ;dest
     (,apparmor-mode-dbus-rule-regexp 10 font-lock-variable-name-face t)
     (,apparmor-mode-dbus-rule-regexp 13 font-lock-variable-name-face t)
     (,apparmor-mode-dbus-rule-regexp 16 font-lock-variable-name-face t))))

(defvar apparmor-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; # is comment start
    (modify-syntax-entry ?# "<" table)
    ;; newline finishes comment line
    (modify-syntax-entry ?\n ">" table)
    ;; / and + is used in path names which we want to treat as an entire word
    (modify-syntax-entry ?/ "w" table)
    (modify-syntax-entry ?+ "w" table)
    table))

(defun apparmor-mode-complete-include (prefix &optional local)
  "Return list of completions of include for PREFIX which could be LOCAL."
  (let* ((file-name (file-name-base prefix))
         (parent (file-name-directory prefix))
         (directory (concat (if local default-directory "/etc/apparmor.d") "/"
                            parent)))
    ;; need to prepend all of directory part of prefix
    (mapcar (lambda (f) (concat parent f))
            (file-name-all-completions file-name directory))))

;; TODO - make a lot smarter than just keywords - complete paths from the
;; system if we look like a path, do sub-completion based on the current lines
;; keyword etc - ie match against syntax highlighting regexes and use those to
;; further complete etc
(defun apparmor-mode-completion-at-point ()
  "`completion-at-point' function for `apparmor-mode'."
  (let ((prefix (or (thing-at-point 'word t) ""))
        (bounds (bounds-of-thing-at-point 'word))
        (bol (save-excursion (beginning-of-line) (point)))
        (candidates nil))
    (setq candidates
          (cond ((looking-back "#?include\\s-+\\([<\"]\\)[[:graph:]]*" bol)
                 (apparmor-mode-complete-include
                  prefix (string= (match-string 1) "\"")))
                (t apparmor-mode-keywords)))
    (list (car bounds) ; start
          (cdr bounds) ; end
          candidates
          :company-docsig #'identity)))

(defun apparmor-mode-indent-line ()
  "Indent current line in `apparmor-mode'."
  (interactive)
  (if (bolp)
      (apparmor-mode--indent-line)
    (save-excursion
      (apparmor-mode--indent-line))))

(defun apparmor-mode--indent-line ()
  "Indent current line in `apparmor-mode'."
  (beginning-of-line)
  (cond
   ((bobp)
    ;; simple case indent to 0
    (indent-line-to 0))
   ((looking-at "^\\s-*}\\s-*$")
    ;; block closing, deindent relative to previous line
    (indent-line-to (save-excursion
                      (forward-line -1)
                      (max 0 (- (current-indentation) apparmor-mode-indent-offset)))))
    ;; other cases need to look at previous lines
   (t
    (indent-line-to (save-excursion
                      (forward-line -1)
                      ;; keep going backwards until we have a line with actual
                      ;; content since blank lines don't count
                      (while (and (looking-at "^\\s-*$")
                                  (not (bobp)))
                        (forward-line -1))
                      (cond
                       ((looking-at "\\(^.*{[^}]*$\\)")
                        ;; previous line opened a block, indent to that line
                        (+ (current-indentation) apparmor-mode-indent-offset))
                       (t
                        ;; default case, indent the same as previous line
                        (current-indentation))))))))

;;;###autoload
(define-derived-mode apparmor-mode prog-mode "aa"
  "apparmor-mode is a major mode for editing AppArmor profiles."
  :syntax-table apparmor-mode-syntax-table
  (setq font-lock-defaults apparmor-mode-font-lock-defaults)
  (set (make-local-variable 'indent-line-function) #'apparmor-mode-indent-line)
  (add-to-list 'completion-at-point-functions #'apparmor-mode-completion-at-point)
  (setq imenu-generic-expression `(("Profiles" ,apparmor-mode-profile-regexp 5)))
  (setq comment-start "#")
  (setq comment-end "")
  (when (require 'flycheck nil t)
    (unless (flycheck-valid-checker-p 'apparmor)
      (flycheck-define-command-checker 'apparmor
        "A checker using apparmor_parser. "
        :command '("apparmor_parser"
                  "-Q" ;; skip kernel load
                  "-K" ;; skip cache
                  "-T" ;; skip read cache
                  source)
        :error-patterns '((error line-start "AppArmor parser error at line "
                                 line ": " (message)
                                line-end)
                          (error line-start "AppArmor parser error for "
                                 (one-or-more not-newline)
                                 " in profile " (file-name)
                                 " at line " line ": " (message)
                                line-end))
        :modes '(apparmor-mode)))
    (add-to-list 'flycheck-checkers 'apparmor t)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\`/etc/apparmor\\.d/" . apparmor-mode))

;; flycheck integration


(provide 'apparmor-mode)
;;; apparmor-mode.el ends here
