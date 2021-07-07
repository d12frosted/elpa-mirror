;;; e2wm-R.el --- some e2wm plugin and perspective for GNU R

;; Author: myuhe <yuhei.maeda_at_gmail.com>
;; Maintainer: myuhe
;; URL: https://github.com/myuhe/e2wm-R.el
;; Package-Version: 20151230.926
;; Package-Commit: 4350601ee1a96bf89777b3f09f1b79b88e2e6e4d
;; Version: 0.4
;; Created: 2011-03-15
;; Keywords: convenience, e2wm
;; Package-Requires: ((e2wm "1.3") (inlineR "1.0") (ess "15.3"))
;; Copyright (C) 2011,2012 myuhe

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (a your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; e2wm is a window manager. e2wm makes windowlayout easy.
;; e2wm-R is a e2wm plugin for GNU R. It provides some window
;; to manage graphics or R objects.

;;; Changelog:
;;  2011-07-12 ess help buffer is now closed like popwin.el
;;             new command: e2wm:dp-R-popup-obj    
;;  2011-08-15 bug fix
;;  2011-10-24 bug fix: exclude duplicate timer
;;  2012-03-01 new command
;;               e2wm:dp-R-image-dired: open thumbnail using image-dired
;;               e2wm:dp-R-popup-obj:   popup rawdata of dataframe
;;  2012-03-01 new perspective
;;               e2wm:dp-R-image-dired: open thumbnail using image-dired
;;               e2wm:dp-R-popup-obj:   popup rawdata of dataframe
;;  2012-03-06 new plugin: R-thumbs-dired
;;  2012-03-08 release v0.4
;;  2012-05-20 bug fix for R2.15.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;require
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when-compile 
  (require 'cl))
(require'ess-site)
(require 'e2wm)
(require 'inlineR)
(require 'image-dired)
(require 'imgur nil t)
(load "ess-rdired")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;perspective definition : R-code / R Code editing 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:c-R-code-recipe
  '(| (:left-max-size 35)
      (- (:upper-size-ratio 0.3)
         R-graphics-list
         (- (:upper-size-ratio 0.5)
            R-graphics
            history))
      (- (:upper-size-ratio 0.7)
         (| (:right-max-size 25)
            (- (:upper-size-ratio 0.7)
               main
               proc)
            (- (:upper-size-ratio 0.3)
               R-dired
               imenu))
         sub)))

(defvar e2wm:c-R-code-winfo
  '((:name main)
    (:name R-dired         :plugin R-dired)
    (:name R-graphics      :plugin R-graphics)
    (:name R-graphics-list :plugin R-graphics-list)
    (:name proc            :plugin R-open  :plugin-args (:command R :buffer "*R*"))
    (:name history         :plugin history-list)
    (:name sub             :buffer "*info*" :default-hide t)
    (:name imenu           :plugin imenu :default-hide nil)))

(e2wm:pst-class-register 
 (make-e2wm:$pst-class
  :name   'R-code
  :extend 'base
  :title  "R-Coding"
  :init   'e2wm:dp-R-code-init
  :main   'main
  :switch 'e2wm:dp-code-switch
  :popup  'e2wm:dp-R-code-popup
  :keymap 'e2wm:dp-R-code-minor-mode-map))

(defun e2wm:dp-R-code-init ()
  (let* 
      ((code-wm 
        (wlf:no-layout 
         e2wm:c-R-code-recipe
         e2wm:c-R-code-winfo))
       (buf (or prev-selected-buffer
                (e2wm:history-get-main-buffer))))
    (when (e2wm:history-recordable-p prev-selected-buffer)
      (e2wm:history-add prev-selected-buffer))
    (wlf:set-buffer code-wm 'main buf)
    code-wm))

(defvar e2wm:dp-R-code-minor-mode-map 
  (e2wm:define-keymap
   '(("prefix h" . e2wm:dp-code-navi-history-command)
     ("prefix i" . e2wm:dp-code-navi-imenu-command)
     ("prefix l" . e2wm:dp-R-navi-grlist-command)
     ("prefix d" . e2wm:dp-R-navi-dired-command) 
     ("prefix s" . e2wm:dp-code-sub-toggle-command)
     ("prefix c" . e2wm:dp-code-toggle-clock-command)
     ("prefix g" . e2wm:def-plugin-R-graphics-timestamp-draw)
     ("prefix G" . e2wm:def-plugin-R-graphics-draw)
     ("prefix m" . e2wm:dp-code-main-maximize-toggle-command)
     ("C-c    m" . e2wm:dp-code-popup-messages)
     ("C-c    v" . e2wm:dp-R-popup-obj)
     ("prefix p" . e2wm:dp-code-popup-messages)
     ("prefix v" . e2wm:dp-R-popup-obj)
     ("prefix t" . e2wm:dp-R-thumbs)
     ("C-c    p" . e2wm:dp-code-popup-messages)
     ("C-c    v" . e2wm:dp-R-popup-obj)
     ("C-c    t" . e2wm:dp-R-thumbs))
   e2wm:prefix-key))

;;; commands / R-code
;;;--------------------------------------------------
(defun e2wm:dp-R-code ()
  (interactive)
  (e2wm:pst-change 'R-code))

(defun e2wm:dp-R-popup-obj ()
  (interactive)
  (let ((objname (current-word)))
    (ess-execute (ess-rdired-get objname) nil "R object")
    (select-window (wlf:get-window (e2wm:pst-get-wm) 'sub))))

(defun e2wm:dp-R-kill-buffer-and-window ()
  "Kill the current buffer and, if possible, also the window."
  (interactive)
  (let ((buffer (current-buffer)))
    (condition-case nil
        (delete-window (selected-window))
      (error nil))
    (kill-buffer buffer)
    (e2wm:pst-buffer-set 'proc (get-buffer-create "*R*") t)
    (e2wm:pst-show-history-main)
    (e2wm:pst-window-select-main)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;perspective definition : R-view / R graphics view
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:c-R-view-recipe
  '(| (:left-size-ratio 0.6)
      (- (:upper-size-ratio 0.5)
         main 
         (- (:upper-size-ratio 0.5)
            proc
            sub))
      (- (:upper-size-ratio 0.4)
         (| (:left-size-ratio 0.5)
            R-dired
            (- (:upper-size-ratio 0.7)
               R-graphics-list
               history))
         R-graphics)))

(defvar e2wm:c-R-view-winfo
  '((:name main)
    (:name R-dired         :plugin R-dired)
    (:name R-graphics      :plugin R-graphics)
    (:name R-graphics-list :plugin R-graphics-list)
    (:name proc            :plugin R-open :plugin-args (:command R :buffer "*R*"))
    (:name history         :plugin history-list)
    (:name sub             :buffer "*info*" :default-hide t)))

(e2wm:pst-class-register
 (make-e2wm:$pst-class
  :name   'R-view
  :extend 'base
  :title  "R-graphics-view"
  :init   'e2wm:dp-R-view-init
  :main   'main
  :switch 'e2wm:dp-code-switch
  :popup  'e2wm:dp-R-code-popup
  :keymap 'e2wm:dp-R-view-minor-mode-map))

(defun e2wm:dp-R-view-init ()
  (let* 
      ((code-wm 
        (wlf:no-layout 
         e2wm:c-R-view-recipe
         e2wm:c-R-view-winfo))
       (buf (or prev-selected-buffer
                (e2wm:history-get-main-buffer))))
    (when (e2wm:history-recordable-p prev-selected-buffer)
      (e2wm:history-add prev-selected-buffer))
    (wlf:set-buffer code-wm 'main buf)
    code-wm))

(defvar e2wm:dp-R-view-minor-mode-map 
  (e2wm:define-keymap
   '(("prefix h" . e2wm:dp-code-navi-history-command)
     ("prefix l" . e2wm:dp-R-navi-grlist-command)
     ("prefix d" . e2wm:dp-R-navi-dired-command)
     ("prefix s" . e2wm:dp-code-navi-sub-command)
     ("prefix S" . e2wm:dp-code-sub-toggle-command)
     ("prefix c" . e2wm:dp-code-toggle-clock-command)
     ("prefix g" . e2wm:def-plugin-R-graphics-timestamp-draw)
     ("prefix G" . e2wm:def-plugin-R-graphics-draw)
     ("prefix m" . e2wm:dp-code-main-maximize-toggle-command)
     ("prefix p" . e2wm:dp-code-popup-messages)
     ("prefix v" . e2wm:dp-R-popup-obj)
     ("prefix t" . e2wm:dp-R-thumbs)
     ("C-c    p" . e2wm:dp-code-popup-messages)
     ("C-c    v" . e2wm:dp-R-popup-obj)
     ("C-c    t" . e2wm:dp-R-thumbs))
   e2wm:prefix-key))

(defun e2wm:dp-R-view ()
  (interactive)
  (e2wm:pst-change 'R-view))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;perspective definition : R-thumbs / thumbnail R graphics 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:c-R-thumbs-recipe
  '(| (:left-size-ratio 0.6)
      (- (:upper-size-ratio 0.7)
         R-thumbs-view
         R-thumbs-dired)
      (- (:upper-size-ratio 0.7)
         main
         sub)))

(defvar e2wm:c-R-thumbs-winfo
  '((:name main           :plugin R-thumbs)
    (:name R-thumbs-view  :plugin R-thumbs-view)
    (:name R-thumbs-dired :plugin R-thumbs-dired)
    (:name sub            :buffer "*info*" :default-hide t)))

(e2wm:pst-class-register
 (make-e2wm:$pst-class
  :name   'R-thumbs
  :extend 'base
  :title  "R-graphics-view"
  :init   'e2wm:dp-R-thumbs-init
  :main   'main
  :switch 'e2wm:dp-code-switch
  :popup  'e2wm:dp-R-code-popup
  :keymap 'e2wm:dp-R-thumbs-minor-mode-map))

(defun e2wm:dp-R-thumbs-init ()
  (let* 
      ((code-wm 
        (wlf:no-layout 
         e2wm:c-R-thumbs-recipe
         e2wm:c-R-thumbs-winfo))
       (buf (or prev-selected-buffer
                (e2wm:history-get-main-buffer))))
    (when (e2wm:history-recordable-p prev-selected-buffer)
      (e2wm:history-add prev-selected-buffer))
    (wlf:set-buffer code-wm 'main buf)
    code-wm))

(defvar e2wm:dp-R-thumbs-minor-mode-map
  (e2wm:define-keymap
   '(("prefix p" . e2wm:dp-code-popup-messages)
     ("C-c    p" . e2wm:dp-code-popup-messages)
     ("q"        . e2wm:dp-R-thumbs-revert))
   e2wm:prefix-key))

(defun e2wm:dp-R-thumbs ()
  (interactive)
  (e2wm:pst-change 'R-thumbs))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;perspective definition : Common Commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:start-R-code ()
  "English:
start window management with R code
Japanese:
e2wmをRで開始する。"
  (interactive)
  (cond
   (e2wm:pst-minor-mode
    (message "E2wm has already started."))
   (t
    (run-hooks 'e2wm:pre-start-hook)
    (e2wm:frame-param-set 
     'e2wm-save-window-configuration 
     (current-window-configuration))
    (e2wm:history-add-loaded-buffers) ; 全部つっこむ
    (e2wm:history-save-backup nil)
    (e2wm:pst-minor-mode 1)
    (ad-activate-regexp "^e2wm:ad-debug" t) ; debug
    (e2wm:pstset-defaults) ; 全部使う
    (e2wm:pst-set-prev-pst nil)
    (e2wm:pst-change 'R-code) 
    (e2wm:menu-define)
    (run-hooks 'e2wm:post-start-hook))))

(defun e2wm:dp-R-code-popup (buf)
  ;;とりあえず全部subで表示してみる
  (let ((cb (current-buffer)))
    (e2wm:message "#DP CODE popup : %s (current %s / backup %s)" 
                  buf cb e2wm:override-window-cfg-backup))
  (let ((buf-name (buffer-name buf))
        (wm (e2wm:pst-get-wm)))
    (cond
     ((e2wm:history-recordable-p buf)
      (e2wm:pst-show-history-main)
      ;;記録対象なら履歴に残るのでupdateで表示を更新させる
      t)
     ((and e2wm:override-window-cfg-backup
           (eq (selected-window) (wlf:get-window wm 'sub)))
      ;;現在subならmainに表示しようとする
      ;;minibuffer以外の補完バッファは動きが特殊なのでbackupをnilにする
      (setq e2wm:override-window-cfg-backup nil)
      ;;一時的に表示するためにset-window-bufferを使う
      ;;(prefix) C-lなどで元のバッファに戻すため
      (set-window-buffer (wlf:get-window wm 'main) buf)
      t)
     ((string= "*R*" buf-name)
      (wlf:set-buffer (e2wm:pst-get-wm) 'proc buf)
      t)
     ((string-match (or "*R object*" "^*help") buf-name)
      (e2wm:dp-code-popup-sub buf)
      (e2wm:start-close-popup-window-timer)
      t)
     ((string-match "\\.rt$" buf-name)
      (e2wm:dp-code-popup-sub buf)
      (e2wm:start-close-popup-window-timer)
      (select-window (wlf:get-window (e2wm:pst-get-wm) 'sub))
      t)
     ((and e2wm:c-code-show-main-regexp
           (string-match  
            e2wm:c-code-show-main-regexp
            buf-name))
      (e2wm:pst-buffer-set 'main buf t)
      t)
     ((and image-dired-display-image-buffer
           (string-match  
            image-dired-display-image-buffer 
            buf-name))
      (e2wm:pst-buffer-set 'R-thumbs-view buf t)
      t)
     (t
      (e2wm:dp-code-popup-sub buf)
      t))))

;;ess-transcript-modeで新たにbufferを作成
;;(inferior-R-input-sender nil "page(iris)")

(defun e2wm:dp-R-navi-dired-command ()
  (interactive)
  (wlf:select (e2wm:pst-get-wm) 'R-dired))

(defun e2wm:dp-R-navi-graphics-command ()
  (interactive)
  (wlf:select (e2wm:pst-get-wm) 'R-graphics))

(defun e2wm:dp-R-navi-grlist-command ()
  (interactive)
  (wlf:select (e2wm:pst-get-wm) 'R-graphics-list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-dired plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:rdired-buffer " *WM:Rdired*"
  "Name of buffer for displaying R objects.")
(defvar e2wm:def-plugin-R-dired-timer-handle nil "timer object")
(defvar e2wm:rdired-tmp-buffer " *tmp-Rdired*"
  "Name of buffer for temporal R objects.")
(defvar e2wm:rdired-tmp-str  nil
  "Name of string for temporal R objects.")
(defvar e2wm:rdired-str  nil
  "Name of string for temporal R objects.")

(e2wm:plugin-register
 'R-dired
 "R-Dired"
 'e2wm:def-plugin-R-dired)

(defun e2wm:def-plugin-R-dired (frame wm winfo)
  (let ((buf (get-buffer-create e2wm:rdired-buffer))
        (get-buffer-create e2wm:rdired-tmp-buffer))
    (with-current-buffer buf
      (unwind-protect
          (progn
            ;;(e2wm:def-plugin-R-revert)
            (setq buffer-read-only nil)
            (e2wm:def-plugin-R-dired-mode)
            (setq header-line-format "R dired"))
        (setq mode-line-format 
              '("-" mode-line-mule-info
                " " mode-line-position "-%-"))
        (setq buffer-read-only t)))
    
    (unless e2wm:def-plugin-R-dired-timer-handle
      (setq e2wm:def-plugin-R-dired-timer-handle
            (run-at-time 5 5
                         'e2wm:def-plugin-R-dired-timer)))
    (wlf:set-buffer wm (wlf:window-name winfo) buf)))

(defun e2wm:def-plugin-R-dired-timer ()
  ;;bufferが死んでいれば、タイマー停止
  ;;bufferが生きていれば更新実行
  (let ((buf (get-buffer e2wm:rdired-buffer)))
    (if (and
         (e2wm:managed-p)
         buf (buffer-live-p buf) 
         (get-buffer-window buf))
        (when (= 0 (minibuffer-depth))
          (e2wm:def-plugin-R-timer-revert))
      (when e2wm:def-plugin-R-dired-timer-handle
        (cancel-timer e2wm:def-plugin-R-dired-timer-handle)
        (setq e2wm:def-plugin-R-dired-timer-handle nil)
        (when buf (kill-buffer buf))
        (e2wm:message "WM: 'R-dired' update timer stopped.")))))

(defvar e2wm:def-plugin-R-dired-mode-map
  (e2wm:define-keymap 
   '(("d"   . ess-rdired-delete)
     ("u"   . ess-rdired-undelete)
     ("x"   . ess-rdired-expunge)
     ("v"   . e2wm:def-plugin-R-dired-view)
     ("P"   . ess-rdired-plot)
     ("s"   . ess-rdired-sort)
     ("y"   . ess-rdired-type)
     ("j"   . ess-rdired-next-line)
     ("k"   . ess-rdired-previous-line)
     ("n"   . ess-rdired-next-line)
     ("p"   . ess-rdired-previous-line)  
     ("C-n" . ess-rdired-next-line)
     ("C-p" . ess-rdired-previous-line)    
     ("g"   . revert-buffer)
     ("q"   . e2wm:pst-window-select-main-command))))

(defun e2wm:def-plugin-R-dired-mode ()
  (kill-all-local-variables)
  (make-local-variable 'revert-buffer-function)
  (setq revert-buffer-function 'e2wm:def-plugin-R-revert-buffer)
  (use-local-map e2wm:def-plugin-R-dired-mode-map)
  (setq major-mode 'e2wm:def-plugin-R-dired-mode)
  (setq mode-name (concat "RDired " ess-local-process-name)))

(defun e2wm:def-plugin-R-dired-view ()
  "View the object at point."
  (interactive)
  (let ((objname (ess-rdired-object)))
    (ess-execute (ess-rdired-get objname)
                 nil "R view" )
    (e2wm:pst-window-select 'R-dired)))

(defun e2wm:def-plugin-R-timer-revert ()
  (let ((buf (get-buffer e2wm:rdired-buffer)))
    (when (or (string= mode-name "ESS[S]")
              (string= (buffer-name (current-buffer)) "*R*"))
      (e2wm:def-plugin-R-revert))))

(defun e2wm:def-plugin-R-revert-buffer (ignore noconfirm)
  "Update the buffer list (in case object list has changed).
Arguments IGNORE and NOCONFIRM currently not used."
  (e2wm:def-plugin-R-revert))

(defun e2wm:def-plugin-R-revert()
  (interactive)
  (let* ((buf (get-buffer-create e2wm:rdired-buffer)))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (e2wm:def-plugin-R-dired-mode)
      (setq header-line-format "R dired")
      (setq mode-line-format 
            '("-" mode-line-mule-info
              " " mode-line-position "-%-"))
      (e2wm:def-plugin-R-execute ess-rdired-objects)
      (unless (string= e2wm:rdired-tmp-str (buffer-string))
        (erase-buffer)
        (e2wm:message "===== Rdired timer is alive!! ==== %s" 
                      (format-time-string "%H:%M:%S" (current-time)))
        (insert e2wm:rdired-tmp-str)
        (setq e2wm:rdired-str (buffer-string))
        (setq ess-rdired-sort-num 1)
        (ess-rdired-insert-set-properties 
         (save-excursion
           (goto-char (point-min))
           (forward-line 1)
           (point))
         (point-max))
        (wlf:set-buffer (e2wm:pst-get-wm) 'R-dired (get-buffer e2wm:rdired-buffer)))
      (setq buffer-read-only t))))

(defun e2wm:def-plugin-R-execute (command)
  (ess-make-buffer-current)
  (let ((the-command (concat command "\n"))
        (buff-name e2wm:rdired-tmp-buffer))
    (let ((buff (ess-create-temp-buffer buff-name)))
      (save-excursion
        (set-buffer (window-buffer (wlf:get-window (e2wm:pst-get-wm) 'main)))
        (ess-command the-command (get-buffer buff-name))
        (set-buffer buff)
        (goto-char (point-min))
        (delete-char (* (1- (length (split-string ess-rdired-objects "\n"))) 2))
        (setq e2wm:rdired-tmp-str (buffer-string))
        (setq ess-local-process-name ess-current-process-name)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-graphics plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:def-plugin-R-graphics-dir ".Rgraphics/")
(defvar e2wm:def-plugin-R-graphics-thumnail-dir ".Rthumnail/")
(defvar e2wm:def-plugin-R-graphics-dir-ok nil)

(defun e2wm:def-plugin-R-graphics-fix-directory (dir-arg)
  ;;バッファのカレントディレクトリに保存先ディレクトリを作る
  ;;一応作って良いかどうか聞く
  (let* ((img-dir dir-arg)
         (main-dir 
          (file-name-directory 
           (buffer-file-name 
            (wlf:get-buffer (e2wm:pst-get-wm) 'main))))
         (dir (concat main-dir img-dir)))
    (unless (file-directory-p dir)
      (when (and (string= mode-name "ESS[S]")
                 (or e2wm:def-plugin-R-graphics-dir-ok 
                     (y-or-n-p 
                      (format "Image directory [%s] not found. Create it ?" 
                              dir))))
        (make-directory dir))
      (unless (file-directory-p dir)
        (error "Could not create a image directory.")))
    dir))

(defvar e2wm:R-graphics-buffer " *WM:R-graphics*"
  "Name of buffer for displaying R graphics.")

(e2wm:plugin-register
 'R-graphics
 "R-graphics"
 'e2wm:def-plugin-R-graphics)

(defun e2wm:def-plugin-R-graphics (frame wm winfo)
  (let ((buf (get-buffer-create e2wm:R-graphics-buffer)))
    (with-current-buffer buf
      (unwind-protect
          (progn
            (setq buffer-read-only nil)
            (setq mode-line-format 
                  '("-" mode-line-mule-info
                    " " mode-line-position "-%-"))  
            ;;(erase-buffer)
            ;;(insert "\n\n\n\n\n\n          no image")
            (setq header-line-format "R graphics"))
        (setq buffer-read-only t)))
    (wlf:set-buffer wm (wlf:window-name winfo) buf)))

(defun e2wm:def-plugin-R-graphics-draw ()
  (interactive)
  (let* ((start (inlineR-get-start))
         (end (inlineR-get-end))
         (fun (buffer-substring start end))
         (format "png")
         (filename (read-string "filename: " nil))
         (file (concat 
                (e2wm:def-plugin-R-graphics-fix-directory
                 e2wm:def-plugin-R-graphics-dir)
                filename "." format)))
    (e2wm:def-plugin-R-graphics-execute file format fun)
    (e2wm:def-plugin-R-graphics-polling file filename format)))

(defun e2wm:def-plugin-R-graphics-timestamp-draw ()
  (interactive)
  (let* ((start (inlineR-get-start))
         (end (inlineR-get-end))
         (fun (buffer-substring start end))
         (format "png")
         (filename (format-time-string "%y%m%d-%H-%M-%S"))
         (file (concat 
                (e2wm:def-plugin-R-graphics-fix-directory
                 e2wm:def-plugin-R-graphics-dir)
                filename "." format)))
    (e2wm:def-plugin-R-graphics-execute file format fun)
    (e2wm:def-plugin-R-graphics-polling file filename format)))

(defun e2wm:def-plugin-R-graphics-execute (file format fun)
  (cond
       ((string= format "svg")  
        (ess-command 
         (concat 
          "svg(\""  file "." format "\", 3, 3)\n"
          fun "\n"
          "dev.off()\n")))
       ((string= format "png") (ess-command
           (concat
            "png(width = 800, height = 800, \"" file  "\", type=\"" "cairo" "\", bg =\"white\" )\n"
            fun "\n"
            "dev.off()\n")))
       ((string= format "jpeg") (ess-command
           (concat
            "jpeg(width = 800, height = 800, \""  file  "\", type=\"" "cairo" "\", bg =\"white\" )\n"
            fun "\n"
            "dev.off()\n")))
       (t (ess-command
           (concat
            "Cairo(800, 800, \"" file "." format "\", type=\"" "cairo" "\", bg =\"white\" )\n"
            fun "\n"
            "dev.off()\n")))))

(lexical-let ((count 0))
  (defun e2wm:def-plugin-R-graphics-polling (file filename format)
    (if (image-type-from-file-header file)
        (progn
          (message "output image complete!!")
          (setq count 0)
          ;;(message "file type check complete!!")
          (e2wm:def-plugin-R-graphics-img-fit file filename format t))
      (progn
        (if   (> count 11)
            (progn
              (setq count 0)
              ;;(message "file type check complete!!")
              (e2wm:def-plugin-R-graphics-img-fit file filename format t)
              (cancel-timer e2wm:def-plugin-R-graphics-timer))
          (progn
            (setq count (1+ count))
            (message (concat "output image." (make-string count ?.)))    
            ;;(message "number %d" count)
            (setq e2wm:def-plugin-R-graphics-timer
                  (run-at-time 1 nil
                               'e2wm:def-plugin-R-graphics-polling file filename format))))))))


(defun e2wm:def-plugin-R-graphics-img-fit (file filename format &optional arg quiet)
  "Japanese:
ウィンドウの大きさに合わせて画像をリサイズする。
引数 argがnonnilだと縦横の比率を保持しない。
English:
Resize image to current window size.
With prefix arg don't preserve the aspect ratio."
  (lexical-let ((base file)
                (thumnail (concat 
                           (e2wm:def-plugin-R-graphics-fix-directory
                            e2wm:def-plugin-R-graphics-thumnail-dir)
                           filename "." format))
                (noverbose quiet))
    (let* ((buf (get-buffer e2wm:R-graphics-buffer))
           (edges  (window-inside-pixel-edges
                    (wlf:get-window (e2wm:pst-get-wm) 'R-graphics)))
           (width  (- (nth 2 edges) (nth 0 edges)))
           (height (- (nth 3 edges) (nth 1 edges))))
      (apply #'start-process "resize-image" nil "convert"
             (list "-resize"
                   (concat (format "%dx%d" width height)
                           (and arg "!"))
                   base thumnail))
      (set-process-sentinel
       (get-process "resize-image")
       #'(lambda (process event)
           (kill-buffer e2wm:R-graphics-buffer)
           (with-current-buffer 
               (find-file-noselect thumnail)
             (rename-buffer e2wm:R-graphics-buffer)
             (wlf:set-buffer (e2wm:pst-get-wm) 'R-graphics (current-buffer))
             (setq mode-line-format 
                   '("-" mode-line-mule-info
                     " " mode-line-position "-%-"))  
             (setq header-line-format "R graphics"))
           (e2wm:pst-window-select 'main)
           (unless noverbose
             (message "Ok %s on %s %s"
                      process
                      (file-name-nondirectory
                       thumnail)
                      event)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-graphics-list plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:R-grlist-buffer " *WM:R-graphics-list*"
  "Name of buffer for displaying R objects.")
(defvar e2wm:def-plugin-R-grlist-timer-handle nil "[internal use]")
(defvar e2wm:R-grlist-tmp-list nil "Name of list for files")

(e2wm:plugin-register
 'R-graphics-list
 "R-graphics-list"
 'e2wm:def-plugin-R-grlist)

(defvar e2wm:def-plugin-R-grlist-mode-map
  (e2wm:define-keymap 
   '(("k"   . ess-rdired-previous-line)
     ("j"   . ess-rdired-next-line)
     ("p"   . ess-rdired-previous-line)
     ("n"   . ess-rdired-next-line)
     ("C-p" . ess-rdired-previous-line)
     ("C-n" . ess-rdired-next-line)
     ("d"   . e2wm:def-plugin-R-grlist-delete)
     ("u"   . e2wm:def-plugin-R-grlist-undelete)
     ("D"   . e2wm:def-plugin-R-grlist-all-delete)
     ("U"   . e2wm:def-plugin-R-grlist-all-undelete)
     ("v"   . e2wm:def-plugin-R-grlist-view)
     ("C-m" . e2wm:def-plugin-R-grlist-view)
     ("x"   . e2wm:def-plugin-R-grlist-expunge)
     ("q"   . e2wm:pst-window-select-main-command)
     ("g"   . e2wm:def-plugin-R-grlist-update))))

(define-derived-mode
  e2wm:def-plugin-R-grlist-mode
  fundamental-mode
  "R graphics list")

(defun e2wm:def-plugin-R-grlist (frame wm winfo)
  ;;bufferが生きていればバッファを表示するだけ（タイマーに任せる）
  ;;bufferが無ければ初回更新してタイマー開始する
  (let ((buf (get-buffer-create e2wm:R-grlist-buffer)))
    (setq e2wm:R-grlist-tmp-list nil)
    (with-current-buffer buf
      (unwind-protect
          (progn
            (setq buffer-read-only t)
            (e2wm:def-plugin-R-grlist-mode)
            (setq header-line-format "R graphics list")
            (setq mode-line-format 
                  '("-" mode-line-mule-info
                    " " mode-line-position "-%-")))))
    (unless e2wm:def-plugin-R-grlist-timer-handle
      (setq e2wm:def-plugin-R-grlist-timer-handle
            (run-at-time 6 6
                         'e2wm:def-plugin-R-grlist-timer)))
    (wlf:set-buffer wm (wlf:window-name winfo) buf)))

(defun e2wm:def-plugin-R-grlist-timer ()
  ;;bufferが死んでいれば、タイマー停止
  ;;bufferが生きていれば更新実行
  (let ((buf (get-buffer e2wm:R-grlist-buffer)))
    (if (and (e2wm:managed-p) buf (buffer-live-p buf) 
             (get-buffer-window buf))
        (when (= 0 (minibuffer-depth))
          (e2wm:def-plugin-R-grlist-update))
      (when e2wm:def-plugin-R-grlist-timer-handle
        (cancel-timer e2wm:def-plugin-R-grlist-timer-handle)
        (setq e2wm:def-plugin-R-grlist-timer-handle nil)
        (when buf (kill-buffer buf))
        (e2wm:message "WM: 'R-graphics-list' update timer stopped.")))))

(defun e2wm:def-plugin-R-grlist-update ()
  (interactive)
  (let* ((buf (get-buffer-create e2wm:R-grlist-buffer))
         (dir (e2wm:def-plugin-R-graphics-fix-directory
               e2wm:def-plugin-R-graphics-thumnail-dir))
         (flist (directory-files dir)))
    (when (buffer-file-name (current-buffer))
      (unless (equal flist e2wm:R-grlist-tmp-list)
        (with-current-buffer buf
          (unwind-protect
              (progn
                (e2wm:message "===== Rgrlist timer is alive!! ==== %s" 
                              (format-time-string "%H:%M:%S" (current-time)))
                (setq buffer-read-only nil)
                (erase-buffer)
                (dolist (i flist)
                  (unless (or
                           (string= i  ".")
                           (string= i  ".." ))
                    (insert (concat "  " i "\n"))))
                (backward-char 1))
            (setq buffer-read-only t))))
      (setq e2wm:R-grlist-tmp-list flist))))

(defun e2wm:def-plugin-R-grlist-view ()
  (interactive)
  (let*
      ((dir (e2wm:def-plugin-R-graphics-fix-directory 
             e2wm:def-plugin-R-graphics-thumnail-dir))
       (file (e2wm:def-plugin-R-grlist-object))
       (fp (concat dir file))
       (buf (find-file-noselect fp)))
    (when (get-buffer e2wm:R-graphics-buffer)
      (kill-buffer e2wm:R-graphics-buffer))
    (set-buffer buf)
    (setq mode-line-format 
          '("-" mode-line-mule-info
            " " mode-line-position "-%-"))
    (rename-buffer e2wm:R-graphics-buffer)
    (wlf:set-buffer (e2wm:pst-get-wm) 'R-graphics (current-buffer))))

(defun e2wm:def-plugin-R-grlist-object ()
  "Return name of file on current line."
  (save-excursion
    (beginning-of-line)
    (forward-char 2)
    (let (beg)
      (setq beg (point))
      (search-forward "\n")
      (backward-char 1)
      (buffer-substring-no-properties beg (point)))))

(defun e2wm:def-plugin-R-grlist-delete (arg)
  "Mark the current (or next ARG) file for deletion."
  (interactive "p")
  (e2wm:def-plugin-R-grlist-mark "D" arg nil))

(defun e2wm:def-plugin-R-grlist-undelete (arg)
  "Unmark the current (or next ARG) file for deletion."
  (interactive "p")
  (e2wm:def-plugin-R-grlist-mark " " arg nil))

(defun e2wm:def-plugin-R-grlist-all-delete (arg)
  "Mark the current (or next ARG) objects for deletion."
  (interactive "p")
  (e2wm:def-plugin-R-grlist-mark "D" arg t))

(defun e2wm:def-plugin-R-grlist-all-undelete (arg)
  "Unmark the current (or next ARG) objects.
If point is on first line, all objects will be unmarked."
  (interactive "p")
  (e2wm:def-plugin-R-grlist-mark " " arg t))

(defun e2wm:def-plugin-R-grlist-mark (mark-char arg all)
  "English:
Mark the file, using MARK-CHAR,  on current line (or next ARG lines). 
ALL is non-nil , all file mark.
Japanese:
ファイルにマークをつける。ALLがnon-nilの時は全てのファイルにマークがつけられる。"
  (let ((buffer-read-only nil)
        move)
    (when all
	  (setq move (point))
	  (setq arg (count-lines (point) (point-max))))
    (while (and (> arg 0) (not (eobp)))
      (setq arg (1- arg))
      (beginning-of-line)
      (progn
        (insert mark-char)
        (delete-char 1)
        (forward-line 1)))
    (if move
        (goto-char move))))

(defun e2wm:def-plugin-R-grlist-expunge ()
  "English:
Delete the marked file.
User is queried first to check that objects should really be deleted.
Japanese:
マークされたファイルを削除する。"
  (interactive)
  (let ((flist nil)
        (count 0)
        (buffer-read-only nil))
    (save-excursion
      (goto-char (point-min))
      ;;(forward-line 1)
      (while (< (count-lines (point-min) (point))
                (count-lines (point-min) (point-max)))
        (beginning-of-line)
        (if (looking-at "^D ")
            (progn
              (setq count (1+ count))
              (push (e2wm:def-plugin-R-grlist-object) flist)
              (forward-line 1))
          (forward-line 1))))
    (if (yes-or-no-p
         (format "Delete %d %s " count
                 (if (> count 1) "objects" "object")))
        (progn
          (save-excursion
            (goto-char (point-min))
            (while (< (count-lines (point-min) (point))
                      (count-lines (point-min) (point-max)))
              (beginning-of-line)
              (if (looking-at "^D ")
                  (kill-whole-line)
                (forward-line 1))))
          (dolist (i flist)
            (delete-file
             (concat
              (e2wm:def-plugin-R-graphics-fix-directory
               e2wm:def-plugin-R-graphics-thumnail-dir) i))))
      ;; else nothing to delete
      (message "no objects set to delete"))))

;;; open / バッファ表示・コマンド実行
;;; 指定のバッファを表示バッファの存在をチェックして、無かったらコマンドを実行
;;;--------------------------------------------------

(defun e2wm:def-plugin-R-open (frame wm winfo)
  (let* ((plugin-args (wlf:window-option-get winfo :plugin-args))
         (buffer-name (plist-get plugin-args ':buffer))
         (command (plist-get plugin-args ':command)) buf)
    (unless (and command buffer-name)
      (error "e2wm:plugin open: arguments can not be nil. Check the options."))
    (setq buf (get-buffer buffer-name))
    (unless buf
      (with-selected-window (wlf:get-window wm (wlf:window-name winfo))
        (setq buf (funcall command))))
    (when buf
      (with-current-buffer buf
        (unwind-protect
            (progn
              (setq buffer-read-only nil)
              (setq mode-line-format 
                    '("-" mode-line-mule-info
                      " " mode-line-position "-%-")))
          (setq buffer-read-only nil)))
      (wlf:set-buffer wm (wlf:window-name winfo) buf))))
(e2wm:plugin-register 
 'R-open
 "Open R interpreter"
 'e2wm:def-plugin-R-open)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-thumbs plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:def-plugin-R-thumbs (frame wm winfo)
  (let ((buf 
         (dired (e2wm:def-plugin-R-graphics-fix-directory
                 e2wm:def-plugin-R-graphics-dir))))
    (dired-mark-files-regexp (image-file-name-regexp))
    (let ((files (dired-get-marked-files)))
      (if (or (<= (length files) image-dired-show-all-from-dir-max-files)
              (and (> (length files) image-dired-show-all-from-dir-max-files)
                   (y-or-n-p
                    (format
                     "Directory contains more than %d image files.  Proceed? "
                     image-dired-show-all-from-dir-max-files))))
          (progn
            (image-dired-display-thumbs)
            (wlf:set-buffer wm
                            (wlf:window-name winfo)
                            (get-buffer-create image-dired-thumbnail-buffer)))
        (message "Cancelled.")))))

(e2wm:plugin-register
 'R-thumbs
 "Draw R graphics thumbnail"
 'e2wm:def-plugin-R-thumbs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-thumbs-view plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:def-plugin-R-thumbs-view (frame wm winfo)
  (wlf:set-buffer
   wm
   (wlf:window-name winfo) 
   (get-buffer-create image-dired-display-image-buffer)))

(defun e2wm:dp-R-thumbs-revert ()
  (interactive)
  (e2wm:pst-change-prev)
  (wlf:set-buffer
   (e2wm:pst-get-wm) 
   'main
   (e2wm:history-get-main-buffer)))

(e2wm:plugin-register 
 'R-thumbs-view
 "Draw R graphics"
 'e2wm:def-plugin-R-thumbs-view)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / R-thumbs-dired plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:def-plugin-R-thumbs-dired (frame wm winfo) 
  (let ((dbuf (dired-noselect default-directory)))
    (with-current-buffer dbuf (revert-buffer))
    (wlf:set-buffer wm (wlf:window-name winfo) dbuf)))

(e2wm:plugin-register
 'R-thumbs-dired
 "Graphics directory"
 'e2wm:def-plugin-R-thumbs-dired)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Internal / popup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:close-popup-window-timer nil
  "Timer of closing the popup window.")

(defun e2wm:start-close-popup-window-timer ()
  (or e2wm:close-popup-window-timer
      (setq e2wm:close-popup-window-timer
            (run-with-timer popwin:close-popup-window-timer-interval
                            popwin:close-popup-window-timer-interval
                            'e2wm:close-popup-window-timer))))

(defun e2wm:close-popup-window-timer ()
  (condition-case var
      (e2wm:close-popup-window-if-necessary
       (e2wm:should-close-popup-window-p))
    (error (message "e2wm:close-popup-window-timer: error: %s" var))))

(defun e2wm:close-popup-window-if-necessary (&optional force)
  "Close the popup window if another window has been selected. If
FORCE is non-nil, this function tries to close the popup window
immediately if possible, and the lastly selected window will be
selected again."
  (when e2wm:pst-minor-mode
    (when (wlf:get-window (e2wm:pst-get-wm) 'sub)
      (let* ((window (selected-window))
             (minibuf-window-p (eq window (minibuffer-window)))
             (other-window-selected
              (and (not (eq window (wlf:get-window (e2wm:pst-get-wm) 'sub)))
                   (not (eq window (wlf:get-window (e2wm:pst-get-wm) 'main))))))
        (when (and (not minibuf-window-p)
                   (or force other-window-selected))
          (wlf:hide (e2wm:pst-get-wm) 'sub)
          (e2wm:pst-window-select-main-command)
          (e2wm:stop-close-popup-window-timer))))))

(defun e2wm:should-close-popup-window-p ()
  "Return t if popwin should close the popup window
immediately. It might be useful if this is customizable
function."
  (if e2wm:pst-minor-mode
      (and (wlf:get-window (e2wm:pst-get-wm) 'sub)
           (and (eq last-command 'keyboard-quit)
                (eq last-command-event ?\C-g)))
    nil))

(defun e2wm:stop-close-popup-window-timer ()
  (when e2wm:close-popup-window-timer
    (cancel-timer e2wm:close-popup-window-timer)
    (setq e2wm:close-popup-window-timer nil)))

(defun e2wm:dp-code-popup-messages ()
  (interactive)
  (e2wm:dp-code-popup-sub "*Messages*")
  (e2wm:start-close-popup-window-timer)
  (e2wm:pst-window-select-main-command))

(provide 'e2wm-R)

;;; e2wm-R.el ends here
