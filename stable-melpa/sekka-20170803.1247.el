;;; sekka.el --- A client for Sekka IME server
;;
;; Copyright (C) 2010-2014 Kiyoka Nishiyama
;;
;; Author: Kiyoka Nishiyama <kiyoka@sumibi.org>
;; Version: 1.8.0          ;;SEKKA-VERSION
;; Package-Version: 20170803.1247
;; Package-Commit: 61840b57d9ae32bf8e297b175942590a1319c7e7
;; Keywords: ime, skk, japanese
;; Package-Requires: ((cl-lib "0.3") (concurrent "0.3.1") (popup "0.5.2"))
;; URL: https://github.com/kiyoka/sekka
;;
;; This file is part of Sekka
;; This program was derived from sumibi.el and yc.el-4.0.13(auther: knak)
;;
;; Sekka is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; Sekka is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Sekka; see the file COPYING.
;;

;;; Commentary:

;; Sekka is yet another Japanese Input Method inspired by SKK.
;; sekka.el is a client for Sekka IME server.
;; [https://github.com/kiyoka/sekka]
;;
;; you might want to enable IME:
;;
;;  (require 'sekka)
;;  (global-sekka-mode 1)
;;
;; To enable sticky-shift with ";" key:
;;
;;  (setq sekka-sticky-shift t)
;;
;;

;;; Code:
(require 'cl)
(require 'popup)
(require 'url-parse)
(require 'concurrent)

;;; 
;;;
;;; customize variables
;;;
(defgroup sekka nil
  "Sekka client."
  :group 'input-method
  :group 'Japanese)

(defcustom sekka-server-url "http://127.0.0.1:12929/"
  "SekkaサーバーのURLを指定する。"
  :type  'string
  :group 'sekka)

(defcustom sekka-server-url-2 ""
  "SekkaサーバーのURLを指定する。"
  :type  'string
  :group 'sekka)

(defcustom sekka-server-url-3 ""
  "SekkaサーバーのURLを指定する。"
  :type  'string
  :group 'sekka)

(defcustom sekka-server-timeout 10
  "Sekkaサーバーと通信する時のタイムアウトを指定する。(秒数)"
  :type  'integer
  :group 'sekka)
 
(defcustom sekka-stop-chars "(){}<> "
  "*漢字変換文字列を取り込む時に変換範囲に含めない文字を設定する"
  :type  'string
  :group 'sekka)

(defcustom sekka-use-curl t
  "non-nil でcurlコマンドを優先して使う。nilで変換動作だけEmacs Lisp(url.el)を使う"
  :type  'boolean
  :group 'sekka)

(defcustom sekka-curl "curl"
  "curlコマンドの絶対パスを設定する"
  :type  'string
  :group 'sekka)

(defcustom sekka-no-proxy-hosts ""
  "http proxyを使わないホスト名を指定する。複数指定する場合は、コンマで区切る。"
  :type  'string
  :group 'sekka)

(defcustom sekka-realtime-guide-running-seconds 30
  "リアルタイムガイド表示の継続時間(秒数)・ゼロでガイド表示機能が無効になる"
  :type  'integer
  :group 'sekka)

(defcustom sekka-realtime-guide-limit-lines 2
  "最後に変換した行から N 行離れたらリアルタイムガイド表示が止まる"
  :type  'integer
  :group 'sekka)

(defcustom sekka-realtime-guide-interval  0.2
  "リアルタイムガイド表示を更新する時間間隔"
  :type  'float
  :group 'sekka)

(defcustom sekka-roman-method "normal"
  "ローマ字入力方式として，normal(通常ローマ字)か、AZIK(拡張ローマ字)のどちらの解釈を優先するか"
  :type '(choice (const :tag "normal" "normal")
		 (const :tag "AZIK"   "azik"  ))
  :group 'sekka)

(defcustom sekka-history-stack-limit 100
  "再度候補選択できる単語と場所を最大何件記憶するか"
  :type  'integer
  :group 'sekka)

(defcustom sekka-keyboard-type "jp"
  "キーボードの指定: 使っているキーボードはjp(日本語106キーボード)、en(英語usキーボード)のどちらか"
  :type '(choice (const :tag "jp106-keyboard"       "jp")
		 (const :tag "english(us)-keyboard" "en"))
  :group 'sekka)

(defcustom sekka-jisyo-filename "~/.sekka-jisyo"
  "sekka-jisyoのファイル名を指定する"
  :type  'string
  :group 'sekka)

(defcustom sekka-use-googleime t
  "変換結果に、漢字のエントリ type=j が含まれていなかったら、自動的にGoogleIMEを APIを使って変換候補を取得する。
non-nil で明示的に呼びだすまでGoogleIMEは起動しない。"
  :type  'boolean
  :group 'sekka)

(defcustom sekka-kakutei-with-spacekey nil
  "*Non-nil であれば、リアルタイムガイド表示中のSPACEキーでの確定動作を有効にする"
  :type  'boolean
  :group 'sekka)


(defface sekka-guide-face
  '((((class color) (background light)) (:background "#E0E0E0" :foreground "#F03030")))
  "リアルタイムガイドのフェイス(装飾、色などの指定)"
  :group 'sekka)


(defvar sekka-muhenkan-key nil     "*Non-nil であれば、リアルタイムガイド表示中は指定したキーで無変換のままスペースを挿入する。アルファベット文字１文字を指定すること")
(defvar sekka-sticky-shift nil     "*Non-nil であれば、Sticky-Shiftを有効にする")
(defvar sekka-mode nil             "漢字変換トグル変数")
(defun sekka-modeline-string ()
  ;; 接続先sekka-serverのホスト名を表示する。
  (format " Sekka[%s%s%s]"
	  (if current-sekka-server-url
	      (url-host
	       (url-generic-parse-url current-sekka-server-url))
	    "")
          (if current-sekka-server-url
              (format ":%d"
                      (url-port
                       (url-generic-parse-url current-sekka-server-url)))
            "")
	  (if sekka-uploading-flag
	      "(UPLOADING)"
	    "")))
(defvar sekka-select-mode nil      "候補選択モード変数")
(or (assq 'sekka-mode minor-mode-alist)
    (setq minor-mode-alist (cons
			    '(sekka-mode (:eval (sekka-modeline-string)))
			    minor-mode-alist)))


;; ローマ字漢字変換時、対象とするローマ字を設定するための変数
(defvar sekka-skip-chars "a-zA-Z0-9.,@:`\\-+!\\[\\]?;'")
(defvar sekka-mode-map        (make-sparse-keymap)         "漢字変換トグルマップ")
(defvar sekka-select-mode-map (make-sparse-keymap)         "候補選択モードマップ")
(defvar sekka-rK-trans-key "\C-j"
  "*漢字変換キーを設定する")
(or (assq 'sekka-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (append (list (cons 'sekka-mode         sekka-mode-map)
			(cons 'sekka-select-mode  sekka-select-mode-map))
		  minor-mode-map-alist)))



;;;
;;; hooks
;;;
(defvar sekka-mode-hook nil)
(defvar sekka-select-mode-hook nil)
(defvar sekka-select-mode-end-hook nil)

(defconst sekka-login-name   (user-login-name))

(defconst sekka-tango-index  0)
(defconst sekka-annotation-index  1)
(defconst sekka-kind-index   3)
(defconst sekka-id-index     4)

;;--- デバッグメッセージ出力
(defvar sekka-psudo-server nil)         ; クライアント単体で仮想的にサーバーに接続しているようにしてテストするモード

;;--- デバッグメッセージ出力
(defvar sekka-debug nil)		; デバッグフラグ
(defun sekka-debug-print (string)
  (if sekka-debug
      (let
	  ((buffer (get-buffer-create "*sekka-debug*")))
	(with-current-buffer buffer
	  (goto-char (point-max))
	  (insert string)))))

;; HTTPクライアントの多重起動防止用
(defvar sekka-busy 0)

;;; 現在のsekka-serverの接続先
(defvar current-sekka-server-url     nil)

;;; 辞書のアップロード中かどうか
(defvar sekka-uploading-flag         nil)


;;; 候補選択モード用
(defvar sekka-history-stack '())        ; 過去に変換した、場所と変換候補の状態を保存しておくスタック
;; データ構造は以下の通り。
;; alistのlistとなる。 alistのキーは、sekka-* というバッファローカル変数のバックアップとなる)
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
(defvar sekka-fence-start nil)          ; fence 始端marker
(defvar sekka-fence-end nil)            ; fence 終端marker
(defvar sekka-henkan-separeter " ")     ; fence mode separeter
(defvar sekka-cand-cur 0)               ; カレント候補番号
(defvar sekka-cand-cur-backup 0)        ; カレント候補番号(UNDO用に退避する変数)
(defvar sekka-cand-len nil)             ; 候補数
(defvar sekka-last-fix "")              ; 最後に確定した文字列
(defvar sekka-last-roman "")            ; 最後にsekka-serverにリクエストしたローマ字文字列
(defvar sekka-select-operation-times 0) ; 選択操作回数
(defvar sekka-henkan-kouho-list nil)    ; 変換結果リスト(サーバから帰ってきたデータそのもの)


;; その他
(defvar sekka-markers '())              ; 単語の開始、終了位置のpair。 次のような形式で保存する ( 1 . 2 )
(defvar sekka-timer    nil)             ; インターバルタイマー型変数
(defvar sekka-timer-rest  0)            ; あと何回呼出されたら、インターバルタイマの呼出を止めるか
(defvar sekka-last-lineno 0)            ; 最後に変換を実行した行番号
(defvar sekka-guide-overlay   nil)      ; リアルタイムガイドに使用するオーバーレイ
(defvar sekka-last-request-time 0)      ; Sekkaサーバーにリクエストした最後の時刻(単位は秒)
(defvar sekka-guide-lastquery  "")      ; Sekkaサーバーにリクエストした最後のクエリ文字列
(defvar sekka-guide-lastresult '())     ; Sekkaサーバーにリクエストした最後のクエリ結果



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Skicky-shift
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar sticky-key ";")
(defvar sticky-list
  '(("a" . "A")("b" . "B")("c" . "C")("d" . "D")("e" . "E")("f" . "F")("g" . "G")
    ("h" . "H")("i" . "I")("j" . "J")("k" . "K")("l" . "L")("m" . "M")("n" . "N")
    ("o" . "O")("p" . "P")("q" . "Q")("r" . "R")("s" . "S")("t" . "T")("u" . "U")
    ("v" . "V")("w" . "W")("x" . "X")("y" . "Y")("z" . "Z")
    ("1" . "!")("2" . "\"")("3" . "#")("4" . "$")("5" . "%")("6" . "&")("7" . "'")
    ("8" . "(")("9" . ")")
    ("`" . "@")("[" . "{")("]" . "}")("-" . "=")("^" . "~")("\\" . "|")("." . ">")
    ("/" . "?")(";" . ";")(":" . "*")("@" . "`")
    ("\C-h" . "")
    ))
(defvar sticky-map (make-sparse-keymap))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ユーティリティ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sekka-assoc-ref (key alist fallback)
  (let ((entry (assoc key alist)))
    (if entry
	(cdr entry)
      fallback)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 表示系関数群
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar sekka-use-fence t)
(defvar sekka-use-color nil)

(defvar sekka-init nil)


;;
;; 初期化
;;
(defun sekka-init ()
  (when (not sekka-init)
    ;; 現在のsekka-serverの接続先
    (setq current-sekka-server-url  sekka-server-url) ;; 第一候補で初期化しておく。

    ;; ユーザー語彙のロード + サーバーへの登録
    (sekka-register-userdict-internal)
    
    ;; 初期化完了
    (setq sekka-init t)))


(defun sekka-construct-curl-argstr (arg-alist)
  (apply
   'append
   (mapcar
    (lambda (x)
      (list "--data" (format "%s=%s"
			     (car x)
			     (if (stringp (cdr x))
				 (url-hexify-string (cdr x))
			       (cdr x)))))
    arg-alist)))

;; test-code
(when nil
  (sekka-construct-curl-argstr
   '(
     ("yomi"   .  "kanji")
     ("limit"  .  2)
     ("method" .  "normal")
     ))
  )


;;
;; 接続先を次候補のsekka-serverに切りかえる
;;
(defun sekka-next-sekka-server ()
  (defun sekka-next-sekka-server-message(str varname)
    (message (format "If you have %s sekka-server, please set the `%s' variable." str varname))
    (sit-for 5))

  (cond
   ((string-equal current-sekka-server-url
		  sekka-server-url)
    (if (< 0 (length sekka-server-url-2))
	(setq current-sekka-server-url sekka-server-url-2)
      (sekka-next-sekka-server-message "second" "sekka-server-url-2")))
   ((string-equal current-sekka-server-url
		  sekka-server-url-2)
    (if (< 0 (length sekka-server-url-3))
	(setq current-sekka-server-url sekka-server-url-3)
      (setq current-sekka-server-url sekka-server-url)))
   (t
    (when (< 0 (length sekka-server-url))
      (setq current-sekka-server-url sekka-server-url)))))


;;
;; ローマ字で書かれた文章をSekkaサーバーを使って変換する
;;
;; arg-alistの引数の形式
;;  例:
;;   '(
;;     ("yomi"   .  "kanji")
;;     ("limit"  .  2)
;;     ("method" .  "normal")
;;    )
(defun sekka-rest-request (func-name arg-alist)
  (defun one-request (func-name arg-alist)
    (let ((result (sekka-rest-request-sub func-name arg-alist)))
      (if (or
	   (string-match-p "^curl: [(]6[)] "  result) ;; Couldn't resolve host 'aaa.example.com' 
	   (string-match-p "^curl: [(]7[)] "  result) ;; Couldn't connect to host 'localhost'
	   (string-match-p "^curl: [(]28[)] " result) ;; Operation timed out after XXXX milliseconds with 0 bytes received
	   )
	  (progn
	    (sekka-next-sekka-server)
	    nil)
	result)))
  (let ((arg-alist
	 (cons
	  `("userid" . ,sekka-login-name)
	  arg-alist)))
    (or
     (one-request func-name arg-alist)
     (one-request func-name arg-alist)
     (one-request func-name arg-alist)
     (concat
      "Error: All sekka-server are down. "
      " " sekka-server-url
      " " sekka-server-url-2
      " " sekka-server-url-3))))

(defun sekka-rest-request-by-curl (func-name arg-alist)
  (let* ((lst
	  (append
	   (if (< 0 (length sekka-no-proxy-hosts))
	       (list "--noproxy" sekka-no-proxy-hosts)
	     nil)
	   (sekka-construct-curl-argstr (cons
					 '("format" . "sexp")
					 arg-alist))))
	 (buffername "*sekka-output*")
	 (result ""))
    (sekka-debug-print (format "arg-lst :[%S]\n" lst))
    (progn
      (apply
       'call-process
       sekka-curl
       nil buffername nil
       "--silent" "--show-error"
       "--max-time" (format "%d" sekka-server-timeout)
       "--insecure"
       "--header" "Content-Type: application/x-www-form-urlencoded"
       (concat current-sekka-server-url func-name)
       lst)
      (setq result
	    (with-current-buffer buffername
	      (buffer-substring-no-properties (point-min) (point-max))))
      (kill-buffer buffername)
      result)))


(when nil
  ;; unit test
  (setq sekka-curl "curl")
  (setq sekka-login-name (user-login-name))
  (setq current-sekka-server-url "http://localhost:12929/")
  (sekka-rest-request-by-curl
   "henkan"
   '(
     ("yomi"   . "Nihon")
     ("limit"  . "1")
     ("method" . "normal")
     ("userid" . "kiyoka")))
  )


(defun sekka-url-http-post (url args)
  "Send ARGS to URL as a POST request."
  (progn
    (setq url-request-method "POST")
    (setq url-http-version "1.0")
    (setq url-request-extra-headers
	  '(("Content-Type" . "application/x-www-form-urlencoded")))
    (setq url-request-data
	  (mapconcat (lambda (arg)
		       (concat (url-hexify-string (car arg))
			       "="
			       (url-hexify-string (cdr arg))))
		     args
		     "&"))
    (let* ((lines
	    (let ((buf (url-retrieve-synchronously url)))
	      (sekka-debug-print (buffer-name buf))
	      (sekka-debug-print "\n")
	      (if buf
                  (with-current-buffer buf
                    (decode-coding-string 
                     (let ((str (buffer-substring-no-properties (point-min) (point-max))))
                       (cond
                        (url-http-response-status
                         (sekka-debug-print (format "http result code:%s\n" url-http-response-status))
                         (sekka-debug-print (format "(%d-%d) eoh=%s\n" (point-min) (point-max) url-http-end-of-headers))
                         (sekka-debug-print (format "<<<%s>>>\n" str))
                         str)
                        (t
                         "curl: (28) Time out\n" ;; Emulate curl Operation timed out.
                         )))
                     'utf-8))
                "curl: (7)  Couldn't connect to host 'localhost'\n"))) ;; Emulate curl error.
           (line-list
            (split-string lines "\n")))
      
      (car (reverse line-list)))))

;;
;; http request function with pure emacs
;;   (no proxy supported)
(defun sekka-rest-request-by-pure (func-name arg-alist)
  (setq sekka-busy (+ sekka-busy 1))
  (sekka-debug-print (format "sekka-busy=%d\n" sekka-busy))
  (let* ((arg-alist 
	  (cons
	   '("format" . "sexp")
	   arg-alist))
	 (result
	  (sekka-url-http-post 
	   (concat current-sekka-server-url func-name)
	   arg-alist)))
    (setq sekka-busy (- sekka-busy 1))
    (sekka-debug-print (format "sekka-busy=%d\n" sekka-busy))
    result))

(when nil
  ;; unit test
  (setq sekka-login-name (user-login-name))
  (setq current-sekka-server-url "http://localhost:12929/")
  (sekka-rest-request-by-pure
   "henkan"
   '(
     ("yomi"   . "Nihon")
     ("limit"  . "1")
     ("method" . "normal")
     ("userid" . "kiyoka"))))

(defun sekka-rest-request-sub (func-name arg-alist)
  (if sekka-psudo-server
      (cond
       ((string-equal func-name "henkan")
	;; クライアント単体で仮想的にサーバーに接続しているようにしてテストするモード
	;; result of /henkan
	;;"((\"変換\" nil \"へんかん\" j 0) (\"変化\" nil \"へんか\" j 1) (\"ヘンカン\" nil \"へんかん\" k 2) (\"へんかん\" nil \"へんかん\" h 3))")
	"((\"ヨンモジジュクゴ\" nil \"よんもじじゅくご\" k 0) (\"よんもじじゅくご\" nil \"よんもじじゅくご\" h 1))")
       ((string-equal func-name "googleime")
	;; result of /google_ime
	;;  1) よんもじじゅくご
	"(\"四文字熟語\" \"４文字熟語\" \"4文字熟語\" \"よんもじじゅくご\" \"ヨンモジジュクゴ\")"
	;;  2) しょかいきどう
	;;    "(\"初回起動\", \"諸快気堂\", \"諸開基堂\", \"しょかいきどう\", \"ショカイキドウ\")"
	))
    ;; 実際のサーバに接続する
    (cond
     (sekka-use-curl
      (sekka-rest-request-by-curl func-name arg-alist))
     (t
      (if (string-equal "register" func-name)
          (sekka-rest-request-by-curl func-name arg-alist) ;; 辞書登録はcurlを使ってバックグラウンドで実行する。pure版は平行動作できない。
        (sekka-rest-request-by-pure func-name arg-alist))))))

;;
;; 現在時刻をUNIXタイムを返す(単位は秒)
;;
(defun sekka-current-unixtime ()
  (let (
	(_ (current-time)))
    (+
     (* (car _)
	65536)
     (cadr _))))


;;
;; ローマ字で書かれた文章をSekkaサーバーを使って変換する
;;
(defun sekka-henkan-request (yomi limit)
  (sekka-debug-print (format "henkan-input :[%s]\n"  yomi))
  (when (string-equal "en" sekka-keyboard-type)
    (setq yomi (replace-regexp-in-string ":" "+" yomi)))
  (sekka-debug-print (format "henkan-send  :[%s]\n"  yomi))

  (let (
	(result (sekka-rest-request "henkan" `(("yomi"   . ,yomi)
					       ("limit"  . ,(format "%d" limit))
					       ("method" . ,sekka-roman-method)))))
    (sekka-debug-print (format "henkan-result:%S\n" result))
    (if (eq (string-to-char result) ?\( )
	(progn
	  (message nil)
	  (condition-case err
	      (read result)
	    (end-of-file
	     (progn
	       (message "Parse error for parsing result of Sekka Server.")
	       nil))))
      (progn
	(message result)
	nil))))

;;
;; 確定した単語をサーバーに伝達する
;;
(defun sekka-kakutei-request (key tango)
  (sekka-debug-print (format "henkan-kakutei key=[%s] tango=[%s]\n" key tango))
  
  ;;(message "Requesting to sekka server...")
  
  (let ((result (sekka-rest-request "kakutei" `(
						("key"   . ,key)
						("tango" . ,tango)))))
    (sekka-debug-print (format "kakutei-result:%S\n" result))
    (message result)
    t))


;;
;; GoogleImeAPIリクエストをサーバーに送る
;;
(defun sekka-googleime-request (yomi)
  (sekka-debug-print (format "googleime yomi=[%s]\n" yomi))
  
  ;;(message "Requesting to sekka server...")
  
  (let ((result (sekka-rest-request "googleime" `(
						  ("yomi"  . ,yomi)))))
    (sekka-debug-print (format "googleime-result:%S\n" result))
    (progn
      (message nil)
      (condition-case err
	  (read result)
	(end-of-file
	 (progn
	   (message "Parse error for parsing result of Sekka Server.")
	   '()))))))


;;
;; ユーザー語彙をサーバーに再度登録する。
;;
(defun sekka-register-userdict (&optional arg)
  "ユーザー辞書をサーバーに再度アップロードする"
  (interactive "P")
  (sekka-register-userdict-internal))

  
;;
;; ユーザー語彙をサーバーに登録する。
(defun sekka-register-userdict-internal (&optional only-first)
  (lexical-let ((str      (sekka-get-jisyo-str sekka-jisyo-filename)))
    (lexical-let ((str-lst  (if only-first
				(list (car (sekka-divide-into-few-line str)))
			      (sekka-divide-into-few-line str)))
		  (x '()))
      (setq sekka-uploading-flag t)
      (redraw-modeline)
      (cc:thread 100
	(while (< 0 (length str-lst))
	  (setq x (pop str-lst))
	  ;;(message "Requesting to sekka server...")
	  (sekka-debug-print (format "register [%s]\n" x))
	  (lexical-let ((result (sekka-rest-request "register" `(("dict" . ,x)))))
	    (sekka-debug-print (format "register-result:%S\n" result))))
	(setq sekka-uploading-flag nil)
	(redraw-modeline)))
    t))


;;
;; ユーザー語彙をサーバーから全て削除する
;;
(defun sekka-flush-userdict (&optional arg)
  "サーバー上のユーザー辞書を全て削除する"
  (interactive "P")
  (message "Requesting to sekka server...")
  (let ((result (sekka-rest-request "flush" `())))
    (sekka-debug-print (format "register-result:%S\n" result))
    (message result)
    t))


;; str = "line1 \n line2 \n line3 \n line4 \n line5 \n "
;; result:
;;     '(
;;        ("line1 \n line2 \n line3 \n ")
;;        ("line4 \n line5 \n ")
;;      )
;;
;; for-testing:
;;   (sekka-divide-into-few-line 
;;     "line1 \n line2 \n line3 \n line4 \n line5 \n line6 \n line7 \n line8 \n line9 \n line10 \n  line11 \n  line12 \n")
;;
(defun sekka-divide-into-few-line (str)
  (if (stringp str)
      (let ((str-lst (split-string str "\n"))
	    (result '()))
	(while (< 0 (length str-lst))
	  (push 
	   (concat
	    (pop str-lst) "\n" (pop str-lst) "\n" (pop str-lst) "\n" (pop str-lst) "\n" (pop str-lst) "\n" )
	   result))
	(reverse result))
    '()))


(defun sekka-file-existp (file)
  "FILE が存在するかどうかをチェックする。 t か nil で結果を返す"
  (let* ((file (or (car-safe file)
		   file))
	 (file (expand-file-name file)))
    (file-exists-p file)))


(defun sekka-get-jisyo-str (file &optional nomsg)
  "FILE を開いて Sekka辞書バッファを作り、バッファ1行1文字列のリストで返す"
  (if (sekka-file-existp file)
      (let ((str "")
	    (buf-name (file-name-nondirectory file)))
	(save-excursion
	  (find-file-read-only file)
	  (setq str (with-current-buffer (get-buffer buf-name)
		      (buffer-substring-no-properties (point-min) (point-max))))
	  (message (format "Sekka辞書 %s を開いています...完了！" (file-name-nondirectory file)))
	  (kill-buffer-if-not-modified (get-buffer buf-name)))
	str)
    (message (format "Sekka辞書 %s が存在しません..." file))))


(defun sekka-add-new-word-to-jisyo (file yomi tango)
  "FILE Sekka辞書ファイルと見做し、ファイルの先頭に「読み」と「単語」のペアを書き込む
登録が成功したかどうかを t or nil で返す"
  (let ((buf-name (file-name-nondirectory file)))
    (save-excursion
      (find-file file)
      (with-current-buffer (get-buffer buf-name)
	(goto-char (point-min))
	(let ((newstr (format "%s /%s/" yomi tango)))
	  (when (not (search-forward newstr nil t))
	    (insert newstr)
	    (insert "\n")
	    (save-buffer)
		(setq added t)
		)))
      (kill-buffer-if-not-modified (get-buffer buf-name)))
    t))



;; ポータブル文字列置換( EmacsとXEmacsの両方で動く )
(defun sekka-replace-regexp-in-string (regexp replace str)
  (cond ((featurep 'xemacs)
	 (replace-in-string str regexp replace))
	(t
	 (replace-regexp-in-string regexp replace str))))
	

;; リージョンをローマ字漢字変換する関数
(defun sekka-henkan-region (b e)
  "指定された region を漢字変換する"
  (sekka-init)
  (when (/= b e)
    (let* (
	   (yomi (buffer-substring-no-properties b e))
	   (henkan-list (sekka-henkan-request yomi 0)))
      
      (if henkan-list
	  (condition-case err
	      (progn
		(setq
		 ;; 変換結果の保持
		 sekka-henkan-kouho-list henkan-list
		 ;; 文節選択初期化
		 sekka-cand-cur 0
		 ;; 
		 sekka-cand-len (length henkan-list))
		
		(sekka-debug-print (format "sekka-henkan-kouho-list:%s \n" sekka-henkan-kouho-list))
		(sekka-debug-print (format "sekka-cand-cur:%s \n" sekka-cand-cur))
		(sekka-debug-print (format "sekka-cand-len:%s \n" sekka-cand-len))
		;;
		t)
	    (sekka-trap-server-down
	     (beep)
	     (message (error-message-string err))
	     (setq sekka-select-mode nil))
	    (run-hooks 'sekka-select-mode-end-hook))
	nil))))


;; カーソル前の文字種を返却する関数
(eval-and-compile
  (if (>= emacs-major-version 20)
      (defun sekka-char-charset (ch)
	(let ((result (char-charset ch)))
	  (sekka-debug-print (format "sekka-char-charset:1(%s) => %s\n" ch result))
	  (if (multibyte-string-p (char-to-string ch)) 
	      'japanese-jisx0208
	    result)))
    (defun sekka-char-charset (ch)
      (sekka-debug-print (format "sekka-char-charset:2(%s) => %s\n" ch (char-category)))
      (cond ((equal (char-category ch) "a") 'ascii)
	    ((equal (char-category ch) "k") 'katakana-jisx0201)
	    ((string-match "[SAHK]j" (char-category ch)) 'japanese-jisx0208)
	    (t nil) )) ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; undo 情報の制御
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; undo buffer 退避用変数
(defvar sekka-buffer-undo-list nil)
(make-variable-buffer-local 'sekka-buffer-undo-list)
(defvar sekka-buffer-modified-p nil)
(make-variable-buffer-local 'sekka-buffer-modified-p)

(defvar sekka-blink-cursor nil)
(defvar sekka-cursor-type nil)
;; undo buffer を退避し、undo 情報の蓄積を停止する関数
(defun sekka-disable-undo ()
  (when (not (eq buffer-undo-list t))
    (setq sekka-buffer-undo-list buffer-undo-list)
    (setq sekka-buffer-modified-p (buffer-modified-p))
    (setq buffer-undo-list t)))

;; 退避した undo buffer を復帰し、undo 情報の蓄積を再開する関数
(defun sekka-enable-undo ()
  (when (not sekka-buffer-modified-p) (set-buffer-modified-p nil))
  (when sekka-buffer-undo-list
    (setq buffer-undo-list sekka-buffer-undo-list)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 現在の変換エリアの表示を行う
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sekka-get-display-string ()
  ;; 変換結果文字列を返す。
  (let* ((kouho      (nth sekka-cand-cur sekka-henkan-kouho-list))
	 (_          (sekka-debug-print (format "sekka-cand-cur=%s\n" sekka-cand-cur)))
	 (_          (sekka-debug-print (format "kouho=%s\n" kouho)))
	 (word       (car kouho))
	 (annotation (cadr kouho)))
    (sekka-debug-print (format "word:[%d] %s(%s)\n" sekka-cand-cur word annotation))
    word))

(defun sekka-display-function (b e select-mode)
  (let ((insert-word (sekka-get-display-string))
	(word (buffer-substring-no-properties b e)))
    (cond
     ((and (not select-mode)
	   (string-equal insert-word word))
      ;; sekka-markersの更新
      (setq sekka-fence-start (progn
				(goto-char b)
				(point-marker)))
      (setq sekka-fence-end   (progn
				(goto-char e)
				(point-marker)))
      (setq sekka-markers
	    (cons sekka-fence-start sekka-fence-end))

      ;; 確定文字列の作成
      (setq sekka-last-fix insert-word)
      
      (sekka-debug-print (format "don't touch:[%s] point:%d-%d\n" insert-word (marker-position sekka-fence-start) (marker-position sekka-fence-end))))

     (t
      (setq sekka-henkan-separeter (if sekka-use-fence " " ""))
      (when sekka-henkan-kouho-list
	;; UNDO抑制開始
	(sekka-disable-undo)
	
	(delete-region b e)

	;; リスト初期化
	(setq sekka-markers '())

	(setq sekka-last-fix "")

	;; 変換したpointの保持
	(setq sekka-fence-start (point-marker))
	(when select-mode (insert "|"))
    
	(let* (
	       (start       (point-marker))
	       (_cur        sekka-cand-cur)
	       (_len        sekka-cand-len))
	  (progn
	    (insert insert-word)
	    (message (format "[%s] candidate (%d/%d)" insert-word (+ _cur 1) _len))
	    (let* ((end         (point-marker))
		   (ov          (make-overlay start end)))
	      
	      ;; 確定文字列の作成
	      (setq sekka-last-fix insert-word)
	      
	      ;; 選択中の場所を装飾する。
	      (when select-mode
		(overlay-put ov 'face 'default)
		(overlay-put ov 'face 'highlight))
	      (setq sekka-markers (cons start end))
	      (sekka-debug-print (format "insert:[%s] point:%d-%d\n" insert-word (marker-position start) (marker-position end))))))
	
	;; fenceの範囲を設定する
	(when select-mode (insert "|"))
	(setq sekka-fence-end   (point-marker))
	
	(sekka-debug-print (format "total-point:%d-%d\n"
				   (marker-position sekka-fence-start)
				   (marker-position sekka-fence-end)))
	;; UNDO再開
	(sekka-enable-undo))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 変換候補選択モード
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(let ((i 0))
  (while (<= i ?\177)
    (define-key sekka-select-mode-map (char-to-string i)
      'sekka-kakutei-and-self-insert)
    (setq i (1+ i))))
(define-key sekka-select-mode-map "\C-m"                   'sekka-select-kakutei)
(define-key sekka-select-mode-map "\C-g"                   'sekka-select-cancel)
(define-key sekka-select-mode-map "q"                      'sekka-select-cancel)
(define-key sekka-select-mode-map "\C-a"                   'sekka-select-kanji)
(define-key sekka-select-mode-map "\C-p"                   'sekka-select-prev)
(define-key sekka-select-mode-map "\C-n"                   'sekka-select-next)
(define-key sekka-select-mode-map sekka-rK-trans-key       'sekka-select-next)
(define-key sekka-select-mode-map (kbd "SPC")              'sekka-select-next)
(define-key sekka-select-mode-map "\C-u"                   'sekka-select-hiragana)
(define-key sekka-select-mode-map "\C-i"                   'sekka-select-katakana)
(define-key sekka-select-mode-map "\C-k"                   'sekka-select-katakana)
(define-key sekka-select-mode-map "\C-l"                   'sekka-select-hankaku)
(define-key sekka-select-mode-map "\C-e"                   'sekka-select-zenkaku)
(define-key sekka-select-mode-map "\C-r"                   'sekka-add-new-word)


(defvar sekka-popup-menu-keymap
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


;; 選択操作回数のインクリメント
(defun sekka-select-operation-inc ()
  (incf sekka-select-operation-times)
  (when (< 3 sekka-select-operation-times)
    (sekka-select-operation-reset)
    (let* ((lst 
	    (mapcar
	     (lambda (x)
	       (concat 
		(nth sekka-tango-index x)
		"   ; "
		(nth sekka-annotation-index x)))
	     sekka-henkan-kouho-list))
	   (map (make-sparse-keymap))
	   (result 
	    (popup-menu* lst
			 :scroll-bar t
			 :margin t
			 :keymap sekka-popup-menu-keymap
                         :initial-index sekka-cand-cur)))
      (let ((selected-word (car (split-string result " "))))
	(setq sekka-cand-cur (sekka-find-by-tango selected-word))))))


;; 選択操作回数のリセット
(defun sekka-select-operation-reset ()
  (setq sekka-select-operation-times 0))

;; 変換を確定し入力されたキーを再入力する関数
(defun sekka-kakutei-and-self-insert (arg)
  "候補選択を確定し、入力された文字を入力する"
  (interactive "P")
  (sekka-select-kakutei)
  (setq unread-command-events (list last-command-event)))

;; 候補選択状態での表示更新
(defun sekka-select-update-display ()
  (sekka-display-function
   (marker-position sekka-fence-start)
   (marker-position sekka-fence-end)
   sekka-select-mode))


;; 候補選択を確定する
(defun sekka-select-kakutei ()
  "候補選択を確定する"
  (interactive)
  ;; 候補番号リストをバックアップする。
  (setq sekka-cand-cur-backup sekka-cand-cur)
  ;; サーバーに確定した単語を伝える(辞書学習)
  (let* ((kouho      (nth sekka-cand-cur sekka-henkan-kouho-list))
	 (_          (sekka-debug-print (format "2:sekka-cand-cur=%s\n" sekka-cand-cur)))
	 (_          (sekka-debug-print (format "2:kouho=%s\n" kouho)))
	 (tango      (car kouho))
	 (key        (caddr kouho))
	 (kind (nth sekka-kind-index kouho)))
    (when (eq 'j kind)
      (sekka-kakutei-request key tango)))
  (setq sekka-select-mode nil)
  (run-hooks 'sekka-select-mode-end-hook)
  (sekka-select-operation-reset)
  (sekka-select-update-display)
  (sekka-history-push))


;; 候補選択をキャンセルする
(defun sekka-select-cancel ()
  "候補選択をキャンセルする"
  (interactive)
  ;; カレント候補番号をバックアップしていた候補番号で復元する。
  (setq sekka-cand-cur sekka-cand-cur-backup)
  (setq sekka-select-mode nil)
  (run-hooks 'sekka-select-mode-end-hook)
  (sekka-select-update-display)
  (sekka-history-push))


;; 前の候補に進める
(defun sekka-select-prev ()
  "前の候補に進める"
  (interactive)
  ;; 前の候補に切りかえる
  (decf sekka-cand-cur)
  (when (> 0 sekka-cand-cur)
    (setq sekka-cand-cur (- sekka-cand-len 1)))
  (sekka-select-operation-inc)
  (sekka-select-update-display))

;; 次の候補に進める
(defun sekka-select-next ()
  "次の候補に進める"
  (interactive)
  ;; 次の候補に切りかえる
  (setq sekka-cand-cur
	(if (< sekka-cand-cur (- sekka-cand-len 1))
	    (+ sekka-cand-cur 1)
	  0))
  (sekka-select-operation-inc)
  (sekka-select-update-display))

;; 指定された tango のindex番号を返す
(defun sekka-find-by-tango ( tango )
  (let ((result-index nil))
    (mapcar
     (lambda (x)
       (let ((_tango (nth sekka-tango-index x)))
	 (when (string-equal _tango tango)
	   (setq result-index (nth sekka-id-index x)))))
     sekka-henkan-kouho-list)
    (sekka-debug-print (format "sekka-find-by-tango: tango=%s result=%S \n" tango result-index))
    result-index))

;; 指定された type の候補を抜き出す
(defun sekka-select-by-type-filter ( _type )
  (let ((lst '()))
    (mapcar
     (lambda (x)
       (let ((sym (nth sekka-kind-index x)))
	 (when (eq sym _type)
	   (push x lst))))
     sekka-henkan-kouho-list)
    (sekka-debug-print (format "filtered-lst = %S\n" (reverse lst)))
    (if (null lst)
	nil
      (reverse lst))))
  
    
;; 指定された type の候補が存在するか調べる
(defun sekka-include-typep ( _type )
  (sekka-select-by-type-filter _type))

;; 指定された type の候補に強制的に切りかえる
;; 切りかえが成功したかどうかを t or nil で返す。
(defun sekka-select-by-type ( _type )
  (let ((kouho (car (sekka-select-by-type-filter _type))))
    (if (not kouho)
	(progn
	 (cond
	  ((eq _type 'j)
	   (message "Sekka: 漢字の候補はありません。"))
	  ((eq _type 'h)
	   (message "Sekka: ひらがなの候補はありません。"))
	  ((eq _type 'k)
	   (message "Sekka: カタカナの候補はありません。"))
	  ((eq _type 'l)
	   (message "Sekka: 半角の候補はありません。"))
	  ((eq _type 'z)
	   (message "Sekka: 全角の候補はありません。"))
	  ((eq _type 'n)
	   (message "Sekka: 数字混在の候補はありません．")))
	 nil)
      (let ((num   (nth sekka-id-index kouho)))
	(setq sekka-cand-cur num)
	(sekka-select-update-display)
	t))))

(defun sekka-select-kanji ()
  "漢字候補に強制的に切りかえる"
  (interactive)
  (sekka-select-by-type 'j))

(defun sekka-select-hiragana ()
  "ひらがな候補に強制的に切りかえる"
  (interactive)
  (sekka-select-by-type 'h))

(defun sekka-select-katakana ()
  "カタカナ候補に強制的に切りかえる"
  (interactive)
  (sekka-select-by-type 'k))

(defun sekka-select-hankaku ()
  "半角候補に強制的に切りかえる"
  (interactive)
  (sekka-select-by-type 'l))

(defun sekka-select-zenkaku ()
  "半角候補に強制的に切りかえる"
  (interactive)
  (sekka-select-by-type 'z))


(defun sekka-replace-kakutei-word (b e insert-word)
  ;; UNDO抑制開始
  (sekka-disable-undo)
    
  (delete-region b e)
  
  (insert insert-word)
  (message (format "replaced by new word [%s]" insert-word))
  ;; UNDO再開
  (sekka-enable-undo))


;; 登録語リストからユーザーに該当単語を選択してもらう
(defun sekka-add-new-word-sub (yomi lst hiragana-lst)
  (let* ((etc "(自分で入力する)")
	 (lst (if (stringp lst) 
		  (progn
		    (message lst) ;; サーバーから返ってきたエラーメッセージを表示
		    '())
		lst))
	 (result (popup-menu*
		  (append hiragana-lst
			  (append lst `(,etc)))
		  :margin t
		  :keymap sekka-popup-menu-keymap))
	 (b (copy-marker sekka-fence-start))
	 (e (copy-marker sekka-fence-end)))
    (let ((tango
	   (if (string-equal result etc)
	       (save-current-buffer
		 (read-string (format "%sに対応する単語:" yomi)))
	     result)))
      ;; 新しい単語で確定する
      (sekka-replace-kakutei-word (marker-position b)
				  (marker-position e)
				  tango)

      (when (member result hiragana-lst) ;; 平仮名フレーズの場合
	(setq yomi  result)
	(setq tango ""))

      ;; .sekka-jisyoとサーバーの両方に新しい単語を登録する
      (let ((added (sekka-add-new-word-to-jisyo sekka-jisyo-filename yomi tango)))
	(if added
	    (progn
	      (sekka-register-userdict-internal t)
	      (message (format "Sekka辞書 %s に単語(%s /%s/)を保存しました！" sekka-jisyo-filename yomi tango)))
	  (message (format "Sekka辞書 %s に 単語(%s /%s/)を追加しませんでした(登録済)" sekka-jisyo-filename yomi tango)))))))


(defun sekka-add-new-word ()
  "変換候補のよみ(平仮名)に対応する新しい単語を追加する"
  (interactive)
  (setq case-fold-search nil)
  (let ((type
	 (cond
	  ((string-match-p "^[A-Z][^A-Z]+$" sekka-last-roman)
	   (if (sekka-select-by-type 'h) ;; 平仮名候補に自動切り替え
	       'H
	     nil))
	  ((string-match-p "^[a-z][^A-Z]+$" sekka-last-roman)
	   'h)
	  (t
	   nil))))
    (let* ((kouho      (nth sekka-cand-cur sekka-henkan-kouho-list))
	   (hiragana   (car kouho)))
      (sekka-debug-print (format "sekka-register-new-word: sekka-last-roman=[%s] hiragana=%s result=%S\n" sekka-last-roman hiragana (string-match-p "^[A-Z][^A-Z]+$" sekka-last-roman)))
      (cond
       ;; 漢字語彙をgoogleimeで取得
       ((eq 'H type)
	(sekka-select-kakutei)
	(sekka-add-new-word-sub
	 hiragana
	 (sekka-googleime-request hiragana)
	 '()))
       ;; 平仮名フレーズから選択
       ((eq 'h type)
	(sekka-select-kakutei)
	(let ((kouho (sekka-select-by-type-filter 'h)))
	  (sekka-debug-print (format "sekka-register-new-word: kouho=%S\n" kouho))
	  (sekka-add-new-word-sub
	   hiragana
	   '()
	   (cons
	    hiragana ;; 確定値の平仮名文言を先頭に追加。
	    (mapcar
	     (lambda (x) (car x)) kouho))))))
      )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 変換履歴操作関数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun sekka-history-gc ()
  ;; sekka-history-stack中の無効なマークを持つエントリを削除する
  (sekka-debug-print (format "sekka-history-gc before len=%d\n" (length sekka-history-stack)))

  (let ((temp-list '()))
    (mapcar
     (lambda (alist)
       (let ((markers  (sekka-assoc-ref 'markers  alist nil)))
	 (sekka-debug-print (format "markers=%S\n" markers))
	 (sekka-debug-print (format "marker-position car=%S\n" (marker-position (car markers))))
	 (sekka-debug-print (format "marker-position cdr=%S\n" (marker-position (cdr markers))))
	 (when (and (marker-position (car markers))	 ;; 存在するバッファを指しているか
		    (marker-position (cdr markers)))
	   (if (= (marker-position (car markers))
		  (marker-position (cdr markers)))
	       ;; マークの開始と終了が同じ位置を指している場合は、
	       ;; そのマークは既に無効(選択モードの再表示で一旦マーク周辺の文字列が削除された)
	       (progn
		 (set-marker (car markers) nil)
		 (set-marker (cdr markers) nil))
	     (push alist temp-list)))))
     sekka-history-stack)

    (sekka-debug-print (format "sekka-history-gc temp-list  len=%d\n" (length temp-list)))

    ;; temp-list から limit 件数だけコピーする
    (setq sekka-history-stack '())
    (mapcar
     (lambda (alist)
       (when (< (length sekka-history-stack)
		sekka-history-stack-limit)
	 (push alist sekka-history-stack)))
     (reverse temp-list)))
  (sekka-debug-print (format "sekka-history-gc after  len=%d\n" (length sekka-history-stack))))


;;確定ヒストリから、指定_pointに変換済の単語が埋まっているかどうか調べる
;; t か nil を返す。
;; また、_load に 真を渡すと、見付かった情報で、現在の変換候補変数にロードしてくれる。
(defun sekka-history-search (_point _load)
  (sekka-history-gc)

  ;; カーソル位置に有効な変換済エントリがあるか探す
  (let ((found nil))
    (mapcar
     (lambda (alist)
       (let* ((markers  (sekka-assoc-ref 'markers  alist nil))
	      (last-fix (sekka-assoc-ref 'last-fix alist ""))
	      (end      (marker-position (cdr markers)))
	      (start    (- end (length last-fix)))
	      (bufname  (sekka-assoc-ref 'bufname alist ""))
	      (pickup   (if (string-equal bufname (buffer-name))
			    (buffer-substring start end)
			  "")))
	 (sekka-debug-print (format "sekka-history-search  bufname:   [%s]\n"   bufname))
	 (sekka-debug-print (format "sekka-history-search  (point):   %d\n"     (point)))
	 (sekka-debug-print (format "sekka-history-search    range:   %d-%d\n"  start end))
	 (sekka-debug-print (format "sekka-history-search last-fix:   [%s]\n"   last-fix))
	 (sekka-debug-print (format "sekka-history-search   pickup:   [%s]\n"   pickup))
	 (when (and
		(string-equal bufname (buffer-name))
		(<  start   (point))
		(<= (point) end)
		(string-equal last-fix pickup))
	   (setq found t)
	   (when _load
	     (setq sekka-markers            (cons
					     (move-marker (car markers) start)
					     (cdr markers)))
	     (setq sekka-cand-cur           (sekka-assoc-ref 'cand-cur alist           nil))
	     (setq sekka-cand-cur-backup    (sekka-assoc-ref 'cand-cur-backup alist    nil))
	     (setq sekka-cand-len           (sekka-assoc-ref 'cand-len alist           nil))
	     (setq sekka-last-fix           pickup)
	     (setq sekka-henkan-kouho-list  (sekka-assoc-ref 'henkan-kouho-list alist  nil))

	     (sekka-debug-print (format "sekka-history-search : sekka-markers         : %S\n" sekka-markers))
	     (sekka-debug-print (format "sekka-history-search : sekka-cand-cur        : %S\n" sekka-cand-cur))
	     (sekka-debug-print (format "sekka-history-search : sekka-cand-cur-backup : %S\n" sekka-cand-cur-backup))
	     (sekka-debug-print (format "sekka-history-search : sekka-cand-len %S\n" sekka-cand-len))
	     (sekka-debug-print (format "sekka-history-search : sekka-last-fix %S\n" sekka-last-fix))
	     (sekka-debug-print (format "sekka-history-search : sekka-henkan-kouho-list %S\n" sekka-henkan-kouho-list)))
	   )))
     sekka-history-stack)
    found))

(defun sekka-history-push ()
  (push 
   `(
     (markers            . ,sekka-markers            )
     (cand-cur           . ,sekka-cand-cur           )
     (cand-cur-backup    . ,sekka-cand-cur-backup    )
     (cand-len           . ,sekka-cand-len           )
     (last-fix           . ,sekka-last-fix           )
     (henkan-kouho-list  . ,sekka-henkan-kouho-list  )
     (bufname            . ,(buffer-name)))
   sekka-history-stack)
  (sekka-debug-print (format "sekka-history-push result: %S\n" sekka-history-stack)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ローマ字漢字変換関数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sekka-rK-trans ()
  "ローマ字漢字変換をする。
・カーソルから行頭方向にローマ字列が続く範囲でローマ字漢字変換を行う。"
  (interactive)
;  (print last-command)			; DEBUG
  (sekka-debug-print "sekka-rK-trans()")


  (cond 
   ;; タイマーイベントを設定しない条件
   ((or
     sekka-timer
     (> 1 sekka-realtime-guide-running-seconds)
     ))
   (t
    ;; タイマーイベント関数の登録
    (progn
      (let 
	  ((ov-point
	    (save-excursion
	      (forward-line 1)
	      (point))))
	  (setq sekka-guide-overlay
			(make-overlay ov-point ov-point (current-buffer))))
      (setq sekka-timer
			(run-at-time 0.1 sekka-realtime-guide-interval
						 'sekka-realtime-guide)))))

  ;; ガイド表示継続回数の更新
  (when (< 0 sekka-realtime-guide-running-seconds)
    (setq sekka-timer-rest  
	  (/ sekka-realtime-guide-running-seconds
	     sekka-realtime-guide-interval)))

  ;; 最後に変換した行番号の更新
  (setq sekka-last-lineno (line-number-at-pos (point)))

  (cond
   (sekka-select-mode
    (sekka-debug-print "<<sekka-select-mode>>\n")
    ;; 候補選択モード中に呼出されたら、keymapから再度候補選択モードに入る
    (funcall (lookup-key sekka-select-mode-map sekka-rK-trans-key)))


   (t
    (cond

     ((eq (sekka-char-charset (preceding-char)) 'ascii)
      (sekka-debug-print (format "ascii? (%s) => t\n" (preceding-char)))
      ;; カーソル直前が alphabet だったら
      (let ((end (point))
	    (gap (sekka-skip-chars-backward)))
	(when (/= gap 0)
	  ;; 意味のある入力が見つかったので変換する
	  (let (
		(b (+ end gap))
		(e end))
	    (when (sekka-henkan-region b e)
	      (if (eq (char-before b) ?/)
		  (setq b (- b 1)))
	      (setq sekka-last-roman (buffer-substring-no-properties b e))
	      (delete-region b e)
	      (goto-char b)
	      (insert (sekka-get-display-string))
	      (setq e (point))
	      (sekka-display-function b e nil)
	      (sekka-select-kakutei)
	      (cond
	       ((string-match-p "^[A-Z][^A-Z]+$" sekka-last-roman)
		;; 漢字語彙
		(when sekka-use-googleime
		  (if (not (sekka-include-typep 'j))
		      (sekka-add-new-word))))
	       (t
		;; 平仮名フレーズはGoogleIMEの問い合わせの自動起動はしない
		)))))))
	      
     ((sekka-kanji (preceding-char))
      (sekka-debug-print (format "sekka-kanji(%s) => t\n" (preceding-char)))
    
      ;; カーソル直前が 全角で漢字以外 だったら候補選択モードに移行する。
      ;; また、最後に確定した文字列と同じかどうかも確認する。
      (when (sekka-history-search (point) t)
	;; 直前に変換したfenceの範囲に入っていたら、候補選択モードに移行する。
	(setq sekka-select-mode t)
	(sekka-debug-print "henkan mode ON\n")
	
	;; 表示状態を候補選択モードに切替える。
	(sekka-display-function
	 (marker-position (car sekka-markers))
	 (marker-position (cdr sekka-markers))
	 t)))

     (t
      (sekka-debug-print (format "<<OTHER:non-ascii,non-kanji>> (%s)\n" (preceding-char))))))))
      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; キャピタライズ/アンキャピタライズ変換
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun sekka-capitalize-trans ()
  "キャピタライズ変換を行う
・カーソルから行頭方向にローマ字列を見つけ、先頭文字の大文字小文字を反転する"
  (interactive)

  (cond
   (sekka-select-mode
    ;; 候補選択モードでは反応しない。
    ;; do nothing
    )
   ((eq (sekka-char-charset (preceding-char)) 'ascii)
    ;; カーソル直前が alphabet だったら
    (sekka-debug-print "capitalize(2)!\n")

    (let ((end (point))
	  (gap (sekka-skip-chars-backward)))
      (when (/= gap 0)
	;; 意味のある入力が見つかったので変換する
	(let* (
	       (b (+ end gap))
	       (e end)
	       (roman-str (buffer-substring-no-properties b e)))
	  (sekka-debug-print (format "capitalize %d %d [%s]" b e roman-str))
	  (setq case-fold-search nil)
	  (cond
	   ((string-match-p "^[A-Z]" roman-str)
	    (downcase-region b (+ b 1)))
	   ((string-match-p "^[a-z]" roman-str)
	    (upcase-region   b (+ b 1))))))))
   ))


;; 全角で漢字以外の判定関数
(defun sekka-nkanji (ch)
  (and (eq (sekka-char-charset ch) 'japanese-jisx0208)
       (not (string-match "[亜-瑤]" (char-to-string ch)))))

(defun sekka-kanji (ch)
  (eq (sekka-char-charset ch) 'japanese-jisx0208))


;; ローマ字漢字変換時、変換対象とするローマ字を読み飛ばす関数
(defun sekka-skip-chars-backward ()
  (let* (
	 (skip-chars
	  (if auto-fill-function
	      ;; auto-fill-mode が有効になっている場合改行があってもskipを続ける
	      (concat sekka-skip-chars "\n")
	    ;; auto-fill-modeが無効の場合はそのまま
	    sekka-skip-chars))
	    
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
	    (goto-char (point-at-bol))
	    (let (
		  (start-point (point)))
	      (setq limit-point
		    (+
		     start-point
		     (skip-chars-forward (concat "\t " sekka-stop-chars) (point-at-eol))))))

	  ;; (sekka-debug-print (format "(point) = %d  result = %d  limit-point = %d\n" (point) result limit-point))
	  ;; (sekka-debug-print (format "a = %d b = %d \n" (+ (point) result) limit-point))

	  ;; パラグラフ位置でストップする
	  (if (< (+ (point) result) limit-point)
	      (- 
	       limit-point
	       (point))
	    result))

      ;; auto-fill-modeが無効の時
      (progn
	(save-excursion
	  (goto-char (point-at-bol))
	  (let (
		(start-point (point)))
	    (setq limit-point
		  (+ 
		   start-point
		   (skip-chars-forward (concat "\t " sekka-stop-chars) (point-at-eol))))))

	;; (sekka-debug-print (format "(point) = %d  result = %d  limit-point = %d\n" (point) result limit-point))
	;; (sekka-debug-print (format "a = %d b = %d \n" (+ (point) result) limit-point))

	(if (< (+ (point) result) limit-point)
	    ;; インデント位置でストップする。
	    (- 
	     limit-point
	     (point))
	  result)))))


(defun sekka-sticky-shift-init-function ()
  ;; sticky-shift
  (define-key global-map sticky-key sticky-map)
  (mapcar (lambda (pair)
	    (define-key sticky-map (car pair)
	      `(lambda()(interactive)
		 (if ,(< 0 (length (cdr pair)))
		     (setq unread-command-events
			   (cons ,(string-to-char (cdr pair)) unread-command-events))
		   nil))))
	  sticky-list)
  (define-key sticky-map sticky-key '(lambda ()(interactive)(insert sticky-key))))


(defun sekka-insert-space (times)
  (if (null times)
      (insert " ")
    (dotimes(i times)
      (insert " "))))

(defun sekka-spacekey-init-function ()
  (define-key global-map (kbd "SPC")
    '(lambda (&optional arg)(interactive "P")
       (cond ((and (< 0 sekka-timer-rest) 
		   sekka-kakutei-with-spacekey)
	      (cond
	       ((string= " " (char-to-string (preceding-char)))
		(sekka-insert-space arg))
	       ((eq       10                 (preceding-char))   ;; 直前に改行があった
		(sekka-insert-space arg))
	       ((string= "/" (char-to-string (preceding-char)))
		(delete-region (- (point) 1) (point))
		(sekka-insert-space arg))
	       (t
		(sekka-rK-trans))))
	     (t
	      (sekka-insert-space arg))))))


(defun sekka-muhenkan-key-init-function ()
  (define-key global-map sekka-muhenkan-key
    '(lambda (&optional arg)(interactive "P")
       (if (< 0 sekka-timer-rest)
	   ;; qキーで無変換+スペースを入力する
	   (cond
	    ((string= " " (char-to-string (preceding-char)))	 
	     ;; 2回目のキー入力で本来のsekka-muhenkan-keyで定義された文字を挿入する
	     (insert sekka-muhenkan-key))
	    (t
	     ;; 無変換で進むために、スペースを開ける。
	     (sekka-insert-space 1)))
	 (insert sekka-muhenkan-key)))))


(defun sekka-realtime-guide ()
  "リアルタイムで変換中のガイドを出す
sekka-modeがONの間中呼び出される可能性がある。"
  (cond
   ((< 0 sekka-busy)
    ;; 残り回数のデクリメント
    (setq sekka-timer-rest (- sekka-timer-rest 1))
    (sekka-debug-print "busy!\n"))
   ((or (null sekka-mode)
	(> 1 sekka-timer-rest))
    (cancel-timer sekka-timer)
    (setq sekka-timer nil)
    (delete-overlay sekka-guide-overlay))
   (sekka-guide-overlay
    ;; 残り回数のデクリメント
    (setq sekka-timer-rest (- sekka-timer-rest 1))

    ;; カーソルがsekka-realtime-guide-limit-lines をはみ出していないかチェック
    (sekka-debug-print (format "sekka-last-lineno [%d] : current-line\n" sekka-last-lineno (line-number-at-pos (point))))
    (when (< 0 sekka-realtime-guide-limit-lines)
      (let ((diff-lines (abs (- (line-number-at-pos (point)) sekka-last-lineno))))
	(when (<= sekka-realtime-guide-limit-lines diff-lines)
	  (setq sekka-timer-rest 0))))

    (let* (
	   (end (point))
	   (gap (sekka-skip-chars-backward)))
      (if 
	  (or 
	   (when (fboundp 'minibufferp)
	     (minibufferp))
	   (= gap 0))
	  ;; 上下スペースが無い または 変換対象が無しならガイドは表示しない。
	  (overlay-put sekka-guide-overlay 'before-string "")
	;; 意味のある入力が見つかったのでガイドを表示する。
	(let* (
	       (b (+ end gap))
	       (e end)
	       (str (buffer-substring-no-properties b e))
	       (lst (if (string-match "^[\s\t]+$" str)
			'()
		      (if (string= str sekka-guide-lastquery)
			  sekka-guide-lastresult
			(progn
			  (setq sekka-guide-lastquery str)
			  (setq sekka-guide-lastresult (sekka-henkan-request str 1))
			  sekka-guide-lastresult))))
	       (mess
		(if (< 0 (length lst))
		    (concat "[" (caar lst) "]")
		  "")))
	  (sekka-debug-print (format "realtime guide [%s]" str))
	  (move-overlay sekka-guide-overlay 
			;; disp-point (min (point-max) (+ disp-point 1))
			b e
			(current-buffer))
	  (overlay-put sekka-guide-overlay 'before-string mess))))
    (overlay-put sekka-guide-overlay 'face 'sekka-guide-face))))


(defun sekka-stop-realtime-guide ()
  (when (eq this-command 'keyboard-quit)
    (setq sekka-timer-rest 0)))


;;;
;;; human interface
;;;
(define-key sekka-mode-map sekka-rK-trans-key 'sekka-rK-trans)
(define-key sekka-mode-map "\M-j" 'sekka-capitalize-trans)
(or (assq 'sekka-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (append (list 
		   (cons 'sekka-mode         sekka-mode-map))
		  minor-mode-map-alist)))



;; sekka-mode の状態変更関数
;;  正の引数の場合、常に sekka-mode を開始する
;;  {負,0}の引数の場合、常に sekka-mode を終了する
;;  引数無しの場合、sekka-mode をトグルする

;; buffer 毎に sekka-mode を変更する
(defun sekka-mode (&optional arg)
  "Sekka mode は ローマ字から直接漢字変換するための minor mode です。
引数に正数を指定した場合は、Sekka mode を有効にします。

Sekka モードが有効になっている場合 \\<sekka-mode-map>\\[sekka-rK-trans] で
point から行頭方向に同種の文字列が続く間を漢字変換します。

同種の文字列とは以下のものを指します。
・半角カタカナとsekka-stop-chars に指定した文字を除く半角文字
・漢字を除く全角文字"
  (interactive "P")
  (sekka-mode-internal arg nil))

;; 全バッファで sekka-mode を変更する
(defun global-sekka-mode (&optional arg)
  "Sekka mode は ローマ字から直接漢字変換するための minor mode です。
引数に正数を指定した場合は、Sekka mode を有効にします。

Sekka モードが有効になっている場合 \\<sekka-mode-map>\\[sekka-rK-trans] で
point から行頭方向に同種の文字列が続く間を漢字変換します。

同種の文字列とは以下のものを指します。
・半角カタカナとsekka-stop-chars に指定した文字を除く半角文字
・漢字を除く全角文字"
  (interactive "P")
  (sekka-mode-internal arg t))


;; sekka-mode を変更する共通関数
(defun sekka-mode-internal (arg global)
  (sekka-debug-print "sekka-mode-internal :1\n")

  (or (local-variable-p 'sekka-mode (current-buffer))
      (make-local-variable 'sekka-mode))
  (if global
      (progn
	(setq-default sekka-mode (if (null arg) (not sekka-mode)
				    (> (prefix-numeric-value arg) 0)))
	(sekka-kill-sekka-mode))
    (setq sekka-mode (if (null arg) (not sekka-mode)
			(> (prefix-numeric-value arg) 0))))
  (when sekka-sticky-shift
    (add-hook 'sekka-mode-hook 'sekka-sticky-shift-init-function))

  (add-hook 'sekka-mode-hook 'sekka-spacekey-init-function)
  (when sekka-muhenkan-key
    (add-hook 'sekka-mode-hook 'sekka-muhenkan-key-init-function))

  (when sekka-mode (run-hooks 'sekka-mode-hook))

  (sekka-debug-print "sekka-mode-internal :2\n")

  ;; Ctrl-G押下時、リアルタイムガイドをOFFにするhook
  (add-hook 'post-command-hook 'sekka-stop-realtime-guide)
  (add-hook 'pre-command-hook  'sekka-stop-realtime-guide))


;; buffer local な sekka-mode を削除する関数
(defun sekka-kill-sekka-mode ()
  (let ((buf (buffer-list)))
    (while buf
      (set-buffer (car buf))
      (kill-local-variable 'sekka-mode)
      (setq buf (cdr buf)))))


;; 全バッファで sekka-input-mode を変更する
(defun sekka-input-mode (&optional arg)
  "入力モード変更"
  (interactive "P")
  (if (< 0 arg)
      (progn
	(setq inactivate-current-input-method-function 'sekka-inactivate)
	(setq sekka-mode t))
    (setq inactivate-current-input-method-function nil)
    (setq sekka-mode nil)))


;; input method 対応
(defun sekka-activate (&rest arg)
  (sekka-input-mode 1))
(defun sekka-inactivate (&rest arg)
  (sekka-input-mode -1))
(register-input-method
 "japanese-sekka" "Japanese" 'sekka-activate
 "" "Roman -> Kanji&Kana"
 nil)

;; input-method として登録する。
(set-language-info "Japanese" 'input-method "japanese-sekka")
(setq default-input-method "japanese-sekka")

(defconst sekka-version
  "1.8.0" ;;SEKKA-VERSION
  )
(defun sekka-version (&optional arg)
  "入力モード変更"
  (interactive "P")
  (message sekka-version))

(provide 'sekka)

;; Local Variables:
;; coding: utf-8
;; End:

;;; sekka.el ends here
