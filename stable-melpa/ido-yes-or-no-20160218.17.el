;;; ido-yes-or-no.el --- Use Ido to answer yes-or-no questions

;; Copyright 2011 Ryan C. Thompson

;; Author: Ryan C. Thompson
;; URL: https://github.com/DarwinAwardWinner/ido-yes-or-no
;; Package-Version: 20160218.17
;; Package-Commit: 9ddee9e878ad62d58c9f4b3a7685f22b8e36e420
;; Version: 1.4
;; Package-Requires: ((ido-completing-read+ "0"))

(require 'ido)

;;;###autoload
(define-minor-mode ido-yes-or-no-mode
  "Use ido for `yes-or-no-p'."
  nil
  :global t
  :group 'ido)

(defun ido-yes-or-no-p (prompt)
  "Ask user a yes-or-no question using ido."
  (let* ((yes-or-no-prompt (concat prompt " "))
         (choices '("yes" "no"))
         (answer (ido-completing-read+ yes-or-no-prompt choices nil 'require-match)))
    ;; Keep asking until they enter a valid choice (needed to work
    ;; around completion allowing exiting with an empty string)
    (while (string= answer "")
      (message "Please answer yes or no.")
      (setq answer (ido-completing-read+
                    (concat "Please answer yes or no.\n"
                            yes-or-no-prompt)
                    choices nil 'require-match)))
    (string= answer "yes")))

(defadvice yes-or-no-p (around use-ido activate)
  (if ido-yes-or-no-mode
      (setq ad-return-value (ido-yes-or-no-p prompt))
    ad-do-it))

(provide 'ido-yes-or-no)
;;; ido-yes-or-no.el ends here
