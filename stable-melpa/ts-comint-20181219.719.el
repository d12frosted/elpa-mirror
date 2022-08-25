;;; ts-comint.el --- Run a Typescript interpreter in an inferior process window.

;;; Copyright (C) 2008 Paul Huff
;;; Copyright (C) 2015 Stefano Mazzucco
;;; Copyright (C) 2016 Jostein Kjønigsen

;;; Author: Paul Huff <paul.huff@gmail.com>, Stefano Mazzucco <MY FIRST NAME - AT - CURSO - DOT - RE>
;;; Created: 28 September 2016
;;; Version: 0.0.1
;; Package-Version: 20181219.719
;; Package-Commit: b280cfe9fe5ecec9d5970043b6b2866f644b39ad
;;; URL: https://github.com/josteink/ts-comint
;;; Package-Requires: ()
;;; Keywords: typescript, node, inferior-mode, convenience

;; This file is NOT part of GNU Emacs.

;;; License:

;; ts-comint.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; at your option any later version.

;; ts-comint.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING, or type `C-h C-c'. If
;; not, write to the Free Software Foundation at this address:

;;   Free Software Foundation
;;   51 Franklin Street, Fifth Floor
;;   Boston, MA 02110-1301
;;   USA

;;; Commentary:

;; ts-comint.el is a comint mode for Emacs which allows you to run a
;; compatible typescript repl like Tsun inside Emacs.
;; It also defines a few functions for sending typescript input to it
;; quickly.

;; Usage:
;;  Put ts-comint.el in your load path
;;  Add (require 'ts-comint) to your .emacs or ~/.emacs.d/init.el
;;
;;  Do: `M-x run-ts'
;;  Away you go.

