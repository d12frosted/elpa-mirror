;;; eno.el --- Goto/copy/cut any word/symbol/line in view, similar to ace-jump/easymotion

;; Author: <e.enoson@gmail.com>
;; License: MIT
;; URL: http://github.com/enoson/eno.el
;; Package-Version: 20191013.1239
;; Package-Commit: c5c6193687c0bede1ddf507c430cf8b0a6d272d9
;; Version: 1.1
;; Package-requires: ((dash "2.12.1") (edit-at-point "1.0"))

;;; Commentary:

;; goto/copy/cut/paste : word,symbol,string,line,parenthesis((),[], {})
;; copy/cut/paste to/from-to : line,symbol
;; comment-to, comment-from-to : line

;; sample keybinding config:
;; (require 'bind-key)
;; (bind-keys
;;   ("M-S-a". eno-word-goto)
;;   ("M-S-b". eno-word-copy)
;;   ("M-S-c". eno-word-cut)
;;   ("M-S-d". eno-word-paste)
;;   ("M-S-e". eno-symbol-goto)
;;   ("M-S-f". eno-symbol-copy)
;;   ("M-S-g". eno-symbol-cut)
;;   ("M-S-h". eno-symbol-paste)
;;   ("M-S-i". eno-str-goto)
;;   ("M-S-j". eno-str-copy)
;;   ("M-S-k". eno-str-cut)
;;   ("M-S-i". eno-str-paste)
;;   ("M-S-m". eno-line-goto)
;;   ("M-S-n". eno-line-copy)
;;   ("M-S-o". eno-line-cut)
;;   ("M-S-p". eno-line-paste)
;;   ("M-S-q". eno-paren-goto)
;;   ("M-S-r". eno-paren-copy)
;;   ("M-S-s". eno-paren-cut)
;;   ("M-S-t". eno-paren-paste)
;;   ("H-S-a". eno-symbol-copy-to)
;;   ("H-S-b". eno-symbol-cut-to)
;;   ("H-S-c". eno-symbol-paste-to)
;;   ("H-S-d". eno-line-copy-to)
;;   ("H-S-e". eno-line-cut-to)
;;   ("H-S-f". eno-line-paste-to)
;;   ("H-S-g". eno-line-comment-to)
;;   ("H-S-h". eno-symbol-copy-from-to)
;;   ("H-S-i". eno-symbol-cut-from-to)
;;   ("H-S-j". eno-symbol-paste-from-to)
;;   ("H-S-k". eno-line-copy-from-to)
;;   ("H-S-l". eno-line-cut-from-to)
;;   ("H-S-m". eno-line-paste-from-to)
;;   ("H-S-n". eno-line-comment-from-to)
;;   ("H-S-o". eno-word-goto-inline)
;;   ("H-S-p". eno-word-copy-to-inline)
;;   ("H-S-q". eno-word-cut-to-inline)
;;   ("H-S-r". eno-word-paste-to-inline)
;;   ("H-S-s". eno-url-open)
;;   ("H-S-t". eno-clear-overlay))

;;; Code:
(require 'dash)
(require 'edit-at-point)

;; init
(defun eno-set-all-letter-str (str)
  (setq eno--all-letter-str str
        eno--all-letter-n (length str)
        eno--all-letter-list (delete "" (split-string str "")))
  (eno--gen-hints-pre-calculate))

(defun eno-set-same-finger-list (list)
  (setq eno--same-finger-list list)
  (eno--gen-hints-pre-calculate))

(defun eno--gen-hints-pre-calculate ()
  (setq eno--all-two-letter-hints nil
        eno--all-max-hints-n (list eno--all-letter-n))
  (--each eno--all-letter-list
    (eno--add-all-two-letter-hints it)
    (eno--add-all-hints-max-n it)))

(defun eno--add-all-two-letter-hints (letter)
  (let* ((same-finger (if eno--same-finger-list
                          (--first (string-match-p (regexp-quote letter) it) eno--same-finger-list)))
         (same-finger-no-letter (eno--remove-chars-from-str letter same-finger))
         (eno--all-letter-str-no-same (eno--remove-chars-from-str same-finger-no-letter eno--all-letter-str)))
    (--each (string-to-list eno--all-letter-str-no-same)
      (add-to-list 'eno--all-two-letter-hints (concat letter (char-to-string it))))))

(defun eno--add-all-hints-max-n (letter)
  (let ((two-letter-hints-n-now (length eno--all-two-letter-hints))
        (one-letter-hints-n-now (- eno--all-letter-n (length eno--all-max-hints-n))))
    (eno--append-list 'eno--all-max-hints-n (+ two-letter-hints-n-now one-letter-hints-n-now))))

(defun eno--remove-chars-from-str (chars str)
  (if (and chars str)
      (--each (delete "" (split-string chars ""))
        (setq str (replace-regexp-in-string (regexp-quote it) "" str))))
  str)

(defun eno--append-list (list el)
  (add-to-list list el t))

;; generate
(defun eno--gen-hints (ovs-n)
  (let* ((two-letter-index (--find-index (<= ovs-n it) eno--all-max-hints-n))
         (one-letter-n (- eno--all-letter-n two-letter-index))
         (one-letter-hints (-slice eno--all-letter-list two-letter-index))
         (two-letter-hints-n-neg (- one-letter-n ovs-n))
         (two-letter-hints (if (>= 0 two-letter-hints-n-neg)
                               (-slice eno--all-two-letter-hints two-letter-hints-n-neg))))
    (list (append two-letter-hints one-letter-hints) one-letter-n)))

;; set
(defun eno--show-hints (ovs hints at-head aside)
  (--zip-with
   (let* ((beg (overlay-start it))
          (end (overlay-end it))
          (ov-len (- end beg))
          (hint-len (length other))
          (is-one-letter (= 1 ov-len))
          (is-empty (= 0 ov-len))
          (chop-len (if (or aside is-empty) 0 (if is-one-letter 1 hint-len))))
     (if (and at-head (not is-empty))
         (eno--set-ov-hint it other (buffer-substring (+ beg chop-len) end) 'eno-hint-face)
       (eno--set-ov-hint it (buffer-substring beg (- end chop-len)) (propertize other 'face 'eno-hint-face))))
   ovs hints))

(defun eno--set-ov-hint (ov head-str after-str &optional face)
  (overlay-put ov 'display head-str)
  (overlay-put ov 'after-string after-str)
  (overlay-put ov 'face face))

;; select
(defun eno--select-hints (ovs hints one-letter-n at-head aside)
  (unwind-protect
      (let* ((letter-char-list (string-to-list eno--all-letter-str))
             (key-seq (read-key-sequence-vector "eno:"))
             (key-char (aref key-seq 0))
             (key-idx (-elem-index key-char letter-char-list)))
        (princ (key-description key-seq))
        (cond
         ((equal (kbd "<escape>") key-seq) (keyboard-quit))
         (key-idx (eno--return-select-ov-beg-end))
         (t (call-interactively (key-binding key-seq))
            (when (-contains? eno-stay-key-list (key-description key-seq))
              (eno--clear-ovs ovs)
              (if (boundp 're)
                  (eno re at-head aside)
                (eno-line-select))
              ))))
    (eno--clear-ovs ovs)))

(defun eno--clear-ovs (ovs)
  (--each ovs (delete-overlay it)))

(defun eno--return-select-ov-beg-end ()
  (setq key-str (char-to-string key-char))
  (if (>= key-idx (- eno--all-letter-n one-letter-n))
      (setq ov (elt ovs (-elem-index key-str hints)))
    (let* ((key-char2 (read-char))
           (key-str2 (char-to-string key-char2)))
      (if (-elem-index key-char2 letter-char-list)
          (setq ov (elt ovs (-elem-index (concat key-str key-str2) hints)))
        (princ "not in eno--all-letter-str."))))
  (if ov (cons (overlay-start ov) (overlay-end ov))))

;; main
;;;###autoload
(defun eno (re &optional at-head aside)
  "show matching regexp with hints then return the beginning and end of the selected hint(overlay)."
  (let* ((v (eno-view-bounds))
         (beg (car v))
         (end (cdr v))
         (ovs (if (stringp re)
                  (eno-make-overlay-regexp re beg end)
                (--mapcat (eno-make-overlay-regexp it beg end) re))))
    (eno-ov-select ovs at-head aside)))

(defun eno-view-bounds ()
  (save-excursion
    (cons (progn (move-to-window-line 0) (point))
          (progn (move-to-window-line -1) (point-at-eol)))))

(defun eno-make-overlay-regexp (re beg end)
  (save-excursion
    (goto-char beg)
    (setq ovs nil)
    (while (re-search-forward re end t)
      (unless (get-char-property (point) 'invisible)
        (push (make-overlay (match-beginning 0)
                            (match-end 0))
              ovs))))
  ovs)

(defun eno-ov-select (ovs at-head aside)
  (let* ((l (eno--gen-hints (length ovs)))
         (hints (car l))
         (one-letter-n (cadr l)))
    (eno--show-hints ovs hints at-head aside)
    (eno--select-hints ovs hints one-letter-n at-head aside)))

(defun eno--edit-regexp (regexp)
  (-when-let* ((l (eno regexp at-head aside))
               (beg (car l))
               (end (cdr l)))
    (if goto? (goto-char end))
    (if action (funcall action beg end))
    l))

;; word
(defun eno-word-edit (action &optional goto? at-head aside)
  (eno--edit-regexp "\\w\\{2,\\}"))

;;;###autoload
(defun eno-word-goto ()
  (interactive)
  (eno-word-edit nil t))

;;;###autoload
(defun eno-word-cut ()
  (interactive)
  (eno-word-edit 'kill-region t))

;;;###autoload
(defun eno-word-copy ()
  (interactive)
  (eno-word-edit 'kill-ring-save))

;;;###autoload
(defun eno-word-paste ()
  (interactive)
  (if (eno-word-edit 'delete-region t)
      (yank)))

;; word
(defun eno-symbol-edit (action &optional goto? at-head aside)
  (eno--edit-regexp "[^\s-(),;\n]\\{2,\\}"))

;;;###autoload
(defun eno-symbol-goto ()
  (interactive)
  (eno-symbol-edit nil t))

;;;###autoload
(defun eno-symbol-cut ()
  (interactive)
  (eno-symbol-edit 'kill-region t))

;;;###autoload
(defun eno-symbol-copy ()
  (interactive)
  (eno-symbol-edit 'kill-ring-save))

;;;###autoload
(defun eno-symbol-paste ()
  (interactive)
  (if (eno-symbol-edit 'delete-region t)
      (yank)))

;; string
(defun eno-str-edit (action &optional goto? at-head aside)
  (eno--edit-regexp '("\'\\([^\\\'\n]\\|\\\\.\\)*\'"
                      "\"\\([^\\\"\n]\\|\\\\.\\)*\"")))

;;;###autoload
(defun eno-str-goto ()
  (interactive)
  (eno-str-edit nil t))

;;;###autoload
(defun eno-str-cut ()
  (interactive)
  (eno-str-edit 'kill-region t))

;;;###autoload
(defun eno-str-copy ()
  (interactive)
  (eno-str-edit 'kill-ring-save))

;;;###autoload
(defun eno-str-paste ()
  (interactive)
  (if (eno-str-edit 'delete-region t)
      (yank)))

;; line
(defun eno-line-select ()
  (interactive)
  (save-excursion
    (setq exclude (point-at-bol))
    (move-to-window-line -1)
    (setq we (point)
          ovs)
    (move-to-window-line 0)
    (while (> we (setq p (point)))
      (if (= exclude p) nil
        (push (make-overlay p (point-at-eol)) ovs))
      (forward-line))
    (push (make-overlay we (point-at-eol)) ovs))
  (eno-ov-select ovs t nil))

(defun eno-line-edit (action goto?)
  (-when-let* ((l (eno-line-select))
               (beg (car l))
               (end (cdr l)))
    (if goto? (goto-char beg))
    (if action (funcall action beg end))
    t))

;;;###autoload
(defun eno-line-goto ()
  (interactive)
  (eno-line-edit nil t))

;;;###autoload
(defun eno-line-cut ()
  (interactive)
  (eno-line-edit 'kill-region t))

;;;###autoload
(defun eno-line-copy ()
  (interactive)
  (eno-line-edit 'kill-ring-save nil))

;;;###autoload
(defun eno-line-paste ()
  (interactive)
  (eno-line-edit 'delete-region t)
  (yank))

;;;###autoload
(defun eno-line-comment ()
  (interactive)
  (eno-line-edit 'comment-or-uncomment-region nil))

;;;###autoload
(defun eno-line-return ()
  "simulate return at line end"
  (interactive)
  (when (eno-line-edit nil t)
    (end-of-line)
    (setq unread-command-events (listify-key-sequence [return]))))

;;;###autoload
(defun eno-paren-goto ()
  (interactive)
  (-if-let* ((beg (car (eno '("(" "\\[" "{") t))))
      (goto-char beg)))

;;;###autoload
(defun eno-paren-copy ()
  (interactive)
  (save-excursion
    (eno-paren-goto)
    (edit-at-point-paren-copy)))

;;;###autoload
(defun eno-paren-cut ()
  (interactive)
  (eno-paren-goto)
  (edit-at-point-paren-cut))

;;;###autoload
(defun eno-paren-delete ()
  (interactive)
  (eno-paren-goto)
  (edit-at-point-paren-delete))

;;;###autoload
(defun eno-paren-paste ()
  (interactive)
  (eno-paren-goto)
  (edit-at-point-paren-paste))

;; to
(defun eno-edit-to (thing to edit)
  (-when-let* ((b (or (bounds-of-thing-at-point thing) (cons (point) (point))))
               (beg (car b))
               (end (cdr b))
               (to-beg (car to))
               (to-end (cdr to)))
    (if (> beg to-beg)
        (funcall edit to-beg end)
      (funcall edit beg to-end))))

(defun eno-line-edit-to (edit)
  (eno-edit-to 'line (eno-line-select) edit))

;;;###autoload
(defun eno-line-comment-to ()
  (interactive)
  (eno-line-edit-to 'comment-or-uncomment-region))

;;;###autoload
(defun eno-line-copy-to ()
  (interactive)
  (eno-line-edit-to 'kill-ring-save))

;;;###autoload
(defun eno-line-cut-to ()
  (interactive)
  (eno-line-edit-to 'kill-region))

;;;###autoload
(defun eno-line-delete-to ()
  (interactive)
  (eno-line-edit-to 'delete-region))

;;;###autoload
(defun eno-line-paste-to ()
  (interactive)
  (eno-line-delete-to)
  (yank))

(defun eno-symbol-edit-to (edit)
  (eno-edit-to 'symbol (eno "[^\s-(),;\n]\\{2,\\}" t) edit))

;;;###autoload
(defun eno-symbol-copy-to ()
  (interactive)
  (eno-symbol-edit-to 'kill-ring-save))

;;;###autoload
(defun eno-symbol-cut-to ()
  (interactive)
  (eno-symbol-edit-to 'kill-region))

;;;###autoload
(defun eno-symbol-delete-to ()
  (interactive)
  (eno-symbol-edit-to 'delete-region))

;;;###autoload
(defun eno-symbol-paste-to ()
  (interactive)
  (eno-symbol-delete-to)
  (yank))

;; to (inline)
(defun eno-word-to-inline (action)
  (setq b (eno-ov-select (eno-make-overlay-regexp "\\w+" (point-at-bol) (point-at-eol)) nil nil)
        beg (car b)
        end (cdr b)
        p (point))
  (if action
      (if (> p beg)
          (funcall action beg p)
        (funcall action p end))
    (goto-char end)))

;;;###autoload
(defun eno-word-goto-inline ()
  (interactive)
  (eno-word-to-inline nil))

;;;###autoload
(defun eno-word-copy-to-inline ()
  (interactive)
  (eno-word-to-inline 'kill-ring-save))

;;;###autoload
(defun eno-word-cut-to-inline ()
  (interactive)
  (eno-word-to-inline 'kill-region))

;;;###autoload
(defun eno-word-paste-to-inline ()
  (interactive)
  (eno-word-to-inline 'delete-region)
  (yank))

;; from to
(defun eno-edit-from-to (fst snd edit)
  (-when-let* ((beg (car fst))
               (end (cdr fst))
               (to-beg (car snd))
               (to-end (cdr snd)))
    (if (> beg to-beg)
        (funcall edit to-beg end)
      (funcall edit beg to-end))))

(defun eno-line-edit-from-to (edit)
  (eno-edit-from-to (eno-line-select) (eno-line-select) edit))

;;;###autoload
(defun eno-line-comment-from-to ()
  (interactive)
  (eno-line-edit-from-to 'comment-or-uncomment-region))

;;;###autoload
(defun eno-line-copy-from-to ()
  (interactive)
  (eno-line-edit-from-to 'kill-ring-save))

;;;###autoload
(defun eno-line-cut-from-to ()
  (interactive)
  (eno-line-edit-from-to 'kill-region))

;;;###autoload
(defun eno-line-delete-from-to ()
  (interactive)
  (eno-line-edit-from-to 'delete-region))

;;;###autoload
(defun eno-line-paste-from-to ()
  (interactive)
  (eno-line-delete-from-to)
  (yank))

(defun eno-symbol-edit-from-to (edit)
  (setq regexp "[^\s-(),;\n]\\{2,\\}")
  (eno-edit-from-to (eno regexp t) (eno regexp t) edit))

;;;###autoload
(defun eno-symbol-copy-from-to ()
  (interactive)
  (eno-symbol-edit-from-to 'kill-ring-save))

;;;###autoload
(defun eno-symbol-cut-from-to ()
  (interactive)
  (eno-symbol-edit-from-to 'kill-region))

;;;###autoload
(defun eno-symbol-delete-from-to ()
  (interactive)
  (eno-symbol-edit-from-to 'delete-region))

;;;###autoload
(defun eno-symbol-paste-from-to ()
  (interactive)
  (eno-symbol-delete-from-to)
  (yank))

(defun eno-swap (regexp &optional at-head aside)
  (-when-let* ((l1 (eno regexp at-head aside))
               (beg1 (car l1))
               (end1 (cdr l1))
               (str1 (buffer-substring beg1 end1))
               (l2 (eno regexp at-head aside))
               (beg2 (car l2))
               (end2 (cdr l2))
               (str2 (buffer-substring beg2 end2)))
    (if (< beg1 beg2)
        (setq beg3 beg1
              end3 end1
              str3 str1
              beg1 beg2
              end1 end2
              str1 str2
              beg2 str3
              end2 end3
              str2 beg3))
    (goto-char beg1)
    (delete-region beg1 end1)
    (insert str2)
    (goto-char beg2)
    (delete-region beg2 end2)
    (insert str1)))

;;;###autoload
(defun eno-word-swap ()
  (interactive)
  (eno-swap "\\w\\{2,\\}"))

;;;###autoload
(defun eno-symbol-swap ()
  (interactive)
  (eno-swap "[^\s-(),;\n]\\{2,\\}"))

;; spcial
;;;###autoload
(defun eno-url-open ()
  (interactive)
  (-when-let* ((beg (car (eno "([a-z]+://" t))))
    (save-excursion
      (goto-char beg)
      (browse-url-at-point))))

;;;###autoload
(defun eno-clear-overlay ()
  (interactive)
  (--each (overlays-in (point-min) (point-max))
    (delete-overlay it)))

;; default config
(defface eno-hint-face
  '((((class color)) (:foreground "red" :background "black"))
    (((background dark)) (:foreground "gray100"))
    (((background light)) (:foreground "gray0"))
    (t (:foreground "red")))
  "Face used for hints during selecting.")

(setq eno--same-finger-list '("(aq" "dtb" "sr," "lmjv" "gwpc" "uiy" "hnf" "koz["))
(eno-set-all-letter-str "e trinaodsuh(k[lgm,bpcyfvwjqz")
(setq eno-stay-key-list '("<prior>" "<next>" "<wheel-up>" "<wheel-down>"))

(provide 'eno)

;;; eno.el ends here
