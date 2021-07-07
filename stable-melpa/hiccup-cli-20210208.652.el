;;; hiccup-cli.el --- Convert HTML to Hiccup syntax -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Kevin W. van Rooijen
;;
;; Author: Kevin W. van Rooijen
;; URL: https://github.com/kwrooijen/hiccup-cli
;; Package-Version: 20210208.652
;; Package-Commit: b56ae0d5cd5ce3ef24ed13be5103e231c91ef4e2

;; Version: 0.1.0
;; Keywords: tools
;; Package-Requires: ((emacs "26.1"))

;; Copyright 2021 Kevin W. van Rooijen

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; Convert standard HTML to Clojure's Hiccup syntax
;; (https://github.com/weavejester/hiccup).
;;
;; Available functions:
;;
;; hiccup-cli-paste-as-hiccup
;; hiccup-cli-region-as-hiccup
;; hiccup-cli-yank-as-hiccup

;;; Code:

(defgroup hiccup-cli nil
  "Hiccup-cli group."
  :prefix "hiccup-cli-"
  :group 'tools)

(defcustom hiccup-cli-custom-path-to-bin
  (or (executable-find "hiccup-cli")
      "hiccup-cli")
  "Custom path to the hiccup-cli executable."
  :type 'file
  :group 'hiccup-cli)

(defcustom hiccup-cli-custom-path-to-tmp-file
  (concat (temporary-file-directory) "hiccup-cli-content")
  "Custom path to the hiccup-cli tmp file."
  :type 'file
  :group 'hiccup-cli)

(defun hiccup-cli--clipboard-string ()
  "Return the current value of the clipboard as a string."
  (let ((clipboard-text (gui--selection-value-internal 'CLIPBOARD))
	(select-enable-clipboard t))
    (if (and clipboard-text (> (length clipboard-text) 0))
	(kill-new clipboard-text))
    (car kill-ring)))

(defun hiccup-cli--write-to-tmp-file (string)
  "Write STRING to `hiccup-cli--custom-path-to-tmp-file'."
  (write-region string nil hiccup-cli-custom-path-to-tmp-file))

(defun hiccup-cli--insert ()
  "Insert converted Hiccup from `hiccup-cli--custom-path-to-tmp-file' into buffer."
  (save-excursion
    (insert
     (shell-command-to-string
      (format "%s --html-file %s"
              hiccup-cli-custom-path-to-bin
              hiccup-cli-custom-path-to-tmp-file)))))

;;;###autoload
(defun hiccup-cli-paste-as-hiccup ()
  "Paste the HTML in your clipboard as Hiccup syntax."
  (interactive)
  (hiccup-cli--write-to-tmp-file (hiccup-cli--clipboard-string))
  (hiccup-cli--insert))

;;;###autoload
(defun hiccup-cli-region-as-hiccup (start end)
  "Replace the HTML in your selected START END region with Hiccup syntax."
  (interactive "r")
  (if (use-region-p)
      (let ((region-str (buffer-substring start end)))
        (kill-region start end)
        (hiccup-cli--write-to-tmp-file region-str)
        (hiccup-cli--insert))))

;;;###autoload
(defun hiccup-cli-yank-as-hiccup ()
  "Paste the HTML in your `kill-ring' as Hiccup syntax."
  (interactive)
  (hiccup-cli--write-to-tmp-file (substring-no-properties (car kill-ring)))
  (hiccup-cli--insert))

(provide 'hiccup-cli)

;;; hiccup-cli.el ends here
