;;; pollen-mode.el --- major mode for editing pollen files

;; Copyright (C) 2016 Junsong Li
;; Author: Junsong Li <ljs.darkfish AT GMAIL>
;; Maintainer: Junsong Li
;; Created: 11 June 2016
;; Keywords: languages, pollen, pollenpub
;; Package-Version: 20210120.422
;; Package-Commit: 09a9dc48c468dcd385982b9629f325e70d569faf
;; License: LGPL
;; Version: 1.0
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5"))
;; Distribution: This file is not part of Emacs
;; URL: https://github.com/lijunsong/pollen-mode

;;; Commentary:
;; Pollen mode provides editing assistant for pollen, the
;; digital-publishing tool.
;;
;; See README for usage in detail.

;;; Code:

(require 'cl-lib)

;; Glossary:
;; - Command Char: also referred to as the lozenge
;; - Top Level: A position NOT inside braces
;; - Pollen Tag: command char followed by racket id or char `;'

;; TODO:
;; - provide a parenthesis matcher
;; - support comment-dwim

(defvar pollen-command-char-code ?\u25CA)
(defvar pollen-command-char (char-to-string pollen-command-char-code))
(defvar pollen-command-char-target "@")

;; Racket identifier. See racket document syntax-overview 2.2.3.
(defvar pollen-racket-id-reg "[^][:space:]\n()[{}\",'`;#|\\]+")

(defvar pollen-header-reg "^#lang .*$")

(defun pollen-gen-highlights (command-char)
  "Generate highlight given the pollen COMMAND-CHAR."
  (let ((id (concat command-char pollen-racket-id-reg))
        (malform1 (concat command-char "[ \\n]+"))
        (malform2 (concat command-char "{")))
    `((,id . font-lock-variable-name-face)
      (,pollen-header-reg . font-lock-comment-face)
      (,malform1 . font-lock-warning-face)
      (,malform2 . font-lock-warning-face))))

(defvar pollen-highlights
  (pollen-gen-highlights pollen-command-char)
  "Font lock in pollen.")

(defun pollen-tag (name)
  "Concat commond char to the given NAME."
  (concat pollen-command-char name))

;;; Pollen tag struct.
(defun pollen--make-tag (name lb rb)
  "Create tag object.

A tag object has NAME (command char excluded), left brace LB and
right brace RB pos.

Note: for |{, LB points to |."
  (list name lb rb))

(defun pollen--tag-name (tag)
  "Get the name of a TAG."
  (car tag))

(defun pollen--tag-lbraces (tag)
  "Get left brace pos of a TAG."
  (cadr tag))

(defun pollen--tag-rbraces (tag)
  "Get right brace pos of a TAG."
  (cadr (cdr tag)))

(defun pollen--matched-right-brace-pos (pos)
  "Get to the right brace matched with a left brace at position POS.

Return the position of the right brace,  nil if the given pos is
not a left brace or there is no matched one.

Note: this function jumps over the \"|\" of \"|{\"."
  (let (p
        ;; since we're sometimes treating left braces as comment
        ;; delimiters, it is important froward-sexp not obey syntax
        ;; table
        (parse-sexp-lookup-properties nil))
    (save-excursion
      (goto-char pos)
      (if (looking-at "|")
          (forward-char))
      (when (char-equal (char-after) ?\{)
        (ignore-errors
          (forward-sexp 1)
          (backward-char 1)
          (setq p (point)))))
    p))

;; Special case for things at point.
(put 'pollen--tag 'bounds-of-thing-at-point 'pollen--bounds-of-tag-at-point)
(defun pollen--bounds-of-tag-at-point ()
  "Move point to the beginning of the current tag.

Note: This function returns nil if the point is not on a tag name
starting with command char."
  ;; Specify \n explicitly because \n is not in [:space:] syntax class anymore.
  (let* ((skip-allowed "^[:space:]()[]{}\",'`;#|\\\n")
         (beg  (save-excursion
                 (skip-chars-backward skip-allowed)
                 (if (looking-at pollen-command-char)
                     (point)
                   nil)))
         (end (save-excursion
                (skip-chars-forward skip-allowed)
                (if (and beg (eq (- (point) beg) 1) (looking-at ";"))
                    (1+ (point))
                  (point)))))
    (if (and beg end (not (= beg end)))
        (cons beg end)
      nil)))

