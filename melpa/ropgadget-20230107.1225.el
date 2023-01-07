;;; ropgadget.el --- Display and filter ROP gadgets of a binary -*- lexical-binding: t -*-

;; Homepage: https://github.com/Dragoncraft89/ropgadget-el
;; Keywords: tools ctf pwn rop
;; Package-Version: 20230107.1225
;; Package-Commit: 10e9d6f66de1ee805d871c59f4acc078b66747a3
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.4") (transient "0.3.6"))
;; Copyright (C) 2021  Florian Kothmeier

;; This program is free software: you can redistribute it and/or modify
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

;; ROPgadget is a well-known python utility for solving "pwn" challenges in
;; IT-Security competitions (CTFs).  The tool searches for so-called gadgets,
;; which are short function fragments that end with a return/syscall/jump
;; instruction.  They are generally used to obtain arbitrary code execution by
;; overwriting return addresses on the stack with suitable gadgets.  This Elisp
;; package uses the ROPgadget utility to find these gadgets and merely displays
;; these in a Emacs friendly way.  You need to have the ROPgadget tool installed
;; and in your PATH If you do not have the utility in your PATH, you can set the
;; location via the variable `ropgadget-executable'.

;; To find gadgets in a binary, run M-x ropgadget.

;; Inside a ROPgadget buffer, you can filter the displayed gadgets by pressing
;; ``f'' or M-x ropgadget-filter

(eval-when-compile (require 'cl-lib))
(require 'transient)

;;; Code:
(defvar ropgadget-mode-map
  (let ((mode-map (make-sparse-keymap)))
    (define-key mode-map (kbd "f") #'ropgadget-filter)
    (define-key mode-map (kbd "n") #'next-line)
    (define-key mode-map (kbd "p") #'previous-line)
    mode-map))

(define-derived-mode ropgadget-mode special-mode "ROPgadget")

(defface ropgadget-address '((t :foreground "blue")) "Face for display of addresses in ropgadget buffers." :group 'ropgadget)
(defface ropgadget-address-separator '((t :foreground "white")) "Face for display of the separating ``:'' between addresses and the first instruction in ropgadget buffers." :group 'ropgadget)
(defface ropgadget-mnemonic '((t :foreground "red")) "Face for display of instruction mnemonics in ropgadget buffers." :group 'ropgadget)
(defface ropgadget-argument '((t :foreground "green")) "Face for display of instruction arguments in ropgadget buffers." :group 'ropgadget)
(defface ropgadget-argument-separator '((t :foreground "white")) "Face for display of the separating ``,'' between instruction arguments in ropgadget buffers." :group 'ropgadget)
(defface ropgadget-instruction-separator '((t :foreground "white")) "Face for display of the separating ``;'' between instructions in ropgadget buffers." :group 'ropgadget)

(defcustom ropgadget-executable "ROPgadget"
  "Path to ROPgadget."
  :type 'string
  :group 'ropgadget)

(cl-defstruct ropgadget-gadget
  address
  instructions)

(cl-defstruct ropgadget-instruction
  mnemonic
  arguments)

(defvar-local ropgadget-gadgets nil "The parsed gadgets for the binary.")


(defun ropgadget--buffer-p ()
  "Predicate to check whether the current buffer is a ROPgadget buffer."
  (local-variable-p 'ropgadget-gadgets))

(defun ropgadget--parse-instruction (instruction)
  "Parse INSTRUCTION from the ROPgadget output."
  (let* ((elements (split-string (substring instruction 1) " "))
         (mnemonic (car elements))
         (args (mapconcat #'identity (cdr elements) " "))
         (arglist (split-string args ",")))
    (make-ropgadget-instruction :mnemonic mnemonic :arguments (mapcar #'string-trim arglist))))

(defun ropgadget--parse-gadget (line)
  "Parse ROPgadget's gadget format from LINE."
  (let* ((sides (split-string line ":"))
         (address (string-to-number (string-trim (substring (car sides) 2)) 16))
         (instructions (split-string (car (cdr sides)) ";")))
    (make-ropgadget-gadget :address address :instructions (mapcar #'ropgadget--parse-instruction instructions))))

(defun ropgadget--format-instruction (instruction)
  "Format INSTRUCTION for display in the buffer."
  (concat (propertize (ropgadget-instruction-mnemonic instruction) 'face 'ropgadget-mnemonic) " "
          (mapconcat (lambda (arg) (propertize arg 'face 'ropgadget-argument))
                     (ropgadget-instruction-arguments instruction)
                     (propertize ", " 'face 'ropgadget-argument-separator))))

(defun ropgadget--format-gadget (gadget)
  "Format GADGET for display in the buffer."
  (concat
   (propertize (format "0x%016x" (ropgadget-gadget-address gadget)) 'face 'ropgadget-address) (propertize ": " 'face 'ropgadget-address-separator)
   (mapconcat #'ropgadget--format-instruction (ropgadget-gadget-instructions gadget) (propertize " ; " 'face 'ropgadget-instruction-separator))))

(defun ropgadget--filter-p (gadget &optional args)
  "Predicate to check whether GADGET should be filtered according to ARGS.
Returns t if the gadget should be in the list of gadgets according to ARGS.

The ARGS are the same arguments that get passed to ``ropgadget--filter''"
  (let ((type-match (not (or (member "--ret" args) (member "--syscall" args) (member "--jmp" args))))
        (instruction-match t)
        (arg-match t))
    (dolist (arg args)
      (cond
       ((string-equal arg "--ret")
        (setq type-match (or type-match
                             (string-match-p "retf?"
                                             (ropgadget-instruction-mnemonic (car (last (ropgadget-gadget-instructions gadget))))))))
       ((string-equal arg "--syscall")
        (setq type-match (or type-match
                             (string-match-p "(syscall|int)"
                                             (ropgadget-instruction-mnemonic (car (last (ropgadget-gadget-instructions gadget))))))))
       ((string-equal arg "--jmp")
        (setq type-match (or type-match
                             (string-equal "jmp"
                                           (ropgadget-instruction-mnemonic (car (last (ropgadget-gadget-instructions gadget))))))))
       ((string-prefix-p "--instruction=" arg)
        (setq instruction-match nil)
        (let ((regex (substring arg 14)))
          (dolist (instruction (ropgadget-gadget-instructions gadget))
            (setq instruction-match
                  (or instruction-match
                      (string-match-p regex (ropgadget-instruction-mnemonic instruction)))))))
       ((string-prefix-p "--arg=" arg)
        (setq arg-match nil)
        (let ((regex (substring arg 6)))
          (dolist (instruction (ropgadget-gadget-instructions gadget))
            (dolist (instruction-arg (ropgadget-instruction-arguments instruction))
              (setq arg-match
                    (or arg-match
                        (string-match-p regex instruction-arg)))))))))
    (and type-match instruction-match arg-match)))

(defun ropgadget--filter (&optional args)
  "Filters the gadgets according to the ARGS.
Use ``ropgadget-filter''"
  (interactive (list (transient-args 'ropgadget-filter)))
  (when (ropgadget--buffer-p)
    (let ((inhibit-read-only t))
      (delete-region (point-min) (point-max))
      (dolist (gadget ropgadget-gadgets)
        (when (ropgadget--filter-p gadget args)
          (insert (ropgadget--format-gadget gadget) "\n"))))
    (goto-char (point-min))))

(transient-define-prefix ropgadget-filter ()
  "Filter the gadgets in the current buffer.  Interactive use only.
If you need to filter the gadgets from Elisp, consider passing a list of options in long format to ``ropgadget--filter''"
  ["Instructions"
   ("-i" "Mnemonic regex" "--instruction=")
   ("-a" "Argument regex" "--arg=")]
  ["Gadget Types"
   ("-r" "Include return gadgets" "--ret")
   ("-s" "Include syscall gadgets" "--syscall")
   ("-j" "Include jump gadgets" "--jmp")]
  ["Filter"
   ("RET" "Filter" ropgadget--filter)])

(defun ropgadget (file)
  "Run ROPgadget on FILE and display the results."
  (interactive "fBinary: ")
  (switch-to-buffer (format "ROPgadget<%s>" file))
  (let ((gadgets))
    (with-temp-buffer
      (call-process ropgadget-executable nil (current-buffer) nil "--binary" file)
      (goto-char (point-min))
      (forward-line 2)
      (delete-region (point-min) (point))
      (goto-char (point-max))
      (forward-line -2)
      (delete-region (point) (point-max))
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (thing-at-point 'line)))
          (push (ropgadget--parse-gadget (string-trim line)) gadgets))
        (forward-line)))
    (ropgadget-mode)
    (setq-local ropgadget-gadgets gadgets))
  (ropgadget--filter '("--ret" "--syscall" "-jmp")))

(provide 'ropgadget)
;;; ropgadget.el ends here
