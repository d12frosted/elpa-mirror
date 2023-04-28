;;; auto-shell-command.el --- Run the shell command asynchronously that you specified when you save the file.

;; Copyright (C) 2012 ongaeshi

;; Author: ongaeshi
;; Keywords: shell, save, async, deferred, auto
;; Package-Version: 20180817.1502
;; Package-Commit: a8f9213e3c773b5687b81881240e6e648f2f56ba
;; Version: 1.0.2
;; Package-Requires: ((deferred "20130312") (popwin "20130329"))

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

;; Run the shell command asynchronously that you specified when you save the file.
;; And there flymake autotest, is Guard as a similar tool.

;; Feature
;;   1. Speicify targete file's regexp and command to execute when the save
;;   2. Can temporarily suspend the execution of the command
;;   3. Emacs is running on the OS of all work
;;   4. It is possible to register a temporary command disappear restart Emacs
;;   5. Caused by rewriting the file does not occur by external tools, malfunctions of the command disappointing

;; URL
;;   https://github.com/ongaeshi/auto-shell-command

;;; Install:

;; Require 'emacs-deferred'
;;   (auto-install-from-url "https://github.com/kiwanami/emacs-deferred/raw/master/deferred.el")
;;   (auto-install-from-url "https://raw.github.com/ongaeshi/auto-shell-command/master/auto-shell-command.el")

;;; Initlial Setting:

