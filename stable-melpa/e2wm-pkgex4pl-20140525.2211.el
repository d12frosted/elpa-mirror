;;; e2wm-pkgex4pl.el --- Plugin of e2wm.el for package explorer of Perl

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: tools, window manager, perl
;; URL: https://github.com/aki2o/e2wm-pkgex4pl
;; Version: 0.0.1
;; Package-Requires: ((e2wm "1.2") (plsense-direx "0.2.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; see <https://github.com/aki2o/e2wm-pkgex4pl/blob/master/README.md>

;;; Dependency:
;; 
;; - e2wm.el ( see <https://github.com/kiwanami/emacs-window-manager> )
;; - plsense-direx.el ( see <https://github.com/aki2o/plsense-direx> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'e2wm-pkgex4pl)

;;; Configuration:
;; 
;; (setq e2wm:c-code-recipe
;;       '(- (:upper-size-ratio 0.5)
;;           (| (:right-max-size 50)
;;              main
;;              (- (:upper-size-ratio 0.7)
;;                 pkgex refex))
;;           sub))
;; 
;; (setq e2wm:c-code-winfo
;;       '((:name main)
;;         (:name pkgex :plugin pkgex4pl)
;;         (:name refex :plugin refex4pl)
;;         (:name sub   :buffer "*info*" :default-hide t)))
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "e2wm-pkgex4pl")

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "e2wm-pkgex4pl:[^:]" :docstring t)
;; `e2wm-pkgex4pl:sync-interval'
;; Number for the interval of sync which is activated during idle.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "e2wm-pkgex4pl:[^:]" :docstring t)
;; `e2wm-pkgex4pl:start-sync-timer'
;; Not documented.
;; `e2wm-pkgex4pl:stop-sync-timer'
;; Not documented.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - e2wm.el ... Version 1.2
;; - plsense-direx.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'e2wm)
(require 'plsense-direx)
(require 'hl-line)

(defgroup e2wm-pkgex4pl nil
  "Plugin of e2wm.el for package explorer of Perl"
  :group 'e2wm
  :prefix "e2wm-pkgex4pl:")

(defcustom e2wm-pkgex4pl:sync-interval idle-update-delay
  "Number for the interval of sync which is activated during idle."
  :type 'number
  :group 'e2wm-pkgex4pl)


;;;;;;;;;;;;;;
;; For E2WM

(defvar e2wm-pkgex4pl::active-plugin-alist nil)

(e2wm:plugin-register 'pkgex4pl "PkgEX4PL" 'e2wm-pkgex4pl:def-plugin-explorer)
(e2wm:plugin-register 'refex4pl "RefEX4PL" 'e2wm-pkgex4pl:def-plugin-referer)

(defun e2wm-pkgex4pl:def-plugin-explorer (frame wm winfo)
  (e2wm-pkgex4pl::activate-plugin 'pkgex4pl (wlf:window-name winfo))
  (e2wm-pkgex4pl:start-sync-timer))

(defun e2wm-pkgex4pl:def-plugin-referer (frame wm winfo)
  (e2wm-pkgex4pl::activate-plugin 'refex4pl (wlf:window-name winfo))
  (e2wm-pkgex4pl:start-sync-timer))

(defun e2wm-pkgex4pl::activate-plugin (plugin-name wname)
  (e2wm-pkgex4pl::deactivate-plugin plugin-name wname)
  (push `(,plugin-name . ,wname) e2wm-pkgex4pl::active-plugin-alist))

(defun e2wm-pkgex4pl::deactivate-plugin (plugin-name wname)
  (e2wm:aif (assq plugin-name e2wm-pkgex4pl::active-plugin-alist)
      (setq e2wm-pkgex4pl::active-plugin-alist
            (delq it e2wm-pkgex4pl::active-plugin-alist))))


;;;;;;;;;;;;;
;; Utility

(defsubst e2wm-pkgex4pl::get-plugin-wname (plugin-name)
  (assoc-default plugin-name e2wm-pkgex4pl::active-plugin-alist))

(defsubst e2wm-pkgex4pl::active-p (wm plugin-name wname)
  (and (e2wm:managed-p)
       (eq (e2wm:pst-window-plugin-get wm wname) plugin-name)))

(defsubst e2wm-pkgex4pl::active-managed-buffer-p (wm wname)
  (let ((buf (wlf:get-buffer wm wname)))
    (and (buffer-live-p buf)
         (with-current-buffer buf plsense-direx::active-p))))

(defvar e2wm-pkgex4pl::err-buffer-name " *WM:PkgEX4PL-Err*")
(defsubst e2wm-pkgex4pl::get-err-buffer ()
  (or (get-buffer e2wm-pkgex4pl::err-buffer-name)
      (with-current-buffer (get-buffer-create e2wm-pkgex4pl::err-buffer-name)
        (insert "Available node is nothing.\n")
        (setq buffer-read-only t)
        (current-buffer))))

