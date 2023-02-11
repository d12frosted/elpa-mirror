;;; el-fetch.el --- Show system information in Neofetch-like style (eg CPU, RAM) -*- lexical-binding: t -*-


;; This file is part of el-fetch.

;; el-fetch is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, version 3, or
;; (at your option) any later version.

;; el-fetch is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with el-fetch.  If not, see <https://www.gnu.org/licenses/>.

;; Copyright (c) 2022-2023, Maciej Barć <xgqt@riseup.net>
;; Licensed under the GNU GPL v3 License
;; SPDX-License-Identifier: GPL-3.0-or-later


;; Author: Maciej Barć <xgqt@riseup.net>
;; Homepage: https://gitlab.com/xgqt/emacs-el-fetch
;; Version: 3.3.0
;; Package-Version: 20230210.1311
;; Package-Commit: 0142f58f075ea39aa6cc7ed35dd599afc4b6b450
;; Package-Requires: ((emacs "25.1"))



;;; Commentary:


;; Show system information in Neofetch-like style (eg CPU, RAM).

;; Neofetch: https://github.com/dylanaraps/neofetch

;; Inspiration also has been driven from RKTFetch - older fetch-like program
;; that I have helped to write some time ago.

;; RKTFetch: https://github.com/mythical-linux/rktfetch

;; Though, this is not a re-implementation;
;; this program is meant to extend "fetch" to this new domain, i.e. Emacs Lisp.
;; El-Fetch does not implement some of Neofetch's features users of the program
;; may take for granted, e.g.: ASCII art.
;; El-Fetch adds some Emacs-specific information gathering,
;; e.g.: Emacs version/packages, used theme, time spent in the editor.

;; WARNING: El-Fetch is primarily developed on GNU/Linux,
;; Windows support is experimental, macOS support is totally untested.

;; To run El-Fetch add it to your load-path,
;; execute M-x load-library el-fetch and then M-x el-fetch
;; You may want to add it to startup or run Emacs with:
;; --eval "(load-library \"el-fetch\")" --eval "(el-fetch)"



;;; Code:


