;;; comware-router-mode.el --- Major mode for editing Comware configuration files -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2021 Davide Restivo

;; Author: Davide Restivo <davide.restivo@yahoo.it>
;; Maintainer: Davide Restivo <davide.restivo@yahoo.it>
;; Created: 25 Jul 2019
;; Version: 0.5
;; Package-Version: 20201229.1706
;; Package-Commit: f0f884f0fe9ab2c3420e62d27eadc59ac2209a4a
;; URL: https://github.com/daviderestivo/comware-router-mode
;; Package-Requires: ((dash "2.16.0") (emacs "24.3"))
;; Keywords: convenience faces

;;; Commentary:
;;
;;  A major mode for editing Comware router and switch configuration
;;  files.

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;;; Change Log:
;; 0.1 - 2019/07/25 - First version
;; 0.2 - 2019/08/04 - Add VRFs, interfaces, route-policies listing functions
;; 0.3 - 2019/09/22 - Derive comware-router-mode from prog-mode
;; 0.4 - 2019/12/20 - Fix an issue with comments, update copyright year and
;;                    improve syntax highlight
;; 0.5 - 2019/12/21 - Add code folding support
;; 0.6 - 2020/11/11 - Add more router- and service-commands

;;; Code:
(require 'dash)

;; Hook
(defvar comware-router-mode-hook nil
  "Hook called by \"comware-router-mode\".")

;; Mode map
(defvar comware-router-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-j")       'newline-and-indent)
    (define-key map (kbd "C-c C-l v") 'comware-router-vrf-list)
    (define-key map (kbd "C-c C-l i") 'comware-router-interfaces-list)
    (define-key map (kbd "C-c C-l r") 'comware-router-route-policies-list)
    (define-key map (kbd "<tab>")     'comware-router-code-folding-toggle)
    map)
  "Keymap for comware router mode.")

;; Font locking definitions
(defvar comware-router-ipadd-face 'comware-router-ipadd-face "Face for IP addresses.")
(defface comware-router-ipadd-face
  '((t :inherit font-lock-constant-face))
  "Face for IP addresses"
  :group 'comware-router-mode)

(defvar comware-router-service-command-face 'comware-router-service-command-face "Face for router service commands.")
(defface comware-router-service-command-face
  '((t :inherit font-lock-keyword-face))
  "Face for router service commands"
  :group 'comware-router-mode)

(defvar comware-router-command-face 'comware-router-command-face "Face for router commands.")
(defface comware-router-command-face
  '((t :inherit font-lock-constant-face))
  "Face for router commands"
  :group 'comware-router-mode)

(defvar comware-router-undo-face 'comware-router-undo-face "Face for \"undo\".")
(defface comware-router-undo-face
  '(
    (t (:underline t))
    )
  "Face for \"undo\""
  :group 'comware-router-mode)

(defconst comware-router-font-lock-keywords
  (let* (
         ;; Define categories of commands
         (comware-router-command '("aaa"
                                   "arp"
                                   "authentication-profile"
                                   "clock"
                                   "domain"
                                   "drop"
                                   "dtls"
                                   "engine"
                                   "http"
                                   "https"
                                   "hwtacacs"
                                   "ike proposa"
                                   "ip host"
                                   "ip netstream"
                                   "ip route"
                                   "ipsec proposal"
                                   "ipsec p2mp-policy"
                                   "info-center"
                                   "license"
                                   "line"
                                   "local-user"
                                   "nat"
                                   "ntp-service"
                                   "password-recovery"
                                   "public-key"
                                   "public-key-code"
                                   "qos"
                                   "radius-server"
                                   "return"
                                   "role"
                                   "scheduler"
                                   "scp"
                                   "sftp"
                                   "snmp-agent"
                                   "ssh"
                                   "sysname"
                                   "time-range"
                                   "update schedule"
                                   "user-group"
                                   "user-interface"
                                   "version"
                                   "vlan"))
         (comware-router-service-command  '("acl"
                                            "address-family"
                                            "bgp"
                                            "dhcp"
                                            "dhcp policy"
                                            "dhcp server"
                                            "dns"
                                            "interface"
                                            "ip community-filter"
                                            "ip community-list"
                                            "ip prefix-list"
                                            "ip route-static"
                                            "ip vpn-instance"
                                            "nqa"
                                            "object-group"
                                            "object-policy"
                                            "ospf"
                                            "rip"
                                            "route-policy"
                                            "security-zone"
                                            "smart-policy-route"
                                            "traffic behavior"
                                            "traffic classifier"
                                            "traffic policy"
                                            "rtm"
                                            "wlan ac"
                                            "vsi"
                                            "zone-pair"))
         ;; Generate regexp strings for each category of commands
         (comware-router-command-regexp         (concat "^[[:space:]]*"
                                                        (regexp-opt comware-router-command 'word)
                                                        "\\([[:space:][:alnum:][:graph:]]*\\)"))
         (comware-router-service-command-regexp (concat "^[[:space:]]*"
                                                        (regexp-opt comware-router-service-command 'words)
                                                        "\\([[:space:][:alnum:][:graph:]]*\\)")))
    `(
      (,comware-router-command-regexp 1 comware-router-command-face)
      (,comware-router-command-regexp 2 font-lock-function-name-face)
      (,comware-router-service-command-regexp  1 comware-router-service-command-face)
      (,comware-router-service-command-regexp  2 font-lock-function-name-face)
      ("\\<\\(undo [[:space:][:alnum:][:graph:]]*\\)\\>" 1 comware-router-undo-face)
      ("\\<\\([0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\)\\>" 1 comware-router-ipadd-face)
      "Font locking definitions for comware router mode")))

;; Imenu
(defvar comware-router-imenu-expression
  '(
    ("Interfaces"        "^[\t ]*interface *\\(.*\\)" 1)
    ("VRFs"              "^ip vpn-instance *\\(.*\\)" 1)
    ("Routing protocols" "\\(^bgp [0-9]*\\|^ospf [0-9]*\\|^rip [0-9]*\\)" 1)
    ))

;; Indentation
(defun comware-router-indent-line ()
  "Indent current line as comware router config line."
  (indent-relative-first-indent-point))

;; Regexp match
(defun comware-router--match-regexp-in-buffer (regexp regexp-group)
  "Return a list of cons cells matching REGEXP and the given REGEXP-GROUP.
The returned list's elements have the following structure:

\(POS . TEXT-PLIST)

E.g.:
\((261 . #(\"VRF-1\" 0 5 (fontified t face `font-lock-function-name-face')))
 (423 . #(\"VRF-2\" 0 5 (fontified t face font-lock-function-name-face))))

where POS is the position of the match in the original buffer,
and TEXT-PLIST is the matched string with faces information."
  (interactive)
  (let ((matches)
        (-compare-fn (lambda (ele1 ele2)
                       (equal
                        (substring-no-properties (cdr ele1))
                        (substring-no-properties (cdr ele2))))))
    (save-match-data
      (save-excursion
        (with-current-buffer (current-buffer)
          (save-restriction
            (widen)
            (goto-char (point-min))
            (while (search-forward-regexp regexp nil t 1)
              (push `(,(point) . ,(match-string regexp-group)) matches))))))
    (reverse (-sort -compare-fn (-uniq matches)))))

(defun comware-router--write-output-in-destination-buffer (text-plists source-buffer destination-buffer)
  "Write TEXT-PLISTS in DESTINATION-BUFFER, creating an hyperlink to SOURCE-BUFFER for each entry."
  (set-buffer
   (get-buffer-create destination-buffer))
  (dolist (ele text-plists)
    (comware-router--insert-text-button ele source-buffer))
  (set-buffer-modified-p nil)
  (split-window-below)
  (other-window 0)
  (switch-to-buffer destination-buffer)
  (local-set-key (kbd "q") (lambda () (interactive)
                             (kill-this-buffer)
                             (delete-window))))

(defun comware-router--insert-text-button (text-plist source-buffer)
  "Create a text button for TEXT-PLIST with an hyperlink to the corresponding text position in SOURCE-BUFFER."
  (insert-button (substring-no-properties (cdr text-plist))
                 'source-buffer source-buffer
                 'text-plist text-plist
                 'action (lambda (x)
                           (print (button-get x 'source-buffer))
                           (switch-to-buffer-other-window (button-get x 'source-buffer))
                           (goto-char (car (button-get x 'text-plist)))))
  (newline))

;; Show VRFs in new buffer
(defun comware-router-vrf-list ()
  "List all VRFs in a new buffer called \"*Comware: vpn-instances*\"."
  (interactive)
  (comware-router--write-output-in-destination-buffer
   (comware-router--match-regexp-in-buffer "^ip vpn-instance \\(.*\\)" 1) ; Matches
   (buffer-name (current-buffer)) ; Source buffer
   "*Comware: vpn-instances*"))   ; Destination buffer

;; Show route policies in new buffer
(defun comware-router-route-policies-list ()
  "List all route policies in a new buffer called \"*Comware: route-policies*\"."
  (interactive)
  (comware-router--write-output-in-destination-buffer
   (comware-router--match-regexp-in-buffer "^route-policy \\([[:alnum:]][[:graph:]]*\\) \\(.*\\)" 1) ; Matches
   (buffer-name (current-buffer))  ; Source buffer
   "*Comware: route-policies*"))   ; Destination buffer

;; Show interfaces in new buffer
(defun comware-router-interfaces-list ()
  "List all interfaces in a new buffer called \"*Comware: interfaces*\"."
  (interactive)
  (comware-router--write-output-in-destination-buffer
   (comware-router--match-regexp-in-buffer "^interface \\(.*\\)" 1) ; Matches
   (buffer-name (current-buffer)) ; Source buffer
   "*Comware: interfaces*"))      ; Destination buffer

;; Fold/unfold code
(defun comware-router-code-folding-toggle (&optional level)
"Fold text indented same of more than the cursor.
If level is set, set the indent level to LEVEL.
If 'selective-display' is already set to LEVEL, clicking
<tab> again will unset 'selective-display' by setting it to 0."
  (interactive "P")
  (if (eq selective-display (1+ (current-column)))
      (set-selective-display 0)
    (set-selective-display (or level (1+ (current-column))))))

;; Custom syntax table
(defvar comware-router-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "w" table) ; All _'s are part of words.
    (modify-syntax-entry ?-  "w" table) ; All -'s are part of words.
    (modify-syntax-entry ?:  "w" table) ; All :'s are part of words.
    (modify-syntax-entry ?\" "w" table) ; All "'s are part of words.
    (modify-syntax-entry ?#  "<" table) ; All #'s start comments.
    (modify-syntax-entry ?\n ">" table) ; All newlines end comments.
    (modify-syntax-entry ?\r ">" table) ; All linefeeds end comments.
    table)
  "Syntax table for comware router mode.")

;; Entry point
;;;###autoload
(define-derived-mode comware-router-mode prog-mode "Comware"
  "Major mode for editing Comware routers/switches configuration files."
  (set-syntax-table comware-router-mode-syntax-table)
  (use-local-map comware-router-mode-map)
  (setq-local font-lock-defaults '(comware-router-font-lock-keywords))
  (setq-local indent-line-function 'comware-router-indent-line)
  (setq-local comment-start "#")
  (setq-local comment-start-skip "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)#+ *")
  (setq-local imenu-case-fold-search t)
  (setq-local imenu-generic-expression comware-router-imenu-expression)
  (imenu-add-to-menubar "Comware")
  (run-hooks comware-router-mode-hook))

(add-to-list 'auto-mode-alist '("\\.cmw\\'" . comware-router-mode))

(provide 'comware-router-mode)

;;; comware-router-mode.el ends here