;; (require 'auto-shell-command)

;; ;; Shortcut setting (Temporarily on/off auto-shell-command run)
;; (global-set-key (kbd "C-c C-m") 'ascmd:toggle) ; Temporarily on/off auto-shell-command run
;; (global-set-key (kbd "C-c C-,") 'ascmd:popup)  ; Pop up '*Auto Shell Command*'
;; (global-set-key (kbd "C-c C-.") 'ascmd:exec)   ; Exec-command specify file name

;; ;; Popup on errors
;; (push '("*Auto Shell Command*" :height 20 :noselect t) popwin:special-display-config)

;; ;; ;; Notification of results to Growl (optional)
;; ;; (defun ascmd:notify (msg) (deferred:process-shell (format "growlnotify -m %s -t emacs" msg))))

;;; Command-list Setting:

;; ;; High priority under
;; (ascmd:add '("/path/to/dir"                  "make"))     ; Exec 'make'
;; (ascmd:add '("/path/to/dir/.gitignore"       "make run")) ; If you touch beneath the root folder '. gitignore' -> 'make run'
;; (ascmd:add '("/path/to/dir/doc"              "make doc")) ; If you touch the folloing 'doc' -> 'make doc'
;; (ascmd:add '("/path/to/dir/BBB"              "(cd /path/to/dir/AAA && make && cd ../BBB && make)")) ; When you build the BBB, need to build the first AAA

;; Configuration example of Ruby
;; (ascmd:add '("/path/test/runner.rb"          "rake test"))                     ; If you touch 'test/runner.rb' -> 'rake test' (Take time)
;; (ascmd:add '("/path/test/test_/.*\.rb"       "ruby -I../lib -I../test $FILE")) ; If you touch 'test/test_*.rb', test by itself only the edited file (Time-saving)

;; Cooperation with the browser
;; (ascmd:add '("Resources/.*\.js" "wget -O /dev/null http://0.0.0.0:9090/run")) ; If you touch the following: 'Resources/*.js' access to 'http://0.0.0.0:9090/run'

;;; Code:

(eval-when-compile (require 'cl))
(require 'deferred)
(require 'popwin)

;;; Public:

;; Notify function
;;;###autoload
(defun ascmd:notify (msg)
  (message msg)                                                        ; emacs's message function
  ;;(deferred:process-shell (format "growlnotify -m %s -t emacs" msg)) ; Growl(OSX)
  ;;(deferred:process-shell (format "growlnotify %s /t:emacs" msg))   ; Growl(Win)
  )

;; Toggle after-save-hook (Recommended to set the key bindings)
;;;###autoload
(defun ascmd:toggle ()
  (interactive)
  (if ascmd:active
      (setq ascmd:active nil)
    (setq ascmd:active t))
  (force-mode-line-update nil))

(defvar ascmd:active t)

;; Add to command list
;;;###autoload
(defun ascmd:add (&optional v)
  (interactive)
  (cond (v
         (push v ascmd:setting))
        (t
         (let (path command)
           (setq path (read-file-name "Path: " nil (buffer-file-name)))
           (setq command (read-string "Command: "))
           (let ((msg (format "(ascmd:add '(\"%s\" \"%s\"))" path command)))
             (kill-new msg)
             (message msg))
           (push (list path command) ascmd:setting)))))

;; Remove first command
;;;###autoload
(defun ascmd:remove ()
  (interactive)
  (let* ((cmd (pop ascmd:setting))
         (msg (format "(ascmd:add '(\"%s\" \"%s\"))" (car cmd) (car (cdr cmd)))))
    (if cmd
        (progn
          (kill-new msg)
          (message (format "Remove : %s" msg)))
      (message "Command list is empty."))))

;; Remove all command
;;;###autoload
(defun ascmd:remove-all ()
  (interactive)
  (setq ascmd:setting nil))

;; Result buffer name
(defvar ascmd:buffer-name "*Auto Shell Command*")

;; Pop up '*Auto Shell Command*'
;;;###autoload
(defun ascmd:popup (n)
  (interactive "P")
    (let ((with-arg (consp n)))
      (if with-arg
          (progn
            (save-selected-window
              (if (one-window-p)
                  (select-window (split-window-horizontally))
                (other-window 1))
              (switch-to-buffer ascmd:buffer-name)))
        ;; (display-buffer ascmd:buffer-name))))
        (pop-to-buffer ascmd:buffer-name))))

;; Exec-command specify file name
;;;###autoload
(defun ascmd:exec ()
  (interactive)
  (unless (ascmd:exec-in (read-file-name "Specify target file : " nil (buffer-file-name) nil) nil)
    (error "Not found `ascmd:add`")))

;;;###autoload
(defun ascmd:process-count-clear ()
  (interactive)
  (setq ascmd:process-queue nil))

;;; Private:

;; Command list
(defvar ascmd:setting nil)

;; Exec-command when you save file
(add-hook 'after-save-hook 'ascmd:exec-on-save)
(defun ascmd:exec-on-save ()
  (if ascmd:active
      (ascmd:exec-in (buffer-file-name) nil)))

(defun ascmd:exec-in (file-name find-file-p)
  (if find-file-p
      (find-file file-name))
  (find-if '(lambda (v) (apply 'ascmd:exec1 file-name v)) ascmd:setting))

(defun ascmd:exec1 (file-name path command)
  (if (string-match (ascmd:expand-path path) (expand-file-name file-name))
      (progn
        (let ((command (ascmd:query-reqplace command file-name t))
              (process-exec-p (ascmd:process-exec-p)))
          (ascmd:add-command-queue command)
          (unless process-exec-p
            (ascmd:shell-deferred command)))
        t)
    nil))

(defun ascmd:expand-path (path)
  (if (string-match "^~" path)
      (expand-file-name path)
    path))

(defun ascmd:shell-deferred (arg &optional notify-start)
  (lexical-let ((arg arg)
                (notify-start notify-start)
                (result "success"))
    (deferred:$
      ;; before
      (deferred:next
        (lambda ()
          (if notify-start (ascmd:notify "start"))))
      ;; main
      (deferred:process-shell arg)
      (deferred:error it (lambda (err) (setq result "failed") (cadr err)))
      ;; after
      (deferred:nextc it
        (lambda (x)
          (with-current-buffer (get-buffer-create ascmd:buffer-name)
            (delete-region (point-min) (point-max))
            (insert x)
            (if (string-equal result "failed")
                (display-buffer ascmd:buffer-name)
              (if (ascmd:window-popup-p)
                  (delete-window popwin:popup-window)))
            (save-selected-window
              (let ((win (get-buffer-window (get-buffer-create ascmd:buffer-name))))
                (if (not (null win))
                    (progn
                      (select-window win)
                      (goto-char (point-max))
                      (recenter -1)
                      )
                  ))))
          (ascmd:notify result)
          (pop ascmd:process-queue)
          (force-mode-line-update nil)
          (if (ascmd:process-exec-p)
              (ascmd:shell-deferred (car ascmd:process-queue))))))))

(defun ascmd:window-popup-p ()
  (and (popwin:popup-window-live-p)
       (string-equal (buffer-name (window-buffer popwin:popup-window)) ascmd:buffer-name)))

(defvar ascmd:process-queue nil)

(defun ascmd:add-command-queue (arg)
  (if (or (<= (length ascmd:process-queue) 1)
          (not (string-equal (car (last ascmd:process-queue)) arg)))
      (setq ascmd:process-queue (append ascmd:process-queue (list arg)))))

;; query-replace special variable
(defun ascmd:query-reqplace (command match-path &optional cd-prefix-p)
  (let (
        (file-name (file-name-nondirectory match-path))
        (dir-name  (file-name-directory match-path))
        (command (if cd-prefix-p
                     (concat "cd $DIR && (" command ")")
                     command)))
    (setq command (replace-regexp-in-string "$FILE" file-name command t))
    (setq command (replace-regexp-in-string "$DIR" dir-name command t))
    command))

;; Display mode-line
(defun ascmd:process-count ()
  (length ascmd:process-queue))

(defun ascmd:process-exec-p ()
  (not (null ascmd:process-queue)))

(defun ascmd:display-process-count ()
  (cond ((not ascmd:active)
         "[ascmd:stop]")
        ((ascmd:process-exec-p)
         (format "[ascmd:%d] " (ascmd:process-count)))
        ))

(add-to-list 'mode-line-format
             '(:eval (ascmd:display-process-count)))

(provide 'auto-shell-command)
;;; auto-shell-command.el ends here