(defvar e2wm-pkgex4pl::noready-buffer-name " *WM:PkgEX4PL-NoReady*")
(defsubst e2wm-pkgex4pl::get-noready-buffer ()
  (or (get-buffer e2wm-pkgex4pl::noready-buffer-name)
      (with-current-buffer (get-buffer-create e2wm-pkgex4pl::noready-buffer-name)
        (insert "Main buffer is not ready.\n")
        (setq buffer-read-only t)
        (current-buffer))))


;;;;;;;;;;
;; Sync

(defvar e2wm-pkgex4pl::sync-timer nil)
(defvar e2wm-pkgex4pl::plugins '(pkgex4pl refex4pl))

(defun e2wm-pkgex4pl:start-sync-timer ()
  (interactive)
  (when (not e2wm-pkgex4pl::sync-timer)
    (setq e2wm-pkgex4pl::sync-timer
          (run-with-idle-timer e2wm-pkgex4pl:sync-interval t 'e2wm-pkgex4pl:do-sync))
    (e2wm:message "PkgEX4PL timer started.")))

(defun e2wm-pkgex4pl:stop-sync-timer ()
  (interactive)
  (when (timerp e2wm-pkgex4pl::sync-timer)
    (cancel-timer e2wm-pkgex4pl::sync-timer))
  (setq e2wm-pkgex4pl::sync-timer nil)
  (e2wm:message "PkgEX4PL timer stopped."))

(defun e2wm-pkgex4pl:do-sync ()
  (let* ((wm (e2wm:pst-get-wm))
         (mbuf (e2wm:history-get-main-buffer))
         (mpath (buffer-file-name mbuf))
         (actplugs (loop for p in e2wm-pkgex4pl::plugins
                         for wname = (e2wm-pkgex4pl::get-plugin-wname p)
                         if (e2wm-pkgex4pl::active-p wm p wname) collect p))
         (setbuf (lambda (buf)
                   (loop for p in actplugs
                         do (wlf:set-buffer wm (e2wm-pkgex4pl::get-plugin-wname p) buf)))))
    (if (not actplugs)
        (e2wm-pkgex4pl:stop-sync-timer)
      (with-current-buffer mbuf
        (cond ((not (plsense--active-p))
               ;; Main buffer is not target.
               (funcall setbuf (e2wm-pkgex4pl::get-err-buffer)))
              ((not (plsense--ready-p))
               ;; Main buffer is not yet ready.
               (funcall setbuf (e2wm-pkgex4pl::get-noready-buffer)))
              (t
               (loop with locsync-p = (and (string= plsense--current-method (plsense--get-current-method))
                                           (string= plsense--current-package (plsense--get-current-package))
                                           (string= plsense--current-file mpath))
                     with syncf-alist = '((pkgex4pl . e2wm-pkgex4pl::sync-explorer)
                                          (refex4pl . plsense-direx:find-referer-no-select))
                     for p in actplugs
                     for wname = (e2wm-pkgex4pl::get-plugin-wname p)
                     for self-manage-p = (e2wm-pkgex4pl::active-managed-buffer-p wm wname)
                     for syncf = (assoc-default p syncf-alist)
                     if (or (not locsync-p)
                            (not self-manage-p))
                     do (let ((buf (progn (e2wm:message "PkgEX4PL try to sync between %s to %s" wname mpath)
                                          (funcall syncf))))
                          (if (buffer-live-p buf)
                              (with-current-buffer buf
                                (e2wm:message "PkgEX4PL finished sync between %s to %s" wname mpath)
                                (set-window-point (wlf:get-window wm wname) (point))
                                (wlf:set-buffer wm wname (current-buffer)))
                            (e2wm:message "PkgEX4PL failed sync between %s to %s" wname mpath)
                            (when (not self-manage-p)
                              ;; Sync has not come yet.
                              (wlf:set-buffer wm wname (e2wm-pkgex4pl::get-err-buffer))))))))))))

(defun e2wm-pkgex4pl::sync-explorer ()
  (let ((buf (plsense-direx:find-explorer-no-select)))
    (when (buffer-live-p buf)
      (e2wm:message "PkgEX4PL finished sync explorer")
      (with-current-buffer buf
        (hl-line-mode 1)
        (hl-line-highlight))
      buf)))


;;;;;;;;;;;;;;;;;;;;;;;
;; For plsense-direx

(defadvice plsense-direx::goto-location (after e2wm-pkgex4pl:update-point activate)
  (when (and (e2wm:managed-p)
             (buffer-live-p ad-return-value))
    (with-current-buffer ad-return-value
      (set-window-point (get-buffer-window) (point)))))


(provide 'e2wm-pkgex4pl)
;;; e2wm-pkgex4pl.el ends here
