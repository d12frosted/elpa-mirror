;;; pinyin-search.el --- Search Chinese by Pinyin

;; Copyright © 2015 Chunyang Xu <xuchunyang56@gmail.com>

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; URL: https://github.com/xuchunyang/pinyin-search.el
;; Package-Version: 20160515.358
;; Package-Commit: 2e877a76851009d41bde66eb33182a03a7f04262
;; Version: 1.0.0
;; Package-Requires: ((pinyinlib "0.1.0"))
;; Created: 30 Jan 2015
;; Keywords: Chinese, search

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Search Chinese by the first letter of Chinese pinyin.
;; 使用拼音首字母搜索中文。
;; e.g. use `zw` to search `中文` (*Z*hong *W*en).
;;
;; Usage:

;; - `isearch-forward-pinyin'
;; - `isearch-backward-pinyin'
;;
;; or run `isearch-toggle-pinyin' (`M-s p') after invoking any normal
;; `isearch' commands like `C-s` (`isearch-forward`).
;;
;; Known Bugs and Limitations:
;; - [anzu.el](https://github.com/syohex/emacs-anzu) compatibility

;;; Change Log:
;; 1.0.1   - 2015/04/05 - Add two aliases (`pinyin-search' and `pinyin-search-backward')
;; 1.0.0   - 2015/03/18 - Simplify integration with `isearch'.
;; 0.0.1   - 2015/01/31 - Created File.

;;; Code:

(require 'pinyinlib)

(defgroup pinyin-search nil
  "Pinyin matching in isearch"
  :prefix "pinyin-search-"
  :group 'isearch
  :link '(url-link :tag "Development and bug reports"
                   "https://github.com/xuchunyang/pinyin-search.el"))

(defcustom pinyin-search-message-prefix "[拼音] "
  "Prepended to the isearch prompt when Pinyin searching is activated."
  :type 'string
  :group 'pinyin-search)

(defcustom pinyin-search-keep-last-state nil
  "Non-nil means the last state will be used in any next isearch commands."
  :type 'boolean
  :group 'pinyin-search)


(defvar pinyin-search-activated nil)

(defvar isearch-mode-exit-flag nil)

(setq isearch-search-fun-function 'isearch-function-with-pinyin)

(add-hook 'isearch-mode-end-hook 'isearch-set-pinyin-state)

(defadvice isearch-exit (before isearch-signal-when-exiting activate)
  (setq isearch-mode-exit-flag t))

(defadvice isearch-message-prefix (after pinyin-search-message-prefix activate)
  (if pinyin-search-activated
      (setq ad-return-value (concat pinyin-search-message-prefix ad-return-value))
    ad-return-value))

(defun pinyin-search--pinyin-to-regexp (pinyin)
  "Convert the first letter of Chinese PINYIN to regexp."
  (pinyinlib-build-regexp-string pinyin t nil t))

(defun pinyin-search-unload-function ()
  "Clean up when unload this package with `unload-feature'.
pinyin-search modifies some default behaviors of isearch."
  (setq isearch-search-fun-function 'isearch-search-fun-default)
  (ad-deactivate 'isearch-exit))

(defun isearch-function-with-pinyin ()
  "Wrap for Pinyin searching."
  (if pinyin-search-activated
      ;; Return the function to use for pinyin search
      `(lambda (string bound noerror)
         (funcall (if ,isearch-forward
                      're-search-forward
                    're-search-backward)
                  (pinyin-search--pinyin-to-regexp string) bound noerror))
    ;; Return default function
    (isearch-search-fun-default)))

(defun isearch-set-pinyin-state ()
  ;; Only when users cancel isearch or exit isearch normally with
  ;; `isearch-exit' should the state of pinyin search be changed.
  (when (or isearch-mode-end-hook-quit
            isearch-mode-exit-flag)
    (setq isearch-mode-exit-flag nil)
    (unless pinyin-search-keep-last-state
      (setq pinyin-search-activated nil))))

;;; Commands

;;;###autoload
(defun isearch-toggle-pinyin ()
  "Toggle pinyin in searching on or off.
Toggles the value of the variable `pinyin-search-activated'."
  (interactive)
  (setq pinyin-search-activated (not pinyin-search-activated))
  (setq isearch-success t isearch-adjusted t)
  (setq isearch-lazy-highlight-error t) ; force updating lazy highlight
  (message (concat "Turn " (if pinyin-search-activated "on" "off") " pinyin search"))
  (sit-for 1)
  (isearch-update))

;;;###autoload
(defun isearch-forward-pinyin ()
  "Search Chinese forward by Pinyin."
  (interactive)
  (setq pinyin-search-activated t)
  (call-interactively 'isearch-forward))

;;;###autoload
(defun isearch-backward-pinyin ()
  "Search Chinese backward by Pinyin."
  (interactive)
  (setq pinyin-search-activated t)
  (call-interactively 'isearch-backward))

;;;###autoload
(defalias 'pinyin-search 'isearch-forward-pinyin)
;;;###autoload
(defalias 'pinyin-search-backward 'isearch-backward-pinyin)

;;; Default Key bindings

;;;###autoload
(define-key isearch-mode-map "\M-sp" #'isearch-toggle-pinyin)

(provide 'pinyin-search)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; pinyin-search.el ends here
