;;; erlstack-mode.el --- Minor mode for analysing Erlang stacktraces -*- lexical-binding: t; -*-

;; Author: k32
;; Keywords: tools, erlang
;; Package-Version: 20210419.1917
;; Package-Commit: ca264bca24cdaa8b2bac57882716f03f633e42b0
;; Version: 0.2.0
;; Homepage: https://github.com/k32/erlstack-mode
;; Package-Requires: ((emacs "25.1") (dash "2.12.0"))

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

;; Enable `erlstack-mode' globally to peek at source code of functions
;; appearing in Erlang stack traces:
;;
;; (require 'erlstack-mode)
;;
;; Moving point to a stack trace will reveal code in question.  This
;; plugin works best with projectile, however it’s not a hard
;; requirement.

;;; Code:

(defgroup erlstack nil
  "Locate source code mentioned in `erlang' stacktraces."
  :group 'erlang
  :prefix "erlstack-")

(require 'dash)

;;; Macros:

(defvar erlstack--caches-global nil)

(defvar erlstack--caches-local nil)

(defmacro erlstack-define-cache (ctype name &rest args)
  "Create a new cache variable together with a getter function."
  (let ((cache-put-fun (pcase ctype
                         ('local 'setq-local)
                         ('global 'setq)))
        (getter-name (intern
                      (concat "erlstack--cache-"
                              (symbol-name name))))
        (cache-name (intern
                     (concat "erlstack--cache-"
                             (symbol-name name)
                             "-store")))
        (caches-var (pcase ctype
                         ('local 'erlstack--caches-local)
                         ('global 'erlstack--caches-global))))
    `(progn
       (,cache-put-fun ,cache-name ,(cons 'make-hash-table args))
       (add-to-list (quote ,caches-var) (quote ,cache-name))

       (defun ,getter-name (key fun)
         (let ((cached (gethash key ,cache-name nil)))
           (if cached
               cached
             (puthash key (eval fun) ,cache-name)))))))

(defmacro erlstack-jump-frame (fun)
  "Helper macro searching for FUN."
  `(let* ((bound      nil) ;;(,dir (point) erlstack-lookup-window))
          (next-frame (save-excursion
                        (erlstack-goto-stack-begin)
                        ,fun)))
     (when next-frame
       (goto-char next-frame)
       (erlstack-goto-stack-begin))))

;;; Variables:

(defvar erlstack--overlay nil)

(defvar erlstack--code-overlay nil)

(defvar erlstack--code-window nil)

(defvar erlstack--code-window-active nil)

(defvar erlstack--code-buffer nil)

(defvar-local erlstack--current-location nil)

(defvar erlstack-frame-mode-map
  (make-sparse-keymap))

(define-key erlstack-frame-mode-map (kbd "C-<return>") 'erlstack-visit-file)
(define-key erlstack-frame-mode-map (kbd "C-<up>")     'erlstack-up-frame)
(define-key erlstack-frame-mode-map (kbd "C-<down>")   'erlstack-down-frame)

;;; Regular expressions:

(defun erlstack--whitespacify-concat (&rest re)
  "Intercalate strings with regexp RE matching whitespace."
  (--reduce (concat acc "[ \t\n]*" it) re))

(defvar erlstack--string-re
  "\"\\([^\"]*\\)\"")

(defvar erlstack--file-re
  (erlstack--whitespacify-concat "{" "file" "," erlstack--string-re "}"))

(defvar erlstack--line-re
  (erlstack--whitespacify-concat "{" "line" "," "\\([[:digit:]]+\\)" "}"))

(defvar erlstack--position-re
  (erlstack--whitespacify-concat "\\[" erlstack--file-re "," erlstack--line-re "]"))

(defvar erlstack--stack-frame-old-re
  (erlstack--whitespacify-concat erlstack--position-re "}"))
(defvar erlstack--stack-frame-new-re
  (erlstack--whitespacify-concat "(\\(.+\\.erl\\)," "line" "\\([[:digit:]]+\\))"))
(defvar erlstack--stack-frame-re
  (concat erlstack--stack-frame-old-re "\\|" erlstack--stack-frame-new-re))

(defvar erlstack--stack-end-new-re ")$")
(defvar erlstack--stack-end-old-re "}]}")
(defvar erlstack--stack-end-re
  (concat erlstack--stack-end-old-re
          "\\|"
          erlstack--stack-end-new-re))

;;; Custom items:

(defcustom erlstack-file-search-hook
  '(erlstack-locate-projectile
    erlstack-locate-otp
    erlstack-locate-abspath
    erlstack-locate-existing-buffer)
  "A hook that is used to locate source code paths of Erlang modules."
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
  :options '(erlstack-prefer-no-rebar-tmp
             erlstack-prefer-library-modules)
  :group 'erlstack
  :type 'hook)

(defcustom erlstack-lookup-window 300
  "Size of lookup window."
  :group 'erlstack
  :type 'integer)

(defcustom erlstack-otp-src-path ""
  "Path to the OTP source code."
  :group 'erlstack
  :type 'string)

(defcustom erlstack-initial-delay 0.8
  "Overlay delay, in seconds"
  :group 'erlstack
  :type 'float)

;;; Faces:

(defface erlstack-active-frame
  '((((background light))
     :background "orange"
     :foreground "darkred")
    (((background dark))
     :background "orange"
     :foreground "red"))
  "Stack frame highlighting face")

;;; Internal functions:

(defun erlstack--frame-found (begin end)
  "This fuction is called with arguments BEGIN END when point enters stack frame."
  (let ((query       (match-string 1))
        (line-number (string-to-number (match-string 2))))
    ;; Hack: preserve initial state of the code window by restoring it
    (when erlstack--code-window-active
      (quit-restore-window erlstack--code-window))
    (setq-local erlstack--current-location `(,query ,line-number))
    (erlstack--try-show-file query line-number)
    (setq erlstack--overlay (make-overlay begin end))
    (set-transient-map erlstack-frame-mode-map t)
    (overlay-put erlstack--overlay 'face 'erlstack-active-frame)))

(defun erlstack--try-show-file (query line-number)
  "Search for the source code of module QUERY and navigate to LINE-NUMBER."
  (let* ((candidates
          (run-hook-with-args-until-success 'erlstack-file-search-hook query line-number))
         (candidates-
          (--reduce-r-from (funcall it query line-number acc)
                           candidates
                           erlstack-file-prefer-hook))
         (filename
          (car (if candidates-
                   candidates-
                 candidates))))
    (if filename
        (progn
          (erlstack--code-popup filename line-number))
      (erlstack--frame-lost))))

(defun erlstack--code-popup (filename line-number)
  "Open a pop-up window with the code of FILENAME at LINE-NUMBER."
  (setq erlstack--code-buffer (find-file-noselect filename t))
  (with-current-buffer erlstack--code-buffer
    (with-no-warnings
      (goto-line line-number))
    (setq erlstack--code-buffer-posn (point))
    (setq erlstack--code-overlay (make-overlay
                                 (line-beginning-position)
                                 (line-end-position)))
    (overlay-put erlstack--code-overlay 'face 'erlstack-active-frame)
    (setq erlstack--code-window (display-buffer erlstack--code-buffer `(nil . ((inhibit-same-window . ,pop-up-windows)))))
    (setq erlstack--code-window-active t)
    (set-window-point erlstack--code-window erlstack--code-buffer-posn)))

(defun erlstack-visit-file ()
  "Open file related to the currently selected stack frame for editing."
  (interactive)
  (when erlstack--code-window-active
    (setq erlstack--code-window-active nil)
    (pcase erlstack--current-location
      (`(,_filename ,line-number)
       (select-window erlstack--code-window)
       (with-no-warnings
         (goto-line line-number))))))

(defun erlstack--frame-lost ()
  "This fuction is called when point leaves stack frame."
  (when erlstack--code-window-active
    (unless (eq erlstack--code-window (selected-window))
      (quit-restore-window erlstack--code-window))
    (setq erlstack--code-window-active nil)))

(defun erlstack-run-at-point ()
  "Attempt to analyse stack frame at the point."
  (interactive)
  (run-with-idle-timer
   (if erlstack--code-window-active
       0.1
     erlstack-initial-delay) nil
   (lambda ()
     (when erlstack--overlay
       (delete-overlay erlstack--overlay))
     (when erlstack--code-overlay
       (delete-overlay erlstack--code-overlay))
     (pcase (erlstack--parse-at-point)
       (`(,begin ,end) (erlstack--frame-found begin end))
       (_              (erlstack--frame-lost))))))

(defun erlstack--re-search-backward ()
  (let ((bound (save-excursion (forward-line -2)
                               (line-beginning-position))))
    (or
     (re-search-backward erlstack--stack-frame-old-re bound t)
     (re-search-backward erlstack--stack-frame-new-re bound t))))

(defun erlstack--parse-at-point ()
  "Attempt to find stacktrace at point."
  (save-excursion
    (let ((point (point))
          (end (re-search-forward erlstack--stack-end-re
                                  (save-excursion (forward-line 2)
                                                  (line-end-position))
                                  t))
          (begin (erlstack--re-search-backward)))
      (when (and begin end (>= point begin))
        `(,begin ,end)))))

;;; Stack navigation:

(defun erlstack-goto-stack-begin ()
  "Jump to the beginning of stack frame."
  (goto-char (nth 0 (erlstack--parse-at-point))))

(defun erlstack-goto-stack-end ()
  "Jump to the end of stack frame."
  (goto-char (nth 1 (erlstack--parse-at-point))))

(defun erlstack-rebar-tmp-dirp (path)
  "Pretty dumb check that `path' is a temporary file created by
rebar3. This function returns parent directory of rebar's temp
drectory or `nil' otherwise."
  (let ((up (directory-file-name (file-name-directory path)))
        (dir (file-name-nondirectory path)))
    (if (string= up path)
        nil
      (if (string= dir "_build")
          up
        (erlstack-rebar-tmp-dirp up)))))

(defun erlstack-prefer-no-rebar-tmp (_query _line-number candidates)
  "Remove rebar3 temporary files when the originals are found in the list."
  (interactive)
  ;; TODO check that the removed files actually match with the ones
  ;; that left?
  (if (cdr candidates)
      (--filter (not (erlstack-rebar-tmp-dirp it)) candidates)
    candidates))

(defun erlstack-prefer-library-modules (_query _line-number candidates)
  "Prefer OTP library modules over mocks"
  (pcase (-separate 'erlstack--is-library-module candidates)
    (`(,a ,b)
     (append a b))))

(defun erlstack--is-library-module (file)
  (string= "src" (file-name-nondirectory
                  (directory-file-name (file-name-directory file)))))

(defun erlstack-up-frame ()
  "Move one stack frame up."
  (interactive)
  (erlstack-jump-frame
   (re-search-backward erlstack--stack-frame-re bound t)))

(defun erlstack-down-frame ()
  "Move one stack frame down."
  (interactive)
  (erlstack-jump-frame
   (progn
     (re-search-forward erlstack--stack-frame-re bound t 2)
     (re-search-backward erlstack--stack-frame-re bound t)))) ;; TODO: refactor this hack \^////

;;; User commands:

(defun erlstack-drop-caches ()
  "Drop all `erlstack' caches."
  (interactive)
  (dolist (it erlstack--caches-global)
    (clrhash (eval it))
    (message "erlstack-mode: Cleared %s" it))
  (dolist (buff (buffer-list))
    (dolist (var erlstack--caches-local)
      (with-current-buffer buff
        (when (boundp var)
          (clrhash (eval var))
          (message "erlstack-mode: Cleared %s in %s" var buff))))))

;;; Locate source hooks:

(defun erlstack-locate-abspath (query _line)
  "Try locating module QUERY by absolute path."
  (when (file-exists-p query)
    (list query)))

(erlstack-define-cache global otp-files
  :test 'equal)

(defun erlstack-locate-otp (query _line)
  "Try searching for module QUERY in the OTP sources."
  (let ((query- (file-name-nondirectory query)))
    (if (not (string= "" erlstack-otp-src-path))
        (erlstack--cache-otp-files
         query-
         `(directory-files-recursively erlstack-otp-src-path
                                       ,(concat "^" query- "$")))
      (message "erlstack-mode: OTP path not specified")
      nil)))

(erlstack-define-cache global projectile
  :test 'equal)

(defun erlstack-locate-projectile (query _line)
  "Try searching for module QUERY in the current `projectile' root."
  (when (fboundp 'projectile-project-root)
    (let ((dir (projectile-project-root))
          (query- (file-name-nondirectory query)))
      (when dir
        (erlstack--cache-projectile
         (list dir query)
         `(directory-files-recursively
           ,dir
           ,(concat "^" query- "$")))))))

(defun erlstack-locate-existing-buffer (query _line)
  "Try matching existing buffers with QUERY."
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
 :require 'erlstack-mode
 (if erlstack-mode
     (add-hook 'post-command-hook #'erlstack-run-at-point)
   (remove-hook 'post-command-hook #'erlstack-run-at-point)))

(provide 'erlstack-mode)

;;; erlstack-mode.el ends here
