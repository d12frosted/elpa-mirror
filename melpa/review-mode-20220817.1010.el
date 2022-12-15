;;; review-mode.el --- major mode for ReVIEW -*- lexical-binding: t -*-
;; Copyright 2007-2022 Kenshi Muto <kmuto@kmuto.jp>

;; Author: Kenshi Muto <kmuto@kmuto.jp>
;; URL: https://github.com/kmuto/review-el

;;; Commentary:

;; "Re:VIEW" text editing mode
;;
;; License:
;;   GNU General Public License version 3 (see COPYING) or any later version
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;
;; C-c C-c ビルドを実行する。初回実行時は
;;         `review-default-compile-command' (デフォルト値 "rake pdf")
;;         が呼ばれ2回め以降は前回実行時のコマンドが履歴に登録される
;;
;; C-c C-a ユーザーから編集者へのメッセージ擬似マーカー
;; C-c C-k ユーザー注釈の擬似マーカー
;; C-c C-d DTP担当へのメッセージ擬似マーカー
;; C-c C-r 参照先をあとで確認する擬似マーカー
;; C-c !   作業途中の擬似マーカー
;; C-c C-t 1 作業者名の変更
;; C-c C-t 2 DTP担当の変更
;;
;; C-c C-e 選択範囲をブロックタグで囲む。選択されていない場合は新規に挿入する。新規タブで補完可
;; C-u C-c C-e 直前のブロックタグの名前を変更する
;; C-c C-o 選択範囲を //beginchild 〜 //endchild で囲む
;; C-c C-f C-f 選択範囲をインラインタグで囲む。選択されていない場合は新規に挿入する。タブで補完可
;; C-c C-f b 太字タグ(@<b>)で囲む
;; C-c C-f C-b 同上
;; C-c C-f k キーワードタグ(@<kw>)で囲む
;; C-c C-f C-k キーワードタグ(@<kw>)で囲む
;; C-c C-f i イタリックタグ(@<i>)で囲む
;; C-c C-f C-i 同上
;; C-c C-f e 同上 (review-use-em tの場合は@<em>)
;; C-c C-f C-e 同上 (review-use-em tの場合は@<em>)
;; C-c C-f s 強調タグ(@<strong>)で囲む
;; C-c C-f C-s 同上
;; C-c C-f t 等幅タグ(@<tt>)で囲む
;; C-c C-f C-t 同上
;; C-c C-f u 同上
;; C-c C-f C-u 同上
;; C-c C-f a 等幅イタリックタグ(@<tti>)で囲む
;; C-c C-f C-a 同上
;; C-c C-f C-h ハイパーリンクタグ(@<href>)で囲む
;; C-c C-f C-c コードタグ(@<code>)で囲む
;; C-c C-f m 数式タグ(@<m>)で囲む
;; C-c C-f C-m 同上
;; C-c C-f C-n 出力付き索引化(@<idx>)する
;;
;; C-c C-p =見出し挿入(レベルを指定)
;; C-c C-b 吹き出しを入れる
;; C-c CR  隠し索引(@<hidx>)を入力して入れる
;; C-c C-w 選択範囲を隠し索引(@<hidx>)にして範囲の前に入れる
;; C-c ,   @<br>{}を挿入
;; C-c <   rawのHTML開きタグを入れる
;; C-c >   rawのHTML閉じタグを入れる
;;
;; C-c 1   近所のURIを検索してブラウザを開く
;; C-c 2   範囲をURIとしてブラウザを開く
;; C-c (   全角(
;; C-c 8   同上
;; C-c )   全角)
;; C-c 9   同上
;; C-c [   【
;; C-c ]    】
;; C-c -    全角ダーシ
;; C-c +    全角＋
;; C-c *    全角＊
;; C-c /    全角／
;; C-c =    全角＝
;; C-c \    ￥
;; C-c SP   全角スペース
;; C-c :    全角：

;;; Code:

(declare-function skk-mode "skk-mode")
(declare-function whitespace-mode "whitespace-mode")

(defconst review-version "1.21"
  "Re:VIEWモードバージョン")

;;;; Custom Variables

(defgroup review-mode nil
  "Major mode for editing text files in Re:VIEW format."
  :prefix "review-"
  :group 'wp)

(defcustom review-mode-hook nil
  "Normal hook when entering `review-mode'."
  :type 'hook
  :group 'review-mode)

