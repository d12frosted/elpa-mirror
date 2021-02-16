;;; helm-exwm.el --- Helm for EXWM buffers -*- lexical-binding: t -*-

;; Copyright (C) 2017-2018 Pierre Neidhardt

;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-exwm
;; Package-Version: 20210215.858
;; Package-Commit: 5b35a42ff10fbcbf673268987df700ea6b6288e8
;; Version: 0.0.2
;; Package-Requires: ((emacs "25.2") (helm "2.8.5") (exwm "0.15"))
;; Keywords: helm, exwm

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; `helm-exwm' run a Helm session over the list of EXWM buffers.
;;
;; To separate EXWM buffers from Emacs buffers in `helm-mini', set up the sources as follows:
;;
;;   (setq helm-exwm-emacs-buffers-source (helm-exwm-build-emacs-buffers-source))
;;   (setq helm-exwm-source (helm-exwm-build-source))
;;   (setq helm-mini-default-sources `(helm-exwm-emacs-buffers-source
;;                                     helm-exwm-source
;;                                     helm-source-recentf)
;;
;; `helm-exwm-switch' is a convenience X application launcher using Helm to
;; switch between the various windows of one or several specific applications.
;; See `helm-exwm-switch-browser' for an example.

;;; Bugs:
;; TODO: kill-persistent is not persistent.
;; This is a Helm issue.  See
;; https://github.com/emacs-helm/helm/issues/1914
;;
;; TODO: Message when killing some buffers: "Killed 0 buffer(s)".
;; See https://github.com/ch11ng/exwm/issues/322.
;; A workaround would be to discard the result of kill-buffer and print the
;; count manually.

;;; Code:
(require 'helm)
(require 'exwm)
(require 'helm-buffers)
(require 'seq)

;; Silence compiler.
(defvar browse-url-generic-program)

(defvar helm-exwm-buffer-max-length 51
  "Max length of EXWM buffer names before truncating.
When disabled (nil) use the longest buffer-name length found.

See `helm-buffer-max-length'.  This variable's default is so that
the EXWM class starts at the column of the open parenthesis in
`helm-buffers-list' detailed view.")

;; Inspired by `helm-highlight-buffers'.
(defun helm-exwm-highlight-buffers (buffers)
  "Transformer function to highlight BUFFERS list.
Should be called after others transformers i.e (boring buffers)."
  (let ((max-length (or helm-exwm-buffer-max-length
                        (cl-loop for b in buffers
                                 maximize (length b)))))
    (cl-loop for i in buffers
             for (name class) = (list i (with-current-buffer i (or exwm-class-name "")))
             for truncbuf = (if (> (string-width name) max-length)
                                (helm-substring-by-width
                                 name max-length
                                 helm-buffers-end-truncated-string)
                              (concat name
                                      (make-string
                                       (- (+ max-length
                                             (length helm-buffers-end-truncated-string))
                                          (string-width name))
                                       ? )))
             collect (let ((helm-pattern (helm-buffers--pattern-sans-filters
                                          (and helm-buffers-fuzzy-matching ""))))
                       (cons (if helm-buffer-details-flag
                                 (concat
                                  (funcall helm-fuzzy-matching-highlight-fn truncbuf)
                                  "  " (propertize class 'face 'helm-buffer-process))
                               (funcall helm-fuzzy-matching-highlight-fn name))
                             (get-buffer i))))))

(defun helm-exwm-toggle-buffers-details ()
  (interactive)
  (with-helm-alive-p
    (let* ((buf (helm-get-selection))
           ;; `helm-buffer--get-preselection' uses `helm-buffer-max-length'.
           (helm-buffer-max-length helm-exwm-buffer-max-length)
           (preselect (helm-buffer--get-preselection buf)))
      (setq helm-buffer-details-flag (not helm-buffer-details-flag))
      ;; TODO: `helm-force-update' seems to be necessary to be necessary to
      ;; update the buffer live.  It is not the case for helm-buffers-list
      ;; though.  Why?
      (helm-force-update (lambda ()
                           (helm-awhile (re-search-forward preselect nil t)
                             (helm-mark-current-line)
                             (when (equal buf (helm-get-selection))
                               (cl-return t))))))))
(put 'helm-exwm-toggle-buffers-details 'helm-only t)

(defvar helm-exwm-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-c o")   'helm-buffer-switch-other-window)
    (define-key map (kbd "C-c C-o") 'helm-buffer-switch-other-frame)
    (define-key map (kbd "M-D")     'helm-buffer-run-kill-buffers)
    ;; (define-key map (kbd "C-c d")   'helm-buffer-run-kill-persistent)
    (define-key map (kbd "C-]")     'helm-exwm-toggle-buffers-details)
    map)
  "Keymap for browser source in Helm.")

(defun helm-exwm-candidates (&optional filter)
  "Return the list of EXWM buffers allowed by FILTER.

If FILTER is nil, then list all EXWM buffers."
  (let ((bufs (delq nil (mapcar
                         (lambda (buf)
                           (if (with-current-buffer buf
                                 (and (eq major-mode 'exwm-mode)
                                      (or (not filter) (funcall filter))))
                               (buffer-name buf)
                             nil))
                         (buffer-list)))))
    (when (> (length bufs) 1)
      ;; Move first buffer (current) to last position.
      (setcdr (last bufs) (list (pop bufs))))
    bufs))

(defun helm-exwm-build-emacs-buffers-source ()
  "Build a Helm source for all non-EXWM buffers."
  (helm-make-source "Emacs buffers" 'helm-source-buffers
    :buffer-list (lambda ()
                   (seq-filter (lambda (b) (with-current-buffer b (not (eq major-mode 'exwm-mode))))
                               (helm-buffer-list)))))

(defun helm-exwm-build-source (&optional filter)
  "Build source for EXWM buffers.
See `helm-exwm' for more details."
  (helm-build-sync-source "EXWM buffers"
    :candidates (lambda () (helm-exwm-candidates filter))
    :candidate-transformer 'helm-exwm-highlight-buffers
    :action '(("Switch to buffer(s)" . helm-buffer-switch-buffers)
              ("Switch to buffer(s) in other window `C-c o'" . helm-buffer-switch-buffers-other-window)
              ("Switch to buffer in other frame `C-c C-o'" . switch-to-buffer-other-frame)
              ("Kill buffer(s) `M-D`" . helm-kill-marked-buffers))
    ;; When follow-mode is on, the persistent-action allows for multiple candidate selection.
    :persistent-action 'helm-buffers-list-persistent-action
    :keymap helm-exwm-map))

;;;###autoload
(defun helm-exwm (&optional filter)
  "Preconfigured `helm' to list EXWM buffers allowed by FILTER.

FILTER must be a function returning non-nil for allowed buffers,
nil for disallowed buffers.  FILTER is run in the context of each
buffer.

If FILTER is nil, then list all EXWM buffers.

Example: List all EXWM buffers but those running XTerm or the URL browser.

  (helm-exwm (function
              (lambda ()
                (pcase (downcase (or exwm-class-name \"\"))
                  (\"XTerm\" nil)
                  ((file-name-nondirectory browse-url-generic-program) nil)
                  (_ t)))))"
  (interactive)
  (helm :sources (helm-exwm-build-source filter)
        :buffer "*helm-exwm*"))



(defun helm-exwm-switch (class &optional program other-window)
  "Switch to some EXWM windows belonging to CLASS.
If current window is not showing CLASS, switch to the last open CLASS window.
If there is none, start PROGRAM.

If PROGRAM is nil, it defaults to CLASS.
With prefix argument or if OTHER-WINDOW is non-nil, open in other window."
  ;; If current window is not in `exwm-mode' we switch to it.  Therefore we must
  ;; also make sure that current window is not a Helm buffer, otherwise calling
  ;; this function will lose focus in Helm.
  (unless helm-alive-p
    (setq program (or program class)
          other-window (or other-window current-prefix-arg))
    (let* ((filter (lambda ()
                     (string= (downcase (or exwm-class-name "")) (downcase class))))
           (maybe-buf (seq-find (lambda (b)
                                  (with-current-buffer b
                                    (and (eq major-mode 'exwm-mode)
                                         (funcall filter))))
                                (buffer-list))))
      (cond
       ((eq maybe-buf (current-buffer))
        (let ((helm-buffer-details-flag nil))
          (helm-exwm filter)))
       (maybe-buf
        (funcall (if other-window 'switch-to-buffer-other-window 'switch-to-buffer) maybe-buf))
       (t
        (when other-window (select-window (split-window-sensibly)))
        (start-process-shell-command program nil program))))))

;;;###autoload
(defun helm-exwm-switch-browser ()
  "Switch to some `browse-url-generic-program' windows.

See `helm-exwm-switch'."
  (interactive)
  (require 'browse-url)
  (helm-exwm-switch (file-name-nondirectory browse-url-generic-program) browse-url-generic-program))

;;;###autoload
(defun helm-exwm-switch-browser-other-window ()
  "Switch to some `browse-url-generic-program' windows in other window.

See `helm-exwm-switch'."
  (interactive)
  (require 'browse-url)
  (helm-exwm-switch (file-name-nondirectory browse-url-generic-program) browse-url-generic-program t))

(provide 'helm-exwm)
;;; helm-exwm.el ends here