(require 'cl-lib)
(require 'easymenu)
(require 'package)
(require 'seq)


(defconst el-fetch-version "3.3.0"
  "El-Fetch version.")


;; Helper functions

(defun el-fetch--file->lines (file)
  "Return the contents of FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (split-string (buffer-string) "\n" t)))

(defun el-fetch--get-linux-release ()
  "Scan os-release file paths and return system's name (PRETTY_NAME)."
  (let ((file-paths '("/bedrock/etc/os-release"
                      "/etc/os-release"
                      "/var/lib/os-release"
                      "/usr/lib/os-release"))
        (return)
        (os (symbol-name system-type)))
    (if (dolist (file file-paths return)
          (if (file-readable-p file)
              (dolist (line (el-fetch--file->lines file))
                (if (string-match-p "PRETTY_NAME" line)
                    (setq return
                          (replace-regexp-in-string
                           "\"" ""
                           (cadr (split-string line "="))))))))
        (concat return " " "(" os ")") os)))

(defun el-fetch--get-enabled-modes (modes default)
  "Return string containing the enabled modes form among MODES list.
If no MODES are enabled, return DEFAULT.
MODES is a list of mode name strings, without \"-mode\" suffix."
  (let* ((names (mapcar (lambda (str)
                          (let ((sym (intern (concat str "-mode"))))
                            (if (and (boundp sym) (eval sym)) str nil)))
                        modes))
         (enabled (seq-filter #'stringp names)))
    (if (equal enabled nil)
        default
      (apply #'concat
             (car enabled)
             (mapcar (lambda (str) (concat ", " str)) (cdr enabled))))))


;; Host information

(defun el-fetch--info-cpu ()
  "El-Fetch: CPU part.
Get CPU information."
  (let ((cpuinfo-file-path "/proc/cpuinfo")
        (return "N/A"))
    (if (file-readable-p cpuinfo-file-path)
        (dolist (line (el-fetch--file->lines cpuinfo-file-path) return)
          (if (string-match-p "model name" line)
              (setq return (cadr (split-string line ": ")))))
      return)))

(defun el-fetch--info-device ()
  "El-Fetch: device part.
Get device model."
  (let ((file-paths '("/sys/devices/virtual/dmi/id/product_name"
                      "/sys/firmware/devicetree/base/model"))
        (return "N/A"))
    (dolist (file file-paths return)
      (if (file-readable-p file)
          (setq return (car (el-fetch--file->lines file)))))))

(defun el-fetch--info-distro ()
  "El-Fetch: device part.
Get system distribution."
  (cond
   ((equal system-type 'windows-nt)
    (replace-regexp-in-string "\n" "" (shell-command-to-string "ver.exe")))
   (t (el-fetch--get-linux-release))))

(defun el-fetch--info-memory ()
  "El-Fetch: memory part.
Get amount of memory, reported by Emacs, both used and total, in gibibytes."
  (let ((el-fetch-memory (memory-info)))
    (if (>= (length el-fetch-memory) 4)
        (let* ((total   (+ (car  el-fetch-memory) (caddr  el-fetch-memory)))
               (free    (+ (cadr el-fetch-memory) (cadddr el-fetch-memory)))
               (used    (- total free))
               (total-g (/ total 1024 1024))
               (total-m (% total 1024))
               (used-g  (/ used  1024 1024))
               (used-m  (% used  1024)))
          (format "%d.%d GiB / %d.%d GiB" used-g used-m total-g total-m))
      "N/A")))

(defun el-fetch--info-kernel ()
  "El-Fetch: kernel part.
Get kernel name."
  (let ((osrelease-file-path "/proc/sys/kernel/osrelease"))
    (if (file-readable-p osrelease-file-path)
        (car (el-fetch--file->lines osrelease-file-path))
      "N/A")))

(defun el-fetch--info-shell ()
  "El-Fetch: shell part.
Get user's shell."
  (or (getenv "SHELL") "N/A"))


;; GNU Emacs information

(defun el-fetch--info-emacs-version ()
  "El-Fetch: Emacs version part.
Get GNU Emacs version and the version of GUI toolkit Emacs was built to use."
  (concat emacs-version
          (or (and (boundp 'gtk-version-string)
                (concat " with GTK " gtk-version-string))
             (and (boundp 'motif-version-string)
                (concat " with Motif " motif-version-string))
             "")))

(defun el-fetch--info-emacs-user-dir ()
  "El-Fetch: directory part.
Get path and size of user's Emacs directory."
  (format "%s (%d files)"
          (abbreviate-file-name user-emacs-directory)
          (if (file-exists-p user-emacs-directory)
              (length
               (directory-files-recursively user-emacs-directory ".*" nil))
            0)))

(defun el-fetch--info-emacs-pkgs ()
  "El-Fetch: packages part.
Get installed Emacs Lisp packages the time that was taken to load them."
  (concat (when (bound-and-true-p package-alist)
            (format "%d (standard) "
                    (length package-activated-list)))
          (when (boundp 'straight--profile-cache)
            (format "%d (straight) "
                    (hash-table-count straight--profile-cache)))
          (when (fboundp 'elpaca--queued)
            (format "%d (elpaca) "
                    (length (elpaca--queued))))
          (format "loaded in %s" (emacs-init-time))))

(defun el-fetch--info-emacs-load-path ()
  "El-Fetch: load-path part.
Get the number of directories and nonexistent paths in the `load-path'."
  (let ((nonexistent
         (seq-filter (lambda (path) (not (file-exists-p path))) load-path)))
    (concat (format "%d directories" (length load-path))
            (when nonexistent
              (format ", %d nonexistent" (length nonexistent))))))

(defun el-fetch--info-emacs-font ()
  "El-Fetch: Emacs font part.
Get main used font."
  (let ((default-font (face-attribute 'default :font)))
    (if (equal default-font 'unspecified)
        "N/A"
      (let* ((font-vec    (font-info default-font))
             (font-full   (aref font-vec 1))
             (font-props  (split-string font-full ":"))
             (font-name   (car font-props))
             (font-height (face-attribute 'default :height))
             (font-weight (face-attribute 'default :weight))
             (font-width  (face-attribute 'default :width)))
        (format "%s (height: %s, weight: %s, width: %s)"
                font-name
                font-height
                font-weight
                font-width)))))

(defun el-fetch--info-emacs-theme ()
  "El-Fetch: Emacs theme part.
Get loaded themes."
  (if custom-enabled-themes
      (apply #'concat (mapcar (lambda (sym) (concat (symbol-name sym) " "))
                              custom-enabled-themes))
    "N/A"))

(defun el-fetch--info-emacs-bars ()
  "El-Fetch: Emacs bars part.
Get enabled bars, that is: menu-bar, scroll-bar, tab-bar and tool-bar."
  (el-fetch--get-enabled-modes (mapcar (lambda (str) (concat str "-bar"))
                                       '("menu" "scroll" "tab" "tool"))
                               "none"))

(defun el-fetch--info-emacs-frame ()
  "El-Fetch: Emacs frame part.
Get width and height of current frame."
  (format "%d lines / %d columns"
          (frame-parameter nil 'width) (frame-parameter nil 'height)))

(defun el-fetch--info-emacs-completion ()
  "El-Fetch: Emacs completion part.
Get enabled completion frameworks."
  (el-fetch--get-enabled-modes '("helm" "ido" "ivy" "selectrum")
                               "completion-at-point"))

(defun el-fetch--info-emacs-buffers ()
  "El-Fetch: open Emacs buffers part.
Get number of open buffers."
  (format "%d open" (length (buffer-list))))

(defun el-fetch--info-emacs-processes ()
  "El-Fetch: Emacs processes part.
Get number of running processes."
  (format "%d running" (length (process-list))))

(defun el-fetch--info-emacs-uptime ()
  "El-Fetch: uptime part.
Get how long the Emacs process is running."
  (concat (emacs-uptime) " in Emacs"))

(defun el-fetch--group-memory-use ()
  "El-Fetch: used memory part.
Get Emacs internal memory use.
Returns a list of strings."
  (cl-mapcar
   (lambda (gc-symbol gc-value)
     (let* ((symbol-str (symbol-name gc-symbol))
            (symbol-len (string-bytes symbol-str)))
       (format "\n%s %s : %d"
               symbol-str
               (make-string (- 9 symbol-len) ?\s)
               gc-value)))
   '(Conses Floats Vectors Symbols Chars Intervals Strings)
   (memory-use-counts)))


;; Collect information

(defun el-fetch--collect-info ()
  "Gather up El-Fetch info data and return it as a string."
  (let ((el-fetch-header (concat (user-real-login-name) "@" (system-name))))
    (apply
     #'concat
     el-fetch-header  "\n"
     (make-string (string-width el-fetch-header) ?-)   "\n"
     ;; Host
     "CPU        : " (el-fetch--info-cpu)              "\n"
     "Memory     : " (el-fetch--info-memory)           "\n"
     "Device     : " (el-fetch--info-device)           "\n"
     "Distro     : " (el-fetch--info-distro)           "\n"
     "Kernel     : " (el-fetch--info-kernel)           "\n"
     "Shell      : " (el-fetch--info-shell)            "\n"
     ;; GNU Emacs
     "Emacs      : " (el-fetch--info-emacs-version)    "\n"
     "User Dir   : " (el-fetch--info-emacs-user-dir)   "\n"
     "Packages   : " (el-fetch--info-emacs-pkgs)       "\n"
     "Load Path  : " (el-fetch--info-emacs-load-path)  "\n"
     "Font       : " (el-fetch--info-emacs-font)       "\n"
     "Theme      : " (el-fetch--info-emacs-theme)      "\n"
     "Bars       : " (el-fetch--info-emacs-bars)       "\n"
     "Size       : " (el-fetch--info-emacs-frame)      "\n"
     "Completion : " (el-fetch--info-emacs-completion) "\n"
     "Buffers    : " (el-fetch--info-emacs-buffers)    "\n"
     "Processes  : " (el-fetch--info-emacs-processes)  "\n"
     "Uptime     : " (el-fetch--info-emacs-uptime)
     (el-fetch--group-memory-use))))


;; Mode

(defvar el-fetch-mode-hook nil
  "Hook for El-Fetch major mode.")

(defconst el-fetch-font-lock-keywords
  '(("^--+" . 'font-lock-constant-face)
    ("^[A-z ]+ :" . 'font-lock-keyword-face)
    ("\(.*\)" . 'font-lock-comment-face)
    ("[0-9]" . 'font-lock-constant-face)
    ("/" . 'font-lock-keyword-face)
    ("@" . 'font-lock-constant-face))
  "Font-lock keywords for El-Fetch major mode.")

(defvar el-fetch-mode-map
  (let ((el-fetch-mode-map (make-keymap)))
    (define-key el-fetch-mode-map (kbd "/") 'isearch-forward)
    (define-key el-fetch-mode-map (kbd "?") 'describe-mode)
    (define-key el-fetch-mode-map (kbd "g") 'el-fetch)
    (define-key el-fetch-mode-map (kbd "h") 'describe-mode)
    (define-key el-fetch-mode-map (kbd "q") 'quit-window)
    (define-key el-fetch-mode-map (kbd "r") 'isearch-backward)
    (define-key el-fetch-mode-map (kbd "s") 'isearch-forward)
    el-fetch-mode-map)
  "Key map for El-Fetch major mode.")

(easy-menu-define el-fetch-mode-menu el-fetch-mode-map
  "Menu for `el-fetch-mode'."
  '("El-Fetch"
    ["Run again" el-fetch]
    ["Quit" quit-window]
    ["Help" describe-mode]))

(define-derived-mode el-fetch-mode fundamental-mode "el-fetch"
  "Major mode for browsing El-Fetch output.
Do not use anywhere else."
  (run-hooks 'el-fetch-mode-hook)
  (use-local-map el-fetch-mode-map)
  (setq font-lock-defaults '(el-fetch-font-lock-keywords))
  (setq buffer-read-only t))


;; Main provided features

;;;###autoload
(defun el-fetch ()
  "Show system information in Neofetch-like style (eg CPU, RAM)."
  (interactive)
  (let ((el-fetch-buffer-name "*El-Fetch*"))
    (if (get-buffer el-fetch-buffer-name)
        (kill-buffer el-fetch-buffer-name))
    (let ((el-fetch-buffer (get-buffer-create el-fetch-buffer-name)))
      (with-current-buffer el-fetch-buffer
        (goto-char (point-max))
        (insert (el-fetch--collect-info))
        (newline)
        (el-fetch-mode))
      (switch-to-buffer el-fetch-buffer))))

(defun el-fetch-console ()
  "Print el-fetch output as message, this is meant to be run from batch mode.
Run Emacs with similar options, for example:
--batch -q --no-site-file --eval \"(load-file \"src/el-fetch/el-fetch.el\")\"
--eval \"(el-fetch-console)\""
  (message (el-fetch--collect-info)))


(provide 'el-fetch)



;;; el-fetch.el ends here