(defcustom review-default-compile-command "rake pdf"
  "Default compile command."
  :type 'string
  :group 'review-mode)

;;;; Mode Map

(defvar review-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-e" 'review-block-region)
    (define-key map "\C-c\C-o" 'review-child-region)
    (define-key map "\C-c\C-f\C-f" 'review-inline-region)
    (define-key map "\C-c\C-fb" 'review-bold-region)
    (define-key map "\C-c\C-fa" 'review-underline-italic-region)
    (define-key map "\C-c\C-fi" 'review-italic-region)
    (define-key map "\C-c\C-fe" 'review-em-region)
    (define-key map "\C-c\C-fs" 'review-strong-region)
    (define-key map "\C-c\C-ft" 'review-underline-region)
    (define-key map "\C-c\C-fu" 'review-underline-region)
    (define-key map "\C-c\C-fk" 'review-keyword-region)
    (define-key map "\C-c\C-fm" 'review-math-region)
    (define-key map "\C-c\C-fn" 'review-index-region)
    (define-key map "\C-c\C-f\C-b" 'review-bold-region)
    (define-key map "\C-c\C-f\C-i" 'review-italic-region)
    (define-key map "\C-c\C-f\C-e" 'review-em-region)
    (define-key map "\C-c\C-f\C-a" 'review-underline-italic-region)
    (define-key map "\C-c\C-f\C-s" 'review-strong-region)
    (define-key map "\C-c\C-f\C-t" 'review-underline-region)
    (define-key map "\C-c\C-f\C-u" 'review-underline-region)
    (define-key map "\C-c\C-f\C-k" 'review-keyword-region)
    (define-key map "\C-c\C-f\C-h" 'review-hyperlink-region)
    (define-key map "\C-c\C-f\C-c" 'review-code-region)
    (define-key map "\C-c\C-f\C-m" 'review-math-region)
    (define-key map "\C-c\C-f\C-n" 'review-index-region)
    (define-key map "\C-c!" 'review-kokomade)
    (define-key map "\C-c\C-a" 'review-normal-comment)
    (define-key map "\C-c\C-b" 'review-balloon-comment)
    (define-key map "\C-c\C-c" 'review-compile)
    (define-key map "\C-c\C-d" 'review-dtp-comment)
    (define-key map "\C-c\C-k" 'review-tip-comment)
    (define-key map "\C-c\C-r" 'review-reference-comment)
    (define-key map "\C-c\C-m" 'review-insert-index)
    (define-key map "\C-c\C-w" 'review-insert-index)
    (define-key map "\C-c\C-p" 'review-header)
    (define-key map "\C-c," 'review-br)
    (define-key map "\C-c<" 'review-opentag)
    (define-key map "\C-c>" 'review-closetag)

    (define-key map "\C-c1" 'review-search-uri)
    (define-key map "\C-c2" 'review-search-uri2)

    (define-key map "\C-c8" 'review-zenkaku-mapping-lparenthesis)
    (define-key map "\C-c\(" 'review-zenkaku-mapping-lparenthesis)
    (define-key map "\C-c9" 'review-zenkaku-mapping-rparenthesis)
    (define-key map "\C-c\)" 'review-zenkaku-mapping-rparenthesis)
    (define-key map "\C-c\[" 'review-zenkaku-mapping-langle)
    (define-key map "\C-c\]" 'review-zenkaku-mapping-rangle)
    (define-key map "\C-c-" 'review-zenkaku-mapping-minus)
    (define-key map "\C-c+" 'review-zenkaku-mapping-plus)
    (define-key map "\C-c*" 'review-zenkaku-mapping-asterisk)
    (define-key map "\C-c/" 'review-zenkaku-mapping-slash)
    (define-key map "\C-c\\" 'review-zenkaku-mapping-yen)
    (define-key map "\C-c=" 'review-zenkaku-mapping-equal)
    (define-key map "\C-c " 'review-zenkaku-mapping-space)
    (define-key map "\C-c:" 'review-zenkaku-mapping-colon)

    (define-key map "\C-c\C-t1" 'review-change-mode)
    (define-key map "\C-c\C-t2" 'review-change-dtp)

    (define-key map "\C-c\C-y" 'review-index-change)
    map)
  "Keymap for `revew-mode'.")


;;;; Outline & Imenu support
(defvar review-section-alist
  '(("=" . 0)
    ("==" . 1)
    ("===" . 2)
    ("====" . 3)
    ("=====" . 4)))

(defvar review-outline-regexp
  "^\\(=\\{1,5\\}\\)\\(\\[.+\\]\\)?\\({.+}\\)? "
  "The regexp matches the outline of Re:VIEW format.

This matches =[nonum], ==[column]{label}, and ==={label} etc.
[CAUTION] It also matches the expression ={label}, which is not
allowed in Re:VIEW format.")

;; This function was originally derived from `latex-outline-level'
;; from tex-mode.el.
(defun review-outline-level ()
  "Return the outline level."
  (interactive)
  (if (looking-at review-outline-regexp)
      (1+ (or (cdr (assoc (match-string 1) review-section-alist)) -1))
    1000))

;; This function was originally derived from `tex-current-defun-name'
;; from tex-mode.el.
(defun review-current-defun-name ()
  "Return the name of the Re:VIEW section or chapter at point, or nil."
  (save-excursion
    (when (re-search-backward review-outline-regexp nil t)
      (goto-char (match-end 0))
      (buffer-substring-no-properties
       (point)
       (line-end-position)))))

(defcustom review-imenu-indent-string ". "
  "String to add repeated in front of nested sectional units for Imenu.
An alternative value is \" . \", if you use a font with a narrow period."
  :type 'string
  :group 'review-mode)

;; This function was originally derived from
;; `latex-imenu-create-index' from tex-mode.el.
(defun review-imenu-create-index ()
  "Generate an alist for imenu from a Re:VIEW buffer."
  (let (menu)
    (save-excursion
      (goto-char (point-min))
      (while (search-forward-regexp review-outline-regexp nil t)
	    (let ((start (match-beginning 0))
	          (here (point))
              (i (cdr (assoc (buffer-substring-no-properties
			                  (match-beginning 1)
			                  (match-end 1))
			                 review-section-alist))))
          (end-of-line)
	      (condition-case nil
	          (progn
		        (push
                 (cons
                  (concat (apply #'concat
					             (make-list i
					              review-imenu-indent-string))
				          (buffer-substring-no-properties
				           here (point)))
			      start)
		         menu))
	        (error nil))))
      ;; Sort in increasing buffer position order.
      (sort menu (lambda (a b) (< (cdr a) (cdr b)))))))

;;;; Syntax Table

;; とりあえず markdown-mode のを参考にしたが、まだ改良の余地あり。
(defvar review-mode-syntax-table
  (let ((tab (make-syntax-table text-mode-syntax-table)))
    (modify-syntax-entry ?\" "." tab)
    tab)
  "Syntax table for `review-mode'.")

;;;; Font Lock

(require 'font-lock)
(require 'outline)
(require 'org-faces)

(defvar review-mode-comment-face 'review-mode-comment-face)
(defvar review-mode-title-face 'review-mode-title-face)
(defvar review-mode-header1-face 'review-mode-header1-face)
(defvar review-mode-header2-face 'review-mode-header2-face)
(defvar review-mode-header3-face 'review-mode-header3-face)
(defvar review-mode-header4-face 'review-mode-header4-face)
(defvar review-mode-header5-face 'review-mode-header5-face)
(defvar review-mode-underline-face 'review-mode-underline-face)
(defvar review-mode-underlinebold-face 'review-mode-underlinebold-face)
(defvar review-mode-bold-face 'review-mode-bold-face)
(defvar review-mode-italic-face 'review-mode-italic-face)
(defvar review-mode-bracket-face 'review-mode-bracket-face)
(defvar review-mode-nothide-face 'review-mode-nothide-face)
(defvar review-mode-hide-face 'review-mode-hide-face)
(defvar review-mode-balloon-face 'review-mode-balloon-face)
(defvar review-mode-ref-face 'review-mode-ref-face)
(defvar review-mode-fullwidth-hyphen-minus-face 'review-mode-fullwidth-hyphen-minus-face)
(defvar review-mode-minus-sign-face 'review-mode-minus-sign-face)
(defvar review-mode-hyphen-face 'review-mode-hyphen-face)
(defvar review-mode-figure-dash-face 'review-mode-figure-dash-face)
(defvar review-mode-en-dash-face 'review-mode-en-dash-face)
(defvar review-mode-em-dash-face 'review-mode-em-dash-face)
(defvar review-mode-horizontal-bar-face 'review-mode-horizontal-bar-face)
(defvar review-mode-left-quote-face 'review-mode-left-quote-face)
(defvar review-mode-right-quote-face 'review-mode-right-quote-face)
(defvar review-mode-reversed-quote-face 'review-mode-reversed-quote-face)
(defvar review-mode-double-prime-face 'review-mode-double-prime-face)

(defgroup review-faces nil
  "Faces used in Review Mode"
  :group 'review-mode
  :group 'faces)

(defface review-mode-comment-face
  '((t (:foreground "Red")))
  "コメントのフェイス"
  :group 'review-faces)

(defface review-mode-title-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "タイトルのフェイス"
  :group 'review-faces)

(defface review-mode-header1-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "ヘッダーのフェイス"
  :group 'review-faces)

(defface review-mode-header2-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "ヘッダーのフェイス"
  :group 'review-faces)

(defface review-mode-header3-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "ヘッダーのフェイス"
  :group 'review-faces)

(defface review-mode-header4-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "ヘッダーのフェイス"
  :group 'review-faces)

(defface review-mode-header5-face
  '((((class color) (background light)) :foreground "darkgreen")
    (((class color) (background dark)) :foreground "spring green")
    (t :weight bold))
  "ヘッダーのフェイス"
  :group 'review-faces)

(defface review-mode-underline-face
  '((t (:underline t :foreground "DarkBlue")))
  "アンダーラインのフェイス"
  :group 'review-faces)

(defface review-mode-underlinebold-face
  '((default :weight bold :underline t)
    (((class color) (background light)) :foreground "DarkBlue")
    (((class color) (background dark)) :foreground "LightBlue"))
  "アンダーラインボールドのフェイス"
  :group 'review-faces)

(defface review-mode-bold-face
  '((default :weight bold)
    (((class color) (background light)) :foreground "Blue")
    (((class color) (background dark)) :foreground "LightBlue"))
  "ボールドのフェイス"
  :group 'review-faces)

(defface review-mode-italic-face
  '((t (:italic t :bold t :foreground "DarkRed")))
  "イタリックのフェイス"
  :group 'review-faces)

(defface review-mode-bracket-face
  '((t (:bold t :foreground "DarkBlue")))
  "<のフェイス"
  :group 'review-faces)

(defface review-mode-nothide-face
  '((t (:bold t :foreground "SlateGrey")))
  "indexのフェイス"
  :group 'review-faces)

(defface review-mode-hide-face
  '((((class color) (background light)) :foreground "plum4")
    (((class color) (background dark)) :foreground "plum2")
    (t :weight bold))
  "indexのフェイス"
  :group 'review-faces)

(defface review-mode-balloon-face
  '((t (:foreground "CornflowerBlue")))
  "balloonのフェイス"
  :group 'review-faces)

(defface review-mode-ref-face
  '((((class color) (background light)) :foreground "yellow4")
    (((class color) (background dark)) :foreground "yellow2")
    (t :weight bold))
  "参照のフェイス"
  :group 'review-faces)

(defface review-mode-fullwidth-hyphen-minus-face
  '((t (:foreground "grey90" :bkacground "red")))
  "全角ハイフン/マイナスのフェイス"
  :group 'review-faces)

(defface review-mode-minus-sign-face
  '((t (:background "grey90")))
  "全角ハイフン/マイナスのフェイス"
  :group 'review-faces)

(defface review-mode-hyphen-face
  '((t (:background "maroon1")))
  "全角ハイフンのフェイス"
  :group 'review-faces)

(defface review-mode-figure-dash-face
  '((t (:foreground "white" :background "firebrick")))
  "figureダッシュ(使うべきでない)のフェイス"
  :group 'review-faces)

(defface review-mode-en-dash-face
  '((t (:foreground "white" :background "sienna")))
  "半角ダッシュ(使うべきでない)のフェイス"
  :group 'review-faces)

(defface review-mode-em-dash-face
  '((t (:background "honeydew1")))
  "全角ダッシュのフェイス"
  :group 'review-faces)

(defface review-mode-horizontal-bar-face
  '((t (:background "LightSkyBlue1")))
  "水平バーのフェイス"
  :group 'review-faces)

(defface review-mode-left-quote-face
  '((t (:foreground "medium sea green")))
  "開き二重引用符のフェイス"
  :group 'review-faces)

(defface review-mode-right-quote-face
  '((t (:foreground "LightSlateBlue")))
  "閉じ二重引用符のフェイス"
  :group 'review-faces)

(defface review-mode-reversed-quote-face
  '((t (:foreground "LightCyan" :background "red")))
  "開き逆二重引用符(使うべきでない)のフェイス"
  :group 'review-faces)

(defface review-mode-double-prime-face
  '((t (:foreground "light steel blue" :background "red")))
  "閉じ逆二重引用符(使うべきでない)のフェイス"
  :group 'review-faces)

;; 原因は不明だが、inheritされた face が使えないので、
;; 色々変更して、 (font-lock-refresh-defaults) で確認する。
(defconst review-font-lock-keywords
  '(("◆→[^◆]*←◆" . review-mode-comment-face)
    ("^#@.*" . review-mode-comment-face)
    ("^====== .*" . review-mode-header5-face)
    ("^===== .*" . review-mode-header4-face)
    ("^==== .*" . review-mode-header3-face)
    ("^=== .*" . review-mode-header2-face)
    ("^== .*" . review-mode-header1-face)
    ("^= .*" . review-mode-title-face)
    ("@<list>{.*?}" . review-mode-ref-face)
    ("@<img>{.*?}" . review-mode-ref-face)
    ("@<table>{.*?}" . review-mode-ref-face)
    ("@<fn>{.*?}" . review-mode-ref-face)
    ("@<chap>{.*?}" . review-mode-ref-face)
    ("@<title>{.*?}" . review-mode-ref-face)
    ("@<chapref>{.*?}" . review-mode-ref-face)
    ("@<bib>{.*?}" . review-mode-ref-face)
    ("@<u>{.*?}" . underline)
    ("@<tt>{.*?}" . font-lock-type-face)
    ("@<ttbold>{.*?}" . review-mode-underlinebold-face)
    ("@<ttb>{.*?}" . review-mode-bold-face)
    ("@<b>{.*?}" . review-mode-bold-face)
    ("@<strong>{.*?}" . review-mode-bold-face)
    ("@<em>{.*?}" . review-mode-bold-face)
    ("@<kw>{.*?}" . review-mode-bold-face)
    ("@<bou>{.*?}" . review-mode-bold-face)
    ("@<ami>{.*?}" . review-mode-bold-face)
    ("@<i>{.*?}" . italic)
    ("@<tti>{.*?}" . italic)
    ("@<sup>{.*?}" . italic)
    ("@<sub>{.*?}" . italic)
    ("@<ruby>{.*?}" . italic)
    ("@<idx>{.*?}" . review-mode-nothide-face)
    ("@<hidx>{.*?}" . review-mode-hide-face)
    ("@<br>{.*?}" . review-mode-bold-face)
    ("@<m>{.*?}" . review-mode-bold-face)
    ("@<m>\\$.*?\\$" . review-mode-bold-face)
    ("@<m>\|.*?\|" . review-mode-bold-face)
    ("@<icon>{.*?}" . review-mode-bold-face)
    ("@<uchar>{.*?}" . review-mode-bold-face)
    ("@<href>{.*?}" . review-mode-bold-face)
    ("@<raw>{.*?[^\\]}" . review-mode-bold-face)
    ("@<code>{.*?[^\\]}" . review-mode-bold-face)
    ("@<balloon>{.*?}" . review-mode-ballon-face)
    ("^//.*{" . review-mode-hide-face)
    ("^//.*]" . review-mode-hide-face)
    ("^//}" . review-mode-hide-face)
    ("<\<>" . review-mode-bracket-face)
    ("－" . review-mode-fullwidth-hyphen-minus-face)
    ("−" . review-mode-minus-sign-face)
    ("‐" . review-mode-hyphen-face)
    ("‒" . review-mode-figure-dash-face)
    ("–" . review-mode-en-dash-face)
    ("―" . review-mode-em-dash-face)
    ("―" . review-mode-horizontal-bar-face)
    ("“" . review-mode-left-quote-face)
    ("”" . review-mode-right-quote-face)
    ("‟" . review-mode-reversed-quote-face)
    ("″" . review-mode-double-prime-face)
    )
  "編集モードのface.")

;;;; Misc Variables
(defvar review-name-list
  '(("編集者" . "編集注")
    ("翻訳者" . "翻訳注")
    ("監訳" . "監注")
    ("著者" . "注")
    ("DTP" . "注")
    ("kmuto" . "注") ; ユーザーの名前で置き換え
    )
  "編集モードの名前リスト")

(defvar review-dtp-list
  '("DTP連絡")
  "DTP担当名リスト")

(defvar review-mode-name "監訳" "ユーザーの権限")
(defvar review-mode-tip-name "監注" "注釈時の名前")
(defvar review-mode-dtp "DTP連絡" "DTP担当の名前")
(defvar review-comment-start "◆→" "編集タグの開始文字")
(defvar review-comment-end "←◆" "編集タグの終了文字")
(defvar review-index-start "@<hidx>{" "索引タグの開始文字")
(defvar review-index-end "}" "索引タグの終了文字")
(defvar review-use-skk-mode nil "t:SKKモードで開始")
(defvar review-use-whitespace-mode nil "t:whitespaceモードで開始")
(defvar review-dtp-name nil "現在のDTP")
(defvar review-use-em nil "t:C-c C-f C-eでiではなくemにする")

(defvar review-key-mapping
  '(
    ("[" . "【")
    ("]" . "】")
    ("(" . "（")
    (")" . "）")
    ("8" . "（")
    ("9" . "）")
    ("-" . "－")
    ("+" . "＋")
    ("*" . "＊")
    ("/" . "／")
    ("=" . "＝")
    ("\\" . "￥")
    (" " . "　")
    (":" . "：")
    ("<" . "<\\<>")
    )
  "全角置換キー")

;; 補完キーワード
(defvar review-block-op
  '("bibpaper[][]" "caution" "cmd" "embed[]" "emlist" "emlistnum" "emtable[]" "graph[][][]" "image[][]" "imgtable[][]" "important" "indepimage[]" "info" "lead" "list[][]" "listnum[][]" "memo" "note" "notice" "numberlessimage[]" "quote" "read" "source" "table[][]" "texequation" "tip" "warning")
  "補完対象のブロック命令")

(defvar review-block-op-single
  '("beginchild" "blankline" "endchild" "endnote[][]" "firstlinenum[]" "footnote[][]" "noindent" "printendnotes" "raw" "tsize[]")
  "補完対象のブロック命令(単一行)")

(defvar review-inline-op
  '("ami" "b" "balloon" "bib" "bou" "br" "chap" "chapref" "chapter" "code" "column" "comment" "em" "embed" "endnote" "eq" "fn" "hd" "hidx" "href" "i" "icon" "idx" "img" "kw" "list" "m" "raw" "ruby" "sec" "secref" "sectitle" "strong" "table" "tcy" "title" "tt" "ttb" "tti" "u" "uchar" "w" "wb")
  "補完対象のインライン命令")

(defvar review-uri-regexp
  "\\(\\b\\(s?https?\\|ftp\\|file\\|gopher\\|news\\|telnet\\|wais\\|mailto\\):\\(//[-a-zA-Z0-9_.]+:[0-9]*\\)?[-a-zA-Z0-9_=?#$@~`%&*+|\\/.,]*[-a-zA-Z0-9_=#$@~`%&*+|\\/]+\\)\\|\\(\\([^-A-Za-z0-9!_.%]\\|^\\)[-A-Za-z0-9._!%]+@[A-Za-z0-9][-A-Za-z0-9._!]+[A-Za-z0-9]\\)"
  "URI選択部分正規表現")

;; for < Emacs24
(unless (fboundp 'setq-local)
  (defmacro setq-local (var val)
    `(set (make-local-variable ',var) ,val)))

;;;; Main routines
;;;###autoload
(define-derived-mode review-mode text-mode "ReVIEW"
  "Major mode for editing ReVIEW text.

To see what version of ReVIEW mode your are running, enter `\\[review-version]'.

Key bindings:
\\{review-mode-map}"

  (auto-fill-mode 0)
  (if review-use-skk-mode (skk-mode))
  (if review-use-whitespace-mode (whitespace-mode))
  (setq-local comment-start "#@#")
  (setq-local compile-command review-default-compile-command)
  (setq-local outline-regexp review-outline-regexp)
  (setq-local outline-level #'review-outline-level)
  (setq-local add-log-current-defun-function #'review-current-defun-name)
  (setq-local imenu-create-index-function #'review-imenu-create-index)
  (setq-local font-lock-defaults '(review-font-lock-keywords))
  (when (fboundp 'font-lock-refresh-defaults) (font-lock-refresh-defaults))
  (use-local-map review-mode-map)
  (run-hooks 'review-mode-hook))

;; リージョン取り込み
(defvar review-default-blockop "emlist")
(defun review-block-region (arg)
  "選択領域を指定したタグで囲みます.

もしRegionが選択されていたら, その領域を指定したタグで囲みます.
もしRegionが選択されていなかったら, 現在のカーソル位置をタグで囲
みます.  もしARGありで呼ばれた場合は、Regionが選択されているかに
よらず, カーソル位置より前の, 最も近いタグを変更します."
  (interactive "*P")
  (let* ((pattern (completing-read
                   (concat "タグ [" review-default-blockop "]: ")
                   (append review-block-op review-block-op-single)
                   nil nil nil nil review-default-blockop)))
    (unless (equal review-default-blockop pattern)
      (setq review-default-blockop pattern))
    (if arg
        (review-modify-previous-block pattern)
      (review-insert-block pattern))))

(defun review-modify-previous-block (pattern)
  "現在位置の一つ前のタグをPATTERNに変更する."
  (save-excursion
    (if (re-search-backward (concat "//" ".+{"))
        (replace-match (concat "//" pattern "{"))
      (message "カーソル位置より前にタグが見つかりません.")
    )))

(defun review-insert-block (pattern)
  "PATTERNタグを挿入する."
  (cond
   ((region-active-p)
	(save-restriction
	  (narrow-to-region (region-beginning) (region-end))
	  (goto-char (point-min))
	  (cond
       ((member pattern review-block-op-single)
		(insert "//" pattern)
        (newline))
	   (t
		(insert "//" pattern "{")
        (newline)
		(goto-char (point-max))
		(insert "//" "}")
        (newline)))))
   (t
	(cond
     ((member pattern review-block-op-single)
	  (insert "//" pattern)
      (newline))
     (t
      (save-excursion
        (insert "//" pattern "{")
        (newline)
		(insert "//" "}")
        (newline))
      (forward-word)
      (forward-char)
      )))
   ))

;; beginchild/endchild囲み
(defun review-child-region ()
  "選択領域を//beginchild, //endchildで囲みます。"
  (interactive)
  (cond ((region-active-p)
	 (save-restriction
	   (narrow-to-region (region-beginning) (region-end))
	   (goto-char (point-min))
	   (insert "//beginchild\n\n")
	   (goto-char (point-max))
	   (insert "\n//endchild\n")))
	))

(defvar review-default-inlineop "b")
(defun review-inline-region ()
  "選択領域を指定したインラインタグで囲みます."
  (interactive)
  (let* ((pattern (completing-read
                   (concat "タグ [" review-default-inlineop "]: ")
                   review-inline-op
                   nil nil nil nil review-default-inlineop)))
    (unless (equal review-default-inlineop pattern)
      (setq review-default-inlineop pattern))
    (cond
     ((region-active-p)
	  (save-restriction
	    (narrow-to-region (region-beginning) (region-end))
	    (goto-char (point-min))
	    (insert "@<" pattern ">{")
	    (goto-char (point-max))
	    (insert "}")))
	 (t
	  (insert "@<" pattern ">{}")
	  (backward-char)
	  ))
    ))

;; フォント付け
(defun review-string-region (markb marke)
  "選択領域にフォントを設定"
  (cond ((region-active-p)
	 (save-restriction
	   (narrow-to-region (region-beginning) (region-end))
	   (goto-char (point-min))
	   (insert markb)
	   (goto-char (point-max))
	   (insert marke)))
	(t
	 (insert markb marke)
	 (backward-char))
      )
  )

(defun review-bold-region ()
  "選択領域を太字タグ(@<b>)で囲みます"
  (interactive)
  (review-string-region "@<b>{" "}"))

(defun review-keyword-region ()
  "選択領域をキーワードフォントタグ(@<kw>)で囲みます"
  (interactive)
  (review-string-region "@<kw>{" "}"))

(defun review-italic-region ()
  "選択領域をイタリックフォントタグ(@<i>)で囲みます"
  (interactive)
  (review-string-region "@<i>{" "}"))

(defun review-em-region ()
  "選択領域をイタリックフォントタグ(@<i>)または強調タグ(@<em>)で囲みます"
  (interactive)
  (if review-use-em
      (review-string-region "@<em>{" "}")
    (review-string-region "@<i>{" "}")
    ))

(defun review-strong-region ()
  "選択領域を強調タグ(@<strong>)で囲みます"
  (interactive)
  (review-string-region "@<strong>{" "}"))

(defun review-underline-italic-region ()
  "選択領域を等幅イタリックフォントタグ(@<tti>)で囲みます"
  (interactive)
  (review-string-region "@<tti>{" "}"))

(defun review-underline-region ()
  "選択領域を等幅タグ(@<tt>)で囲みます"
  (interactive)
  (review-string-region "@<tt>{" "}"))

(defun review-hyperlink-region ()
  "選択領域をハイパーリンクタグ(@<href>)で囲みます"
  (interactive)
  (review-string-region "@<href>{" "}"))

(defun review-code-region ()
  "選択領域をコードタグ(@<code>)で囲みます"
  (interactive)
  (review-string-region "@<code>{" "}"))

(defun review-math-region ()
  "選択領域を数式タグ(@<m>)で囲みます"
  (interactive)
  (if (region-active-p)
      (save-restriction
	(narrow-to-region (region-beginning) (region-end))
	(goto-char (point-min))
	(if (string-match "}" (buffer-string))
	    (progn
              (insert "@<m>$")
              (goto-char (point-max))
              (insert "$"))
	  (progn
	    (insert "@<m>{")
	    (goto-char (point-max))
	    (insert "}"))))
    (progn
      (insert "@<m>$$")
      (backward-char)
      )
    ))

(defun review-index-region ()
  "選択領域を出力付き索引化(@<idx>)で囲みます"
  (interactive)
  (review-string-region "@<idx>{" "}"))

;; 吹き出し
(defun review-balloon-comment (pattern &optional _force)
  "吹き出しを挿入。"
  (interactive "s吹き出し: \nP")
  (insert "@<balloon>{" pattern "}"))

;; 編集一時終了
(defun review-kokomade ()
  "一時終了タグを挿入。

作業途中の疑似マーカーを挿入します。"
  (interactive)
  (insert review-comment-start "ここまで -" review-mode-name
          review-comment-end  "\n"))

;; 編集コメント
(defun review-normal-comment (pattern &optional _force)
  "コメントを挿入。

ユーザーから編集者へのメッセージ疑似マーカーを挿入します。"
  (interactive "sコメント: \nP")
  (insert review-comment-start pattern " -" review-mode-name
          review-comment-end))

;; DTP向けコメント
(defun review-dtp-comment (pattern &optional _force)
  "DTP向けコメントを挿入。

DTP担当へのメッセージ疑似マーカーを挿入します。"
  (interactive "sDTP向けコメント: \nP")
  (insert review-comment-start review-mode-dtp
          ":" pattern " -" review-mode-name review-comment-end))

;; 注釈
(defun review-tip-comment (pattern &optional _force)
  "注釈コメントを挿入。

ユーザー注釈の疑似マーカーを挿入します。
"
  (interactive "s注釈コメント: \nP")
  (insert review-comment-start review-mode-tip-name
          ":" pattern " -" review-mode-name review-comment-end))

;; 参照
(defun review-reference-comment ()
  "参照コメントを挿入。

参照先をあとで確認する疑似マーカーを挿入します。"
  (interactive)
  (insert review-comment-start "参照先確認 -"
          review-mode-name review-comment-end))

;; 索引
(defun review-insert-index ()
  "索引 @<hidx>{} 挿入用の関数.

領域が選択されているか、それがインラインタグのカッコ内全部,
つまり, @<tag>{XYZ}のXYZであるかに応じて以下のように動作が変わる.
なお, @<tag>{XYZ}でXYやYZのみが選択されていた場合は 3番の動作になる.

1. 領域が選択されていなかったら, ユーザーの入力を受け取りそれを索
引としてカーソル位置に挿入する.

2. 領域が選択されていて, それがインラインタグのカッコ内全てであれ
ばその内容をタグの直前に索引として挿入する.

3. それ以外の場合で、領域が選択されているときは選択領域を索引とし
て領域の直前に挿入する."
  (interactive)
  (cond
   ((region-active-p)
    (let* ((start (region-beginning))
           (end (region-end))
           (review-index-buffer (buffer-substring-no-properties start end))
           (string-after (char-to-string (char-after end)))
           (strings-before
            (concat
             (char-to-string (char-before (- start 1)))
             (char-to-string (char-before start)))))
      ;; インラインタグ内の全領域かの判定.
      ;; regionの直前の文字が ">{"で直後が "}" だったら@<.+?>{を探し,
      ;; マッチした位置の終わりがregionの始まりに一致した場合は,
      ;; @の直前をstartに変更する.
      (when (and (equal string-after "}")
                 (equal strings-before ">{")
                 (re-search-backward "@<.+?[^}]>{" nil t)
                 (= start (match-end 0)))
        (setq start (point)))
	  (save-restriction
	    (narrow-to-region start end)
        (goto-char (point-min))
	    (insert "@<hidx>{" review-index-buffer "}"))))
   (t
    (let ((pattern (read-from-minibuffer "索引: ")))
      (insert review-index-start pattern review-index-end))))
  )

;; ヘッダ
(defun review-header (pattern &optional _force)
  "見出しを挿入"
  (interactive "sヘッダレベル: \nP")
  (insert (make-string (string-to-number pattern) ?=) " "))

(defun review-br ()
  "強制改行タグ(@<br>{})を挿入します。"
  (interactive)
  (insert "@<br>{}"))

;; rawでタグのオープン/クローズ
(defun review-opentag (pattern &optional _force)
  "raw開始タグ"
  (interactive "sタグ: \nP")
  (insert "//raw[|html|<" pattern ">]"))

(defun review-closetag (pattern &optional _force)
  "raw終了タグ"
  (interactive "sタグ: \nP")
  (insert "//raw[|html|</" pattern ">]"))

;; ブラウズ
(defun review-search-uri ()
  "手近なURIを検索してブラウザで表示"
  (interactive)
  (re-search-forward review-uri-regexp)
  (goto-char (match-beginning 1))
  (browse-url (match-string 1)))

(defun review-search-uri2 (start end)
  "選択領域をブラウザで表示"
  (interactive "r")
  (message (buffer-substring-no-properties start end))
  (browse-url (buffer-substring-no-properties start end)))

;; 全角文字
(defun review-zenkaku-mapping (key)
  "全角文字の挿入"
  (insert (cdr (assoc key review-key-mapping))))

(defun review-zenkaku-mapping-lparenthesis ()
  (interactive) "全角(" (review-zenkaku-mapping "("))

(defun review-zenkaku-mapping-rparenthesis ()
  (interactive) "全角)" (review-zenkaku-mapping ")"))

(defun review-zenkaku-mapping-langle ()
  (interactive) "全角[" (review-zenkaku-mapping "["))

(defun review-zenkaku-mapping-rangle ()
  (interactive) "全角[" (review-zenkaku-mapping "]"))

(defun review-zenkaku-mapping-plus ()
  (interactive) "全角+" (review-zenkaku-mapping "+"))

(defun review-zenkaku-mapping-minus ()
  (interactive) "全角-" (review-zenkaku-mapping "-"))

(defun review-zenkaku-mapping-asterisk ()
  (interactive) "全角*" (review-zenkaku-mapping "*"))

(defun review-zenkaku-mapping-slash ()
  (interactive) "全角/" (review-zenkaku-mapping "/"))

(defun review-zenkaku-mapping-equal ()
  (interactive) "全角=" (review-zenkaku-mapping "="))

(defun review-zenkaku-mapping-yen ()
  (interactive) "全角￥" (review-zenkaku-mapping "\\"))

(defun review-zenkaku-mapping-space ()
  (interactive) "全角 " (review-zenkaku-mapping " "))

(defun review-zenkaku-mapping-colon ()
  (interactive) "全角:" (review-zenkaku-mapping ":"))

(defun review-zenkaku-mapping-lbracket ()
  (interactive) "<タグ" (review-zenkaku-mapping "<"))

;; 基本モードの変更
(defun review-change-mode ()
  "編集モードの変更。

作業者名を変更します。"
  (interactive)
  (let (key message element (list review-name-list) (sum 0))
    (while list
      (setq element (car (car list)))
      (setq sum ( + sum 1))
      (if message
          (setq message (format "%s%d.%s " message sum element))
	(setq message (format "%d.%s " sum element))
	)
      (setq list (cdr list))
      )
    (message (concat "編集モード: " message ":"))
    (setq key (read-char))
    (cond
     ((eq key ?1) (review-change-mode-sub 0))
     ((eq key ?2) (review-change-mode-sub 1))
     ((eq key ?3) (review-change-mode-sub 2))
     ((eq key ?4) (review-change-mode-sub 3))
     ((eq key ?5) (review-change-mode-sub 4))))
  (setq review-mode-tip-name (cdr (assoc review-mode-name review-name-list)))
  (message (concat "現在のモード: " review-mode-name))
  (setq mode-name review-mode-name))

;; DTP の変更
(defun review-change-dtp ()
  "DTP担当の変更。

DTP担当を変更します。"
  (interactive)
  (let (key message element (list review-dtp-list) (sum 0))
    (while list
      (setq element (car list))
      (setq sum ( + sum 1))
      (if message
          (setq message (format "%s%d.%s " message sum element))
	(setq message (format "%d.%s " sum element))
	)
      (setq list (cdr list))
      )
    (message (concat "DTP担当: " message ":"))
    (setq key (read-char))
    (cond
     ((eq key ?1) (review-change-dtp-mode-sub 0))
     ((eq key ?2) (review-change-dtp-mode-sub 1))
     ((eq key ?3) (review-change-dtp-mode-sub 2))
     ((eq key ?4) (review-change-dtp-mode-sub 3))
     ((eq key ?5) (review-change-dtp-mode-sub 4)))))

(defun review-change-dtp-mode-sub (number)
  "DTP担当変更サブルーチン"
  (let (list)
    (setq list (nth number review-dtp-list))
    (setq review-dtp-name list)
    (message (concat "現在のDTP: " review-dtp-name))))

;; 組の変更
(defun review-change-mode-sub (number)
  "編集モードのサブルーチン"
  (let (list)
    (setq list (nth number review-name-list))
    (setq review-mode-name (car list))
    ;;(setq review-tip-name (cdr list))
    ))

(defun review-index-change (start end)
  "選択領域を索引として追記する。索引からは()とスペースを取る"
  (interactive "r")
  (if (region-active-p)
      (let (review-index-buffer)
	(save-restriction
	  (narrow-to-region start end)
	  (setq review-index-buffer (buffer-substring-no-properties start end))
	  (goto-char (point-min))
	  (while (re-search-forward "\(\\|\)\\| " nil t)
	    (replace-match "" nil nil))
	  (goto-char (point-max))
	  (insert "@" review-index-buffer)))
    (message "索引にする範囲を選択してください")
    )
  )

(defun page-increment-region (pattern &optional _force start end)
  "選択領域のページ数を増減(DTP作業用)"
  (interactive "n増減値: \nP\nr")
  (save-restriction
    (narrow-to-region start end)
    (let ((pos (point-min)))
      (goto-char pos)
      (while (setq pos (re-search-forward "^\\([0-9][0-9]*\\)\t" nil t))
        (replace-match
         (concat (number-to-string
                  (+ pattern (string-to-number (match-string 1)))) "\t")))))
  (save-restriction
    (narrow-to-region start end)
    (let ((pos (point-min)))
      (goto-char pos)
      (while (setq pos (re-search-forward "^p\\.\\([0-9][0-9]*\\) " nil t))
        (replace-match
         (concat "p."
                 (number-to-string
                  (+ pattern (string-to-number (match-string 1)))) " "))))))

;; カーソル位置から後続の英字記号範囲を選択して等幅化
(defun review-surround-tt ()
  "カーソル位置から後続の英字記号範囲を選択して等幅化"
  (interactive)
  (re-search-forward "[-a-zA-Z0-9_=?#$@~`%&*+|()'\\/.,:<>]+")
  (goto-char (match-end 0))
  (insert "}")
  (goto-char (match-beginning 0))
  (insert "@<tt>{")
  (goto-char (+ 7 (match-end 0)))
  )

;;; Compile用のコマンド
(defun review-compile ()
  "Run rake command on the current document."
  (interactive)
  (cond
   ((file-exists-p "Rakefile")
    (review-compile-exec-command)
    )
   ((file-exists-p "../Rakefile")
    (let ((current-dir default-directory))
      (cd "..")
      (review-compile-exec-command)
      (cd current-dir)))
   (t
    (message "Rakefile not found!"))
   ))

(defun review-compile-exec-command ()
  "Execute rake command."
  (call-interactively 'compile))

;; Associate .re files with review-mode
;;;###autoload
(setq auto-mode-alist (append '(("\\.re$" . review-mode)) auto-mode-alist))

(provide 'review-mode)

;;; review-mode.el ends here
