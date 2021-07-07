;;; erlstack-mode.el --- Minor mode for analyzing Erlang stacktraces  -*- lexical-binding: t; -*-

;; Author: k32
;; Keywords: tools
;; Package-Version: 20180806.2131
;; Package-Commit: 07398e929978b0eaf2bf119e97cba7b9f9e90d2a

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

;;

;;; Code:

(defgroup erlstack nil
  "Locate source code mantioned in `erlang' stacktraces"
  :group 'erlang
  :prefix "erlstack-")

(require 'dash)

;;; Macros:

(defvar erlstack-caches-global nil)
(defvar erlstack-caches-local nil)

(defmacro erlstack-defcache (ctype name &rest args)
  "Creates a new cache variable together with a getter function"
  (let ((cache-put-fun (pcase ctype
                         ('local 'setq-local)
                         ('global 'setq)))
        (getter-name (intern
                      (concat "erlstack-cache-"
                              (symbol-name name))))
        (cache-name (intern
                     (concat "erlstack-cache-"
                             (symbol-name name)
                             "-store")))
        (caches-var (pcase ctype
                         ('local 'erlstack-caches-local)
                         ('global 'erlstack-caches-global))))
    `(progn
       (,cache-put-fun ,cache-name ,(cons 'make-hash-table args))
       (add-to-list (quote ,caches-var) (quote ,cache-name))

       (defun ,getter-name (key fun)
         (let ((cached (gethash key ,cache-name nil)))
           (if cached
               cached
             (puthash key (eval fun) ,cache-name)))))))

(defmacro erlstack-jump-frame (fun dir)
  `(let* ((bound      nil) ;;(,dir (point) erlstack-lookup-window))
          (next-frame (save-excursion
                        (erlstack-goto-stack-begin)
                        ,fun)))
     (when next-frame
       (goto-char next-frame)
       (erlstack-goto-stack-begin))))

;;; Variables:

(defvar erlstack-overlay nil)
(defvar erlstack-code-overlay nil)
(defvar erlstack-code-window nil)
(defvar erlstack-code-window-active nil)
(defvar erlstack-code-buffer nil)
(defvar-local erlstack-buffer-file-name nil)
(defvar-local erlstack-current-location nil)
;(defvar erlstack-preferred-alternative (make-hash-table :test 'equal))

(defvar erlstack-frame-mode-map
  (make-sparse-keymap))

(define-key erlstack-frame-mode-map (kbd "C-<return>") 'erlstack-visit-file)
(define-key erlstack-frame-mode-map (kbd "C-<up>")     'erlstack-up-frame)
(define-key erlstack-frame-mode-map (kbd "C-<down>")   'erlstack-down-frame)

;;; Regular expressions:

(defun erlstack-whitespacify-concat (&rest re)
  "Intercalate strings with regexp matching whitespace"
  (--reduce (concat acc "[ \t\n]*" it) re))

(defvar erlstack-string-re
  "\"\\([^\"]*\\)\"")

(defvar erlstack-file-re
  (erlstack-whitespacify-concat "{" "file" "," erlstack-string-re "}"))

(defvar erlstack-line-re
  (erlstack-whitespacify-concat "{" "line" "," "\\([[:digit:]]+\\)" "}"))

(defvar erlstack-position-re
  (erlstack-whitespacify-concat "\\[" erlstack-file-re "," erlstack-line-re "]"))

(defvar erlstack-stack-frame-re
  (erlstack-whitespacify-concat "{[^{}]*" erlstack-position-re "}"))

(defvar erlstack-stack-end-re
  "}]}")

;;; Custom items:

(defcustom erlstack-file-search-hook
  '(erlstack-locate-projectile
    erlstack-locate-otp
    erlstack-locate-abspath
    erlstack-locate-existing-buffer)
  "A hook that is used to locate source code paths of Erlang
modules"
  :options '(erlstack-locate-abspath
             erlstack-locate-otp
             erlstack-locate-projectile
             erlstack-locate-existing-buffer)
  :group 'erlstack
  :type 'hook)

(defcustom erlstack-file-prefer-hook
  '(erlstack-prefer-no-rebar-tmp)
  "A hook that is called when `erlstack-file-search-hook' returns
multiple paths for a module. It can be used to pick the preferred
alternative"
  :options '(erlstack-prefer-no-rebar-tmp)
  :group 'erlstack
  :type 'hook)

(defcustom erlstack-lookup-window 300
  "Size of lookup window"
  :group 'erlstack
  :type 'integer)

(defcustom erlstack-otp-src-path ""
  "Path to the OTP source code"
  :group 'erlstack
  :type 'string)

;;; Faces:

(defface erlstack-frame-face
  '((((background light))
     :background "orange"
     :foreground "darkred")
    (((background dark))
     :background "orange"
     :foreground "red"))
  "Stack frame highlighting face")

;;; Internal functions:

(defun erlstack-frame-found (begin end)
  "This fuction is called when point enters stack frame"
  (let ((query       (match-string 1))
        (line-number (string-to-number (match-string 2))))
    (setq-local erlstack-current-location `(,query ,line-number))
    (erlstack-try-show-file query line-number)
    (setq erlstack-overlay (make-overlay begin end))
    (set-transient-map erlstack-frame-mode-map t)
    (overlay-put erlstack-overlay 'face 'erlstack-frame-face)))

(defun erlstack-try-show-file (query line-number)
  "Search for a file"
  ;(message "Trying to open file %s" query)
  (let* ((candidates
          (run-hook-with-args-until-success 'erlstack-file-search-hook query line-number))
         (candidates-
          (run-hook-with-args-until-success 'erlstack-file-prefer-hook
                                            query
                                            line-number
                                            candidates))
         (filename
          (car (if candidates-
                   candidates-
                 candidates))))
    (if filename
        (progn
          (erlstack-code-popup filename line-number))
      (erlstack-frame-lost))))

(defun erlstack-code-popup (filename line-number)
  "Opens a pop-up window with the code"
  (setq erlstack-code-buffer (find-file-noselect filename t))
  (with-current-buffer erlstack-code-buffer
    (with-no-warnings
      (goto-line line-number))
    (setq erlstack-code-buffer-posn (point))
    (setq erlstack-code-overlay (make-overlay
                                 (line-beginning-position)
                                 (line-end-position)))
    (overlay-put erlstack-code-overlay 'face 'erlstack-frame-face)
    (setq erlstack-code-window (display-buffer-in-side-window
                                erlstack-code-buffer
                                '((display-buffer-reuse-window
                                   display-buffer-pop-up-window))))
    (setq erlstack-code-window-active t)
    (set-window-point erlstack-code-window erlstack-code-buffer-posn)))

(defun erlstack-visit-file ()
  "Open file related to the currently selected stack frame for
editing"
  (interactive)
  (when erlstack-code-window-active
    (setq erlstack-code-window-active nil)
    (pcase erlstack-current-location
      (`(,filename ,line-number)
       (select-window erlstack-code-window)
       (with-no-warnings
         (goto-line line-number))))))

(defun erlstack-frame-lost ()
  "This fuction is called when point leaves stack frame"
  (when erlstack-code-window-active
    ;; (switch-to-prev-buffer erlstack-code-window)
    (delete-side-window erlstack-code-window)
    (setq erlstack-code-window-active nil)))

(defun erlstack-run-at-point ()
  "Attempt to analyze stack frame at the point"
  (interactive)
  (run-with-idle-timer
   0.1 nil
   (lambda ()
     (when erlstack-overlay
       (delete-overlay erlstack-overlay))
     (when erlstack-code-overlay
       (delete-overlay erlstack-code-overlay))
     (pcase (erlstack-parse-at-point)
       (`(,begin ,end) (erlstack-frame-found begin end))
       (_              (erlstack-frame-lost))))))

(defun erlstack-parse-at-point ()
  "Attempt to find stacktrace at point"
  (save-excursion
    (let ((point (point))
          (end (re-search-forward erlstack-stack-end-re
                                  (+ (point) erlstack-lookup-window) t))
          (begin (re-search-backward erlstack-stack-frame-re
                                     (- (point) erlstack-lookup-window) t)))
      (when (and begin end (>= point begin))
        `(,begin ,end)))))

;;; Stack navigation:

(defun erlstack-goto-stack-begin ()
  (goto-char (nth 0 (erlstack-parse-at-point))))

(defun erlstack-goto-stack-end ()
  (goto-char (nth 1 (erlstack-parse-at-point))))

(defun erlstack-rebar-tmp-dirp (path)
  "Pretty dumb check that `path' is a temporary file created by
rebar3. This function returns parent directory of rebar's temp
drectory or `nil' otherwise"
  (let ((up (directory-file-name (file-name-directory path)))
        (dir (file-name-nondirectory path)))
    (if (string= up path)
        nil
      (if (string= dir "_build")
          up
        (erlstack-rebar-tmp-dirp up)))))


(defun erlstack-prefer-no-rebar-tmp (query line-number candidates)
  "Removes rebar3 temporary files when the originals are found in the list"
  (interactive)
  ;; TODO check that the removed files actually match with the ones
  ;; that left?
  (if (cdr candidates)
      (--filter (not (erlstack-rebar-tmp-dirp it)) candidates)
    candidates))

(defun erlstack-up-frame ()
  "Move one stack frame up"
  (interactive)
  (erlstack-jump-frame
   (re-search-backward erlstack-file-re bound t) -))

(defun erlstack-down-frame ()
  "Move one stack frame down"
  (interactive)
  (erlstack-jump-frame
   (re-search-forward erlstack-file-re bound t 2) +))

;;; User commands:

(defun erlstack-drop-caches ()
  "Drop all `erlstack' caches"
  (interactive)
  (mapcar (lambda (it)
            (clrhash (eval it))
            (message "erlstack-mode: Cleared %s" it))
          erlstack-caches-global)
  (mapcar (lambda (buff)
            (mapcar (lambda (var)
                      (with-current-buffer buff
                        (when (boundp var)
                          (clrhash (eval var))
                          (message "erlstack-mode: Cleared %s in %s" var buff))))
                    erlstack-caches-local))
            (buffer-list)))

;;; Locate source hooks:

(defun erlstack-locate-abspath (query line)
  "Try absolute path"
  (when (file-exists-p query)
    (list query)))

(erlstack-defcache global otp-files
                   :test 'equal)

(defun erlstack-locate-otp (query line)
  "Try searching the file in the OTP sources"
  (let ((query- (file-name-nondirectory query)))
    (if (not (string-empty-p erlstack-otp-src-path))
        (erlstack-cache-otp-files
         query-
         `(directory-files-recursively erlstack-otp-src-path
                                       ,(concat "^" query- "$")))
      (progn
        (message "erlstack-mode: OTP path not specified")
        nil))))

(erlstack-defcache global projectile
                   :test 'equal)

(defun erlstack-locate-projectile (query line)
  "Try searching the file in the current `projectile' root"
  (let ((dir (projectile-project-root))
        (query- (file-name-nondirectory query)))
    (when dir
      (erlstack-cache-projectile
       (list dir query)
       `(directory-files-recursively
         ,dir
         ,(concat "^" query- "$"))))))

(defun erlstack-locate-existing-buffer (query line)
  "Try matching existing buffers with the query"
  (let ((query- (file-name-nondirectory query)))
    (--filter
     (string= query- (file-name-nondirectory it))
     (--filter it (--map (buffer-file-name it) (buffer-list))))))

(define-minor-mode erlstack-mode
 "Parse Erlang stacktrace at the point and quickly navigate to
the line of the code"
 :keymap nil
 :group 'erlstack
 :lighter " es"
 :global t
 (if erlstack-mode
     (add-hook 'post-command-hook #'erlstack-run-at-point)
   (remove-hook 'post-command-hook #'erlstack-run-at-point)))

(provide 'erlstack-mode)

;;; Example stacktrace:
;;
;; [{shell,apply_fun,3,[{file,"shell.erl"},{line,907}]},
;;  {erl_eval,do_apply,6,[{file,"erl_eval.erl"},{line,681}]},
;;  {erl_eval,try_clauses,8,[{file,"erl_eval.erl"},{line,911}]},
;;  { shell , exprs , 7 , [{file,"shell.erl"},{line,686}]},{shell,eval_exprs,7,[{file,"shell.erl"},{line,642}]},
;;  {shell,eval_loop,3,[ {file,"shell.erl"}, {line,627}]}]


;;; erlstack-mode.el ends here
