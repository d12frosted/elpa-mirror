;;; symbolword-mode.el --- modify word split -*- lexical-binding: t -*-

;; Author: ncaq <ncaq@ncaq.net>
;; Version: 0.0.0
;; Package-Version: 20180401.1427
;; Package-Commit: c254ec56e83a5d9de04df0856248723cf6d4be50
;; Package-Requires: ((emacs "24")(f "0.19.0"))
;; URL: https://github.com/ncaq/symbolword-mode

;;; Commentary:

;; modify word split.
;; symbolword-mode determine word split for symbol.
;; for instance hyphen.

;; Key     Word oriented command      Symbolword oriented command
;; ============================================================
;; M-f     `forward-word'             `symbolword-forward'
;; M-b     `backward-word'            `symbolword-backward'
;; M-d     `kill-word'                `symbolword-kill'
;; M-DEL   `backward-kill-word'       `symbolword-backward-kill'

;;; Code:

(defun symbolword-div-word? (left-char curr-char)
  "Div word rule.  Argument LEFT-CHAR left character.
Argument CURR-CHAR current character."
  (or
   (not (characterp left-char))
   (not (characterp curr-char))
   (let ((left-class (symbolword-unicode-class left-char))
         (curr-class (symbolword-unicode-class curr-char)))
     (or
      (and
       (not (or ;without
             (and
              (eq left-class 'space)
              (eq curr-class 'space))
             (and
              (eq left-class 'upper-case)
              (eq curr-class 'lower-case))
             (and
              (eq left-class 'lower-case)
              (eq curr-class 'lower-case))
             (and
              (eq left-class 'upper-case)
              (eq curr-class 'upper-case))
             (and
              (eq left-class 'digit)
              (eq curr-class 'digit))))
       (not (and
             (eq left-class curr-class)
             (symbolword-equal-syntax? left-char curr-char))))))))

(defun symbolword-equal-syntax? (a b)
  "Depend on language synta Argument A is char.  Argument B is char."
  (=
   (char-syntax a)
   (char-syntax b)))

(defun symbolword-unicode-class (ucs)
  "XML like unicode character class.  Argument UCS is code point."
  (cond
   ((or
     (= ucs 32)
     (= ucs 160)
     (= ucs 8199)
     (= ucs 8203)
     (= ucs 8288)
     (= ucs 12288)
     (= ucs 65279)
     (= ucs 9);tab
     )
    'space)
   ((= ucs 10) 'newline)
   ((and (>= ucs 48) (<= ucs 57))       'digit)
   ((and (>= ucs 65) (<= ucs 90))       'upper-case)
   ((and (>= ucs 97) (<= ucs 122))      'lower-case)
   ((and (>= ucs 12352) (<= ucs 12447)) 'hiragana)
   ((and (>= ucs 12448) (<= ucs 12543)) 'katakana)
   ((and (>= ucs 19968) (<= ucs 40959)) 'kanji)
   ((and (>= ucs 13312) (<= ucs 19902)) 'kanji)
   ((and (>= ucs 63744) (<= ucs 64255)) 'kanji)
   (t 'otherwise)))

(defun symbolword-div-word-point? (n)
  "Do `symbolword-div-word?'.  Argument N is slide."
  (symbolword-div-word? (char-before n) (char-after n)))

(defun symbolword-forward ()
  "Symbolword version `forward'."
  (interactive)
  (if (eobp)
      ()
    (forward-char (-
                   (symbolword-get-div-word-count-forward (1+ (point)))
                   (point)))))

(defun symbolword-get-div-word-count-forward (n)
  "`symbolword-forward' backend.  Argument N is for recursion."
  (if (symbolword-div-word-point? n)
      n
    (symbolword-get-div-word-count-forward (1+ n))))

(defun symbolword-backward ()
  "Symbolword version `backward'."
  (interactive)
  (if (bobp)
      ()
    (backward-char (-
                    (point)
                    (symbolword-get-div-word-count-backward (1- (point)))))))

(defun symbolword-get-div-word-count-backward (n)
  "`symbolword-backward' backend.  Argument N is for recursion."
  (if (symbolword-div-word-point? n)
      n
    (symbolword-get-div-word-count-backward (1- n))))

(defun symbolword-kill ()
  "Symbolword version `kill'."
  (interactive)
  (if (or (eobp) (get-text-property (1+ (point)) 'read-only))
      ()
    (kill-forward-chars (-
                         (symbolword-get-div-word-count-forward-for-kill (1+ (point)))
                         (point)))))

(defun symbolword-get-div-word-count-forward-for-kill (n)
  "`symbolword-kill' backend.  Argument N is for recursion."
  (if (or (symbolword-div-word-point? n) (get-text-property n 'read-only))
      n
    (symbolword-get-div-word-count-forward (1+ n))))

(defun symbolword-backward-kill ()
  "Symbolword version `backward-kill'."
  (interactive)
  (if (or (bobp) (get-text-property (1- (point)) 'read-only))
      ()
    (kill-backward-chars (-
                          (point)
                          (symbolword-get-div-word-count-backward (1- (point)))))))

(defvar symbolword-mode-map (make-sparse-keymap))

(define-key symbolword-mode-map [remap forward-word]       'symbolword-forward)
(define-key symbolword-mode-map [remap backward-word]      'symbolword-backward)
(define-key symbolword-mode-map [remap kill-word]          'symbolword-kill)
(define-key symbolword-mode-map [remap backward-kill-word] 'symbolword-backward-kill)

;;;###autoload
(easy-mmode-define-minor-mode symbolword-mode "Change word breaks" t " SW" symbolword-mode-map)

(provide 'symbolword-mode)

;;; symbolword-mode.el ends here
