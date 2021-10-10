;;; iplayer.el --- Browse and download BBC TV/radio shows

;; Copyright (C) 2012-2015  Christophe Rhodes

;; Author: Christophe Rhodes <csr21@cantab.net>
;; URL: https://github.com/csrhodes/iplayer-el
;; Package-Version: 20161120.2120
;; Package-Commit: b788fffa4b36bbd558047ffa6be51b1f0f462f23
;; Version: 0.1
;; Keywords: multimedia, bbc

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

;; Requires and uses the 'get-iplayer' script to provide a
;; convenient interface to BBC iPlayer.

;;; Code:

(defgroup iplayer nil
  "Browse and download BBC TV/radio shows."
  :prefix "iplayer-"
  :group 'applications)

(defcustom iplayer-download-directory "~/iPlayer/"
  "Directory into which shows will be downloaded."
  :group 'iplayer
  :type 'directory)

(defvar iplayer-updating-cache-process nil)
(defvar iplayer-updating-cache-sentinel-info nil)
(defvar iplayer-updating-cache-sentinel-executing nil)

(defun iplayer-updating-cache-sentinel (process event)
  ;; FIXME: assumes that all went well
  (let* ((iplayer-updating-cache-sentinel-executing t)
         (info (reverse iplayer-updating-cache-sentinel-info)))
    (setq iplayer-updating-cache-process nil
          iplayer-updating-cache-sentinel-info nil)
    (dolist (info info)
      (let ((iplayer-command-frame (nth 0 info))
            (iplayer-command-window (nth 1 info))
            (iplayer-command-buffer (nth 2 info))
            (keys (nth 3 info))
            (function (nth 4 info)))
        (when (and (frame-live-p iplayer-command-frame)
                   (window-live-p iplayer-command-window)
                   (buffer-live-p iplayer-command-buffer))
          (let ((old-frame (selected-frame))
                (old-window (selected-window))
                (old-buffer (current-buffer)))
            (cond
             ((version< emacs-version "24")
              (let ((pre-command-hook
                     (lambda ()
                       (select-frame iplayer-command-frame)
                       (select-window iplayer-command-window)
                       (set-buffer iplayer-command-buffer)
                       (setq pre-command-hook nil))))
                ;; KLUDGE: execute-kbd-macro executes a normal
                ;; command-loop, whose first action is to select the
                ;; current frame and window, which is why we contort
                ;; things to select the frame/window/buffer we actually
                ;; want in pre-command-hook.  I'm actually surprised
                ;; that it works, but mine is not too much to reason
                ;; why; lots of other ways to try to achieve this didn't
                ;; in fact work.
                (execute-kbd-macro keys)
                ;; KLUDGE: and then we restore old state
                (select-window old-window)
                (select-frame old-frame)
                (set-buffer old-buffer)))
             (t
              ;; KLUDGE: we store the function name, which is fine,
              ;; but some of our functions need to know which
              ;; keystrokes were used to invoke them, so we need to
              ;; pass those along, so we need to make sure that all
              ;; iplayer-functions accept an optional argument, argh
              ;; argh argh.
              (with-selected-frame iplayer-command-frame
                (with-current-buffer iplayer-command-buffer
                  (with-selected-window iplayer-command-window
                    (funcall function keys)))))))))
      (message "Done updating iPlayer cache"))))

(defmacro define-iplayer-command (name arglist &rest body)
  (let (docstring interactive)
    (when (stringp (car body))
      (setq docstring (car body) body (cdr body)))
    (when (and (consp (car body)) (eql (car (car body)) 'interactive))
      (setq interactive (car body) body (cdr body)))
    `(defun ,name ,arglist
       ,@(when docstring (list docstring))
       ,@(when interactive (list interactive))
       (unless iplayer-updating-cache-process
         (setq iplayer-updating-cache-process
               (start-process "updating-iplayer" " *updating-iplayer*"
                              "get-iplayer" "--type" "radio,tv" "-q"))
         (set-process-sentinel iplayer-updating-cache-process
                               'iplayer-updating-cache-sentinel)
         (message "Updating iPlayer cache"))
       (if iplayer-updating-cache-sentinel-executing
           (progn ,@body)
         (push (list (selected-frame) (selected-window) (current-buffer) (this-command-keys-vector) ',name)
               iplayer-updating-cache-sentinel-info)))))

(defun get-iplayer-tree (&rest args)
  (with-temp-buffer
    (apply #'call-process "get-iplayer" nil t nil "--nocopyright" "--type" "radio,tv" "--tree" "--terse" args)
    (goto-char (point-min))
    (let (result program episodes)
      (while (< (point) (point-max))
        (cond
         ((looking-at "^\\w")
          (when (and program episodes)
            (push (cons program (reverse episodes)) result))
          (setf program (buffer-substring (point) (progn (end-of-line) (point))))
          (when (string-match "^\\(tv\\|radio\\), " program)
            (setq program (substring program (match-end 0))))
          (setf episodes nil)
          (unless (= (point) (point-max))
            (forward-char)))
         ((looking-at "^  \\([0-9]+\\):\\s-\\(.*\\)$")
          (let ((episode
                 (cons (buffer-substring (match-beginning 1) (match-end 1))
                       (buffer-substring (match-beginning 2) (match-end 2)))))
            (when (string-match "^\\(tv\\|radio\\), " (cdr  episode))
              (rplacd episode (substring (cdr episode) (match-end 0))))
            (push episode episodes))
          (forward-line))
         (t (forward-line))))
      (reverse result))))

(defun display-iplayer-tree (tree)
  (with-current-buffer (get-buffer-create "*iplayer*")
    (let ((buffer-read-only nil))
      (fundamental-mode)
      (delete-region (point-min) (point-max))
      (dolist (entry tree)
        (let ((program (car entry))
              (episodes (cdr entry)))
          (insert (propertize (format "* %s\n" program) 'face 'outline-1))
          (dolist (episode episodes)
            (insert (propertize (format "** %s\n" (cdr episode))
                                'face 'outline-2 'iplayer-id (car episode)))))))
    (iplayer-mode)
    (orgstruct-mode 1)
    (org-overview)
    (goto-char (point-min))
    (if iplayer-current-channel
        (setq mode-line-process (format "[%s]" iplayer-current-channel))
      (setq mode-line-process nil)))
  (switch-to-buffer (get-buffer-create "*iplayer*")))

(defvar iplayer-presets
  '(("1" . "BBC One")
    ("2" . "BBC Two")
    ("3" . "BBC Three")
    ("4" . "BBC Four")
    ("8" . "CBBC")
    ("9" . "CBeebies")

    ("!" . "BBC Radio 1")
    ("\"" . "BBC Radio 2")
    ("£" . "BBC Radio 3")
    ("$" . "BBC Radio 4")
    ("%" . "BBC Radio 5 live")
    ("^" . "BBC 6 Music")
    ("&" . "BBC 7")
    ("*" . "BBC Radio 4 Extra"))
  "Alist mapping keys to iPlayer channels.

Used in the `iplayer-preset' command.")

(defcustom iplayer-startup-channel "BBC One"
  "The channel to display at startup"
  :type `(choice
          ,@(mapcar (lambda (x) `(const ,(cdr x))) iplayer-presets)
          (const :tag "Show all content" nil))
  :group 'iplayer)

(defun iplayer-frob-presets (presets)
  (cond
   ((version< emacs-version "24")
    (mapcar (lambda (x) (cons (read-kbd-macro (car x)) (cdr x))) presets))
   (t presets)))

(defvar iplayer-current-channel nil)

(define-iplayer-command iplayer-preset (&optional keys)
  "Switch display to a preset channel.

The presets are defined in the variable `iplayer-presets'."
  (interactive)
  (let ((keys (or (and keys (concat keys)) (this-command-keys)))
        (presets (iplayer-frob-presets iplayer-presets)))
    (cond
     ((= (length keys) 1)
      (let ((channel (cdr (assoc keys presets))))
        (if channel
            (iplayer-channel channel)
          (error "no preset for key %s" keys)))))))

(defun iplayer-channel (channel)
  (setq iplayer-current-channel channel)
  (display-iplayer-tree (get-iplayer-tree "--channel" (format "^%s( England| Scotland| Northern Ireland| Wales)?$" channel))))

(define-iplayer-command iplayer-refresh (&optional keys)
  "Refresh the current iPlayer channel display."
  (interactive)
  (if iplayer-current-channel
      (iplayer-channel iplayer-current-channel)
    (iplayer-show-all)))

(defun iplayer-download-display-state (process)
  (let ((id (process-get process 'iplayer-id))
        (state (process-get process 'iplayer-state))
        (progress (process-get process 'iplayer-progress)))
    (with-current-buffer (get-buffer-create "*iplayer-progress*")
      (special-mode)
      (save-excursion
        (goto-char (point-min))
        (let ((found (re-search-forward (format "^%s:" id) nil 'end))
              (inhibit-read-only t))
          (unless found
            (unless (= (point) (progn (forward-line 0) (point)))
              (goto-char (point-max))
              (newline)))
          (forward-line 0)
          (let ((beg (point)))
            (end-of-line)
            (delete-region beg (point)))
          (insert (format "%s: %s %s%%" id state progress)))))))

(defun iplayer-download-process-filter (process string)
  (catch 'no-progress
    (cond
     ((or (string-match "^Starting download" string)
          (string-match "^INFO: Begin recording" string))
      (process-put process 'iplayer-state 'downloading)
      (process-put process 'iplayer-progress 0.0))
     ((and (eql (process-get process 'iplayer-state) 'downloading)
           (string-match "\\([0-9]\\{1,3\\}\\).[0-9]%" string))
      (process-put process 'iplayer-progress (string-to-number (match-string 1 string))))
     ((string-match "Started writing to temp file" string)
      (process-put process 'iplayer-state 'transcoding)
      (process-put process 'iplayer-progress 0.0))
     ((string-match " Progress: =*>? *\\([0-9]\\{1,3\\}\\)%[- ]*|" string)
      (let ((idx (match-beginning 0)) (data (match-data)))
        (while (string-match " Progress: =*> *?\\([0-9]\\{1,3\\}\\)%[- ]*|" string (match-end 0))
          (setq idx (match-beginning 0))
          (setq data (match-data)))
        (set-match-data data)
        (process-put process 'iplayer-progress (string-to-number (match-string 1 string)))))
     (t (with-current-buffer (process-buffer process)
          (insert string))
        (throw 'no-progress nil)))
    (iplayer-download-display-state process)))

(defun iplayer-download-process-sentinel (process string)
  (cond
   ((string-match "^finished" string)
    ;; KLUDGE: get-iplayer installs signal handlers and exit with a 0
    ;; exit code from them.  That means we can't use the sentinel to
    ;; distinguish between being killed and exiting with success, so
    ;; we hack around the problem.
    (if (= (process-get process 'iplayer-progress) 100)
        (process-put process 'iplayer-state 'finished)
      (process-put process 'iplayer-state 'failed)))
   ((string-match "^exited abnormally" string)
    (process-put process 'iplayer-state 'failed)))
  (iplayer-download-display-state process))

(defun iplayer-download (mode)
  (interactive "p")
  (let ((id (get-text-property (point) 'iplayer-id))
        (mode (case mode
                (1 "default")
                (4 "good")
                (t "best"))))
    (if id
        (let ((default-directory iplayer-download-directory))
          ;; should probably use a process filter instead to give us a
          ;; progress bar
          (message "downloading id %s" id)
          (let ((process
                 (start-process "get-iplayer" " *get-iplayer*" "get-iplayer" (format  "--modes=%s" mode) "--force" "--get" (format "%s" id))))
            (process-put process 'iplayer-id id)
            (process-put process 'iplayer-state 'connecting)
            (process-put process 'iplayer-progress 0.0)
            (set-process-filter process 'iplayer-download-process-filter)
            (set-process-sentinel process 'iplayer-download-process-sentinel)
            (display-buffer (get-buffer-create "*iplayer-progress*"))
            (iplayer-download-display-state process)))
      (message "no id at point"))))

(defun iplayer-previous ()
  (interactive)
  (save-match-data
    (outline-previous-heading)
    (while (and (= (funcall outline-level) 1) (not (bobp)))
      (outline-previous-heading)))
  (hide-other)
  (unless (bobp)
    (save-excursion
      (outline-up-heading 1 t)
      (show-children))))

(defun iplayer-next ()
  (interactive)
  (save-match-data
    (outline-next-heading)
    (while (and (= (funcall outline-level) 1) (not (eobp)))
      (outline-next-heading)))
  (hide-other)
  (save-excursion
    (outline-up-heading 1 t)
    (show-children)))

(defconst iplayer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "0") 'iplayer-show-all)
    (let ((presets "123456789!\"£$%^&*()"))
      (dotimes (i (length presets))
        (define-key map (read-kbd-macro (substring presets i (1+ i)))
          'iplayer-preset)))
    (define-key map (kbd "RET") 'iplayer-download)
    (define-key map (kbd "g") 'iplayer-refresh)
    (define-key map (kbd "j") 'iplayer-next)
    (define-key map (kbd "k") 'iplayer-previous)
    (define-key map (kbd "n") 'iplayer-next)
    (define-key map (kbd "p") 'iplayer-previous)
    map
    ))

(define-derived-mode iplayer-mode special-mode "iPlayer"
  "A major mode for the BBC's iPlayer.
\\{iplayer-mode-map}")

(define-iplayer-command iplayer-show-all (&optional keys)
  "Show all iPlayer entries."
  (interactive)
  (setq iplayer-current-channel nil)
  (display-iplayer-tree (get-iplayer-tree)))

(define-iplayer-command iplayer (&optional keys)
  "Start the emacs iPlayer interface."
  (interactive)
  (if iplayer-startup-channel
      (iplayer-channel iplayer-startup-channel)
    (iplayer-show-all)))

;;;###autoload
(autoload 'iplayer "iplayer" "Start the emacs iPlayer interface." t)

(provide 'iplayer)
;;; iplayer.el ends here
