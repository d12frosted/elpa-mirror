;;; -*- lexical-binding: t -*-
;;; jaword.el --- Minor-mode for handling Japanese words better

;; Copyright (C) 2014-2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://zk-phi.github.io/
;; Package-Version: 20210306.420
;; Package-Commit: 783544a265f91b2e568b52311afb36e3691d5ad3
;; Version: 1.0.1
;; Package-Requires: ((tinysegmenter "0.1") (emacs "25.1"))

;;; Commentary:

;; This script provides a minor-mode that improves
;; backward/forward-word behavior for Japanese words.

;; tinysegmenter.el とこのファイルを load-path の通ったディレクトリに置
;; いて、ロードする。
;;
;;   (require 'jaword)
;;
;; "jaword-mode" で jaword-mode の有効を切り替える。すべてのバッファで
;; 有効にするには "global-jaword-mode" を用いる。
;;
;; jaword-mode は subword-mode と同時に有効にすることができないが、
;; jaword-mode はデフォルトで "hogeFugaPiyo" のような単語を３つの独立し
;; た単語として扱う。これを無効にするためには、
;; "jaword-enable-subword" を nil に設定する。
;;
;;   (setq jaword-enable-subword nil)

;;; Change Log:

;; 1.0.0 first released
;; 1.0.1 Migrate to nadvice.el (now requires Emacs 25.1 or later)

;;; Code:

(require 'tinysegmenter)
(require 'subword)

(defconst jaword-version "1.0.0")

;; + customs

(defgroup jaword nil
  "Minor-mode for handling Japanese words better."
  :group 'emacs)

(defcustom jaword-buffer-size 50
  "size of text passed to the segmenter. set larger for better
accuracy, but slower speed."
  :group 'jaword
  :type 'integer)

(defcustom jaword-enable-subword t
  "when non-nil, handle subwords like `subword-mode'."
  :group 'jaword
  :type 'boolean)

;; + internal functions

(defun jaword--segment-around-point ()
  (let* ((back (buffer-substring-no-properties
                (max (point-min) (- (point) (lsh jaword-buffer-size -1)))
                (point)))
         (forward (buffer-substring-no-properties
                   (point)
                   (min (point-max) (+ (point) (lsh jaword-buffer-size -1)))))
         (_ (when (> (length forward) 0) ; mark the beginning of "forward"
              (put-text-property 0 1 'base-pos t forward)))
         (str (concat back forward))
         (segments (tseg-segment str))
         last current pos)
    (while (and segments (null pos))
      (setq last     current
            current  (car segments)
            pos      (text-property-any 0 (length current) 'base-pos t current)
            segments (cdr segments)))
    (cons (if (or (null pos) (zerop pos))
              last
            (substring current 0 pos))
          (if (or (null pos) (= pos (length current)))
              (car segments)
            (substring current pos (length current))))))

;; + interactive commands

;;;###autoload
(defun jaword-backward (arg)
  "Like backward-word, but handles Japanese words better."
  (interactive "p")
  (if (< arg 0)
      (jaword-forward (- arg))
    (let (segment)
      (dotimes (_ arg)
        (cond ((and (progn
                      (skip-chars-backward "\s\t\n")
                      (looking-back "\\Ca" (point-min)))
                    (setq segment (car (jaword--segment-around-point))))
               (search-backward
                (replace-regexp-in-string "^[\s\t\n]*" "" segment)))
              (jaword-enable-subword
               (subword-backward 1))
              (t
               (backward-word 1)))))))

;;;###autoload
(defun jaword-forward (arg)
  "Like forward-word, but handle Japanese words better."
  (interactive "p")
  (if (< arg 0)
      (jaword-backward (- arg))
    (let (segment)
      (dotimes (_ arg)
        (cond ((and (progn
                      (skip-chars-forward "\s\t\n")
                      (looking-at "\\Ca"))
                    (setq segment (cdr (jaword--segment-around-point))))
               (search-forward
                (replace-regexp-in-string "[\s\t\n]*$" "" segment)))
              (jaword-enable-subword
               (subword-forward 1))
              (t
               (forward-word 1)))))))

;;;###autoload
(put 'jaword 'forward-op 'jaword-forward)

;;;###autoload
(defun jaword-mark (&optional arg allow-extend)
  "Like mark-word, but handle Japanese words better."
  (interactive "P\np")
  ;; based on "mark-word" in "simple.el"
  (cond ((and allow-extend
              (or (and (eq last-command this-command)
                       (mark t))
                  (region-active-p)))
         (setq arg (cond (arg (prefix-numeric-value arg))
                         ((< (mark) (point)) -1)
                         (t 1)))
         (set-mark (save-excursion
                     (goto-char (mark))
                     (jaword-forward arg)
                     (point))))
        (t
         (push-mark (save-excursion
                      (jaword-forward (prefix-numeric-value arg))
                      (point))
                    nil t))))

;;;###autoload
(defun jaword-kill (n)
  "Like kill-word, but handle Japanese words better."
  (interactive "p")
  (kill-region (point) (progn (jaword-forward n) (point))))

;;;###autoload
(defun jaword-backward-kill (n)
  "Like backward-kill-word, but handle Japanese words better."
  (interactive "p")
  (jaword-kill (- n)))

;;;###autoload
(defun jaword-transpose (n)
  "Like transpose-words, but handle Japanese words better."
  (interactive "*p")
  (transpose-subr 'jaword-forward n))

;; + minor modes

(defvar jaword-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap [remap backward-word] 'jaword-backward)
    (define-key kmap [remap forward-word] 'jaword-forward)
    (define-key kmap [remap kill-word] 'jaword-kill)
    (define-key kmap [remap backward-kill-word] 'jaword-backward-kill)
    (define-key kmap [remap transpose-words] 'jaword-transpose)
    kmap))

;;;###autoload
(define-minor-mode jaword-mode
  "Toggle Japanese word movement and editing."
  :init-value nil
  :global nil
  :keymap jaword-mode-map)

;;;###autoload
(define-globalized-minor-mode global-jaword-mode jaword-mode
  (lambda () (jaword-mode 1)))

;; + isearch support

;;;###autoload
(define-advice isearch-yank-word-or-char (:around (fn &rest args) jaword-support-isearch)
  "Add support for jaword."
  (if (bound-and-true-p jaword-mode)
      (isearch-yank-internal
       (lambda ()
         (if (or (= (char-syntax (or (char-after) 0)) ?w)
                 (= (char-syntax (or (char-after (1+ (point))) 0)) ?w))
             (jaword-forward 1)
           (forward-char 1))
         (point)))
    (apply fn args)))

;;;###autoload
(define-advice isearch-yank-word (:around (fn &rest args) jaword-support-isearch)
  "Add support for jaword."
  (if (bound-and-true-p jaword-mode)
      (isearch-yank-internal (lambda () (jaword-forward 1) (point)))
    (apply fn args)))

;; + subword workaround

;; `subword-backward' by default sometimes moves cursor too far. for
;; example, after "ほげ1", `backward-word' moves cursor between "げ"
;; and "1", but `subword-backward' moves before "ほ"
(define-advice subword-backward (:around (fn &rest args) jaword-fix-subword)
  "Don't move cursor further than `forward-word'."
  (goto-char (max (save-excursion (backward-word (car args)) (point))
                  (save-excursion (apply fn args) (point)))))

;; + provide

(provide 'jaword)

;;; jaword.el ends here
