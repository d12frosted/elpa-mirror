;;; phi-search-migemo.el --- migemo extension for phi-search

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
;; URL: http://hins11.yu-yake.com/
;; Package-Version: 20170618.921
;; Package-Commit: 308909ebfc8003d16673f97ca9eb26a667b72969
;; Version: 1.1.0
;; Package-Requires: ((phi-search "2.2.0") (migemo "1.9.1"))

;;; Commentary:

;; This script provides "phi-search"-based Japanese incremental
;; search, powered by "migemo".

;; phi-search, migemo をインストールしこのファイルをロードすると、"M-x
;; phi-search-migemo-toggle" で migemo の有効/無効を切り替えることがで
;; きます。 phi-search-default-map にキーバインドを追加しておいても便利
;; です。
;;
;;   (define-key phi-search-default-map (kbd "M-m") 'phi-search-toggle-migemo)
;;
;; "phi-search-migemo", "phi-search-migemo-backward" は、 phi-search を
;; 起動し migemo を有効にするところまでをひとまとめにしたコマンドです。
;; migemo がデフォルトで有効になっていて欲しい場合は、 "phi-search",
;; "phi-search-backward" の代わりにこれらの関数を使うと便利です。たんに
;; 正規表現で検索をしたい場合は、前置引数を渡すことで migemo を無効のま
;; ま起動することもできます。

;;; Change Log:

;; 1.0.0 first release
;; 1.1.0 implement naive cahching

;;; Code:

(require 'migemo)
(require 'phi-search-core)

(defconst phi-search-migemo-version "1.1.0")

(defgroup phi-search-migemo nil
  "migemo extension for phi-search"
  :group 'phi-search)

(defvar phi-search-migemo--last-query nil)
(defun phi-search-migemo--get-pattern (query)
  (if (and phi-search-migemo--last-query
           (string= (car phi-search-migemo--last-query) query))
      (cdr phi-search-migemo--last-query)
    (condition-case nil
        (let ((pat (migemo-get-pattern query)))
          (setq phi-search-migemo--last-query (cons query pat))
          pat)
      (error query))))

;;;###autoload
(defun phi-search-migemo-toggle ()
  "migemo の有効/無効を切り替えます。 phi-search ウィンドウ内で実
行してください。"
  (interactive)
  (unless phi-search--target
    (error "phi-search が実行されていません。"))
  (setq phi-search--convert-query-function
        (unless phi-search--convert-query-function
          'phi-search-migemo--get-pattern))
  (phi-search--update))

;;;###autoload
(defun phi-search-migemo (&optional disable-migemo)
  "migemo が有効な状態で phi-search を起動します。"
  (interactive "P")
  (if (or disable-migemo (use-region-p))
      (phi-search)
    (let ((phi-search-hook
           (cons 'phi-search-migemo-toggle phi-search-hook)))
      (phi-search))))

;;;###autoload
(defun phi-search-migemo-backward (&optional disable-migemo)
  "migemo が有効な状態で phi-search-backward を起動します。"
  (interactive "P")
  (if (or disable-migemo (use-region-p))
      (phi-search-backward)
    (let ((phi-search-hook
           (cons 'phi-search-migemo-toggle phi-search-hook)))
      (phi-search-backward))))

(provide 'phi-search-migemo)

;;; phi-search-migemo.el ends here
