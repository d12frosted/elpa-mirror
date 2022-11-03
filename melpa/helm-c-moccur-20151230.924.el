;;; helm-c-moccur.el --- helm source for color-moccur.el

;; Copyright (C) 2008, 2009, 2010, 2011 Kenji.I (Kenji Imakado) <ken.imakaado@gmail.com>
;; Copyright (C) 2012 Yuhei Maeda <yuhei.maeda_at_gmail.com>

;; Author: Kenji.I (Kenji Imakado) <ken.imakaado@gmail.com>
;; Version: 0.0.1
;; Package-Commit: b0a906f85fa352db091f88b91a9c510de607dfe9
;; Package-Version: 20151230.924
;; Package-X-Original-Version: 0.0.1
;; Package-Requires: ((helm "20120811")(color-moccur "2.71"))
;; Keywords: convenience, emulation

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:
;;
;; Tested on Emacs 24

;;; Changelog:
;;  2012/08/11 port to helm 
;;
;;

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `helm-c-moccur-from-isearch'
;;    Run `helm-c-moccur-occur-by-moccur' with isearch string.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `helm-c-moccur-helm-idle-delay'
;;    helm-c-moccurが提供するコマンドでhelmが起動された際の`helm-idle-delay'の値
;;    default = nil
;;  `helm-c-moccur-push-mark-flag'
;;    non-nilならコマンド起動時に現在のポイントにマークをセットする
;;    default = nil
;;  `helm-c-moccur-widen-when-goto-line-flag'
;;    non-nilなら必要に応じてナローイングを解除する
;;    default = nil
;;  `helm-c-moccur-show-all-when-goto-line-flag'
;;    non-nilなら必要に応じてoutlineの折畳み表示を解除する
;;    default = nil
;;  `helm-c-moccur-higligt-info-line-flag'
;;    non-nilならdmoccur, dired-do-moccurの候補を表示する際にバッファ名などの情報をハイライト表示する
;;    default = nil
;;  `helm-c-moccur-enable-auto-look-flag'
;;    non-nilなら選択中の候補を他のバッファにリアルタイムに表示する
;;    default = nil
;;  `helm-c-moccur-enable-initial-pattern'
;;    non-nilなら`helm-c-moccur-occur-by-moccur'を起動する際に、ポイントの位置の単語をpatternの初期値として起動する。
;;    default = nil
;;  `helm-c-moccur-use-moccur-helm-map-flag'
;;    non-nilならhelm-c-moccurのデフォルトのキーバインドを使用する
;;    default = t
;;  `helm-c-moccur-recenter-count'
;;    これは選択した候補の位置にポイントを移動した後に呼ばれる 関数`recenter'に引数として渡される値である
;;    default = 10
;;  `helm-c-moccur-preselect-current-line'
;;    *Preselect current line in *helm moccur* buffer.
;;    default = t