(defun pollen-tag-at-point (&optional no-properties)
  "Return the tag at point, or nil if none is found.
NO-PROPERTIES will be passed to `thing-at-point'."
  (thing-at-point 'pollen--tag no-properties))

(defun pollen--get-current-tagobj ()
  "Get a tag object under the cursor.

It returns nil when the cursor is on the toplevel.  It returns
the tag object of the enclosing tag otherwise.

Implementation Caveat: This function jumps to comment start using
parsing state from `syntax-ppss'.  Use it with causion in
`syntax-propertize-function', because when the position is right
after a comment start character, the parsing state may not mark
it a comment start yet, in this case the tagobj found is a tag
prior to current tag."
  (let* ((parse-sexp-lookup-properties nil)
         (make-tag
          #'(lambda ()
              (let ((tag (pollen-tag-at-point t)))
                (when tag
                  ;; make sure bounds is not nil
                  (let ((bounds (bounds-of-thing-at-point 'pollen--tag))
                        (name (substring tag 1)))
                    (unless (string= name "")
                      (let ((lb-pos (if (char-equal (char-after (cdr bounds)) ?\|)
                                        (1+ (cdr bounds))
                                      (cdr bounds))))
                        (pollen--make-tag
                         name lb-pos
                         (pollen--matched-right-brace-pos lb-pos))))))))))
    (cond ((pollen-tag-at-point t)
           ;; in the front or the middle of a tag name
           (funcall make-tag))
          (t
           ;; search backward
           (save-excursion
             (let (result)
               (while (and (null result)
                           (progn
                             (skip-chars-backward  "^{}")
                             (not (= (point) (point-min)))))
                 (cond ((char-equal ?\} (char-before))
                        (backward-sexp 1))
                       ((char-equal ?\{ (char-before))
                        (backward-char 2)
                        (setq result (funcall make-tag)))))
               result))))))

(defun pollen-insert-target (&optional arg)
  "Insert the command char or @ in the document.

If the command char is not the preceding char, insert it, otherwise
insert @."
  (interactive)
  (cond ((use-region-p)
         (let* ((region (cons (region-beginning) (region-end)))
                (text (buffer-substring-no-properties
                       (car region) (cdr region)))
                cursor-final-pos)
           (delete-region (car region) (cdr region))
           (insert pollen-command-char)
           (setq cursor-final-pos (point))
           (insert "{")
           (insert text)
           (insert "}")
           (goto-char cursor-final-pos)))
        ((string= (string (preceding-char))
                  pollen-command-char)
         (delete-char -1)
         (insert pollen-command-char-target))
        (t (insert pollen-command-char))))

(defun pollen--goto-enclosing-left-brace ()
  "Go to the left brace enclosing current point."
  (interactive)
  (let ((tag (pollen--get-current-tagobj)))
    (let ((lb-pos (pollen--tag-lbraces tag)))
      (if lb-pos
          (goto-char lb-pos)
        (message "unbalanced braces."))))  )

(defun pollen--goto-enclosing-right-brace ()
  "Go to the right brace enclosing current point.

Return t if succeed, nil otherwise."
  (interactive)
  (let ((tag (pollen--get-current-tagobj)))
    (let ((rb-pos (pollen--tag-rbraces tag)))
      (if rb-pos
          (goto-char rb-pos)
        (message "unbalanced braces.")))))

(defun pollen-edit-block-other-window ()
  "This command does similar thing as org-edit-special in \"org-mode\".

When the cursor inside any block enclosed by braces, this
function will pop up another buffer containing only the content
of that block. Feel free to change the new buffer's mode."
  (interactive)
  (let ((tag (pollen--get-current-tagobj))
        (buff-name "*pollen-editing*"))
    (cond ((null tag)
           ;; Tag is null. Issue an warning.
           (message "Are you really inside a block?"))
          ((get-buffer buff-name)
           ;; User is editing another tag. Pop up the buffer.
           (message "You're still editing another block.")
           (switch-to-buffer-other-window buff-name))
          (t
           (let ((l (pollen--tag-lbraces tag))
                 (r (pollen--tag-rbraces tag))
                 (tag-name (pollen--tag-name tag)))
             (if (and l r)
                 (let* ((l (1+ l))
                        (text (buffer-substring-no-properties l r))
                        ;; for restore window
                        (win-config (current-window-configuration)))
                   (let* ((cur-buf (current-buffer))
                          (new-buf (make-indirect-buffer cur-buf buff-name)))
                     (switch-to-buffer-other-window new-buf)
                     ;; working on the new buffer from this point
                     (local-set-key (kbd "C-c C-c")
                                    `(lambda ()
                                       (interactive)
                                       (kill-buffer-and-window)
                                       (set-window-configuration ,win-config)))
                     (narrow-to-region l r)
                     (setq-local header-line-format
                                 (format "Editing %s%s. Close the window with <C-c C-c>"
                                         pollen-command-char tag-name))))
               (message "Tag %s%s has unbalanced braces." pollen-command-char tag-name)))))))

