;;; line-up-words.el --- Align words in an intelligent way

;; Copyright 2018 Jane Street Group, LLC <opensource@janestreet.com>
;; URL: https://github.com/janestreet/line-up-words
;; Package-Version: 20180213.1423
;; Package-Commit: 54d2c51c1c3da7e06be47b829bf465bf467ab53f
;; Version: 1.0

;;; Commentary:

;; See the README.md for more info;
;; https://github.com/janestreet/line-up-words

;;; Code:

(defvar line-up-words-command "line-up-words")

;;;###autoload
(defun line-up-words ()
  "Try to align words in the region in an intelligent way."
  (interactive)
  (shell-command-on-region
   (region-beginning) (region-end) line-up-words-command t t
   shell-command-default-error-buffer t)
  (indent-region (region-beginning) (region-end)))

(provide 'line-up-words)

;;; line-up-words.el ends here
