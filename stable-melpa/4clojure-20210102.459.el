;;; 4clojure.el --- Open and evaluate 4clojure.com questions.  -*- lexical-binding: t -*-

;; Copyright (C) 2013-2020 Joshua Hoff

;; Author: Joshua Hoff
;; Maintainer: Sasha Kovar <sasha-git@arcocene.org>
;; Keywords: languages, data
;; Package-Version: 20210102.459
;; Package-Commit: 6f494d3905284ccdd57aae3d8ac16fc7ab431596
;; Version: 0.3.1
;; Package-Requires: ((request "0.2.0"))
;; Homepage: https://github.com/abend/4clojure.el

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

;; To open a specific problem, use `4clojure-open-question':
;; e.g. "M-x 4clojure-open-question RET 2" opens question 2.

;; To check your answers, use `4clojure-check-answers':
;; e.g. `M-x 4clojure-check-answers`

;; To open the next question (or the first if you’re not in a 4clojure
;; buffer), use `4clojure-next-question'.  Similarly,
;; `4clojure-previous-question' opens the previous question.

;;; Code:

(require 'json)
(require 'request)
(require 'cl-lib)

(defvar 4clojure-cached-question nil
  "The current question, in the format: (number question-data).")

(defun 4clojure-get-question-cached (problem-number)
  "Get (and memoize) the problem PROBLEM-NUMBER."
  (if (string= (car 4clojure-cached-question) problem-number)
      (cadr 4clojure-cached-question)
    (progn
      (request
       (format "https://www.4clojure.com/api/problem/%s" problem-number)
       :parser 'json-read
       :sync t
       :success (cl-function
                 (lambda (&key data &allow-other-keys)
                   (setq 4clojure-cached-question
                         `(,problem-number ,data)))))
      (cadr 4clojure-cached-question))))

(defun 4clojure-questions-for-problem (problem-number)
  "Get a list of questions for PROBLEM-NUMBER."
  (mapconcat #'identity
             (assoc-default 'tests
                            (4clojure-get-question-cached problem-number))
             "\n\n"))

(defun 4clojure-first-question-for-problem (problem-number)
  "Get the first question of the problem PROBLEM-NUMBER.
These are called 'tests' on the site."
  (replace-regexp-in-string
   "" ""
   (elt (assoc-default 'tests
                       (4clojure-get-question-cached problem-number))
        0)))

(defun 4clojure-title-of-problem (problem-number)
  "Gets the title of problem PROBLEM-NUMBER."
  (assoc-default 'title
                 (4clojure-get-question-cached problem-number)))

(defun 4clojure-description-of-problem (problem-number)
  "Get the description of problem PROBLEM-NUMBER."
  (assoc-default 'description
                 (4clojure-get-question-cached problem-number)))

(defun 4clojure-restrictions-for-problem (problem-number)
  "Get a list of restrictions (forbidden functions) for PROBLEM-NUMBER."
  (let ((restrictions (assoc-default 'restricted
                        (4clojure-get-question-cached problem-number))))
    (if (= 0 (length restrictions))
        nil
      restrictions)))

(defun 4clojure-start-new-problem (problem-number)
  "Open a new buffer for PROBLEM-NUMBER with the question and description.
Don't clobber existing text in the buffer if the problem was already opened."
  (let ((buffer (get-buffer-create (format "*4clojure-problem-%s*" problem-number)))
        (questions    (4clojure-questions-for-problem problem-number))
        (title        (4clojure-title-of-problem problem-number))
        (description  (4clojure-description-of-problem problem-number))
        (restrictions (4clojure-restrictions-for-problem problem-number)))
    (switch-to-buffer buffer)
    ;; only add to empty buffers, thanks: https://stackoverflow.com/q/18312897
    (when (= 0 (buffer-size buffer))
      (insert (4clojure-format-problem-for-buffer problem-number title description questions restrictions))
      (goto-char (point-min))
      (search-forward "__")
      (backward-char 2)
      (when (functionp #'clojure-mode)
        (clojure-mode)
        (4clojure-mode)))))

(defun 4clojure-format-problem-for-buffer (problem-number title description questions &optional restrictions)
  "Format problem PROBLEM-NUMBER for an Emacs buffer.
In addition to displaying the TITLE, DESCRIPTION, QUESTIONS and RESTRICTIONS,
it adds a header and tip about how to check your answers."
  (concat
   ";; 4Clojure Question " problem-number " - " title "\n"
   ";;\n"
   ";; " (replace-regexp-in-string "\s*\n+\s*" "\n;;\n;; " description) "\n"
   (when restrictions
     (concat ";;\n;; Restrictions (please don't use these function(s)): "
             (mapconcat #'identity restrictions ", ")
             "\n"))
   ";;\n;; Use M-x 4clojure-check-answers when you're done!\n\n"
   (replace-regexp-in-string "" "" questions)))

(defun 4clojure-get-answer-from-current-buffer (problem-number)
  "Get the user's answer to the first question in PROBLEM-NUMBER.
Compares the original question (with a blank in it) to the current buffer."
  (string-match
   (replace-regexp-in-string
    "__"
    "\\(\\(\n\\|.\\)\+\\)"
    (replace-regexp-in-string
     "[\s\n]\+"
     "[\s\n]\+"
     (regexp-quote (4clojure-first-question-for-problem problem-number))
     nil t)
    nil t)
   (buffer-string))
  (match-string 1 (buffer-string)))

(defun 4clojure-problem-number-of-current-buffer ()
  "Get the problem number for the current buffer or 0."
  (let* ((bufname (buffer-name (current-buffer)))
         (number-with-star (first (last (split-string bufname "-"))))
         (problem-number (substring number-with-star
                                    0
                                    (1- (string-width number-with-star)))))
    (if (string-match "[^0-9]" problem-number)
        0
      (string-to-number problem-number))))

(defun 4clojure-check-answer (problem-number answer)
  "PROBLEM-NUMBER receives an ANSWER and is sent to 4clojure and return the result."
  (request
   (format "https://www.4clojure.com/rest/problem/%s" problem-number)
   :type "POST"
   :parser 'json-read
   :sync t
   :data `(("id" . ,problem-number) ("code" . ,answer))
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (let ((error (assoc-default 'error data))
                     (message (assoc-default 'message data))
                     (indexOfFailing (assoc-default 'failingTest data)))
                 (setq result
                       (if (> (string-width error) 0)
                           `(,indexOfFailing ,error)
                         `(,nil ,message)))))))
  result)

;;;###autoload
(defun 4clojure-open-question (problem-number)
  "Open problem PROBLEM-NUMBER in an aptly named buffer."
  (interactive "sWhich 4clojure question? ")
  (4clojure-start-new-problem problem-number))

;;;###autoload
(defun 4clojure-login (username)
  "Log in to the 4clojure website with the supplied USERNAME.
Prompts for a password."
  (interactive "sUsername: ")
  (let ((password (read-passwd "Password: ")))
    (request
     "https://www.4clojure.com/login"
     :type "POST"
     :data `(("user" . ,username) ("pwd" . ,password))
     ;; When user login successful, 4clojure will redirect user to main page,
     ;; If `request-backend` is `curl`, we will get response code 400 (4 clojure's behavior)
     ;; or 500 (see http://curl.haxx.se/mail/tracker-2012-01/0018.html
     ;; If `request-backend` is `url-retrieve`, we will get response 302
     ;; (it does not process redirection)
     :status-code '((404 . (lambda (&rest _) (message "login successful!")))
                    (302 . (lambda (&rest _) (message "login successful")))
                    (500 . (lambda (&rest _) (message "login successful")))))))

;;;###autoload
(defun 4clojure-next-question ()
  "Get the next question or 1st question based on the current buffer name."
  (interactive)
  (let ((problem-number (4clojure-problem-number-of-current-buffer)))
    (4clojure-start-new-problem (int-to-string (1+ problem-number)))))


;;;###autoload
(defun 4clojure-previous-question ()
  "Open the previous question or 1st question based on the current buffer name."
  (interactive)
  (let ((problem-number (4clojure-problem-number-of-current-buffer)))
    (4clojure-start-new-problem (int-to-string (if (< problem-number 3)
                                                   1
                                                 (1- problem-number))))))

;;;###autoload
(defun 4clojure-check-answers ()
  "Send the first answer to 4clojure and check the result."
  (interactive)
  (let* ((problem-number-as-int (4clojure-problem-number-of-current-buffer))
         (problem-number (int-to-string problem-number-as-int))
         (result (4clojure-check-answer
                  problem-number
                  (4clojure-get-answer-from-current-buffer problem-number))))
    (if (car result)
        (message "Test %d failed.\n%s"
                 (car result)
                 (cadr result))
      (message "%s" (cadr result)))))

;;;###autoload
(defvar 4clojure-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "c") '4clojure-check-answers)
      (define-key prefix-map (kbd "n") '4clojure-next-question)
      (define-key map "C-c" prefix-map))
    map)
  "Keymap for 4clojure mode.")

;;;###autoload
(define-minor-mode 4clojure-mode
  "4clojure Minor Mode.
  \\{4clojure-mode-map}"
  :lighter " 4clj"
  :keymap  '4clojure-mode-map
  :group   '4clojure
  :require '4clojure)

(provide '4clojure)
;;; 4clojure.el ends here