;; sample config
;; (require 'helm-c-moccur)
;; (global-set-key (kbd "M-o") 'helm-c-moccur-occur-by-moccur)
;; (global-set-key (kbd "C-M-o") 'helm-c-moccur-dmoccur)
;; (add-hook 'dired-mode-hook
;;           '(lambda ()
;;              (local-set-key (kbd "O") 'helm-c-moccur-dired-do-moccur-by-moccur)))
;; (global-set-key (kbd "C-M-s") 'helm-c-moccur-isearch-forward)
;; (global-set-key (kbd "C-M-r") 'helm-c-moccur-isearch-backward)

;;; Todo:
;; resume

;;;code:

(eval-when-compile
  (require 'cl))

(require 'helm)
(require 'cl-lib)
(require 'color-moccur)
(require 'rx)

(defgroup helm-c-moccur nil
  "helm config moccur"
  :group 'helm-c-moccur)


(defcustom helm-c-moccur-helm-idle-delay nil
  "helm-c-moccurが提供するコマンドでhelmが起動された際の`helm-idle-delay'の値
nilなら`helm-idle-delay'の値を使う"
  :type '(choice (number)
                 (boolean))
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-push-mark-flag nil
  "non-nilならコマンド起動時に現在のポイントにマークをセットする"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-widen-when-goto-line-flag nil
  "non-nilなら必要に応じてナローイングを解除する"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-show-all-when-goto-line-flag nil ;outline
  "non-nilなら必要に応じてoutlineの折畳み表示を解除する"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-higligt-info-line-flag nil
  "non-nilならdmoccur, dired-do-moccurの候補を表示する際にバッファ名などの情報をハイライト表示する"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-enable-auto-look-flag nil
  "non-nilなら選択中の候補を他のバッファにリアルタイムに表示する"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-enable-initial-pattern nil
  "non-nilなら`helm-c-moccur-occur-by-moccur'を起動する際に、ポイントの位置の単語をpatternの初期値として起動する。"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-use-moccur-helm-map-flag t
  "non-nilならhelm-c-moccurのデフォルトのキーバインドを使用する
nilなら使用しない"
  :type 'boolean
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-recenter-count 10
  "これは選択した候補の位置にポイントを移動した後に呼ばれる 関数`recenter'に引数として渡される値である"
  :type '(choice (integer)
                 (boolean))
  :group 'helm-c-moccur)

(defcustom helm-c-moccur-preselect-current-line t
  "*Preselect current line in *helm moccur* buffer."
  :type 'boolean  
  :group 'helm-c-moccur)

;;; variables
(defvar helm-c-moccur-version 0.33)
(defvar helm-c-moccur-helm-invoking-flag nil)
(defvar helm-c-moccur-helm-initial-pattern "")
(defvar helm-c-moccur-helm-current-buffer nil)
(defvar helm-c-moccur-saved-info nil)
(defvar helm-c-moccur-buffer "*helm moccur*")
(defvar helm-c-moccur-helm-map
  (let ((map (copy-keymap helm-map)))
    (when helm-c-moccur-use-moccur-helm-map-flag
      (define-key map (kbd "D")  'helm-c-moccur-wrap-symbol)
      (define-key map (kbd "W")  'helm-c-moccur-wrap-word)
      (define-key map (kbd "F")  'helm-c-moccur-match-only-function)
      (define-key map (kbd "C")  'helm-c-moccur-match-only-comment)
      (define-key map (kbd "S")  'helm-c-moccur-match-only-string)

      (define-key map (kbd "U")  'helm-c-moccur-start-symbol)
      (define-key map (kbd "I")  'helm-c-moccur-end-symbol)
      (define-key map (kbd "O")  'helm-c-moccur-start-word)
      (define-key map (kbd "P")  'helm-c-moccur-end-word)

      (define-key map (kbd "J")  'scroll-other-window)
      (define-key map (kbd "K")  'scroll-other-window-down)

      ;; helm
      (define-key map (kbd "C-n")  'helm-c-moccur-next-line)
      (define-key map (kbd "C-p")  'helm-c-moccur-previous-line)

      (define-key map (kbd "C-M-f")  'helm-c-moccur-helm-next-file-matches)
      (define-key map (kbd "C-M-b")  'helm-c-moccur-helm-previous-file-matches)
      (define-key map (kbd "C-c C-e")  'helm-c-moccur-edit)
      (define-key map (kbd "C-M-%")  'helm-c-moccur-query-replace-regexp)
      )
    map))

;;overlay
(defvar helm-c-moccur-current-line-overlay
  (make-overlay (point) (point)))

;;; utilities
(defun helm-c-moccur-widen-if-need ()
  (when helm-c-moccur-widen-when-goto-line-flag
    (widen))
  (when helm-c-moccur-show-all-when-goto-line-flag
    (require 'outline)
    (show-all)))

;; regexp from `moccur-get-info'
(defvar helm-c-moccur-info-line-re "^[-+ ]*Buffer:[ ]*\\([^\r\n]*\\) File\\([^:/\r\n]*\\):[ ]*\\([^\r\n]+\\)$")

(defun helm-c-moccur-helm-move-selection-if-info-line (direction)
  (unless (= (buffer-size (get-buffer helm-buffer)) 0)
    (with-current-buffer helm-buffer
      (let ((re helm-c-moccur-info-line-re))
        (when (save-excursion
                (beginning-of-line)
                (looking-at re))
          (cl-case direction
            (next (helm-next-line))
            (previous (helm-previous-line)))))
      (helm-mark-current-line))))

(defun helm-c-moccur-next-line-if-info-line ()
  (helm-c-moccur-helm-move-selection-if-info-line 'next))

(defun helm-c-moccur-previous-line-if-info-line ()
  (helm-c-moccur-helm-move-selection-if-info-line 'previous))

(defun helm-c-moccur-get-info ()
  "return (values buffer file)"
  (cond
   (helm-c-moccur-saved-info
    helm-c-moccur-saved-info)
   (t
    (unless (or (= (buffer-size (get-buffer helm-buffer)) 0))
      (with-current-buffer helm-buffer
        (save-excursion
          (let ((re helm-c-moccur-info-line-re))
            (when (re-search-backward re nil t)
              (values (match-string-no-properties 1) ;buffer
                      (match-string-no-properties 3))))))))))

(defun helm-c-moccur-helm-move-selection (unit direction)
  (unless (or (= (buffer-size (get-buffer helm-buffer)) 0)
              (not (get-buffer-window helm-buffer 'visible)))
    (save-selected-window
      (select-window (get-buffer-window helm-buffer 'visible))

      (cl-case unit
        (file (let ((search-fn (cl-case direction
                                 (next 're-search-forward)
                                 (previous (prog1 're-search-backward
                                             (re-search-backward helm-c-moccur-info-line-re nil t)))
                                 (t (error "Invalid direction.")))))
                ;;(funcall search-fn (rx bol "Buffer:" (* not-newline) "File:") nil t)))
                (funcall search-fn helm-c-moccur-info-line-re nil t)))

        (t (error "Invalid unit.")))

      (while (helm-pos-header-line-p)
        (forward-line (if (and (eq direction 'previous)
                               (not (eq (line-beginning-position)
                                        (point-min))))
                          -1
                        1)))

      (if (eobp)
          (forward-line -1))
      (helm-mark-current-line)

      ;; top
      (recenter 0))))

(defun helm-c-moccur-helm-next-file-matches ()
  (interactive)
  (helm-c-moccur-helm-move-selection 'file 'next)
  (helm-c-moccur-next-line-if-info-line)
  (helm-c-moccur-helm-try-execute-persistent-action))

(defun helm-c-moccur-helm-previous-file-matches ()
  (interactive)
  (helm-c-moccur-helm-move-selection 'file 'previous)
  (helm-c-moccur-next-line-if-info-line)
  (helm-c-moccur-helm-try-execute-persistent-action))

(defun helm-c-moccur-initialize ()
  (setq helm-c-moccur-saved-info nil
        helm-c-moccur-helm-invoking-flag t))

(defun helm-c-moccur-helm-try-execute-persistent-action ()
  (when (and helm-c-moccur-enable-auto-look-flag
             helm-c-moccur-helm-invoking-flag)
    (unless (zerop (buffer-size (get-buffer (helm-buffer-get))))
      (helm-execute-persistent-action))))

(defun helm-c-moccur-preselect-current-line-maybe ()
  (and helm-c-moccur-preselect-current-line
       (helm-preselect (format "^ *%d "
                                   (with-current-buffer helm-current-buffer
                                     (line-number-at-pos))))))


(defvar helm-c-moccur-last-buffer nil)
(defmacro helm-c-moccur-with-helm-env (sources &rest body)
  (declare (indent 1))
  `(let ((helm-buffer helm-c-moccur-buffer)
         (helm-sources ,sources)
         (helm-map helm-c-moccur-helm-map)
         (helm-idle-delay (cond
                               ((integerp helm-c-moccur-helm-idle-delay)
                                helm-c-moccur-helm-idle-delay)
                               (t helm-idle-delay))))
     (add-hook 'helm-update-hook 'helm-c-moccur-preselect-current-line-maybe)
     (add-hook 'helm-c-moccur-helm-after-update-hook 'helm-c-moccur-helm-try-execute-persistent-action)
     (unwind-protect
         (progn
           ,@body)
       (remove-hook 'helm-c-moccur-helm-after-update-hook 'helm-c-moccur-helm-try-execute-persistent-action)
       (remove-hook 'helm-update-hook 'helm-c-moccur-preselect-current-line-maybe)
       (setq helm-c-moccur-last-buffer helm-current-buffer))))


(defun helm-c-moccur-clean-up ()
  (setq helm-c-moccur-helm-invoking-flag nil)
  (when (overlayp helm-c-moccur-current-line-overlay)
    (delete-overlay helm-c-moccur-current-line-overlay)))

;; (helm-next-line) 後のhelm-update-hook
;; persistent-actionを動作させるために実装
(defvar helm-c-moccur-helm-after-update-hook nil)
(defadvice helm-process-delayed-sources (after helm-c-moccur-helm-after-update-hook activate protect)
  (when (and (boundp 'helm-c-moccur-helm-invoking-flag)
             helm-c-moccur-helm-invoking-flag)
    (ignore-errors
      (run-hooks 'helm-c-moccur-helm-after-update-hook))))

(defadvice helm-select-action (before helm-c-moccur-saved-info activate)
  (when (and (boundp 'helm-c-moccur-helm-invoking-flag)
             helm-c-moccur-helm-invoking-flag)
    (ignore-errors
      (unless helm-c-moccur-saved-info
        (setq helm-c-moccur-saved-info (helm-c-moccur-get-info))))))

(defadvice moccur-search (around helm-c-moccur-no-window-change)
  (cond
   ((and (boundp 'helm-c-moccur-helm-invoking-flag)
         helm-c-moccur-helm-invoking-flag)
    (let ((regexp (ad-get-arg 0))
          (arg (ad-get-arg 1))
          (buffers (ad-get-arg 2)))
      (when (or (not regexp)
                (string= regexp ""))
        (error "No search word specified!"))
      ;; initialize
      (let ((lst (list regexp arg buffers)))
        (if (equal lst (car moccur-searched-list))
            ()
          (setq moccur-searched-list (cons (list regexp arg buffers) moccur-searched-list))))
      (setq moccur-special-word nil)
      (moccur-set-regexp)
      (moccur-set-regexp-for-color)
      ;; variable reset
      (setq dmoccur-project-name nil)
      (setq moccur-matches 0)
      (setq moccur-match-buffers nil)
      (setq moccur-regexp-input regexp)
      (if (string= (car regexp-history) moccur-regexp-input)
          ()
        (setq regexp-history (cons moccur-regexp-input regexp-history)))
      (save-excursion
        (setq moccur-mocur-buffer (generate-new-buffer "*Moccur*"))
        (set-buffer moccur-mocur-buffer)
        (insert "Lines matching " moccur-regexp-input "\n")
        (setq moccur-buffers buffers)
        ;; search all buffers
        (while buffers
          (if (and (car buffers)
                   (buffer-live-p (car buffers))
                   ;; if b:regexp exists,
                   (if (and moccur-file-name-regexp
                            moccur-split-word)
                       (string-match moccur-file-name-regexp (buffer-name (car buffers)))
                     t))
              (if (and (not arg)
                       (not (buffer-file-name (car buffers))))
                  (setq buffers (cdr buffers))
                (if (moccur-search-buffer (car moccur-regexp-list) (car buffers))
                    (setq moccur-match-buffers (cons (car buffers) moccur-match-buffers)))
                (setq buffers (cdr buffers)))
            ;; illegal buffer
            (setq buffers (cdr buffers)))))))
   (t
    ad-do-it)))

(defun helm-c-moccur-bad-regexp-p (re)
  (or (string-match (rx bol (+ space) eol) re)
      (string-equal "" re)
      (string-match (rx (or bol (+ space)) (+ (any "<" ">" "\\" "_" "`")) (or eol (+ space ))) re)))

(defun helm-c-moccur-moccur-search (regexp arg buffers)
  (ignore-errors
    (unwind-protect
        (progn
          ;; active advice
          (ad-enable-advice 'moccur-search 'around 'helm-c-moccur-no-window-change)
          (ad-activate 'moccur-search)
          ;; 空白のみで呼ばれると固まることがあったので追加
          (when (helm-c-moccur-bad-regexp-p helm-pattern)
            (error ""))

          (save-window-excursion
            (moccur-setup)
            (moccur-search regexp arg buffers)))
      ;; disable advance
      (ad-disable-advice 'moccur-search 'around 'helm-c-moccur-no-window-change)
      (ad-activate 'moccur-search))))

(defun helm-c-moccur-occur-by-moccur-scraper ()
  (when (buffer-live-p moccur-mocur-buffer)
    (with-current-buffer moccur-mocur-buffer
      (let* ((buf (buffer-substring (point-min) (point-max)))
             (lines (delete "" (cl-subseq (split-string buf "\n") 3))))
        lines))))

(defun helm-c-moccur-occur-by-moccur-get-candidates ()
  (helm-c-moccur-moccur-search helm-pattern t (list helm-current-buffer))
  (helm-c-moccur-occur-by-moccur-scraper))

(defun helm-c-moccur-occur-by-moccur-persistent-action (candidate)
  (helm-c-moccur-widen-if-need)
  (goto-line (string-to-number candidate))
  (recenter helm-c-moccur-recenter-count)
  (when (overlayp helm-c-moccur-current-line-overlay)
    (move-overlay helm-c-moccur-current-line-overlay
                  (line-beginning-position)
                  (line-end-position)
                  (current-buffer))
    (overlay-put helm-c-moccur-current-line-overlay 'face 'highlight)))

(defun helm-c-moccur-occur-by-moccur-goto-line (candidate)
  (helm-c-moccur-widen-if-need)     ;utility
  (goto-line (string-to-number candidate))
  (recenter helm-c-moccur-recenter-count))

(defvar helm-c-source-occur-by-moccur
  `((name . "Occur by Moccur")
    (candidates . helm-c-moccur-occur-by-moccur-get-candidates)
    (action . (("Goto line" . helm-c-moccur-occur-by-moccur-goto-line)))
    (persistent-action . helm-c-moccur-occur-by-moccur-persistent-action)
    (init . helm-c-moccur-initialize)
    (cleanup . helm-c-moccur-clean-up)
    (match . (identity))
    (requires-pattern . 3)
    (delayed)
    (volatile)))

(defun helm-c-moccur-occur-by-moccur-base (initial-pattern)
  (helm-c-moccur-with-helm-env (list helm-c-source-occur-by-moccur)
    (and helm-c-moccur-push-mark-flag (push-mark))
    (helm nil initial-pattern)))

(defun helm-c-moccur-occur-by-moccur (&optional prefix)
  (interactive "P")
  (if prefix
      (helm-c-moccur-resume)
    (helm-c-moccur-occur-by-moccur-base
     (if helm-c-moccur-enable-initial-pattern
         (regexp-quote (or (thing-at-point 'symbol) ""))
       ""))))

(defun helm-c-moccur-occur-by-moccur-only-function ()
  (interactive)
  (helm-c-moccur-occur-by-moccur-base "! "))

(defun helm-c-moccur-occur-by-moccur-only-comment ()
  (interactive)
  (helm-c-moccur-occur-by-moccur-base ";;; "))

(defun helm-c-moccur-query-replace-regexp ()
  (interactive)
  (lexical-let ((input-re (minibuffer-contents))
                (cur-point (first helm-current-position)))
    (setq helm-saved-action (lambda (dummy)
                                  (let ((to-string (read-from-minibuffer "to: " input-re)))
                                    (unwind-protect
                                        (perform-replace input-re to-string t t nil nil nil (point-min) (point-max))
                                      (goto-char cur-point)))))
    (helm-exit-minibuffer)))

;; e.x, (global-set-key (kbd "C-c f") (helm-c-moccur-define-occur-command "defun "))
;; rubikitch: This is replaced by headline plug-in in helm-config.el.
(defun helm-c-moccur-define-occur-command (initial)
  (lexical-let ((initial initial))
    (lambda () (interactive) (helm 'helm-c-source-occur-by-moccur initial))))


;;; moccur buffers
(defvar helm-c-source-moccur-buffer-list
  '((name . "Moccur To Buffers")
    (candidates . (lambda ()
                    (helm-c-moccur-moccur-search helm-pattern nil (buffer-list))
                    (helm-c-moccur-dmoccur-scraper)))
    (action . (("Goto line" . helm-c-moccur-dmoccur-goto-line)))
    (persistent-action . helm-c-moccur-dmoccur-persistent-action)
    (match . (identity))
    (requires-pattern . 5)
    (init . helm-c-moccur-initialize)
    (cleanup . helm-c-moccur-clean-up)
    (delayed)
    (volatile)))

(defun helm-c-moccur-buffer-list ()
  (interactive)
  (helm-c-moccur-with-helm-env (list helm-c-source-moccur-buffer-list)
    (helm)))

;;; dmoccur
(defvar helm-c-moccur-dmoccur-buffers nil)

(defun helm-c-moccur-dmoccur-higligt-info-line ()
  (let ((re helm-c-moccur-info-line-re))
    (cl-loop initially (goto-char (point-min))
             while (re-search-forward re nil t)
             do (put-text-property (line-beginning-position)
                                   (line-end-position)
                                   'face
                                   'helm-header))))

(defun helm-c-moccur-dmoccur-scraper ()
  (when (buffer-live-p moccur-mocur-buffer)
    (with-current-buffer moccur-mocur-buffer
      (let ((lines nil)
            (re (rx bol (group (+ not-newline)) eol)))

        ;; put face [Buffer:...] line
        (when helm-c-moccur-higligt-info-line-flag
          (helm-c-moccur-dmoccur-higligt-info-line))
        
        (cl-loop initially (progn (goto-char (point-min))
                                  (forward-line 1))
                 while (re-search-forward re nil t)
                 do (push (match-string 0) lines))
        (nreverse lines)))))

(defun helm-c-moccur-dmoccur-get-candidates ()
  (helm-c-moccur-moccur-search helm-pattern nil helm-c-moccur-dmoccur-buffers)
  (helm-c-moccur-dmoccur-scraper))

(defun helm-c-moccur-dmoccur-persistent-action (candidate)
  (helm-c-moccur-next-line-if-info-line)

  (let ((real-candidate (helm-get-selection)))
  
    (multiple-value-bind (buffer file-path)
        (helm-c-moccur-get-info)    ;return (values buffer file)
      (when (and (stringp buffer)
                 (bufferp (get-buffer buffer))
                 (stringp file-path)
                 (file-readable-p file-path))
        
        (find-file file-path)
      
        (helm-c-moccur-widen-if-need)

        (let ((line-number (string-to-number real-candidate)))
          (when (and (numberp line-number)
                     (not (= line-number 0)))
            (goto-line line-number)
      
            (recenter helm-c-moccur-recenter-count)
            (when (overlayp helm-c-moccur-current-line-overlay)
              (move-overlay helm-c-moccur-current-line-overlay
                            (line-beginning-position)
                            (line-end-position)
                            (current-buffer))
              (overlay-put helm-c-moccur-current-line-overlay 'face 'highlight))))))))

(defun helm-c-moccur-dmoccur-goto-line (candidate)
  (multiple-value-bind (buffer file-path)
                       (helm-c-moccur-get-info)
    (let ((line-number (string-to-number candidate)))
      (when (and (stringp buffer)
                 (bufferp (get-buffer buffer))
                 (stringp file-path)
                 (file-readable-p file-path))
        (find-file file-path)
        (goto-line line-number)))))

(defvar helm-c-source-dmoccur
  '((name . "DMoccur")
    (candidates . helm-c-moccur-dmoccur-get-candidates)
    (action . (("Goto line" . helm-c-moccur-dmoccur-goto-line)))
    (persistent-action . helm-c-moccur-dmoccur-persistent-action)
    (match . (identity))
    (requires-pattern . 5)
    (init . helm-c-moccur-initialize)
    (cleanup . helm-c-moccur-clean-up)    
    (delayed)
    (volatile)))

(defun helm-c-moccur-dmoccur (dir)
  (interactive (list (dmoccur-read-from-minibuf current-prefix-arg)))
  (let ((buffers (sort
                   (moccur-add-directory-to-search-list dir)
                   moccur-buffer-sort-method)))

  (setq helm-c-moccur-dmoccur-buffers buffers)

  (helm-c-moccur-with-helm-env (list helm-c-source-dmoccur)
    (helm))))

;;; dired-do-moccur
(defvar helm-c-moccur-dired-do-moccur-buffers nil)

(defun helm-c-moccur-dired-get-buffers ()
  (moccur-add-files-to-search-list
   (funcall (cond ((fboundp 'dired-get-marked-files) ; GNU Emacs
                   'dired-get-marked-files)
                  ((fboundp 'dired-mark-get-files) ; XEmacs
                   'dired-mark-get-files))
            t nil) default-directory t 'dired))

(defun helm-c-moccur-dired-do-moccur-by-moccur-get-candidates ()
  (helm-c-moccur-moccur-search helm-pattern nil helm-c-moccur-dired-do-moccur-buffers)
  (helm-c-moccur-dmoccur-scraper))

(defvar helm-c-source-dired-do-moccur
  '((name . "Dired do Moccur")
    (candidates . helm-c-moccur-dired-do-moccur-by-moccur-get-candidates)
    (action . (("Goto line" . helm-c-moccur-dmoccur-goto-line)))
    (persistent-action . helm-c-moccur-dmoccur-persistent-action)
    (match . (identity))
    (requires-pattern . 3)
    (init . helm-c-moccur-initialize)
    (cleanup . helm-c-moccur-clean-up)    
    (delayed)
    (volatile)))

(defun helm-c-moccur-dired-do-moccur-by-moccur ()
  (interactive)
  (let ((buffers (helm-c-moccur-dired-get-buffers)))
    (setq helm-c-moccur-dired-do-moccur-buffers buffers)

    (helm-c-moccur-with-helm-env (list helm-c-source-dired-do-moccur)
      (helm))))

(defun helm-c-moccur-isearch-get-regexp ()
  (if isearch-regexp
      isearch-string
    (regexp-quote isearch-string)))

;;; Commands

(defun helm-c-moccur-last-sources-is-moccur-p ()
  (and (equal helm-c-moccur-last-buffer (current-buffer))
       (cl-every (lambda (source)
                   (let ((source (if (listp source) source (symbol-value source))))
                     (string-match "moccur" (assoc-default 'name source))))
                 helm-last-sources)))

(defun helm-c-moccur-resume ()
  (interactive)
  (let (current-prefix-arg)
    (helm-resume helm-c-moccur-buffer)))

(defun helm-c-moccur-isearch-forward ()
  (interactive)
  (let ((helm-c-moccur-widen-when-goto-line-flag nil))
    (save-window-excursion
      (save-restriction
        (narrow-to-region (point-at-bol) (point-max))
        (helm-c-moccur-occur-by-moccur)))))

(defun helm-c-moccur-isearch-backward ()
  (interactive)
  (let* ((helm-c-moccur-widen-when-goto-line-flag nil)
         (copied-source (copy-alist helm-c-source-occur-by-moccur)) ;helm-c-source-occur-by-moccur is list. not symbol
         (helm-c-source-occur-by-moccur (cons '(candidate-transformer . (lambda (-candidates)
                                                                              (reverse -candidates)))
                                                  copied-source)))
    (save-window-excursion
      (save-restriction
        (narrow-to-region (point-min) (point-at-eol))
        (helm-c-moccur-occur-by-moccur)))))

(defun helm-c-moccur-from-isearch ()
  "Run `helm-c-moccur-occur-by-moccur' with isearch string."
  (interactive)
  (isearch-exit)
  (helm-c-moccur-occur-by-moccur-base (helm-c-moccur-isearch-get-regexp)))
;; (define-key isearch-mode-map "\M-o" 'helm-c-moccur-from-isearch)

;;; Commands for `helm-c-moccur-helm-map'
(defun helm-c-moccur-next-line ()
  (interactive)
  (helm-next-line)
  (helm-c-moccur-next-line-if-info-line)
  (helm-c-moccur-helm-try-execute-persistent-action))

(defun helm-c-moccur-previous-line ()
  (interactive)
  (helm-previous-line)
  (helm-c-moccur-previous-line-if-info-line)
  (helm-c-moccur-helm-try-execute-persistent-action))


(defun helm-c-moccur-wrap-word-internal (s1 s2)
  (ignore-errors
    (let ((cur-syntax-table
           (with-current-buffer helm-current-buffer
             (syntax-table))))
      (when (syntax-table-p cur-syntax-table)
        (with-syntax-table cur-syntax-table
          (save-excursion
            (backward-sexp)
            (insert s1))
          (insert s2))))))

(defun helm-c-moccur-start-symbol ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "\\_<" ""))

(defun helm-c-moccur-end-symbol ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "" "\\_>"))

(defun helm-c-moccur-wrap-symbol ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "\\_<" "\\_>"))

(defun helm-c-moccur-start-word ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "\\<" ""))

(defun helm-c-moccur-end-word ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "" "\\>"))

(defun helm-c-moccur-wrap-word ()
  (interactive)
  (helm-c-moccur-wrap-word-internal "\\<" "\\>"))

(defun helm-c-moccur-edit-1 (cand)
  (interactive)
  (occur-by-moccur helm-pattern nil))

(defun helm-c-moccur-edit ()
(interactive)
(helm-quit-and-execute-action 'helm-c-moccur-edit-1))

;; minibuf: hoge
;; => minibuf: ! hoge
(defun helm-c-moccur-delete-special-word ()
  (let ((re (rx (or "!" ";" "\"")
                (* space))))
    (ignore-errors
      (save-excursion
        (beginning-of-line)
        (when (looking-at re)
          (replace-match ""))))))

(defun helm-c-moccur-match-only-internal (str)
  (helm-c-moccur-delete-special-word)
  (save-excursion
    (beginning-of-line)
    (insert-before-markers str)))

(defun helm-c-moccur-match-only-function ()
  (interactive)
  (helm-c-moccur-match-only-internal "! "))

(defun helm-c-moccur-match-only-comment ()
  (interactive)
  (helm-c-moccur-match-only-internal "; "))

(defun helm-c-moccur-match-only-string ()
  (interactive)
  (helm-c-moccur-match-only-internal "\" "))

(provide 'helm-c-moccur)

;;; helm-c-moccur.el ends here