;;  You can add  the following couple of lines to your .emacs to take advantage of
;;  cool keybindings for sending things to the typescript interpreter inside
;;  of typescript-mode:
;;
;;   (add-hook 'typescript-mode-hook
;;             (lambda ()
;;               (local-set-key (kbd "C-x C-e") 'ts-send-last-sexp)
;;               (local-set-key (kbd "C-M-x") 'ts-send-last-sexp-and-go)
;;               (local-set-key (kbd "C-c b") 'ts-send-buffer)
;;               (local-set-key (kbd "C-c C-b") 'ts-send-buffer-and-go)
;;               (local-set-key (kbd "C-c l") 'ts-load-file-and-go)))

;;; Code:

(require 'comint)

(defgroup ts-comint nil
  "Run a Typescript process in a buffer."
  :group 'languages)

(defcustom ts-comint-program-command "tsun"
  "Typescript interpreter."
  :type 'string
  :group 'ts-comint)

(defcustom ts-comint-program-arguments nil
  "List of command line arguments to pass to the Typescript interpreter."
  :type 'string
  :group 'ts-comint)

(defcustom ts-comint-mode-hook nil
  "*Hook for customizing `ts-comint-mode'."
  :type 'hook
  :group 'ts-comint)

(defcustom ts-comint-mode-ansi-color t
  "Use ansi-colors for inferior Typescript mode."
  :type 'boolean
  :group 'ts-comint)

(defvar ts-comint-buffer nil
  "Name of the inferior Typescript buffer.")


(defun ts-comint--get-load-file-cmd (filename)
  "Generate a Typescript import-statement for `FILENAME'."
  (concat "import * as "
          (file-name-base filename)
          " from \""
          (file-name-base filename)
          "\"\n"))

;;;###autoload
(defun run-ts (&optional cmd dont-switch-p)
  "Run an inferior Typescript process, via buffer `*Typescript*'.
If there is a process already running in `*Typescript*', switch
to that buffer.  With argument `CMD', allows you to edit the
command line (default is value of `ts-comint-program-command').
Runs the hook `ts-comint-mode-hook' \(after the
`comint-mode-hook' is run).  \(Type \\[describe-mode] in the
process buffer for a list of commands). Use `DONT-SWITCH-P' to
prevent switching to the new buffer once created."
  (interactive
   (list
    (when current-prefix-arg
      (read-string "Run typescript: "
                   (mapconcat
                    'identity
                    (cons
                     ts-comint-program-command
                     ts-comint-program-arguments)
                    " ")))))

  (when cmd
    (setq ts-comint-program-arguments (split-string cmd))
    (setq ts-comint-program-command (pop ts-comint-program-arguments)))

  (if (not (comint-check-proc "*Typescript*"))
      (with-current-buffer
          (apply 'make-comint "Typescript" ts-comint-program-command
                 nil ts-comint-program-arguments)
        (ts-comint-mode)))
  (setq ts-comint-buffer "*Typescript*")
  (if (not dont-switch-p)
      (pop-to-buffer "*Typescript*"))

  ;; apply terminal preferences
  (if ts-comint-mode-ansi-color
      (progn
        ;; based on
        ;; http://stackoverflow.com/questions/13862471/using-node-ts-with-ts-comint-in-emacs

        ;; We like nice colors
        (ansi-color-for-comint-mode-on)
        ;; Deal with some prompt nonsense
        (make-local-variable 'comint-preoutput-filter-functions)
        (add-to-list
         'comint-preoutput-filter-functions
         (lambda (output)
           (replace-regexp-in-string "\033\\[[0-9]+[GKJ]" "" output))))
    (setenv "NODE_NO_READLINE" "1")))

;;;###autoload
(defun ts-send-string (text)
  "Send `TEXT' to the inferior Typescript process."
  (interactive "r")
  (run-ts ts-comint-program-command t)
  (comint-send-string (get-buffer-process ts-comint-buffer)
                      (concat text "\n")))

;;;###autoload
(defun ts-send-region (start end)
  "Send the current region to the inferior Typescript process."
  (interactive "r")
  (let ((text (buffer-substring-no-properties start end)))
    (ts-send-string text)))

;;;###autoload
(defun ts-send-region-and-go (start end)
  "Send the current region to the inferior Typescript process."
  (interactive "r")
  (ts-send-region start end)
  (switch-to-ts ts-comint-buffer))

;;;###autoload
(defun ts-send-last-sexp-and-go ()
  "Send the previous sexp to the inferior Typescript process."
  (interactive)
  (ts-send-region-and-go
   (save-excursion
     (backward-sexp)
     (move-beginning-of-line nil)
     (point))
   (point)))

;;;###autoload
(defun ts-send-last-sexp ()
  "Send the previous sexp to the inferior Typescript process."
  (interactive)
  (ts-send-region
   (save-excursion
     (backward-sexp)
     (move-beginning-of-line nil)
     (point))
   (point)))

;;;###autoload
(defun ts-send-buffer ()
  "Send the buffer to the inferior Typescript process."
  (interactive)
  (ts-send-region (point-min) (point-max)))


;;;###autoload
(defun ts-send-buffer-and-go ()
  "Send the buffer to the inferior Typescript process."
  (interactive)
  (ts-send-region-and-go (point-min) (point-max)))

;;;###autoload
(defun ts-load-file (filename)
  "Load file `FILENAME' in the Typescript interpreter."
  (interactive "f")
  (let ((filename (expand-file-name filename)))
     (ts-send-string (ts-comint--get-load-file-cmd filename))))

;;;###autoload
(defun ts-load-file-and-go (filename)
  "Load file `FILENAME' in the Typescript interpreter."
  (interactive "f")
  (ts-load-file filename)
  (switch-to-ts ts-comint-buffer))

;;;###autoload
(defun switch-to-ts (eob-p)
  "Switch to the Typescript process buffer.
With argument `EOB-P', position cursor at end of buffer."
  (interactive "P")
  (if (and ts-comint-buffer (get-buffer ts-comint-buffer))
      (pop-to-buffer ts-comint-buffer)
    (error "No current process buffer.  See variable `ts-comint-buffer'"))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

;;;###autoload
(define-derived-mode ts-comint-mode comint-mode "Inferior Typescript"
  "Major mode for interacting with an inferior Typescript process.

The following commands are available:
\\{ts-comint-mode-map}

A typescript process can be fired up with M-x run-ts.

Customization: Entry to this mode runs the hooks on comint-mode-hook and
ts-comint-mode-hook (in that order).

You can send text to the inferior Typescript process from other buffers containing
Typescript source.
    switch-to-ts switches the current buffer to the Typescript process buffer.
    ts-send-region sends the current region to the Typescript process.
"
  :group 'ts-comint
  ;; no specific initialization needed.
  )

(define-key ts-comint-mode-map "\C-x\C-e" 'ts-send-last-sexp)
(define-key ts-comint-mode-map "\C-xl" 'ts-load-file)


(provide 'ts-comint)
;;; ts-comint.el ends here
