;;; sumibi.el --- Japanese input method powered by ChatGPT API   -*- lexical-binding: t; -*-
;;
;; -*- indent-tabs-mode: nil -*-
;;
;; Copyright (C) 2023 Kiyoka Nishiyama
;;
;; Author: Kiyoka Nishiyama <kiyoka@sumibi.org>
;; Version: 1.6.3
;; Package-Version: 20230531.1247
;; Package-Commit: e23cef243d4b635a5e24e0b8684c256edf3d73c9
;; Keywords: lisp, ime, japanese
;; Package-Requires: ((emacs "28.1") (popup "0.5.9") (unicode-escape "1.1") (deferred "0.5.1"))
;; URL: https://github.com/kiyoka/Sumibi
;;
;; This file is part of Sumibi
;; This program was derived from sekka.el and yc.el-4.0.13(auther: knak)
;;
;; Sumibi is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Sumibi is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Sumibi; see the file COPYING.
;;

;;; Commentary:

;; you might want to enable IME:
;;
;;  (require 'sumibi)
;;  (global-sumibi-mode 1)
;;
;;

;;; Code:
(require 'cl-lib)
(require 'popup)
(require 'url)
(require 'url-http)
(require 'unicode-escape)
(require 'deferred)

;;; 
;;;
;;; customize variables
;;;
(defgroup sumibi nil
  "Sumibi client."
  :group 'input-method
  :group 'Japanese)

(defcustom sumibi-stop-chars "(){}<>"
  "*漢字変換文字列を取り込む時に変換範囲に含めない文字を設定する."
  :type  'string
  :group 'sumibi)

(defcustom sumibi-current-model "gpt-3.5-turbo"
  "OpenAPIのLLM使用モデル名を指定する."
  :type  'string
  :group 'sumibi)

(defcustom sumibi-history-stack-limit 100
  "再度候補選択できる単語と場所を最大何件記憶するか."
  :type  'integer
  :group 'sumibi)

(defcustom sumibi-api-timeout 60
  "OpenAIサーバーと通信する時のタイムアウトを指定する。(秒数)."
  :type  'integer
  :group 'sumibi)

(defcustom sumibi-threshold-letters-of-long-sentence 100
  "OpenAIサーバーに送信する際、長文として判断する文字数。この文字数を超えるとOpenAI APIの引数nを1に減らす."
  :type  'integer
  :group 'sumibi)

(defvar sumibi-mode nil             "漢字変換トグル変数.")
(defun sumibi-modeline-string ()
  "接続先サーバーのホスト名を表示する."
  (format " Sumibi[%s]" sumibi-current-model))

(defvar sumibi-select-mode nil      "候補選択モード変数.")
(or (assq 'sumibi-mode minor-mode-alist)
    (setq minor-mode-alist (cons
                            '(sumibi-mode (:eval (sumibi-modeline-string)))
                            minor-mode-alist)))


;; ローマ字漢字変換時、対象とするローマ字を設定するための変数
(defvar sumibi-skip-chars "a-zA-Z0-9.,@:`\\-+!\\[\\]?;' ")
(defvar sumibi-rK-trans-key "\C-j"
  "*漢字変換キーを設定する.")
(defvar sumibi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map sumibi-rK-trans-key 'sumibi-rK-trans)
    (define-key map "\M-j" 'sumibi-english-trans)
    map)
  "漢字変換トグルマップ.")
(defvar sumibi-select-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((i 0))
      (while (<= i ?\177)
	(define-key map (char-to-string i)
	  'sumibi-kakutei-and-self-insert)
	(setq i (1+ i))))
    (define-key map "\C-m"                   'sumibi-select-kakutei)
    (define-key map "\C-g"                   'sumibi-select-cancel)
    (define-key map "q"                      'sumibi-select-cancel)
    (define-key map "\C-a"                   'sumibi-select-kanji)
    (define-key map "\C-p"                   'sumibi-select-prev)
    (define-key map "\C-n"                   'sumibi-select-next)
    (define-key map sumibi-rK-trans-key      'sumibi-select-next)
    (define-key map (kbd "SPC")              'sumibi-select-next)
    (define-key map "\C-u"                   'sumibi-select-hiragana)
    (define-key map "\C-i"                   'sumibi-select-katakana)
    (define-key map "\C-k"                   'sumibi-select-katakana)
    (define-key map "\C-l"                   'sumibi-select-hankaku)
    (define-key map "\C-e"                   'sumibi-select-zenkaku)
    map)
  "候補選択モードマップ.")
(or (assq 'sumibi-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
          (append (list (cons 'sumibi-mode         sumibi-mode-map)
                        (cons 'sumibi-select-mode  sumibi-select-mode-map))
                  minor-mode-map-alist)))

;; OpenAPIを呼び出さずに固定文字列の結果を返すもの ( copied from GNU Emacs's japanese.el)
(defvar sumibi-japanese-transliteration-rules
  '(( "a" "あ") ( "i" "い") ( "u" "う") ( "e" "え") ( "o" "お")
    ("ka" "か") ("ki" "き") ("ku" "く") ("ke" "け") ("ko" "こ")
    ("sa" "さ") ("si" "し") ("su" "す") ("se" "せ") ("so" "そ")
    ("ta" "た") ("ti" "ち") ("tu" "つ") ("te" "て") ("to" "と")
    ("na" "な") ("ni" "に") ("nu" "ぬ") ("ne" "ね") ("no" "の")
    ("ha" "は") ("hi" "ひ") ("hu" "ふ") ("he" "へ") ("ho" "ほ")
    ("ma" "ま") ("mi" "み") ("mu" "む") ("me" "め") ("mo" "も")
    ("ya" "や")             ("yu" "ゆ")             ("yo" "よ")
    ("ra" "ら") ("ri" "り") ("ru" "る") ("re" "れ") ("ro" "ろ")
    ("la" "ら") ("li" "り") ("lu" "る") ("le" "れ") ("lo" "ろ")
    ("wa" "わ") ("wi" "ゐ") ("wu" "う") ("we" "ゑ") ("wo" "を")
    ("n'" "ん") ("nn" "ん")
    ("ga" "が") ("gi" "ぎ") ("gu" "ぐ") ("ge" "げ") ("go" "ご")
    ("za" "ざ") ("zi" "じ") ("zu" "ず") ("ze" "ぜ") ("zo" "ぞ")
    ("da" "だ") ("di" "ぢ") ("du" "づ") ("de" "で") ("do" "ど")
    ("ba" "ば") ("bi" "び") ("bu" "ぶ") ("be" "べ") ("bo" "ぼ")
    ("pa" "ぱ") ("pi" "ぴ") ("pu" "ぷ") ("pe" "ぺ") ("po" "ぽ")

    ("kya" "きゃ") ("kyu" "きゅ") ("kye" "きぇ") ("kyo" "きょ")
    ("sya" "しゃ") ("syu" "しゅ") ("sye" "しぇ") ("syo" "しょ")
    ("sha" "しゃ") ("shu" "しゅ") ("she" "しぇ") ("sho" "しょ")
    ("cha" "ちゃ") ("chu" "ちゅ") ("che" "ちぇ") ("cho" "ちょ")
    ("tya" "ちゃ") ("tyu" "ちゅ") ("tye" "ちぇ") ("tyo" "ちょ")
    ("nya" "にゃ") ("nyu" "にゅ") ("nye" "にぇ") ("nyo" "にょ")
    ("hya" "ひゃ") ("hyu" "ひゅ") ("hye" "ひぇ") ("hyo" "ひょ")
    ("mya" "みゃ") ("myu" "みゅ") ("mye" "みぇ") ("myo" "みょ")
    ("rya" "りゃ") ("ryu" "りゅ") ("rye" "りぇ") ("ryo" "りょ")
    ("lya" "りゃ") ("lyu" "りゅ") ("lye" "りぇ") ("lyo" "りょ")
    ("gya" "ぎゃ") ("gyu" "ぎゅ") ("gye" "ぎぇ") ("gyo" "ぎょ")
    ("zya" "じゃ") ("zyu" "じゅ") ("zye" "じぇ") ("zyo" "じょ")
    ("jya" "じゃ") ("jyu" "じゅ") ("jye" "じぇ") ("jyo" "じょ")
    ( "ja" "じゃ") ( "ju" "じゅ") ( "je" "じぇ") ( "jo" "じょ")
    ("bya" "びゃ") ("byu" "びゅ") ("bye" "びぇ") ("byo" "びょ")
    ("pya" "ぴゃ") ("pyu" "ぴゅ") ("pye" "ぴぇ") ("pyo" "ぴょ")

    ("kwa" "くゎ") ("kwi" "くぃ") ("kwe" "くぇ") ("kwo" "くぉ")
    ("tsa" "つぁ") ("tsi" "つぃ") ("tse" "つぇ") ("tso" "つぉ")
    ( "fa" "ふぁ") ( "fi" "ふぃ") ( "fe" "ふぇ") ( "fo" "ふぉ")
    ("gwa" "ぐゎ") ("gwi" "ぐぃ") ("gwe" "ぐぇ") ("gwo" "ぐぉ")

    ("dyi" "でぃ") ("dyu" "どぅ") ("dye" "でぇ") ("dyo" "どぉ")
    ("xwi" "うぃ")                  ("xwe" "うぇ") ("xwo" "うぉ")

    ("shi" "し") ("tyi" "てぃ") ("chi" "ち") ("tsu" "つ") ("ji" "じ")
    ("fu"  "ふ")
    ("ye" "いぇ")

    ("va" "ヴぁ") ("vi" "ヴぃ") ("vu" "ヴ") ("ve" "ヴぇ") ("vo" "ヴぉ")

    ("xa"  "ぁ") ("xi"  "ぃ") ("xu"  "ぅ") ("xe"  "ぇ") ("xo"  "ぉ")
    ("xtu" "っ") ("xya" "ゃ") ("xyu" "ゅ") ("xyo" "ょ") ("xwa" "ゎ")
    ("xka" "ヵ") ("xke" "ヶ")

    ("1" "１") ("2" "２") ("3" "３") ("4" "４") ("5" "５")
    ("6" "６") ("7" "７") ("8" "８") ("9" "９") ("0" "０")

    ("!" "！") ("@" "＠") ("#" "＃") ("$" "＄") ("%" "％")
    ("^" "＾") ("&" "＆") ("*" "＊") ("(" "（") (")" "）")
    ("-" "ー") ("=" "＝") ("`" "｀") ("\\" "￥") ("|" "｜")
    ("_" "＿") ("+" "＋") ("~" "￣") ("[" "「") ("]" "」")
    ("{" "｛") ("}" "｝") (":" "：") (";" "；") ("\""  "”")
    ("'" "’") ("." "。") ("," "、") ("<" "＜") (">" "＞")
    ("?" "？") ("/" "／")

    ("z1" "○") ("z!" "●")
    ("z2" "▽") ("z@" "▼")
    ("z3" "△") ("z#" "▲")
    ("z4" "□") ("z$" "■")
    ("z5" "◇") ("z%" "◆")
    ("z6" "☆") ("z^" "★")
    ("z7" "◎") ("z&" "£")
    ("z8" "¢") ("z*" "×")
    ("z9" "♂") ("z(" "【")
    ("z0" "♀") ("z)" "】")
    ("z-" "〜") ("z_" "∴")
    ("z=" "≠") ("z+" "±")
    ("z\\" "＼") ("z|" "‖")
    ("z`" "´") ("z~" "¨")

    ("zq" "《") ("zQ" "〈")
    ("zw" "》") ("zW" "〉")
    ("zr" "々") ("zR" "仝")
    ("zt" "〆") ("zT" "§")
    ("zp" "〒") ("zP" "↑")
    ("z[" "『") ("z{" "〔")
    ("z]" "』") ("z}" "〕")

    ("zs" "ヽ") ("zS" "ヾ")
    ("zd" "ゝ") ("zD" "ゞ")
    ("zf" "〃") ("zF" "→")
    ("zg" "‐") ("zG" "—")
    ("zh" "←")
    ("zj" "↓")
    ("zk" "↑")
    ("zl" "→")
    ("z;" "゛") ("z:" "゜")
    ("z'" "‘") ("z\"" "“")

    ("zx" ":-") ("zX" ":-)")
    ("zc" "〇") ("zC" "℃")
    ("zv" "※") ("zV" "÷")
    ("zb" "°") ("zB" "←")
    ("zn" "′") ("zN" "↓")
    ("zm" "″") ("zM" "〓")
    ("z," "‥") ("z<" "≦")
    ("z." "…") ("z>" "≧")
    ("z/" "・") ("z?" "∞")))

;;;
;;; hooks
;;;
(defvar sumibi-mode-hook nil)
(defvar sumibi-select-mode-hook nil)
(defvar sumibi-select-mode-end-hook nil)

(defconst sumibi-tango-index  0)
(defconst sumibi-annotation-index  1)
(defconst sumibi-kind-index   3)
(defconst sumibi-id-index     4)

;;--- デバッグメッセージ出力
(defvar sumibi-psudo-server nil)         ; クライアント単体で仮想的にサーバーに接続しているようにしてテストするモード

;;--- デバッグメッセージ出力
(defvar sumibi-debug nil)        ; デバッグフラグ
(defun sumibi-debug-print (string)
  "引数STRINGで指定されたデバッグメッセージを*sumibi-debug* に出力する."
  (if sumibi-debug
      (let
          ((buffer (get-buffer-create "*sumibi-debug*")))
        (with-current-buffer buffer
          (goto-char (point-max))
          (insert string)))))

;; HTTPクライアントの多重起動防止用
(defvar sumibi-busy 0)


;;; 候補選択モード用
(defvar sumibi-history-stack '())        ; 過去に変換した、場所と変換候補の状態を保存しておくスタック
;; データ構造は以下の通り。
;; alistのlistとなる。 alistのキーは、sumibi-* というバッファローカル変数のバックアップとなる)
;; 新しいものは先頭に追加され、検索も先頭から行われる。即ち、古い情報も残るがいつかstackのlimitを超えるとあふれて捨てられる。
;;(
;; (
;;  (bufname           . "*scratch*")
;;  (markers           . '(#<marker at 192 in *scratch*> . #<marker at 194 in *scratch*>))
;;  (cand-cur          . 0)
;;  (cand-cur-backup   . 0)
;;  (cand-len          . 0)
;;  (last-fix          . 0)
;;  (henkan-kouho-list . '())
;;  ))
(defvar sumibi-fence-start nil)          ; fence 始端marker
(defvar sumibi-fence-end nil)            ; fence 終端marker
(defvar sumibi-henkan-separeter " ")     ; fence mode separeter
(defvar sumibi-cand-cur 0)               ; カレント候補番号
(defvar sumibi-cand-cur-backup 0)        ; カレント候補番号(UNDO用に退避する変数)
(defvar sumibi-cand-len nil)             ; 候補数
(defvar sumibi-last-fix "")              ; 最後に確定した文字列
(defvar sumibi-last-roman "")            ; 最後にsumibi-serverにリクエストしたローマ字文字列
(defvar sumibi-select-operation-times 0) ; 選択操作回数
(defvar sumibi-henkan-kouho-list nil)    ; 変換結果リスト(サーバから帰ってきたデータそのもの)


;; その他
(defvar sumibi-markers '())              ; 単語の開始、終了位置のpair。 次のような形式で保存する ( 1 . 2 )
(defvar sumibi-timer    nil)             ; インターバルタイマー型変数
(defvar sumibi-timer-rest  0)            ; あと何回呼出されたら、インターバルタイマの呼出を止めるか
(defvar sumibi-last-lineno 0)            ; 最後に変換を実行した行番号
(defvar sumibi-guide-overlay   nil)      ; リアルタイムガイドに使用するオーバーレイ
(defvar sumibi-last-request-time 0)      ; OpenAIサーバーにリクエストした最後の時刻(単位は秒)
(defvar sumibi-guide-lastquery  "")      ; OpenAIサーバーにリクエストした最後のクエリ文字列
(defvar sumibi-guide-lastresult '())     ; OpenAIサーバーにリクエストした最後のクエリ結果



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ユーティリティ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sumibi-assoc-ref (key alist fallback)
  "指定したassocから内容を取り出すユーティリティ.
Argument KEY: key of alist.
Argument ALIST: alist.
Argument FALLBACK: fallback function."
  (let ((entry (assoc key alist)))
    (if entry
        (cdr entry)
      fallback)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 表示系関数群
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar sumibi-use-fence t)
(defvar sumibi-use-color nil)
(defvar sumibi-init nil)

;;
;; 初期化
;;
(defun sumibi-init ()
  "Sumibi環境の初期化を行う."
  (if sumibi-init
      t
    (cond
     ((not (getenv "OPENAI_API_KEY"))
      (message "%s" "Please set OPENAI_API_KEY environment variable."))
     ((and (>= emacs-major-version 28) (>= emacs-minor-version 1))
      ;; 初期化完了
      (setq sumibi-init t))
     (t
      (message "%s" "Emacs version 28.1 or higher is required.")))))

(defun sumibi-escape-for-json (str)
  "引数STRで指定した、JSON文字列に含まれるバックスペースとダブルクォーテーションと改行を削除する."
  (let* ((str1 (string-replace "\\" "" str))
         (str2 (string-replace "\"" "\\\"" str1))
         (str3 (string-replace "\n" "\\n" str2))
         (str4 (unicode-escape str3)))
    str4))

;;
;; OpenAPIにプロンプトを発行する
;;
(defun sumibi-openai-http-post (message-lst
                                arg-n
                                sync-func
                                deferred-func
                                deferred-func2)
  "Call OpenAI completions API.
Argument MESSAGE-LST : OpenAI API に渡す role と content のリスト.
Argument ARG-N : OpenAI API の引数nの値.
Argument SYNC-FUNC : OpenAI API を同期呼び出しで呼び出す場合は
  コールバック関数を指定する。非同期呼び出しの場合は、nilを指定する.
Argument DEFERRED-FUNC: 非同期呼び出し時のコールバック関数(1).
Argument DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2)."
  (let ((url "https://api.openai.com/v1/chat/completions"))
    (setq url-request-method "POST")
    (setq url-http-version "1.1")
    (setq url-request-extra-headers
          `(("Content-Type" . "application/json; charset=utf-8")
            ("Authorization" . ,(concat "Bearer " (getenv "OPENAI_API_KEY")))))
    (setq url-request-data
          (concat
           "{"
           (format "  \"model\": \"%s\"," sumibi-current-model)
           "  \"temperature\": 0.8,"
           (format  "  \"n\": %d," arg-n)
           "  \"messages\": [ "
           (string-join
            (-map
             (lambda (x)
               (format " {\"role\": \"%s\",    \"content\": \"%s\"}"
                       (car x)
                       (sumibi-escape-for-json (cdr x))))
             message-lst)
            ",")
           "  ] "
           "}"))
    (cond
     ((not deferred-func2) ;; 同期バージョン
      (let* ((lines
              (let ((buf (url-retrieve-synchronously url t t sumibi-api-timeout)))
                (sumibi-debug-print (buffer-name buf))
                (sumibi-debug-print "\n")
                (if buf
                    (with-current-buffer buf
                      (decode-coding-string
                       (let ((str (buffer-substring-no-properties (point-min) (point-max))))
                         (sumibi-debug-print (format "<<<%s>>>\n" str))
                         str)
                       'utf-8))
                  "{\"err\": \"!!TIMEOUT ERROR!!\"}\n")))
             (line-list
              (split-string lines "\n")))
        (funcall sync-func (cadr (reverse line-list)))))

     (t ;; 非同期バージョン
      (deferred:$
        (deferred:url-retrieve url)
        (deferred:nextc it
          (lambda (buf)
            (sumibi-debug-print (buffer-name buf))
            (sumibi-debug-print "\n")
            (if buf
                (with-current-buffer buf
                  (decode-coding-string
                   (let ((str (buffer-substring-no-properties (point-min) (point-max))))
                     (sumibi-debug-print (format "<<<%s>>>\n" str))
                     str)
                   'utf-8))
              "{\"err\": \"!!TIMEOUT ERROR!!\"}\n")))
        (deferred:nextc it
          (lambda (lines)
            (cadr (reverse (split-string lines "\n")))))
        (deferred:nextc it
          (lambda (json)
            (atomic-change-group
              (funcall deferred-func2)
              (sumibi-debug-print (format "<<<%s>>>\n" (funcall deferred-func json))))
            t))))
     '())))


(defun sumibi-drop-guide-sentence (utf8-str)
  "引数UTF8-STRで指定した文字列中のgpt-3.5-turboが出力する不要な定型文を削除する."
  (let ((lines (split-string utf8-str "\n")))
    (if
        (or (string-match "以下の通りです。[ ]*" (car lines))
            (string-match "以下のようになります。[ ]*" (car lines))
            (string-match "以下になります。[ ]*" (car lines)))
        (string-trim-left (string-join (cdr lines) "\n"))
      utf8-str)))

(defun sumibi-analyze-openai-json-obj (json-obj arg-n)
  "JSONから変換結果の文字列を取り出す.
引数JSON-OBJ: パース済みのJSONオブジェクト
引数ARG-N: 候補を何件返すか"
  (let ((result '())
        (count 0))
    (cond
     ((gethash "err" json-obj)
      (list (gethash "err" json-obj)))
     (t
      (while (< count arg-n)
        (let* ((hex-str
                (gethash "content"
                         (gethash "message"
                                  (aref (gethash "choices" json-obj) count))))
               (utf8-str
                (decode-coding-string (url-unhex-string hex-str) 'utf-8)))
          (setq result (cons (sumibi-drop-guide-sentence utf8-str) result)))
        (setq count (1+ count)))
      result))))

(defun sumibi-roman-to-kanji (roman arg-n deferred-func2)
  "ローマ字で書かれた文章をOpenAIサーバーを使って変換し、結果を文字列で返す.
ROMAN: \"bunsyou no mojiretu
ARG-N: 候補を何件返すか
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2).
戻り値: (\"1番目の文章の文字列\" \"2番目の文章の文字列\" \"3番目の文章の文字列\" ...)"
  (let ((saved-marker (point-marker)))
    (sumibi-openai-http-post
     (list
      (cons "system"
            (concat
             "あなたはローマ字とひらがなを日本語に変換するアシスタントです。"
             "ローマ字の 「nn」 は 「ん」と読んでください。"
             "[](URL)のようなmarkdown構文は維持してください。"
             "# や ## や ### や #### のようなmarkdown構文は維持してください。"))
      (cons "user"
            "ローマ字の文を漢字仮名混じり文にしてください。 : watashi no namae ha nakano desu .")
      (cons "assistant"
            "私の名前は中野です。")
      (cons "user"
            "ローマ字とひらがなの文を漢字仮名混じり文にしてください。 : ikano toori desu .")
      (cons "assistant"
            "以下の通りです。")
      (cons "user"
            "ローマ字とひらがなの文を漢字仮名混じり文にしてください。 : hannishitei shimasu")
      (cons "assistant"
            "範囲指定します")
      (cons "user"
            "ローマ字とひらがなの文を漢字仮名混じり文にしてください。 : We succeeded in taking a photo like this:\n![example](https://www.example.com/dir1/dir2/example.png)")
      (cons "assistant"
            "このような写真を撮ることに成功しました：\n![例](https://www.example.com/dir1/dir2/example.png)")
      (cons "user"
            "ローマ字とひらがなの文を漢字仮名混じり文にしてください。 : ## this is markdown section")
      (cons "assistant"
            "## これはMarkdownのセクションです。")
      (cons "user"
            (format "ローマ字の文を漢字仮名混じり文にしてください。 : %s" roman)))
     arg-n
     (lambda (json-str)
       (let ((json-obj (json-parse-string json-str)))
         (sumibi-analyze-openai-json-obj json-obj arg-n)))
     (lambda (json-str)
       (let* ((json-obj (json-parse-string json-str))
              (lst (sumibi-analyze-openai-json-obj json-obj arg-n)))
         (when lst
           (save-excursion
             (goto-char (marker-position saved-marker))
             (insert (car lst))
             (goto-char (marker-position saved-marker))))))
     deferred-func2)))

(defun sumibi-roman-to-yomigana (roman deferred-func2)
  "ローマ字で書かれた文章をOpenAIサーバーを使って読み仮名を返す.
ROMAN: \"shita\" や \"nano\"
ARG-N: 候補を何件返すか
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2).
戻り値: (\"した\" \"シタ\") や (\"なの\" \"ナノ\")"
  (let ((saved-marker (point-marker)))
    (sumibi-openai-http-post
     (list
      (cons "system"
            "あなたはローマ字をひらがなとカタカナに変換するアシスタントです。ローマ字の 「nn」 は 「ん」と読んでください。")
      (cons "user"
            "ローマ字をひらがなとカタカナにしてください : shita")
      (cons "assistant"
            "した シタ")
      (cons "user"
            "ローマ字をひらがなとカタカナにしてください : nano")
      (cons "assistant"
            "なの ナノ")
      (cons "user"
            "ローマ字をひらがなとカタカナにしてください : aiueokakikukeko")
      (cons "assistant"
            "あいうえおかきくけこ アイウエオカキクケコ")
      (cons "user"
            (format "ローマ字をひらがなとカタカナにしてください : %s" roman)))
     1
     (lambda (json-str)
       (let ((json-obj (json-parse-string json-str)))
         (split-string (car (sumibi-analyze-openai-json-obj json-obj 1)))))
     (lambda (json-str)
       (let* ((json-obj (json-parse-string json-str))
              (lst (split-string (car (sumibi-analyze-openai-json-obj json-obj 1)))))
         (if lst
             (save-excursion
               (goto-char (marker-position saved-marker))
               (insert (car lst))
               (goto-char (marker-position saved-marker))))))
     deferred-func2)))

(defun sumibi-kanji-to-yomigana (kanji deferred-func2)
  "漢字仮名混じりで書かれた文章をOpenAIサーバーを使って読み仮名を返す.
KANJI: \"日本語\" のような文字列
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2).
戻り値: (\"にほんご\" \"ニホンゴ\")"
  (let ((saved-marker (point-marker)))
    (sumibi-openai-http-post
     (list
      (cons "system"
            "あなたは漢字が与えられると、ひらがなとカタカナとその漢字の同音異義語を返すアシスタントです。")
      (cons "user"
            "ひらがなとカタカナと同音異義語をなるべく多く列挙してください。 : 東西南北")
      (cons "assistant"
            "とうざいなんぼく トウザイナンボク 東西南北")
      (cons "user"
            "ひらがなとカタカナと同音異義語をなるべく多く列挙してください。 : 漢字")
      (cons "assistant"
            "かんじ カンジ 漢字 感じ 幹事 監事 寛二")
      (cons "user"
            (format "ひらがなとカタカナと同音異義語をなるべく多く列挙してください。 : %s" kanji)))
     1
     (lambda (json-str)
       (let ((json-obj (json-parse-string json-str)))
         (split-string (car (sumibi-analyze-openai-json-obj json-obj 1)))))
     (lambda (json-str)
       (let* ((json-obj (json-parse-string json-str))
              (lst (split-string (car (sumibi-analyze-openai-json-obj json-obj 1)))))
         (if lst
             (save-excursion
               (goto-char (marker-position saved-marker))
               (insert (car lst))
               (goto-char (marker-position saved-marker))))))
     deferred-func2)))

(defun sumibi-kanji-to-english (kanji arg-n deferred-func2)
  "日本語の文章を、OpenAIサーバーを使って英語に翻訳する.
KANJI: \"私の名前は中野です。\" のような文字列
ARG-N: 候補を何件返すか
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2).
戻り値: (\"My name is Nakano.\" \"My name is Nakano.\" \"My name is Nakano.\")"
  (let ((saved-marker (point-marker)))
    (sumibi-openai-http-post
     (list
      (cons "system"
            "あなたは、与えられた文章を英語に翻訳するアシスタントです。")
      (cons "user"
            "文章を英語に翻訳してください。 : 私の名前は中野です。")
      (cons "assistant"
            "My name is Nakano.")
      (cons "user"
            "文章を英語に翻訳してください。 : GPTはOpenAIから2018年に以下の論文で提案されたモデルで、基本的にはTransformerをベースに、事前学習-ファインチューニングをすることで非常に高い精度を達成したモデルです。")
      (cons "assistant"
            "GPT is a model proposed by OpenAI in 2018 in the following paper, which is basically based on Transformer and achieves very high accuracy by pre-training - fine tuning.")
      (cons "user"
            (format "文章を英語に翻訳してください。 : %s" kanji)))
     arg-n
     (lambda (json-str)
       (let ((json-obj (json-parse-string json-str)))
         (sumibi-analyze-openai-json-obj json-obj arg-n)))
     (lambda (json-str)
       (let* ((json-obj (json-parse-string json-str))
              (lst (sumibi-analyze-openai-json-obj json-obj arg-n)))
         (if lst
             (save-excursion
               (goto-char (marker-position saved-marker))
               (insert (car lst))
               (goto-char (marker-position saved-marker))))))
     deferred-func2)))

(defun sumibi-determine-number-of-n (request-str)
  "引数REQUEST-STRからOpenAI APIの引数「n」に指定する数を決める."
  (if (<= sumibi-threshold-letters-of-long-sentence (length request-str))
      1
    3))

(defun sumibi-determine-sync-p (request-str)
  "引数REQUEST-STRからOpenAI APIを非同期で呼び出すかを決める."
  (> sumibi-threshold-letters-of-long-sentence (length request-str)))


(defun sumibi-inverse-henkan (roman arg-n deferred-func2)
  "日本語=>英語翻訳を実行する.
ROMAN: \"私の名前は中野です。\" のような文字列
ARG-N: 候補を何件返すか
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2)."
  (let ((lst (sumibi-kanji-to-english roman arg-n deferred-func2)))
    (append
     (-map
      (lambda (x)
        (list (car x)
              (format "候補%d" (+ 1 (cdr x)))
              0 'l (cdr x)))
      (-zip-pair
       lst
       '(0 1 2 3 4)))
     (list
      (list roman "原文まま" 0 'l (length lst))))))


(defun sumibi-nihongo-saihenkan (roman deferred-func2)
  "日本語を再変換する.
ROMAN: \"日本語\" のような変換済の文字列
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2)."
  (let* ((lst (sumibi-kanji-to-yomigana roman deferred-func2))
         (kouho-lst
          (-map
           (lambda (x)
             (list (car x)
                   (format "候補%d" (+ 1 (cdr x)))
                   0 'h (cdr x)))
           (-zip-pair
            lst
            '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)))))
    (append
     kouho-lst
     (list (list roman "原文まま" 0 'l (length kouho-lst))))))

(defun sumibi-alphabet-henkan (roman arg-n deferred-func2)
  "アルファベット(ローマ字or英語の文章)からカナ漢字混じり文へ変換する.
ROMAN: \"watashi no namae ha nakano desu\" のような文字列
ARG-N: 候補を何件返すか
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2)."
  (let ((lst (sumibi-roman-to-kanji roman arg-n deferred-func2)))
    (when (>= 10 (length roman))
      (setq lst
            (append
             lst
             (sumibi-roman-to-yomigana roman deferred-func2))))
    (append
     (-map
      (lambda (x)
        (list (car x)
              (format "候補%d" (+ 1 (cdr x)))
              0 'l (cdr x)))
      (-zip-pair
       lst
       '(0 1 2 3 4)))
     (list
      (list roman "原文まま" 0 'l (length lst))))))

(defun sumibi-henkan-request (roman inverse-flag deferred-func2)
  "ローマ字で書かれた文章を複数候補作成して返す.
ROMAN: \"watashi no namae ha nakano desu\" のような文字列
INVERSE-FLAG: 英語から日本語への逆変換の場合だけ t を指定する
DEFERRED-FUNC2: 非同期呼び出し時のコールバック関数(2)."
  (let ((fixed-kouho
         (-filter
          (lambda (x)
            (string= roman (car x)))
          sumibi-japanese-transliteration-rules)))
    (cond
     (inverse-flag
      (sumibi-inverse-henkan roman (sumibi-determine-number-of-n roman) deferred-func2))
     (t
      (cond
       ;; 固定の変換キーワードの場合(wo ha ga...)
       ((< 0 (length fixed-kouho))
        (list (list (cadr (car fixed-kouho)) "固定文字列" 0 'j 0)))
       ;; 漢字を含む場合
       ((sumibi-string-include-kanji roman)
        (sumibi-nihongo-saihenkan roman deferred-func2))
       (t
        (sumibi-alphabet-henkan roman (sumibi-determine-number-of-n roman) deferred-func2)))))))


(defun sumibi-file-existp (file)
  "FILE が存在するかどうかをチェックする。 t か nil で結果を返す."
  (let* ((file (or (car-safe file)
                   file))
         (file (expand-file-name file)))
    (file-exists-p file)))



(defun sumibi-henkan-region-sync (b e inverse-flag)
  "リージョンをローマ字漢字変換する(同期関数バージョン).
Argument B: リージョンの開始位置
Argument E: リージョンの終了位置
Argument INVERSE-FLAG：逆変換かどうか"
  (when (/= b e)
    (let* (
           (yomi (buffer-substring-no-properties b e))
           (henkan-list (sumibi-henkan-request yomi inverse-flag nil)))
      (if henkan-list
          (condition-case err
              (progn
                (setq
                 ;; 変換結果の保持
                 sumibi-henkan-kouho-list henkan-list
                 ;; 文節選択初期化
                 sumibi-cand-cur 0
                 ;; 
                 sumibi-cand-len (length henkan-list))
                
                (sumibi-debug-print (format "sumibi-henkan-kouho-list:%s \n" sumibi-henkan-kouho-list))
                (sumibi-debug-print (format "sumibi-cand-cur:%s \n" sumibi-cand-cur))
                (sumibi-debug-print (format "sumibi-cand-len:%s \n" sumibi-cand-len))

                ;; 同期で変換が成功した場合は、変換候補の保存を行う
                (if (eq (char-before b) ?/)
                    (setq b (- b 1)))
                (setq sumibi-last-roman (buffer-substring-no-properties b e))
                (delete-region b e)
                (goto-char b)
                (insert (sumibi-get-display-string))
                (setq e (point))
                (sumibi-display-function b e nil)
                (sumibi-select-kakutei)
                t)
            (sumibi-trap-server-down
             (beep)
             (message (error-message-string err))
             (setq sumibi-select-mode nil))
            (run-hooks 'sumibi-select-mode-end-hook))
        nil))))


(defun sumibi-henkan-region-async (b e inverse-flag)
  "リージョンをローマ字漢字変換する(非同期関数バージョン).
Argument B: リージョンの開始位置
Argument E: リージョンの終了位置
Argument INVERSE-FLAG：逆変換かどうか"
  (when (/= b e)
    (let ((yomi (buffer-substring-no-properties b e))
          (saved-b-marker 0)
          (saved-e-marker 0)
          (cur-buf (current-buffer)))
      (deactivate-mark)
      (goto-char e)
      (setq saved-e-marker (point-marker))
      (goto-char b)
      (setq saved-b-marker (point-marker))
      (goto-char e)
      (let ((yomi-overlay (make-overlay b e)))
        (overlay-put yomi-overlay 'display yomi)
        (overlay-put yomi-overlay 'face '(:foreground "gray"))
        (sumibi-henkan-request
         yomi
         inverse-flag
         (lambda ()
           (with-current-buffer cur-buf
             (save-excursion
               (delete-overlay yomi-overlay)
               (delete-region (marker-position saved-b-marker)
                              (marker-position saved-e-marker))))))))))

(defun sumibi-henkan-region (b e inverse-flag)
  "指定された region を漢字変換する.  同期か非同期かはBからEまでの文字数で決定する.
Argument B: リージョンの開始位置
Argument E: リージョンの終了位置
Argument INVERSE-FLAG：逆変換かどうか"
  (sumibi-init)
  (when sumibi-init
    (when (/= b e)
      (if (sumibi-determine-sync-p (buffer-substring-no-properties b e))
          (sumibi-henkan-region-sync b e inverse-flag)
        (sumibi-henkan-region-async b e inverse-flag)))))



(defun sumibi-char-charset (ch)
  "引数CHで指定した、カーソル前の文字種を返却する."
  (let ((result (char-charset ch)))
    (if (multibyte-string-p (char-to-string ch))
        'japanese-jisx0208
      result)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; undo 情報の制御
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; undo buffer 退避用変数
(defvar sumibi-buffer-undo-list nil)
(make-variable-buffer-local 'sumibi-buffer-undo-list)
(defvar sumibi-buffer-modified-p nil)
(make-variable-buffer-local 'sumibi-buffer-modified-p)

(defvar sumibi-blink-cursor nil)
(defvar sumibi-cursor-type nil)

(defun sumibi-disable-undo ()
  "Undo bufferを退避し、undo 情報の蓄積を停止する."
  (when (not (eq buffer-undo-list t))
    (setq sumibi-buffer-undo-list buffer-undo-list)
    (setq sumibi-buffer-modified-p (buffer-modified-p))
    (setq buffer-undo-list t)))

(defun sumibi-enable-undo ()
  "退避した undo buffer を復帰し、undo 情報の蓄積を再開する."
  (when (not sumibi-buffer-modified-p) (set-buffer-modified-p nil))
  (when sumibi-buffer-undo-list
    (setq buffer-undo-list sumibi-buffer-undo-list)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 現在の変換エリアの表示を行う
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sumibi-get-display-string ()
  "変換結果文字列を返す."
  (let* ((kouho      (nth sumibi-cand-cur sumibi-henkan-kouho-list))
         (_          (sumibi-debug-print (format "sumibi-cand-cur=%s\n" sumibi-cand-cur)))
         (_          (sumibi-debug-print (format "kouho=%s\n" kouho)))
         (word       (car kouho))
         (annotation (cadr kouho)))
    (sumibi-debug-print (format "word:[%d] %s(%s)\n" sumibi-cand-cur word annotation))
    word))

(defun sumibi-display-function (b e select-mode)
  "変換結果文字列をバッファに埋め込む形で表示する.
Argument B: リージョンの開始位置
Argument E: リージョンの終了位置
Argument SELECT-MODE：選択状態"
  (let ((insert-word (sumibi-get-display-string))
        (word (buffer-substring-no-properties b e)))
    (cond
     ((and (not select-mode)
           (string-equal insert-word word))
      ;; sumibi-markersの更新
      (setq sumibi-fence-start (progn
                                 (goto-char b)
                                 (point-marker)))
      (setq sumibi-fence-end   (progn
                                 (goto-char e)
                                 (point-marker)))
      (setq sumibi-markers
            (cons sumibi-fence-start sumibi-fence-end))

      ;; 確定文字列の作成
      (setq sumibi-last-fix insert-word)
      
      (sumibi-debug-print (format "don't touch:[%s] point:%d-%d\n" insert-word (marker-position sumibi-fence-start) (marker-position sumibi-fence-end))))

     (t
      (setq sumibi-henkan-separeter (if sumibi-use-fence " " ""))
      (when sumibi-henkan-kouho-list
        ;; UNDO抑制開始
        (sumibi-disable-undo)
        
        (delete-region b e)

        ;; リスト初期化
        (setq sumibi-markers '())

        (setq sumibi-last-fix "")

        ;; 変換したpointの保持
        (setq sumibi-fence-start (point-marker))
        (when select-mode (insert "|"))
        
        (let* (
               (start       (point-marker)))
          (progn
            (insert insert-word)
            (message "[%s] candidate (%d/%d)" insert-word (+ sumibi-cand-cur 1) sumibi-cand-len)
            (let* ((end         (point-marker))
                   (ov          (make-overlay start end)))
              
              ;; 確定文字列の作成
              (setq sumibi-last-fix insert-word)
              
              ;; 選択中の場所を装飾する。
              (when select-mode
                (overlay-put ov 'face 'default)
                (overlay-put ov 'face 'highlight))
              (setq sumibi-markers (cons start end))
              (sumibi-debug-print (format "insert:[%s] point:%d-%d\n" insert-word (marker-position start) (marker-position end))))))
        
        ;; fenceの範囲を設定する
        (when select-mode (insert "|"))
        (setq sumibi-fence-end   (point-marker))
        
        (sumibi-debug-print (format "total-point:%d-%d\n"
                                    (marker-position sumibi-fence-start)
                                    (marker-position sumibi-fence-end)))
        ;; UNDO再開
        (sumibi-enable-undo))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 変換候補選択モード
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar sumibi-popup-menu-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map "\r"        'popup-select)
    (define-key map "\C-f"      'popup-open)
    (define-key map [right]     'popup-open)
    (define-key map "\C-b"      'popup-close)
    (define-key map [left]      'popup-close)

    (define-key map "\C-n"      'popup-next)
    (define-key map "\C-j"      'popup-next)
    (define-key map (kbd "SPC") 'popup-next)
    (define-key map [down]      'popup-next)
    (define-key map "\C-p"      'popup-previous)
    (define-key map [up]        'popup-previous)

    (define-key map [f1]        'popup-help)
    (define-key map (kbd "\C-?") 'popup-help)

    (define-key map "\C-s"      'popup-isearch)
    (define-key map "\C-g"      'popup-close)
    (define-key map "\C-r"      'popup-select)
    map))



(defun sumibi-select-operation-inc ()
  "選択操作回数のインクリメント."
  (cl-incf sumibi-select-operation-times)
  (when (< 3 sumibi-select-operation-times)
    (sumibi-select-operation-reset)
    (let* ((lst
            (mapcar
             (lambda (x)
               (concat
                (nth sumibi-tango-index x)
                "   ; "
                (nth sumibi-annotation-index x)))
             sumibi-henkan-kouho-list))
           (result
            (popup-menu* lst
                         :scroll-bar t
                         :margin t
                         :keymap sumibi-popup-menu-keymap
                         :initial-index sumibi-cand-cur)))
      (let ((selected-word (car (split-string result " "))))
        (setq sumibi-cand-cur (sumibi-find-by-tango selected-word))))))



(defun sumibi-select-operation-reset ()
  "選択操作回数のリセット."
  (setq sumibi-select-operation-times 0))

(defun sumibi-kakutei-and-self-insert (_arg)
  "候補選択を確定し、入力された文字を入力する.
_ARG: (未使用)"
  (interactive "P")
  (sumibi-select-kakutei)
  (setq unread-command-events (list last-command-event)))

(defun sumibi-select-update-display ()
  "候補選択状態での表示更新."
  (sumibi-display-function
   (marker-position sumibi-fence-start)
   (marker-position sumibi-fence-end)
   sumibi-select-mode))

(defun sumibi-select-kakutei ()
  "候補選択を確定する."
  (interactive)
  ;; 候補番号リストをバックアップする。
  (setq sumibi-cand-cur-backup sumibi-cand-cur)
  (setq sumibi-select-mode nil)
  (run-hooks 'sumibi-select-mode-end-hook)
  (sumibi-select-operation-reset)
  (sumibi-select-update-display)
  (sumibi-history-push))


(defun sumibi-select-cancel ()
  "候補選択をキャンセルする."
  (interactive)
  ;; カレント候補番号をバックアップしていた候補番号で復元する。
  (setq sumibi-cand-cur sumibi-cand-cur-backup)
  (setq sumibi-select-mode nil)
  (run-hooks 'sumibi-select-mode-end-hook)
  (sumibi-select-update-display)
  (sumibi-history-push))

(defun sumibi-select-prev ()
  "前の候補に進める."
  (interactive)
  ;; 前の候補に切りかえる
  (cl-decf sumibi-cand-cur)
  (when (> 0 sumibi-cand-cur)
    (setq sumibi-cand-cur (- sumibi-cand-len 1)))
  (sumibi-select-operation-inc)
  (sumibi-select-update-display))

(defun sumibi-select-next ()
  "次の候補に進める."
  (interactive)
  ;; 次の候補に切りかえる
  (setq sumibi-cand-cur
        (if (< sumibi-cand-cur (- sumibi-cand-len 1))
            (+ sumibi-cand-cur 1)
          0))
  (sumibi-select-operation-inc)
  (sumibi-select-update-display))

(defun sumibi-find-by-tango ( tango )
  "指定された TANGO のindex番号を返す."
  (let ((result-index nil))
    (mapc
     (lambda (x)
       (when (string-equal (nth sumibi-tango-index x) tango)
         (setq result-index (nth sumibi-id-index x))))
     sumibi-henkan-kouho-list)
    (sumibi-debug-print (format "sumibi-find-by-tango: tango=%s result=%S \n" tango result-index))
    result-index))

(defun sumibi-select-by-type-filter (type)
  "指定された TYPE の候補を抜き出す."
  (let ((lst '()))
    (mapc
     (lambda (x)
       (let ((sym (nth sumibi-kind-index x)))
         (when (eq sym type)
           (push x lst))))
     sumibi-henkan-kouho-list)
    (sumibi-debug-print (format "filtered-lst = %S\n" (reverse lst)))
    (if (null lst)
        nil
      (reverse lst))))


(defun sumibi-include-typep (type)
  "指定された TYPE の候補が存在するか調べる."
  (sumibi-select-by-type-filter type))

(defun sumibi-select-by-type (type)
  "指定された TYPE の候補に強制的に切りかえる.
切りかえが成功したかどうかを t or nil で返す"
  (let ((kouho (car (sumibi-select-by-type-filter type))))
    (if (not kouho)
        (progn
          (cond
           ((eq type 'j)
            (message "Sumibi: 漢字の候補はありません。"))
           ((eq type 'h)
            (message "Sumibi: ひらがなの候補はありません。"))
           ((eq type 'k)
            (message "Sumibi: カタカナの候補はありません。"))
           ((eq type 'l)
            (message "Sumibi: 半角の候補はありません。"))
           ((eq type 'z)
            (message "Sumibi: 全角の候補はありません。"))
           ((eq type 'n)
            (message "Sumibi: 数字混在の候補はありません．")))
          nil)
      (let ((num   (nth sumibi-id-index kouho)))
        (setq sumibi-cand-cur num)
        (sumibi-select-update-display)
        t))))

(defun sumibi-select-kanji ()
  "漢字候補に強制的に切りかえる."
  (interactive)
  (sumibi-select-by-type 'j))

(defun sumibi-select-hiragana ()
  "ひらがな候補に強制的に切りかえる."
  (interactive)
  (sumibi-select-by-type 'h))

(defun sumibi-select-katakana ()
  "カタカナ候補に強制的に切りかえる."
  (interactive)
  (sumibi-select-by-type 'k))

(defun sumibi-select-hankaku ()
  "半角候補に強制的に切りかえる."
  (interactive)
  (sumibi-select-by-type 'l))

(defun sumibi-select-zenkaku ()
  "半角候補に強制的に切りかえる."
  (interactive)
  (sumibi-select-by-type 'z))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 変換履歴操作関数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun sumibi-history-gc ()
  "変数sumibi-history-stack中の無効なマークを持つエントリを削除する."
  (sumibi-debug-print (format "sumibi-history-gc before len=%d\n" (length sumibi-history-stack)))

  (let ((temp-list '()))
    (mapc
     (lambda (alist)
       (let ((markers  (sumibi-assoc-ref 'markers  alist nil)))
         (sumibi-debug-print (format "markers=%S\n" markers))
         (sumibi-debug-print (format "marker-position car=%S\n" (marker-position (car markers))))
         (sumibi-debug-print (format "marker-position cdr=%S\n" (marker-position (cdr markers))))
         (when (and (marker-position (car markers))     ;; 存在するバッファを指しているか
                    (marker-position (cdr markers)))
           (if (= (marker-position (car markers))
                  (marker-position (cdr markers)))
               ;; マークの開始と終了が同じ位置を指している場合は、
               ;; そのマークは既に無効(選択モードの再表示で一旦マーク周辺の文字列が削除された)
               (progn
                 (set-marker (car markers) nil)
                 (set-marker (cdr markers) nil))
             (push alist temp-list)))))
     sumibi-history-stack)

    (sumibi-debug-print (format "sumibi-history-gc temp-list  len=%d\n" (length temp-list)))

    ;; temp-list から limit 件数だけコピーする
    (setq sumibi-history-stack '())
    (mapc
     (lambda (alist)
       (when (< (length sumibi-history-stack)
                sumibi-history-stack-limit)
         (push alist sumibi-history-stack)))
     (reverse temp-list)))
  (sumibi-debug-print (format "sumibi-history-gc after  len=%d\n" (length sumibi-history-stack))))


(defun sumibi-history-search (_point load-flag)
  "確定ヒストリから、指定_POINTに変換済の単語が埋まっているかどうか調べる.
戻り値: t か nil を返す
補足: LOAD-FLAG に 真を渡すと、見付かった情報で、現在の変換候補変数にロードしてくれる"
  (sumibi-history-gc)

  ;; カーソル位置に有効な変換済エントリがあるか探す
  (let ((found nil))
    (mapc
     (lambda (alist)
       (let* ((markers  (sumibi-assoc-ref 'markers  alist nil))
              (last-fix (sumibi-assoc-ref 'last-fix alist ""))
              (end      (marker-position (cdr markers)))
              (start    (- end (length last-fix)))
              (bufname  (sumibi-assoc-ref 'bufname alist ""))
              (pickup   (if (string-equal bufname (buffer-name))
                            (buffer-substring start end)
                          "")))
         (sumibi-debug-print (format "sumibi-history-search  bufname:   [%s]\n"   bufname))
         (sumibi-debug-print (format "sumibi-history-search  (point):   %d\n"     (point)))
         (sumibi-debug-print (format "sumibi-history-search    range:   %d-%d\n"  start end))
         (sumibi-debug-print (format "sumibi-history-search last-fix:   [%s]\n"   last-fix))
         (sumibi-debug-print (format "sumibi-history-search   pickup:   [%s]\n"   pickup))
         (when (and
                (string-equal bufname (buffer-name))
                (<  start   (point))
                (<= (point) end)
                (string-equal last-fix pickup))
           (setq found t)
           (when load-flag
             (setq sumibi-markers            (cons
                                              (move-marker (car markers) start)
                                              (cdr markers)))
             (setq sumibi-cand-cur           (sumibi-assoc-ref 'cand-cur alist           nil))
             (setq sumibi-cand-cur-backup    (sumibi-assoc-ref 'cand-cur-backup alist    nil))
             (setq sumibi-cand-len           (sumibi-assoc-ref 'cand-len alist           nil))
             (setq sumibi-last-fix           pickup)
             (setq sumibi-henkan-kouho-list  (sumibi-assoc-ref 'henkan-kouho-list alist  nil))

             (sumibi-debug-print (format "sumibi-history-search : sumibi-markers         : %S\n" sumibi-markers))
             (sumibi-debug-print (format "sumibi-history-search : sumibi-cand-cur        : %S\n" sumibi-cand-cur))
             (sumibi-debug-print (format "sumibi-history-search : sumibi-cand-cur-backup : %S\n" sumibi-cand-cur-backup))
             (sumibi-debug-print (format "sumibi-history-search : sumibi-cand-len %S\n" sumibi-cand-len))
             (sumibi-debug-print (format "sumibi-history-search : sumibi-last-fix %S\n" sumibi-last-fix))
             (sumibi-debug-print (format "sumibi-history-search : sumibi-henkan-kouho-list %S\n" sumibi-henkan-kouho-list))))))
     sumibi-history-stack)
    found))

(defun sumibi-history-push ()
  "確定ヒストリにエントリーを追加する."
  (push
   `(
     (markers            . ,sumibi-markers            )
     (cand-cur           . ,sumibi-cand-cur           )
     (cand-cur-backup    . ,sumibi-cand-cur-backup    )
     (cand-len           . ,sumibi-cand-len           )
     (last-fix           . ,sumibi-last-fix           )
     (henkan-kouho-list  . ,sumibi-henkan-kouho-list  )
     (bufname            . ,(buffer-name)))
   sumibi-history-stack)
  (sumibi-debug-print (format "sumibi-history-push result: %S\n" sumibi-history-stack)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ローマ字漢字変換関数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sumibi-rK-trans ()
  "ローマ字漢字変換をする.
カーソルから行頭方向にローマ字列が続く範囲でローマ字漢字変換を行う."
  (interactive)
  (sumibi-debug-print "sumibi-rK-trans()")

  (cond
   ;; region指定している場合
   ((region-active-p)
    (let ((b (region-beginning))
          (e (region-end)))
      (sumibi-henkan-region b e nil)))

   ;; region指定していない場合
   (t
    ;; 最後に変換した行番号の更新
    (setq sumibi-last-lineno (line-number-at-pos (point)))

    (cond
     (sumibi-select-mode
      (sumibi-debug-print "<<sumibi-select-mode>>\n")
      ;; 候補選択モード中に呼出されたら、keymapから再度候補選択モードに入る
      (funcall (lookup-key sumibi-select-mode-map sumibi-rK-trans-key)))

     (t
      (cond

       ((eq (sumibi-char-charset (preceding-char)) 'ascii)
        (sumibi-debug-print (format "ascii? (%s) => t\n" (preceding-char)))
        ;; カーソル直前が alphabet だったら
        (let ((end (point))
              (gap (sumibi-skip-chars-backward)))
          (when (/= gap 0)
            ;; 意味のある入力が見つかったので変換する
            (let (
                  (b (+ end gap))
                  (e end))
              (sumibi-henkan-region b e nil)))))
       
       ((or (sumibi-kanji (preceding-char))
            (sumibi-nkanji (preceding-char)))
        (sumibi-debug-print (format "sumibi-kanji(%s) or sumibi-nkanji(%s) => t\n"
                                    (preceding-char)
                                    (preceding-char)))
        ;; カーソル直前が 全角で漢字以外 だったら候補選択モードに移行する。
        ;; また、最後に確定した文字列と同じかどうかも確認する。
        (when (sumibi-history-search (point) t)
          ;; 直前に変換したfenceの範囲に入っていたら、候補選択モードに移行する。
          (setq sumibi-select-mode t)
          (sumibi-debug-print "henkan mode ON\n")
          
          ;; 表示状態を候補選択モードに切替える。
          (sumibi-display-function
           (marker-position (car sumibi-markers))
           (marker-position (cdr sumibi-markers))
           t)))

       (t
        (sumibi-debug-print (format "<<OTHER:non-ascii,non-kanji>> (%s)\n" (preceding-char))))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 英語への翻訳関数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sumibi-english-trans ()
  "英語への翻訳を行う."
  (interactive)
  (sumibi-debug-print "sumibi-english-trans()")

  ;; region指定している場合しか発動しない。
  (when (region-active-p)
    (let ((b (region-beginning))
          (e (region-end)))
      (sumibi-henkan-region b e t))))


(defun sumibi-string-include-kanji (str)
  "STRが漢字を含む文字列であるかどうかの判定関数."
  (let ((kanji-lst
         (-filter
          (lambda (x)
            (if (string-equal x "")
                nil
              (sumibi-kanji (string-to-char x))))
          (split-string str ""))))
    (< 0 (length kanji-lst))))

(defun sumibi-nkanji (ch)
  "文字CHが全角で漢字以外かを判定する."
  (and (eq (sumibi-char-charset ch) 'japanese-jisx0208)
       (not (string-match "[亜-黑]" (char-to-string ch)))))


(defun sumibi-kanji (ch)
  "文字CHが全角で漢字かを判定する."
  (and (eq (sumibi-char-charset ch) 'japanese-jisx0208)
       (string-match "[亜-黑]" (char-to-string ch))))


(defun sumibi-skip-chars-backward ()
  "ローマ字漢字変換時、変換対象とするローマ字を読み飛ばす."
  (let* (
         (skip-chars
          (if auto-fill-function
              ;; auto-fill-mode が有効になっている場合改行があってもskipを続ける
              (concat sumibi-skip-chars "\n")
            ;; auto-fill-modeが無効の場合はそのまま
            sumibi-skip-chars))
         
         ;; マークされている位置を求める。
         (pos (or (and (markerp (mark-marker)) (marker-position (mark-marker)))
                  1))

         ;; 条件にマッチする間、前方方向にスキップする。
         (result (save-excursion
                   (skip-chars-backward skip-chars (and (< pos (point)) pos))))
         (limit-point 0))

    (if auto-fill-function
        ;; auto-fill-modeが有効の時
        (progn
          (save-excursion
            (backward-paragraph)
            (when (< 1 (point))
              (forward-line 1))
            (beginning-of-line)
            (let (
                  (start-point (point)))
              (setq limit-point
                    (+
                     start-point
                     (skip-chars-forward sumibi-stop-chars (point-at-eol))))))

          ;; (sumibi-debug-print (format "(point) = %d  result = %d  limit-point = %d\n" (point) result limit-point))
          ;; (sumibi-debug-print (format "a = %d b = %d \n" (+ (point) result) limit-point))

          ;; パラグラフ位置でストップする
          (if (< (+ (point) result) limit-point)
              (-
               limit-point
               (point))
            result))

      ;; auto-fill-modeが無効の時
      (progn
        (save-excursion
          (beginning-of-line)
          (let (
                (start-point (point)))
            (setq limit-point
                  (+
                   start-point
                   (skip-chars-forward sumibi-stop-chars (point-at-eol))))))

        ;; (sumibi-debug-print (format "(point) = %d  result = %d  limit-point = %d\n" (point) result limit-point))
        ;; (sumibi-debug-print (format "a = %d b = %d \n" (+ (point) result) limit-point))

        (if (< (+ (point) result) limit-point)
            ;; インデント位置でストップする。
            (-
             limit-point
             (point))
          result)))))


(defun sumibi-insert-space (times)
  "TIMESで指定した回数スペース文字を挿入する."
  (if (null times)
      (insert " ")
    (dotimes(_ times)
      (insert " "))))

;; sumibi-mode の状態変更関数
;;  正の引数の場合、常に sumibi-mode を開始する
;;  {負,0}の引数の場合、常に sumibi-mode を終了する
;;  引数無しの場合、sumibi-mode をトグルする

;; buffer 毎に sumibi-mode を変更する
(defun sumibi-mode (&optional arg)
  "Sumibi mode は ローマ字から直接漢字変換するための minor mode です.
引数に正数を指定した場合は、Sumibi mode を有効にします

Sumibi モードが有効になっている場合 \\<sumibi-mode-map>\\[sumibi-rK-trans] で
point から行頭方向に同種の文字列が続く間を漢字変換します

同種の文字列とは以下のものを指します
・半角カタカナとsumibi-stop-chars に指定した文字を除く半角文字
・漢字を除く全角文字
引数 ARG は未使用"
  (interactive "P")
  (sumibi-mode-internal arg nil))

;; 全バッファで sumibi-mode を変更する
(defun global-sumibi-mode (&optional arg)
  "Sumibi mode は ローマ字から直接漢字変換するための minor mode です.
引数に正数を指定した場合は、Sumibi mode を有効にします

Sumibi モードが有効になっている場合 \\<sumibi-mode-map>\\[sumibi-rK-trans] で
point から行頭方向に同種の文字列が続く間を漢字変換します

同種の文字列とは以下のものを指します。
・半角カタカナとsumibi-stop-chars に指定した文字を除く半角文字
・漢字を除く全角文字
引数 ARG は未使用"
  (interactive "P")
  (sumibi-mode-internal arg t))



(defun sumibi-mode-internal (arg global)
  "Sumibi modeを変更する共通関数.
引数ARG: 未使用
引数GLOBAL: Sumibi modeをどのバッファでも有効にするグローバルモードにする"
  (sumibi-debug-print "sumibi-mode-internal :1\n")

  (or (local-variable-p 'sumibi-mode (current-buffer))
      (make-local-variable 'sumibi-mode))
  (if global
      (progn
        (setq default-input-method "japanese-sumibi")
        (setq-default sumibi-mode (if (null arg) (not sumibi-mode)
                                    (> (prefix-numeric-value arg) 0)))
        (sumibi-kill-sumibi-mode))
    (setq sumibi-mode (if (null arg) (not sumibi-mode)
                        (> (prefix-numeric-value arg) 0))))
  (when sumibi-mode (run-hooks 'sumibi-mode-hook))

  (sumibi-debug-print "sumibi-mode-internal :2\n"))



(defun sumibi-kill-sumibi-mode ()
  "バッファローカルな `sumibi-mode` を削除する."
  (let ((buf (buffer-list)))
    (while buf
      (set-buffer (car buf))
      (kill-local-variable 'sumibi-mode)
      (setq buf (cdr buf)))))


;; 全バッファで sumibi-input-mode を変更する
(defun sumibi-input-mode (&optional arg)
  "入力モード変更.
引数ARG: 未使用"
  (interactive "P")
  (if (< 0 arg)
      (progn
        (setq deactivate-current-input-method-function 'sumibi-inactivate)
        (setq sumibi-mode t))
    (setq deactivate-current-input-method-function nil)
    (setq sumibi-mode nil)))


;; input method 対応
(defun sumibi-activate (&rest _arg)
  "入力モードを有効にする.
引数_ARG: 未使用"
  (sumibi-input-mode 1))
(defun sumibi-inactivate (&rest _arg)
  "入力モードを無効にする.
引数_ARG: 未使用"
  (sumibi-input-mode -1))
(register-input-method
 "japanese-sumibi" "Japanese" 'sumibi-activate
 "" "Roman -> Kanji&Kana"
 nil)

;; input-method として登録する。
(set-language-info "Japanese" 'input-method "japanese-sumibi")


(defconst sumibi-version
  "1.6.3" ;;SUMIBI-VERSION
  )
(defun sumibi-version (&optional _arg)
  "Sumibiのバージョン番号をミニバッファに表示する.
引数_ARG: 未使用"
  (interactive "P")
  (message sumibi-version))

(provide 'sumibi)


(when nil
  ;; unti test
  (sumibi-henkan-request "watashi no namae ha nakano desu ." nil (lambda ()))
  (sumibi-henkan-request "2kome no bunsyou desu ." nil (lambda ())))

(when nil
  ;; unit test
  (sumibi-henkan-request "読みがな" nil t))

(when nil
  ;; unit test
  (sumibi-henkan-request "私の名前は中野です。" t t))


;; Local Variables:
;; coding: utf-8
;; End:

;;; sumibi.el ends here
