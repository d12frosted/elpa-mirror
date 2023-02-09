;;; baidu-translate.el --- A plugin using baidu-translate-api

;; Copyright (C) 2019

;; Author:  <LiShizhen gsu4017@gmail.com>
;; Version: 1.0
;; URL: https://github.com/liShiZhensPi/baidu-translate
;; Package-Requires: ((unicode-escape "1.1"))

;; This file is not part of GNU Emacs

;; Keywords: docs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 本插件需要 unicode-unescape插件的支持

;;; Code:



(require 'unicode-escape)

(defconst baidu-translate-api-host "https://api.fanyi.baidu.com/api/trans/vip/translate")
;;需要去百度申请API
;;设置你的百度翻译APPID
(defvar baidu-translate-appid)
;;设置你的秘钥
(defvar baidu-translate-security)


(defun baidu-translate-clear-buffer (buffer-or-name)
  "Clear the buffer (BUFFER-OR-NAME)."
  (let ((buffer nil))
    (if (bufferp buffer-or-name)
	(setq buffer buffer-or-name)
      (setq buffer (get-buffer buffer-or-name)))
    (if (not (buffer-live-p buffer))
	(error "Buffer don't exist"))
    (with-current-buffer buffer
      ;;清空buffer
      (goto-char (point-min))
      (mark-end-of-buffer)
      (delete-region (point) (mark)))))

  
(defun baidu-translate-core (query src-language dis-language)
  "Translate QUERY from SRC-LANGUAGE to DIS-LANGUAGE,return as string.
\nExample: (baidu-translate-core '你好' 'auto' 'en')
\nResult: {\"from\":\"zh\",\"to\":\"en\",\"trans_result\":[{\"src\":\"\\u4f60\\u597d\",\"dst\":\"Hello\"}]}"
  (let* ((salt (number-to-string (random)))
	 (URL (concat baidu-translate-api-host
	  ;;百度API的URL格式在官方网站的文档中有详细介绍
		     "?"
		     (format "q=%s" query)
		     "&"
		     (format "salt=%s" salt)
		     "&"
		     (format "appid=%s" baidu-translate-appid)
		     "&"
		     (format "sign=%s" (md5 (concat baidu-translate-appid query  salt baidu-translate-security) nil nil (coding-system-from-name "utf-8")))
		     "&"
		     (format "from=%s" src-language)
		     "&"
		     (format "to=%s" dis-language))))
    (with-current-buffer (url-retrieve-synchronously URL)
       (set-buffer-multibyte t)
       (goto-char (point-min))
       (re-search-forward "\n\n")
       (prog1 (buffer-substring (point)
                                (point-max))
         (kill-buffer)))))


(defun baidu-translate-string (string src-language dis-language)
  "Translate STRING from SRC-LANGUAGE to DIS-LANGUAGE.Print the string to buffer *baidu-translate*."
  
  (if (buffer-live-p (get-buffer "*baidu-translate*"))
      (baidu-translate-clear-buffer "*baidu-translate*"))
  (switch-to-buffer-other-window "*baidu-translate*")
  (let ((result (baidu-translate-core string src-language dis-language))
	(GBKS nil))
    (while (string-match "\"dst\":\"" result)
      (setq GBKS (substring result
			    (+ (string-match "\"dst\":\"" result) 7)
			    (string-match "\"}" result)))
      (setq result (substring result
			      (+ (string-match "\"}" result) 1)))
      (insert (unicode-unescape GBKS))
      (insert "\n")
      (insert "\n"))
    (goto-char (point-min))))

;;对内核函数的包装UI，你可以根据需要修改语言类型参数，定制自己的UI，下面2个例子是将region或者buffer中的文字翻译为中文
(defun baidu-translate-zh-mark (start end)
  "Translate the marked text to Chinese.
Argument START .
Argument END ."
  (interactive "r")
  (baidu-translate-string (buffer-substring start end) "auto" "zh"))

(defun baidu-translate-zh-whole-buffer ()
  "Translate the whole buffer to Chinese."
  (interactive)
  (baidu-translate-string (buffer-string) "auto" "zh"))

;;将region或者buffer中的文字翻译为英文
(defun baidu-translate-en-mark (start end)
  "Translate the marked text to English.
Argument START .
Argument END ."
  (interactive "r")
  (baidu-translate-string (buffer-substring start end) "auto" "en"))

(defun baidu-translate-en-whole-buffer ()
  "Translate the whole buffer to English."
  (interactive)
  (baidu-translate-string (buffer-string) "auto" "en"))


;; auto	自动检测
;; zh	中文
;; en	英语
;; yue	粤语
;; wyw	文言文
;; jp	日语
;; kor	韩语
;; fra	法语
;; spa	西班牙语
;; th	泰语
;; ara	阿拉伯语
;; ru	俄语
;; pt	葡萄牙语
;; de	德语
;; it	意大利语
;; el	希腊语
;; nl	荷兰语
;; pl	波兰语
;; bul	保加利亚语
;; est	爱沙尼亚语
;; dan	丹麦语
;; fin	芬兰语
;; cs	捷克语
;; rom	罗马尼亚语
;; slo	斯洛文尼亚语
;; swe	瑞典语
;; hu	匈牙利语
;; cht	繁体中文
;; vie	越南语


(provide 'baidu-translate)
;;; baidu-translate.el ends here