(defvar pollen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd pollen-command-char-target)
      'pollen-insert-target)
    (define-key map (kbd "C-c C-c") 'pollen-edit-block-other-window)
    map))

(defconst pollen-minor-mode-indicator
  (concat " " pollen-command-char-target "/" pollen-command-char))

;;;###autoload
(define-minor-mode pollen-minor-mode
  "pollen minor mode.

Keybindings for editing pollen file."
  nil
  pollen-minor-mode-indicator
  :keymap pollen-mode-map
  :group 'pollen)

(defun pollen-minor-mode-on ()
  "Turn on pollen minor mode."
  (pollen-minor-mode 1))

;; together with (add-hook * * * t) pollen will be always on.
(put 'pollen-minor-mode-on 'permanent-local-hook t)

(defun pollen--put-text-property-at (pos ty)
  "A warper for put at POS and (POS+1) text property of comment type TY."
  (if (null ty)
      (put-text-property pos (1+ pos) 'syntax-table nil)
    (put-text-property pos (1+ pos) 'syntax-table (string-to-syntax ty))))

(defun pollen--propertize-comment (semicolon-pos)
  "Fix pollen comments in syntax table at given SEMICOLON-POS."
  (goto-char semicolon-pos)
  ;; (assert (equal (char-after semicolon-pos) ?\;))
  (let* ((tag (pollen--get-current-tagobj))
         (beg (pollen--tag-lbraces tag))
         (end (pollen--tag-rbraces tag)))
    (when end
      (pollen--put-text-property-at semicolon-pos "."))
    (when (and tag (string-equal (pollen--tag-name tag) ";") beg end)
      (pollen--put-text-property-at beg "< bn")
      (pollen--put-text-property-at end "> bn"))))

;; Caveat: call (syntax-ppss (match-beginning 0)) will cause infinite loop.
;; Caveat: jump back without using save-excursion will cause infinite loop.
(defconst pollen--syntax-propertize-function
  (syntax-propertize-rules
   ("◊;{"
    (0
     (let ((beg-ppss (prog2
                         (backward-char 3)
                         (syntax-ppss)
                       (forward-char 3))))
       (unless (and (nth 4 beg-ppss)
                    (null (nth 7 beg-ppss)))
         ;; first unmark ; to normal punctuation
         (pollen--propertize-comment (1+ (match-beginning 0)))
         ))))
   ("}" (0
         (save-excursion
           (let ((parse-sexp-lookup-properties nil)
                 (ppss (syntax-ppss)))
             (ignore-errors
               (backward-sexp 1)
               (when (char-equal (char-before (point)) ?\;)
                 (cond ((equal 1 (nth 7 ppss))
                        ;; When } is in comment starting with ;{, mark
                        ;; it as endcomment.  When modifying text at
                        ;; the same line as the endcomment "}",
                        ;; its text property will be cleaned. Mark "}"
                        ;; as a comment delimiter again.
                        (pollen--put-text-property-at (match-beginning 0) "> bn"))
                       ((null (nth 4 ppss))
                        ;; Not in a comment, so add comment
                        (pollen--propertize-comment (1- (point)))))))))))))

(defvar pollen-syntax-table
  (let ((tb (make-syntax-table)))
    (modify-syntax-entry pollen-command-char-code ". 1" tb)
    (modify-syntax-entry ?\; ". 2" tb)
    (modify-syntax-entry ?\n ">" tb)
    tb))

;;;###autoload
(define-derived-mode pollen-mode fundamental-mode
  "pollen"
  "Major mode for pollen file"
  (set (make-local-variable 'parse-sexp-ignore-comments) nil)
  (set (make-local-variable 'parse-sexp-lookup-properties) nil)
  (set-syntax-table pollen-syntax-table)
  (set (make-local-variable 'font-lock-defaults)
       '((pollen-highlights) nil nil))
  (set (make-local-variable 'syntax-propertize-function)
       pollen--syntax-propertize-function)
  ;; make the minor mode available across all major modes (even if major
  ;; mode falls through)
  (add-hook 'after-change-major-mode-hook 'pollen-minor-mode-on t t))

;;;; Bind pollen mode with file suffix.
;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.pm$" . pollen-mode))
  (add-to-list 'auto-mode-alist '("\\.pmd$" . pollen-mode))
  (add-to-list 'auto-mode-alist '("\\.pp$" pollen-mode t))
  (add-to-list 'auto-mode-alist '("\\.p$"  pollen-mode t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pollen server interactions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Pollen server provides effective access to start/stop/restart
;; pollen server.
;;
;; A note to the "restart" function: restart looks for a buffer local
;; variable called pollen-server--previous-root-dir in buffer
;; *pollen-server*. That variable stores project root of previous
;; server. The variable is created the first the buffer is created
;; (i.e. pollen-server-start is called.)

(defconst pollen-server--buffer-name "*pollen-server*"
  "Buffer name for pollen server.")

(defvar-local pollen-server--previous-root-dir nil
  "This variable caches project root directory.  It is set when
  `pollen-server-start' is called.")

;;;###autoload
(defun pollen-server-start (root-dir)
  "Start pollen server at the given ROOT-DIR.

Server output is stored in buffer *pollen-server*."
  (interactive
   (list (let* ((file-name (buffer-file-name (current-buffer)))
                (default-dir (cond (file-name
                                    ;; case 1: run the command in pm buffer
                                    (file-name-directory file-name))
                                   (pollen-server--previous-root-dir
                                    ;; case 2: run it in server buffer
                                    pollen-server--previous-root-dir)
                                   (t
                                    ;; case 3: unknown position
                                    "~/"))))
           (read-directory-name "Server Root Directory: " default-dir))))
  (let ((default-directory root-dir))
    (unless (get-buffer-process pollen-server--buffer-name)
      (let ((pollen-server
             (start-process "pollen-server" pollen-server--buffer-name
                            "raco" "pollen" "start")))
        (set-process-sentinel
         pollen-server
         (lambda (proc event)
           (with-current-buffer pollen-server--buffer-name
             (unless (eq (process-status proc) 'exit)
               (quit-process proc))
             ;; provide new bindings for new actions.
             (local-set-key (kbd "q") 'kill-buffer-and-window)
             (local-set-key (kbd "r")
                            (lambda ()
                              (interactive)
                              (pollen-server-start pollen-server--previous-root-dir)))
             (setq-local header-line-format
                         (substitute-command-keys
                          "Exited. Kill the buffer with <\\[kill-buffer-and-window]>. Resume the server with <r>"))
             (let ((inhibit-read-only t)
                   (msg
                    (cond ((string-match-p "finished" event)
                           "* Pollen server exited cleanly.\n")
                          (t
                           (format  "* Pollen server exited unexpectedly. Received %s.\n"
                                    event)))))
               (goto-char (point-max))
               (insert msg)))))))
    (display-buffer
     pollen-server--buffer-name
     '((display-buffer-reuse-window
        display-buffer-at-bottom
        display-buffer-pop-up-window)
       (window-height . 10)))
    (let ((win (get-buffer-window pollen-server--buffer-name)))
      (when win
        (select-window win)))
    (with-current-buffer pollen-server--buffer-name
      ;; now operate on the server buffer.
      (read-only-mode 1)
      (local-set-key (kbd "C-c C-c") 'pollen-server-stop)
      (local-set-key (kbd "q") 'delete-window)
      ;; make the buffer auto scroll
      (set (make-local-variable 'window-point-insertion-type) t)
      ;; remember this directory for restarting the server.
      (setq pollen-server--previous-root-dir root-dir)
      (setq-local header-line-format
                  (substitute-command-keys
                   "Hide the buffer with <\\[delete-window]>. Stop the server with <\\[pollen-server-stop]>.")))))

(defun pollen-server-stop ()
  "Stop the running pollen server."
  (interactive)
  (let ((proc (get-buffer-process pollen-server--buffer-name)))
    (when proc
      (interrupt-process proc))))

(provide 'pollen-mode)

;;; pollen-mode.el ends here
