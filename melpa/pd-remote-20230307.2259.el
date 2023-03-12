;;; pd-remote.el --- Pd remote control helper

;; Copyright (c) 2023 Albert Graef

;; Author: Albert Graef <aggraef@gmail.com>
;; Keywords: multimedia, pure-data
;; Package-Version: 20230307.2259
;; Package-Commit: e944426a4d59a31ee913c8547a1ff66c2f7fe82a
;; Version: 1.2.0
;; Package-Requires: ((emacs "24.3") (faust-mode "0.6") (lua-mode "20210802"))
;; URL: https://github.com/agraef/pd-remote
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; pd-remote is a remote-control and live-coding utility for Pd and Emacs.

;; You can add this to your .emacs for remote control of Pd patches in
;; conjunction with the accompanying pd-remote.pd abstraction.  In particular,
;; there's built-in live-coding support for faust-mode and lua-mode via the
;; pd-faustgen2 and pd-lua externals.  The package also includes a minor mode
;; (enabled automatically in faust-mode and lua-mode) which adds some
;; keybindings to invoke these commands.

;; Install this with the Emacs package manager or put it anywhere where Emacs
;; will find it, and load it in your .emacs as follows:

;; (require 'pd-remote)
;; (add-hook 'faust-mode-hook #'pd-remote-mode)
;; (add-hook 'lua-mode-hook #'pd-remote-mode)

;;; Code:

(defgroup pd-remote nil
  "Pd remote control helper."
  :prefix "pd-remote-"
  :group 'multimedia)

(defcustom pd-remote-pdsend "pdsend"
  "This variable specifies the pathname of the pdsend program."
  :type 'string
  :group 'pd-remote)

(defcustom pd-remote-port "4711"
  "This variable specifies the UDP port number to be used."
  :type 'string
  :group 'pd-remote)

(defun pd-remote-start-process ()
  "Start a pdsend process to communicate with Pd via UDP."
  (interactive)
  (start-process "pdsend" nil pd-remote-pdsend pd-remote-port "localhost" "udp")
  (set-process-query-on-exit-flag (get-process "pdsend") nil))

(defun pd-remote-stop-process ()
  "Stops a previously started pdsend process."
  (interactive)
  (delete-process "pdsend"))

;;;###autoload
(defun pd-remote-message (message)
  "Send the given MESSAGE to Pd.  Start the pdsend process if needed."
  (interactive "sMessage: ")
  (unless (get-process "pdsend") (pd-remote-start-process))
  (process-send-string "pdsend" (concat message "\n")))

;; some convenient helpers

;;;###autoload
(defun pd-remote-compile ()
  "Send compile (Faust) or reload (Lua) message."
  (interactive)
  (cond
   ((derived-mode-p 'faust-mode) (pd-remote-message "faustgen2~ compile"))
   ((derived-mode-p 'lua-mode) (pd-remote-message "pdluax reload"))
   (t (user-error "Can't compile %s buffer" (symbol-name major-mode)))))

;;;###autoload
(defun pd-remote-dsp-on ()
  "Start dsp processing."
  (interactive)
  (pd-remote-message "pd dsp 1"))

;;;###autoload
(defun pd-remote-dsp-off ()
  "Stop dsp processing."
  (interactive)
  (pd-remote-message "pd dsp 0"))

;;;###autoload
(define-minor-mode pd-remote-mode
  "Toggle Pd-Remote mode.

This is a minor mode which adds some convenient key bindings to
send messages to Pd:

\\{pd-remote-mode-map}"
 :init-value nil
 :lighter " Pd"
 :group 'pd-remote
 :keymap
 '(("\C-c\C-q" . pd-remote-stop-process)
   ("\C-c\C-m" . pd-remote-message)
   ("\C-c\C-s" . (lambda () "Start" (interactive)
		   (pd-remote-message "play 1")))
   ("\C-c\C-t" . (lambda () "Stop" (interactive)
		   (pd-remote-message "play 0")))
   ("\C-c\C-r" . (lambda () "Restart" (interactive)
		   (pd-remote-message "play 0")
		   (pd-remote-message "play 1")))
   ("\C-c\C-k" . pd-remote-compile)
   ([(control ?\/)] . pd-remote-dsp-on)
   ([(control ?\.)] . pd-remote-dsp-off)))

;; We require Faust and Lua modes here since we need to add some default
;; filename extensions and pd-remote-mode hooks for these.
(require 'faust-mode)
(require 'lua-mode)

;; Faust mode doesn't have a default extension, add one
(add-to-list 'auto-mode-alist '("\\.dsp\\'" . faust-mode))

;; pd-lua uses this as the extension for Lua scripts
(add-to-list 'auto-mode-alist '("\\.pd_luax?\\'" . lua-mode))

;; enable our keybindings in Faust and Lua mode
;(add-hook 'faust-mode-hook #'pd-remote-mode)
;(add-hook 'lua-mode-hook #'pd-remote-mode)

;; add any convenient global keybindings here
;(global-set-key [(control ?\/)] #'pd-remote-dsp-on)
;(global-set-key [(control ?\.)] #'pd-remote-dsp-off)

(provide 'pd-remote)

;; End:
;;; pd-remote.el ends here
