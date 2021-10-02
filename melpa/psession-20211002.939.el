;;; psession.el --- Persistent save of elisp objects. -*- lexical-binding: t -*-

;; Author: Thierry Volpiatto <thierry.volpiatto@gmail.com>
;; Copyright (C) 2010~2014 Thierry Volpiatto, all rights reserved.
;; X-URL: https://github.com/thierryvolpiatto/psession

;; Compatibility: GNU Emacs 24.1+
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (async "1.9.3"))
;; Package-Version: 20211002.939
;; Package-Commit: 76da05f5fb798572a911c398d2dd6f5f30a74746

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


;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'async)
(require 'frameset)

(defvar dired-buffers)
(defvar helm-comp-read-use-marked)


(defgroup psession nil
  "Persistent sessions."
  :group 'frames)

(defcustom psession-elisp-objects-default-directory
  (locate-user-emacs-file "elisp-objects/")
  "The directory where lisp objects will be stored."
  :group 'psession
  :type 'string)

(defcustom psession-object-to-save-alist
  '((extended-command-history . "extended-command-history.el")
    (helm-external-command-history . "helm-external-command-history.el")
    (helm-surfraw-engines-history . "helm-surfraw-engines-history.el")
    (psession--save-buffers-alist . "psession-save-buffers-alist.el")
    (helm-ff-history . "helm-ff-history.el")
    (helm-browse-project-history . "helm-browse-project-history.el")
    (regexp-search-ring . "regexp-search-ring.el")
    (search-ring . "search-ring.el")
    (file-name-history . "file-name-history.el")
    (kill-ring . "kill-ring.el")
    (kill-ring-yank-pointer . "kill-ring-yank-pointer.el")
    (register-alist . "register-alist.el")
    (psession--winconf-alist . "psession-winconf-alist.el")
    (psession--selected-frame-parameters . "psession-selected-frame-parameters.el"))
  "Alist of vars to save persistently.
It is composed of (var_name . \"var_name.el\").
Where \"var_name.el\" is the file where to save value of 'var_name.

These variables are saved when `psession-mode' is enabled, you don't
have to add here the `minibuffer-history' variables, instead enable
`psession-savehist-mode' as a replacement of `savehist-mode'."
  :group 'psession
  :type '(alist :key-type symbol :value-type string))

(defcustom psession-save-buffers-unwanted-buffers-regexp
  ".*[.]org$\\|diary$\\|[.]newsticker-cache$"
  "Regexp matching buffers you don't want to save."
  :group 'psession
  :type 'string)

(defcustom psession-auto-save-delay 300
  "Delay in seconds to auto-save emacs session."
  :group 'psession
  :type 'integer)

(defcustom psession-savehist-ignored-variables nil
  "List of `minibuffer-history' variables to not save."
  :group 'psession
  :type '(repeat symbol))


;;;###autoload
(defun psession-make-persistent-variable (var &optional save)
  "Make symbol variable VAR persistent with psession.

Do not make `minibuffer-history' variables persistent from here,
enable instead `psession-savehist-mode'.

Variable VAR is added to `psession-object-to-save-alist'.

When used interactively or SAVE is non nil, save VAR in
`psession-object-to-save-alist' with customize.

This function is meant to be used interactively, but
if called from elisp in e.g. -your init file- you don't need to specify
SAVE arg."
  (interactive (list (intern
                      (completing-read "Make persistent variable: "
                                       (cl-loop for s being the symbols
                                                when (boundp s)
                                                collect s)))
                     "\np"))
  (cl-assert (and var (boundp var)))
  (cl-pushnew (cons var (format "%s.el" var))
              psession-object-to-save-alist
              :test 'equal)
  (when save ; Interactive.
    (customize-save-variable 'psession-object-to-save-alist
                             psession-object-to-save-alist)))


;;; The main function to save objects to byte compiled file.
;;
;; Each object have its own compiled file.
(defun psession--dump-object-to-file (obj file)
  "Save symbol object OBJ to the byte compiled version of FILE.
OBJ can be any Lisp object, list, hash-table, etc...
Window configurations and markers are not supported.
FILE must be an elisp file with ext \"*.el\" (NOT \"*.elc\").
Loading the *.elc file will return the object.
That may not work with Emacs versions <=23.1 for hash tables."
  (require 'cl-lib) ; Be sure we use the CL version of `eval-when-compile'.
  (cl-assert (not (file-exists-p file)) nil
             (format "dump-object-to-file: File `%s' already exists, please remove it." file))
  (unwind-protect
       (let ((print-length           nil)
             (print-level            nil)
             (print-circle           t)
             (print-escape-nonascii  t)
             (print-escape-multibyte t))
         (with-temp-file file
           (prin1 `(setq-default ,obj (eval-when-compile ,obj)) (current-buffer)))
         (byte-compile-file file)
         (message "`%s' dumped to %sc" obj file))
    (delete-file file)))

;;; Objects (variables to save)
;;
;;
(defun psession--dump-object-to-file-save-alist (&optional skip-props)
  (when psession-object-to-save-alist
    ;; Ensure `psession-elisp-objects-default-directory' is clean.
    (psession-cleanup-dir)
    (cl-loop for (o . f) in psession-object-to-save-alist
             for abs = (expand-file-name f psession-elisp-objects-default-directory)
             for compfile = (concat abs "c")
             ;; Registers and kill-ring are treated specially.
             do
             (cond ((and (eq o 'register-alist)
                         (symbol-value o))
                    (psession--dump-object-save-register-alist f skip-props))
                   ;; Delete saved compiled file with
                   ;; nil value to avoid restoring old non nil value later.
                   ((and (boundp o) (null (symbol-value o))
                         (file-exists-p compfile))
                    (delete-file compfile))
                   ((and (boundp o) (symbol-value o))
                    (psession--dump-object-no-properties o abs skip-props))))))

(defun psession-cleanup-dir ()
  (let ((files (directory-files psession-elisp-objects-default-directory t "\\.el$")))
    (when files
      (if (y-or-n-p (format "%s is not clean, cleanup ? "
                            psession-elisp-objects-default-directory))
          (cl-loop for f in files
                   do (delete-file f))
        (error "Psession aborted, *.el files found in '%s' please remove them"
               psession-elisp-objects-default-directory)))))

(cl-defun psession--restore-objects-from-directory
    (&optional (dir psession-elisp-objects-default-directory))
  (let ((file-list (directory-files dir t directory-files-no-dot-files-regexp)))
    (cl-loop for file in file-list do (and file (load file)))))

(defun psession--purecopy (object)
  (cond ((stringp object)
         (substring-no-properties object))
        ((consp object)
         (cl-loop for elm in object
                  ;; A string.
                  if (stringp elm)
                  collect (substring-no-properties elm)
                  else
                  ;; Proper lists.
                  if (and (consp elm) (null (cdr (last elm))))
                  collect (psession--purecopy elm)
                  else
                  ;; Dotted lists.
                  ;; We handle here only dotted list where car and cdr
                  ;; are atoms i.e. (x . y) and not (x . (x . y)) or
                  ;; (x . (x y)) which should fit most cases.
                  if (and (consp elm) (cdr (last elm)))
                  collect (let ((key (car elm))
                                (val (cdr elm)))
                            (cons (if (stringp key)
                                      (substring-no-properties key)
                                    key)
                                  (if (stringp val)
                                      (substring-no-properties val)
                                    val)))
                  else
                  collect elm))
        (t object)))

(defun psession--dump-object-no-properties (object file &optional skip-props)
  ;; Force not checking properties with SKIP-PROPS.
  (let ((value (symbol-value object)))
    (unless skip-props
      (set object (psession--purecopy value)))
    (psession--dump-object-to-file object file)))

(cl-defun psession--dump-object-save-register-alist (&optional (file "register-alist.el") skip-props)
  "Save `register-alist' but only supported objects."
  (let ((register-alist (cl-loop for (char . rval) in register-alist
                                 for e27 = (and (fboundp 'registerv-p)
                                                (registerv-p rval))
                                 for val = (if e27 (registerv-data rval) rval)
                                 unless (or (markerp val)
                                            (vectorp val)
                                            (and (consp val) (window-configuration-p (car val))))
                                 collect (cons char (if (stringp val)
                                                        (if e27
                                                            (registerv-make (substring-no-properties val))
                                                          (substring-no-properties val))
                                                      rval))))
        (def-file (expand-file-name file psession-elisp-objects-default-directory)))
    (psession--dump-object-no-properties 'register-alist def-file skip-props)))

;;; Persistents window configs
;;
;;
(defconst psession--last-winconf "last_session5247")
(defvar psession--winconf-alist nil)
(defun psession--window-name ()
  (let (result)
    (walk-windows (lambda (w) (cl-pushnew (buffer-name (window-buffer w)) result)))
    (mapconcat 'identity result " | ")))

;;;###autoload
(defun psession-save-winconf (place)
  "Save persistently current window config to PLACE.
Arg PLACE is the key of an entry in `psession--winconf-alist'."
  (interactive (list (let ((name (psession--window-name)))
                       (read-string (format "Place (%s) : " name) nil nil name))))
  (let ((assoc (assoc place psession--winconf-alist))
        (new-conf (list (cons place (window-state-get nil 'writable)))))
    (if assoc
        (setq psession--winconf-alist (append new-conf
                                             (delete assoc psession--winconf-alist)))
        (setq psession--winconf-alist (append new-conf psession--winconf-alist)))))

(defun psession--restore-winconf-1 (conf &optional window ignore)
  (let ((winconf (assoc conf psession--winconf-alist)))
    (if winconf
        (with-selected-frame (last-nonminibuffer-frame)
          (delete-other-windows)
          (window-state-put (cdr (assoc conf psession--winconf-alist)) window ignore))
      (user-error "Psession: Invalid window configuration `%s'" conf))))

;;;###autoload
(defun psession-restore-winconf (conf)
  "Restore window config CONF.
Arg CONF is an entry in `psession--winconf-alist'."
  (interactive (list (completing-read
                      "WinConfig: "
                      (sort (mapcar 'car psession--winconf-alist) #'string-lessp))))
  (psession--restore-winconf-1 conf))

;;;###autoload
(defun psession-delete-winconf (conf)
  "Delete window config CONF from `psession--winconf-alist'."
  (interactive (list (let ((helm-comp-read-use-marked t))
                       (completing-read
                        "WinConfig: "
                        (sort (mapcar 'car psession--winconf-alist) #'string-lessp)))))
  (when (stringp conf)
    (setq conf (list conf)))
  (cl-loop for cfg in conf
           for assoc = (assoc cfg psession--winconf-alist)
           do (setq psession--winconf-alist (delete assoc psession--winconf-alist))))

(defun psession-save-last-winconf ()
  (unless (and (boundp 'helm-alive-p) helm-alive-p)
    (psession-save-winconf psession--last-winconf)))

(defun psession-restore-last-winconf ()
  (when (assoc-default psession--last-winconf psession--winconf-alist)
    (run-with-idle-timer
     0.01 nil (lambda ()
                (psession--restore-winconf-1 psession--last-winconf nil 'safe)))))

;;; Tabs and current frame settings
;;
;;
(defvar psession--selected-frame-parameters nil)

(defun psession-save-frame-tabs ()
  (setq psession--selected-frame-parameters
        (and (boundp 'tab-bar-mode)
             tab-bar-mode
             (frameset-save (list (selected-frame))
                            :app 'psession))))

(defun psession-restore-frame-tabs ()
  (when (frameset-valid-p psession--selected-frame-parameters)
    (frameset-restore psession--selected-frame-parameters
                      :reuse-frames t :cleanup-frames t))
  (when (frame-parameter (selected-frame) 'tabs)
    (tab-bar-mode 1)))


;;; Persistents-buffer 
;;
;;
(defun psession--save-some-buffers ()
  (require 'dired)
  (cl-loop with dired-blist = (cl-loop for (_f . b) in dired-buffers
                                       when (buffer-name b)
                                       collect b)
           with blist = (append (buffer-list) dired-blist)
           for b in blist
           for buf-fname = (or (buffer-file-name b) (car (rassoc b dired-buffers)))
           for place = (with-current-buffer b (point))
           when (and buf-fname
                     (not (or (file-remote-p buf-fname)
                              (and (fboundp 'tramp-archive-file-name-p)
                                   (tramp-archive-file-name-p buf-fname))))
                     (not (string-match  psession-save-buffers-unwanted-buffers-regexp
                                         buf-fname))
                     (file-exists-p buf-fname))
           collect (cons buf-fname place)))

(defvar psession--save-buffers-alist nil)
(defun psession--dump-some-buffers-to-list ()
  (setq psession--save-buffers-alist (psession--save-some-buffers)))

(defun psession--restore-some-buffers ()
  (when psession--save-buffers-alist
    (let* ((max (length psession--save-buffers-alist))
           (progress-reporter (make-progress-reporter "Restoring buffers..." 0 max)))
      (cl-loop for (f . p) in psession--save-buffers-alist
               for count from 0
               do
               (with-current-buffer (find-file-noselect f 'nowarn)
                 (goto-char p)
                 (push-mark p 'nomsg)
                 (progress-reporter-update progress-reporter count)))
      (progress-reporter-done progress-reporter))))

(defun psession-savehist-hook ()
  (unless (or (eq minibuffer-history-variable t)
              (memq minibuffer-history-variable psession-savehist-ignored-variables))
    (cl-pushnew (cons minibuffer-history-variable
                      (concat (symbol-name minibuffer-history-variable) ".el"))
                psession-object-to-save-alist
                :test 'equal)))

;;;###autoload
(define-minor-mode psession-savehist-mode
    "Save minibuffer-history variables persistently."
  :global t
  (if psession-savehist-mode
      (add-hook 'minibuffer-setup-hook 'psession-savehist-hook)
    (remove-hook 'minibuffer-setup-hook 'psession-savehist-hook)))


;;; Auto saving psession
;;
(defun psession--get-variables-regexp ()
  (regexp-opt (cl-loop for (k . _v) in
                       (append psession-object-to-save-alist
                               (mapcar
                                'list
                                '(psession-elisp-objects-default-directory
                                  psession-savehist-ignored-variables
                                  psession-save-buffers-unwanted-buffers-regexp)))
                       collect (symbol-name k))))

(defun psession-save-all-async ()
  "Save current emacs session asynchronously."
  (message "Psession: auto saving session...")
  (psession--dump-some-buffers-to-list)
  (async-start
   `(lambda ()
      (add-to-list 'load-path
                   ,(file-name-directory (locate-library "psession")))
      (require 'psession)
      ;; Inject variables without properties.
      ,(async-inject-variables (format "\\`%s" (psession--get-variables-regexp))
                               nil nil 'noprops)
      ;; No need to treat properties here it is already done.
      (psession--dump-object-to-file-save-alist 'skip-props))
   (lambda (_result)
     (message "Psession: auto saving session done"))))

(defvar psession--auto-save-timer nil)
(defun psession-start-auto-save ()
  "Start auto-saving emacs session in background."
  (setq psession--auto-save-timer
        (run-with-idle-timer
         psession-auto-save-delay t #'psession-save-all-async)))

(defun psession-auto-save-cancel-timer ()
  "Cancel psession auto-saving."
  (when psession--auto-save-timer
    (cancel-timer psession--auto-save-timer)
    (setq psession--auto-save-timer nil)))

;;;###autoload
(define-minor-mode psession-autosave-mode
    "Auto save emacs session when enabled."
  :global t
  (if psession-autosave-mode
      (psession-start-auto-save)
    (psession-auto-save-cancel-timer)))

;;;###autoload
(define-minor-mode psession-mode
  "Persistent emacs sessions."
  :global t
  (if psession-mode
      (progn
        (unless (file-directory-p psession-elisp-objects-default-directory)
          (make-directory psession-elisp-objects-default-directory t))
        (add-hook 'kill-emacs-hook 'psession--dump-object-to-file-save-alist)
        (add-hook 'emacs-startup-hook 'psession--restore-objects-from-directory)
        (add-hook 'kill-emacs-hook 'psession--dump-some-buffers-to-list)
        (add-hook 'emacs-startup-hook 'psession--restore-some-buffers 'append)
        (add-hook 'kill-emacs-hook 'psession-save-last-winconf)
        (add-hook 'emacs-startup-hook 'psession-restore-last-winconf 'append)
        (when (fboundp 'tab-bar-mode)
          (add-hook 'kill-emacs-hook 'psession-save-frame-tabs)
          (add-hook 'emacs-startup-hook 'psession-restore-frame-tabs 'append))
        (add-hook 'kill-emacs-hook 'psession-auto-save-cancel-timer))
    (remove-hook 'kill-emacs-hook 'psession--dump-object-to-file-save-alist)
    (remove-hook 'emacs-startup-hook 'psession--restore-objects-from-directory)
    (remove-hook 'kill-emacs-hook 'psession--dump-some-buffers-to-list)
    (remove-hook 'emacs-startup-hook 'psession--restore-some-buffers)
    (remove-hook 'kill-emacs-hook 'psession-save-last-winconf)
    (remove-hook 'emacs-startup-hook 'psession-restore-last-winconf)
    (when (fboundp 'tab-bar-mode)
      (remove-hook 'kill-emacs-hook 'psession-save-frame-tabs)
      (remove-hook 'emacs-startup-hook 'psession-restore-frame-tabs))))


(provide 'psession)

;;; psession.el ends here
