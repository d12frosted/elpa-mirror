;;; winds.el --- Window configuration switcher grouped by workspaces                          -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Javier A. Pollak

;; Author: Javier A. Pollak <javi.po.123@gmail.com>
;; Maintainer: Javier A. Pollak <javi.po.123@gmail.com>
;; Created: 17 Apr 2020
;; Keywords: convenience
;; Package-Version: 20201121.123
;; Package-Commit: 5827e890059d0ce67ebb4779da63c15afccf0973
;; Version: 1.1.1
;; Homepage: https://github.com/Javyre/winds.el
;; Package-Requires: ((emacs "25.1"))

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
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; #+TITLE: Winds.el
;; #+AUTHOR: Javier A. Pollak
;;
;; Window configuration switcher grouped by workspaces
;;
;; winds.el is very similar to [[https://github.com/wasamasa/eyebrowse/][eyebrowse]], =tab-bar-mode=, and other window
;; config switchers, but allows for having multiple "workspaces" grouping
;; sets of window config slots. It also saves winner-like history for
;; each window config slot independently.
;;
;; This small package was started because I tend to have multiple
;; unrelated projects open at once, and need to keep them open. I do
;; not want to cycle through unrelated window configs to get to what I
;; want and I want to keep only one fullscreen emacs frame open.
;;
;; (This package has basic support for multiple frames)
;;
;; * Screenshot
;;   [[file:scrot.png]]
;;
;; * Install
;;
;;   This package is available on Melpa. Simply install it with your
;;   favorite package manager:
;;
;;   #+BEGIN_SRC elisp
;;   (use-package winds :ensure t)
;;   #+END_SRC
;;
;; * Getting Started
;;
;;   To get started, bind some keys to ~winds-goto~:
;;
;;   #+BEGIN_SRC elisp
;;   (global-set-key (kbd "M-1") (lambda () (interactive) (winds-goto :ws 1)))
;;   (global-set-key (kbd "M-2") (lambda () (interactive) (winds-goto :ws 2)))
;;   (global-set-key (kbd "M-3") (lambda () (interactive) (winds-goto :ws 3)))
;;   (global-set-key (kbd "C-c 1") (lambda () (interactive) (winds-goto :cfg 1)))
;;   (global-set-key (kbd "C-c 2") (lambda () (interactive) (winds-goto :cfg 2)))
;;   (global-set-key (kbd "C-c 3") (lambda () (interactive) (winds-goto :cfg 3)))
;;   #+END_SRC
;;
;;   You might also want to bind ~next~/~prev~ and ~close~
;;
;;   #+BEGIN_SRC elisp
;;   (global-set-key (kbd "C-c <")  'winds-next)
;;   (global-set-key (kbd "C-c >")  'winds-prev)
;;   (global-set-key (kbd "C-c \\") 'winds-close)
;;   (global-set-key (kbd "C-<")    'winds-cfg-next)
;;   (global-set-key (kbd "C->")    'winds-cfg-prev)
;;   (global-set-key (kbd "C-\\")   'winds-cfg-close)
;;   #+END_SRC
;;
;; * Options
;;
;;   To disable the status message when changing window configs:
;;
;;   #+BEGIN_SRC elisp
;;   (setq winds-display-status-msg nil)
;;   #+END_SRC
;;
;;   For a simple mode-line indicator, add this to your ~mode-line-format~:
;;
;;   #+BEGIN_SRC elisp
;;     (:eval (format "%s|%s " (winds-get-cur-ws) (winds-get-cur-cfg)))
;;   #+END_SRC
;;
;;   For example (dumb example):
;;
;;   #+BEGIN_SRC elisp
;;     (setq mode-line-format
;;           `(,mode-line-format
;;             (:eval (format "%s|%s "
;;                            (winds-get-cur-ws)
;;                            (winds-get-cur-cfg)))))
;;   #+END_SRC
;;
;;   =winds.el= works with =desktop.el=! If you want to enable saving of
;;   winds workspaces add this to your configuration:
;;
;;   #+BEGIN_SRC elisp
;;     (with-eval-after-load 'desktop (winds-enable-desktop-save))
;;   #+END_SRC
;;
;;   =winds.el= saves winner-like history for each window config slot!
;;   To enable history tracking, add this:
;;
;;   #+BEGIN_SRC elisp
;;     (winds-history-mode)
;;     (global-set-key (kbd "C-c <left>")  'winds-history-undo)
;;     (global-set-key (kbd "C-c <right>")  'winds-history-redo)
;;   #+END_SRC
;;
;; * My config
;;
;;   As an example, here is how I use this package:
;;
;;   #+BEGIN_SRC elisp
;;     (use-package winds
;;       :straight t
;;       :custom
;;       (winds-default-ws 1)
;;       (winds-default-cfg 1)
;;       :init
;;       ;; Avoid lazy loading so that history is saved
;;       ;; from the very start of session
;;       (winds-mode)
;;       (winds-history-mode)
;;       (with-eval-after-load 'desktop (winds-enable-desktop-save))
;;       :general
;;       (:prefix "SPC w"
;;         "[" 'winds-history-undo
;;         "]" 'winds-history-redo
;;         "w n" 'winds-next
;;         "w p" 'winds-prev
;;         "w c" 'winds-close
;;         "w w TAB" 'winds-last
;;         "n" 'winds-cfg-next
;;         "p" 'winds-cfg-prev
;;         "c" 'winds-cfg-close
;;         "w TAB" 'winds-cfg-last
;;         "w o" 'winds-pos-last
;;         "w 0" (lambda () (interactive) (winds-goto :ws 10))
;;         "w 1" (lambda () (interactive) (winds-goto :ws 1))
;;         "w 2" (lambda () (interactive) (winds-goto :ws 2))
;;         "w 3" (lambda () (interactive) (winds-goto :ws 3))
;;         "w 4" (lambda () (interactive) (winds-goto :ws 4))
;;         "w 5" (lambda () (interactive) (winds-goto :ws 5))
;;         "w 6" (lambda () (interactive) (winds-goto :ws 6))
;;         "w 7" (lambda () (interactive) (winds-goto :ws 7))
;;         "w 8" (lambda () (interactive) (winds-goto :ws 8))
;;         "w 9" (lambda () (interactive) (winds-goto :ws 9))
;;         "0" (lambda () (interactive) (winds-goto :cfg 10))
;;         "1" (lambda () (interactive) (winds-goto :cfg 1))
;;         "2" (lambda () (interactive) (winds-goto :cfg 2))
;;         "3" (lambda () (interactive) (winds-goto :cfg 3))
;;         "4" (lambda () (interactive) (winds-goto :cfg 4))
;;         "5" (lambda () (interactive) (winds-goto :cfg 5))
;;         "6" (lambda () (interactive) (winds-goto :cfg 6))
;;         "7" (lambda () (interactive) (winds-goto :cfg 7))
;;         "8" (lambda () (interactive) (winds-goto :cfg 8))
;;         "9" (lambda () (interactive) (winds-goto :cfg 9)))
;;       ("M-0" (lambda () (interactive) (winds-goto :cfg 10))
;;        "M-1" (lambda () (interactive) (winds-goto :cfg 1))
;;        "M-2" (lambda () (interactive) (winds-goto :cfg 2))
;;        "M-3" (lambda () (interactive) (winds-goto :cfg 3))
;;        "M-4" (lambda () (interactive) (winds-goto :cfg 4))
;;        "M-5" (lambda () (interactive) (winds-goto :cfg 5))
;;        "M-6" (lambda () (interactive) (winds-goto :cfg 6))
;;        "M-7" (lambda () (interactive) (winds-goto :cfg 7))
;;        "M-8" (lambda () (interactive) (winds-goto :cfg 8))
;;        "M-9" (lambda () (interactive) (winds-goto :cfg 9))))
;;   #+END_SRC

;;; Code:

(require 'cl-lib)
(require 'ring)

;; Custom

(defgroup winds nil
  "A window configuration switcher for multiple workspaces"
  :group 'convenience
  :prefix "winds-")

(defcustom winds-default-ws 1
  "Default selected workspace."
  :type 'integer
  :group 'winds)
(defcustom winds-default-cfg 1
  "Default selected window config slot."
  :type 'integer
  :group 'winds)

(defcustom winds-display-status-msg t
  "Whether to display a status message upon switching window config."
  :type 'boolean
  :group 'winds)

(defcustom winds-init-cfg-hook
  (list (lambda (w c)
          (ignore w c)
          (delete-other-windows)
          (switch-to-buffer "*scratch*")))
  "Hook called to create a new layout upon opening a new window config slot.

The hook receives two parameters: the window-id and cfg-id of the new slot
Set to `nil` to not run any initialization"
  :type 'hook
  :group 'winds)

(defcustom winds-history-size 200
  "Size of window config history saved for each slot."
  :type 'integer
  :group 'winds)


;; Vars/Decls

(cl-defstruct (winds--ring
               (:constructor make-winds--ring
                             (&optional (size 10)
                                        &aux (rwnd (make-ring size))
                                        (fwd (make-ring size)))))
  "A rewindable ring."
  rwnd
  fwd)

(defun winds--ring-clear-forward (ring)
  "Clear the RING's fwd history."
  (let ((fhist (winds--ring-fwd ring)))
    (unless (ring-empty-p fhist)
      (setf (winds--ring-fwd ring)
            (make-ring (ring-size fhist))))))

(defun winds--ring-insert (ring item &optional keep-forward)
  "Insert ITEM into RING, clearing it's fwd history unless KEEP-FORWARD is non-nil."
  (unless keep-forward (winds--ring-clear-forward ring))
  (ring-insert (winds--ring-rwnd ring) item))

(defun winds--ring-remove (ring index)
  "Remove INDEX item from RING's rwnd hist."
  (ring-remove (winds--ring-rwnd ring) index))

(defun winds--ring-replace (ring item)
  "Replace top element in RING's rwnd hist with ITEM."
  (winds--ring-remove ring 0)
  (winds--ring-insert ring item t))

(defun winds--ring-replace-or-insert (ring item)
  "Replace top element in RING's rwnd hist with ITEM or insert if it is completely empty."
  (if (winds--ring-total-empty-p ring)
      (winds--ring-insert ring item)
    (winds--ring-replace ring item)))

(defun winds--ring-rewind (ring)
  "Rewind RING by one element."
  (let ((r (winds--ring-rwnd ring))
        (f (winds--ring-fwd ring)))
    (if (= 1 (ring-length r))
        (error "Rewind ring already at oldest element")
      (let ((hd (ring-remove r 0)))
        (ring-insert f hd)))))

(defun winds--ring-forward (ring)
  "Fast-forward RING by one element."
  (let ((r (winds--ring-rwnd ring))
        (f (winds--ring-fwd ring)))
    (if (ring-empty-p f)
        (error "Forward ring empty")
      (let ((hd (ring-remove f 0)))
        (ring-insert r hd)))))

(defun winds--ring-ref (ring index)
  "Retrieve element at INDEX from RING's rwnd history."
  (ring-ref (winds--ring-rwnd ring) index))

(defun winds--ring-fwd-empty-p (ring)
  "Check whether the RING's fwd history is empty."
  (ring-empty-p (winds--ring-fwd ring)))

(defun winds--ring-rwnd-empty-p (ring)
  "Check whether the RING's rwnd history is empty."
  (ring-empty-p (winds--ring-rwnd ring)))

(defun winds--ring-total-empty-p (ring)
  "Check whether the RING's rwnd and fwd history are empty."
  (and (winds--ring-rwnd-empty-p ring)
       (winds--ring-fwd-empty-p ring)))

(defun winds--ring-fwd-length (ring)
  "Get the RING's fwd history length."
  (ring-length (winds--ring-fwd ring)))

(defun winds--ring-rwnd-length (ring)
  "Get the RING's rwnd history length."
  (ring-length (winds--ring-rwnd ring)))

(defun winds--ring-total-length (ring)
  "Get the RING's total history length."
  (+ (winds--ring-fwd-length ring)
     (winds--ring-rwnd-length ring)))

(defmacro winds--alist-get (alist &rest path)
  "Utility macro to get nested attributes in an ALIST by PATH."
  (if (>= (length path) 2)
      `(winds--alist-get (alist-get ,(car path) ,alist) ,@(cdr path))
    `(alist-get ,(car path) ,alist)))

(defmacro winds--state-get (frame &rest path)
  "Utility macro get winds FRAME state via PATH."
  (if path
      `(winds--alist-get (winds--state-get ,frame) ,@path)
    `(frame-parameter ,frame 'winds--state)))

(cl-defstruct (winds-workspace (:type vector) :named)
  cfgs) ;; window config slots alist

(defvar winds-*workspaces* '())

;; NOTE: whenever we set `record-history` to nil we must consume
;; the nil with a redisplay to trigger the on-config-change hook
(defvar winds--*record-history* t)

;; cur ws/cfg
(defun winds-get-cur-ws (&optional frame)
  "Get the currently selected workspace id in FRAME or the current frame."
  (or (winds--state-get frame :cur-ws) winds-default-ws))

(defun winds-get-cur-cfg (&optional frame wsid)
  "Get the currently selected window config slot id in FRAME in workspace WSID.

FRAME defaults to current frame.
WSID defaults to current workspace id."
  (unless wsid (setf wsid (winds-get-cur-ws)))
  (or (winds--state-get frame :workspaces wsid :cur-cfg)
      winds-default-cfg))

;; last ws/cfg
(defun winds-get-last-cfg (&optional frame wsid)
  "Get the previously selected window config slot in FRAME in workspace WSID.

FRAME defaults to current frame.
WSID defaults to current workspace id.
Returns nil if no last-cfg found."
  (unless wsid (setf wsid (winds-get-cur-ws frame)))
  (winds--state-get frame :workspaces wsid :last-cfg))

(defun winds-get-last-ws (&optional frame)
  "Get the previously selected workspace slot in FRAME.

FRAME defaults to current frame.
Returns nil if no last-cfg found."
  (winds--state-get frame :last-ws))

(defun winds-get-last-pos (&optional frame)
  "Get the previously selected (ws cfg) pair in  FRAME.

FRAME defaults to current frame.
Returns nil if no last-cfg found."
  (winds--state-get frame :last-pos))


(defun winds-get-last-or-cur-cfg (&optional frame wsid)
  "Get the previously selected window config slot in FRAME in workspace WSID.

FRAME defaults to current frame.
WSID defaults to current workspace id.
Returns `(winds-get-cur-cfg)' if no last-cfg found."
  (or (winds-get-last-cfg frame wsid)
      (winds-get-cur-cfg frame wsid)))

;; Private

(defun winds--get-or-create-ws (wsid)
  "Get or create workspace in slot WSID."
  (let ((ws (alist-get wsid winds-*workspaces*)))
    (unless ws
      (setf ws (make-winds-workspace :cfgs '()))
      (setf (alist-get wsid winds-*workspaces*) ws))
    ws))

(defun winds--save-cfg-if-empty ()
  "Save the current window config to the current slot if slot is empty."
  (let* ((wsid   (winds-get-cur-ws))
         (cfgid  (winds-get-cur-cfg))
         (ws    (winds--get-or-create-ws wsid))
         (cfgs  (winds-workspace-cfgs ws)))
    (unless (alist-get cfgid cfgs)
      (winds-save-cfg :ws wsid :cfg cfgid))))

(defun winds--get-wsids ()
  "Get the current set of workspace ids."
  (cl-loop for assoc in winds-*workspaces*
           collect (car assoc) into keys
           finally return (progn
                            (cl-pushnew (winds-get-cur-ws) keys)
                            keys)))

(cl-defun winds--get-cfgids (&optional (wsid (winds-get-cur-ws)))
  "Get the current set of window config ids."
  (let ((ws (winds--get-or-create-ws wsid)))
    (cl-loop for assoc in (winds-workspace-cfgs ws)
             collect (car assoc) into keys
             finally return (progn
                              (when (eq wsid (winds-get-cur-ws))
                                (cl-pushnew (winds-get-cur-cfg) keys))
                              keys))))

(defun winds--before-config-change ()
  (when winds--*record-history*
    (let ((minibuf-open-p (not (zerop (minibuffer-depth)))))
      (setf (winds--state-get nil :maybe-old-minibuf-open-p) minibuf-open-p)
      (unless minibuf-open-p
        (setf (winds--state-get nil :maybe-old-window-config)
              (window-state-get nil t))))))

(defun winds--on-config-change ()
  "Save the window config to the current active cfg slot's history ring."
  (when (and winds--*record-history*
             (winds--state-get nil :maybe-old-window-config)
             (not (winds--state-get nil :maybe-old-minibuf-open-p)))
    (let* ((wsid (winds-get-cur-ws))
           (cfgid (winds-get-cur-cfg))
           (ws (winds--get-or-create-ws wsid))
           (cfgs (winds-workspace-cfgs ws))
           (cfg (alist-get cfgid cfgs)))

      (winds--ring-replace-or-insert
       cfg (winds--state-get nil :maybe-old-window-config))
      (setf (winds--state-get nil :maybe-old-window-config) nil)

      ;;  create an empty ring slot to be filled by winds-save-cfg
      (winds--ring-insert cfg nil)
      (winds-save-cfg)
      (winds--ring-clear-forward cfg)))
  (setf winds--*record-history* t))

;; Public

;;;###autoload
(define-minor-mode winds-mode
  "Toggle winds.el window config and workspace manager."
  :global t
  (when winds-mode
    (winds-save-cfg))

  (if winds-mode
      (progn
        (with-eval-after-load 'desktop
          (winds-enable-desktop-save)))

    (when (boundp 'desktop-save-mode)
      (winds-enable-desktop-save t))))

;;;###autoload
(define-minor-mode winds-history-mode
  "Toggle winds.el history mode.

Saves history of window config changes within a window-config slot in
winds.el. Use this global minor mode to replace `winner-mode` and have a
more relevant history ring saved."
  :global t
  (if winds-history-mode
      (progn
        (add-hook 'pre-command-hook 'winds--before-config-change)
        (add-hook 'window-configuration-change-hook 'winds--on-config-change))
    (remove-hook 'pre-command-hook 'winds--before-config-change)
    (remove-hook 'window-configuration-change-hook 'winds--on-config-change)))

;; defvar to silence compiler warning
(eval-when-compile (defvar desktop-globals-to-save))
(defun winds-enable-desktop-save (&optional disable)
  "Enable or disable (if DISABLE) saving of winds workspaces with desktop.el.

NOTE: This function loads feature `desktop' if not loaded already.
      You should probably put this in a `with-eval-after-load' clause."
  (interactive)

  (require 'desktop)
  (if disable
      (setq desktop-globals-to-save
            (cl-loop for s in desktop-globals-to-save
                     unless (eq s 'winds-*workspaces*)
                     collect s))
    (add-to-list 'desktop-globals-to-save 'winds-*workspaces*)))

(defun winds-display-status-msg ()
  "Display a status message in the echo area with the current ws id and cfg id."
  (interactive)
  (let* ((wsids  (sort (winds--get-wsids) #'<))
         (cfgids (sort (winds--get-cfgids) #'<))
         (bg       (face-attribute 'mode-line-inactive :background))
         (sel-fg   (face-attribute 'mode-line :foreground))
         (unsel-fg (face-attribute 'mode-line-inactive :foreground))
         (sel-face   `(:background ,bg :foreground ,sel-fg))
         (unsel-face `(:background ,bg :foreground ,unsel-fg))
         (msg-left (mapcar
                    (lambda (id) (if (eq id (winds-get-cur-ws))
                                     (propertize (format "%s " id) 'face sel-face)
                                   (propertize (format "%s " id) 'face unsel-face)))
                    wsids))
         (msg-right (mapcar
                     (lambda (id) (if (eq id (winds-get-cur-cfg))
                                      (propertize (format " %s" id) 'face sel-face)
                                    (propertize (format " %s" id) 'face unsel-face)))
                     cfgids))
         (msg-left  (cl-reduce #'concat msg-left))
         (msg-right (cl-reduce #'concat msg-right))
         (msg-left  (concat (propertize "W " 'face unsel-face) msg-left))
         (msg-right (concat msg-right (propertize " C" 'face unsel-face))))

    ;; Don't spam *Messages*
    (let ((message-log-max nil))
      (message "%s|%s" msg-left msg-right))))

;;;###autoload
(cl-defun winds-save-cfg (&key ((:ws  wsid)   (winds-get-cur-ws))
                               ((:cfg cfgid)  nil))
  "Save current window configuration into workspace WS, config CFG.

WS  defaults to current workspace
CFG defaults to current cfg if WS is current or to `winds-default-cfg'

Call interactively to be prompted for a workspace and window config to save to.

Call interactively with a prefix argument to save to the current window config slot
 in the current workspace."

  (interactive (unless current-prefix-arg
                 (list :ws (read-from-minibuffer
                            "Workspace to save window config to (blank for current): "
                            nil nil t nil (format "%s" (winds-get-cur-ws)))
                       :cfg (read-from-minibuffer
                             "Window config slot to save to (blank for current): "
                             nil nil t nil (format "%s" (winds-get-cur-cfg))))))
  (unless cfgid (setf cfgid
                      (if (eq wsid (winds-get-cur-ws))
                          (winds-get-cur-cfg)
                        winds-default-cfg)))

  (let ((ws (winds--get-or-create-ws wsid)))
    (if (alist-get cfgid (winds-workspace-cfgs ws))
        (let ((cfg (alist-get cfgid (winds-workspace-cfgs ws))))
          (winds--ring-replace-or-insert cfg (window-state-get nil t)))

      (setf (alist-get cfgid (winds-workspace-cfgs ws))
            (make-winds--ring winds-history-size))
      (winds-save-cfg :ws wsid
                      :cfg cfgid))))

;;;###autoload
(cl-defun winds-goto (&key ((:ws wsid) (winds-get-cur-ws))
                           ((:cfg cfgid) nil)
                           (do-save t))
  "Switch to another workspace and/or window config slot.

Call interactively to be prompted for a workspace and window config to swtich to.

Call interactively with a prefix argument to go to the last selected
window config slot in the current workspace."

  (interactive (unless current-prefix-arg
                 (list :ws (read-from-minibuffer
                            "Workspace to switch to (blank for current): "
                            nil nil t nil (format "%s" (winds-get-cur-ws)))
                       :cfg (read-from-minibuffer
                             "Window config slot to switch to (blank for last selected): "
                             nil nil t nil "nil"))))

  ;; Return to last selected cfg for selected ws
  (unless cfgid (setf cfgid (winds-get-last-or-cur-cfg nil wsid)))

  ;; Save current cfg before leaving
  (when do-save (winds-save-cfg))

  (let ((cur-ws  (winds-get-cur-ws))
        (cur-cfg (winds-get-cur-cfg)))
    (unless (eq cur-ws wsid)
      (setf (winds--state-get nil :last-ws) cur-ws))
    (setf (winds--state-get nil :workspaces cur-ws :last-cfg) cur-cfg)
    (setf (winds--state-get nil :last-pos) (cons cur-ws cur-cfg)))

  (setf (winds--state-get nil :cur-ws) wsid)
  (setf (winds--state-get nil :workspaces wsid :cur-cfg) cfgid)

  (let* ((ws (winds--get-or-create-ws wsid))
         (cfgs (winds-workspace-cfgs ws))
         (cfg  (alist-get cfgid cfgs)))
    (if cfg
        ;; Goto
        (let ((window-config (winds--ring-ref cfg 0)))
          (setq winds--*record-history* nil)
          (window-state-put window-config (frame-root-window) 'safe)
          (redisplay))

      ;; Init new win config
      (setq winds--*record-history* nil)
      (run-hook-with-args 'winds-init-cfg-hook wsid cfgid)
      (winds-save-cfg :ws wsid :cfg cfgid)))

  (when winds-display-status-msg
    (winds-display-status-msg)))

;;;###autoload
(defun winds-last ()
  "Go to the previously selected workspace slot."
  (interactive)
  (winds-goto :ws (winds-get-last-ws)))

;;;###autoload
(defun winds-cfg-last ()
  "Go to the previously selected window config slot in the current workspace."
  (interactive)
  (winds-goto :cfg (winds-get-last-cfg)))

;;;###autoload
(defun winds-pos-last ()
  "Go to the previously selected window config slot and workspace."
  (interactive)
  (let ((pos (winds-get-last-pos)))
    (winds-goto :ws (car pos)
                :cfg (cdr pos))))

;;;###autoload
(defun winds-next ()
  "Go to next workspace slot."
  (interactive)

  ;; In order to include the current ws in the sorted list
  (winds--save-cfg-if-empty)

  (let* ((wsids    (sort (winds--get-wsids) #'<))
         (next-pos (1+ (cl-position (winds-get-cur-ws) wsids))))
    (when (= next-pos (length wsids))
      (message "Already on last workspace. Wrapping back to first.")
      (setf next-pos 0))
    (winds-goto :ws (nth next-pos wsids))))

;;;###autoload
(defun winds-prev ()
  "Go to previous workspace slot."
  (interactive)

  ;; In order to include the current ws in the sorted list
  (winds--save-cfg-if-empty)

  (let* ((wsids    (sort (winds--get-wsids) #'>))
         (next-pos (1+ (cl-position (winds-get-cur-ws) wsids))))
    (when (= next-pos (length wsids))
      (message "Already on first workspace. Wrapping back to last.")
      (setf next-pos 0))
    (winds-goto :ws (nth next-pos wsids))))

;;;###autoload
(defun winds-cfg-next ()
  "Go to next window config slot."
  (interactive)

  ;; In order to include the current cfg in the sorted list
  (winds--save-cfg-if-empty)

  (let* ((cfgids   (sort (winds--get-cfgids) #'<))
         (next-pos (1+ (cl-position (winds-get-cur-cfg) cfgids))))
    (when (= next-pos (length cfgids))
      (message "Already on last window config. Wrapping back to first.")
      (setf next-pos 0))
    (winds-goto :cfg (nth next-pos cfgids))))

;;;###autoload
(defun winds-cfg-prev ()
  "Go to previous window config slot."
  (interactive)

  ;; In order to include the current cfg in the sorted list
  (winds--save-cfg-if-empty)

  (let* ((cfgids   (sort (winds--get-cfgids) #'>))
         (next-pos (1+ (cl-position (winds-get-cur-cfg) cfgids))))
    (when (= next-pos (length cfgids))
      (message "Already on first window config. Wrapping back to last.")
      (setf next-pos 0))
    (winds-goto :cfg (nth next-pos cfgids))))

;;;###autoload
(defun winds-close (wsid)
  "Close workspace slot WSID.

Close workspace slot WSID and switch to nearest slot or `winds-default-ws'
 if none open.  If interactive, you are prompted for an id or blank to close
 current ws."

  (interactive (list (read-from-minibuffer "Workspace to close (blank for current): "
                                           nil nil t nil
                                           (format "%s" (winds-get-cur-ws)))))
  (let ((wsids (sort (winds--get-wsids) #'<)))
    (if (memql wsid wsids)
        (progn
          (setf (alist-get wsid winds-*workspaces* nil 'remove) nil)
          (when (eq wsid (winds-get-cur-ws))
            (let ((goto (car (cl-remove-if (lambda (e) (eq wsid e)) wsids))))
              (winds-goto :ws (or goto winds-default-ws) :do-save nil))))
      (message "Workspace %s does not exist!" wsid))))

;;;###autoload
(defun winds-cfg-close (cfgid)
  "Close window config slot CFGID.

Close window config slot CFGID and switch to nearest slot or `winds-default-cfg'
 if none open.  If interactive, you are prompted for an id or blank to close
 current cfg"

  (interactive (list (read-from-minibuffer "Window config to close (blank for current): "
                                           nil nil t nil
                                           (format "%s" (winds-get-cur-cfg)))))
  (let ((cfgids (sort (winds--get-cfgids) #'<))
        (ws (winds--get-or-create-ws (winds-get-cur-ws))))
    (if (memql cfgid cfgids)
        (progn
          (setf (alist-get cfgid (winds-workspace-cfgs ws) nil 'remove) nil)
          (when (eq cfgid (winds-get-cur-cfg))
            (let ((goto (car (cl-remove-if (lambda (e) (eq cfgid e)) cfgids))))
              (winds-goto :cfg (or goto winds-default-cfg) :do-save nil))))
      (message "Window config %s does not exist!" cfgid))))

;;;###autoload
(defun winds-history-undo (&optional redo)
  "Go back or forward in the window config history for the current slot.

Go forward in the history if REDO is non-nil"
  (interactive)

  (let* ((wsid (winds-get-cur-ws))
         (cfgid (winds-get-cur-cfg))
         (ws (winds--get-or-create-ws wsid))
         (cfgs (winds-workspace-cfgs ws))
         (cfg (alist-get cfgid cfgs)))
    (if redo
        (if (winds--ring-fwd-empty-p cfg)
            (user-error "Already at latest position in history: (%d/%d)"
                        (winds--ring-rwnd-length cfg)
                        (winds--ring-total-length cfg))
          (winds--ring-forward cfg))
      (if (= 1 (winds--ring-rwnd-length cfg))
          (user-error "Already at first position in history: (%d/%d)"
                      (winds--ring-rwnd-length cfg)
                      (winds--ring-total-length cfg))
        (winds--ring-rewind cfg)))

    (setq winds--*record-history* nil)
    (window-state-put (winds--ring-ref cfg 0)
                      (frame-root-window)
                      'safe)
    (redisplay)

    (let ((pos (winds--ring-rwnd-length cfg))
          (total (winds--ring-total-length cfg)))
      (if redo
          (message (format "Redo! (%d/%d)" pos total))
        (message (format "Undo! (%d/%d)" pos total))))))

;;;###autoload
(defun winds-history-redo ()
  "Go forward in the window config history for the current slot"
  (interactive)
  (winds-history-undo t))

(provide 'winds)
;;; winds.el ends here
