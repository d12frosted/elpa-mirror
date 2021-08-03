;;; notmuch-addr.el --- An alternative to notmuch-address.el  -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021 Free Software Foundation, Inc.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://git.sr.ht/~tarsius/notmuch-addr
;; Keywords: mail
;; Package-Version: 20210615.1512
;; Package-Commit: c447ddb94b3c2a473ec1762fc083794acd6057f0

;; Package-Requires: ((emacs "27.1") (notmuch "0.32"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; An alternative to `notmuch-address'.  This implementation is much
;; simpler.  It gives up on persistent caching, external scripts and
;; backward compatibility.

;; This implementation uses the improved completion API offered by
;; Emacs 27.1 and later.  `notmuch-address' uses that old API, which
;; Emacs still supports.  In [1] I have documented the issues of the
;; old API and its use in Notmuch, as well as some other defects.

;; To use `notmuch-addr' you must enable its use right after Notmuch
;; has loaded the old `notmuch-address', which cannot be prevented.
;; If you do it later then it might have no effect:
;;
;; (with-eval-after-load 'notmuch-address
;;   (require 'notmuch-addr)
;;   (notmuch-addr-setup))

;; This implementation is essentially identical to the upstream
;; implementation, except that it uses "notmuch address ..." as
;; an additional source of completion candidates.

;; [1]: https://nmbug.notmuchmail.org/nmweb/show/20201108231150.5419-1-jonas%40bernoul.li

;;; Code:

(require 'notmuch)

;; Copy of notmuch-address-completion-headers-regexp.
(defvar notmuch-addr-completion-headers-regexp
  "^\\(Resent-\\)?\\(To\\|B?Cc\\|Reply-To\\|\
From\\|Mail-Followup-To\\|Mail-Copies-To\\):")

(defun notmuch-address-from-minibuffer--use-notmuch-addr (prompt)
  "Pivot to `notmuch-addr-read-recipient'."
  (notmuch-addr-read-recipient prompt))

(defun notmuch-addr-setup ()
  "Configure `message-mode' to use `notmuch-addr-expand-name'.
Also sustituted `notmuch-addr-read-recipient'
for `notmuch-address-from-minibuffer'."
  (setq notmuch-address-command 'as-is)
  (advice-add 'notmuch-address-from-minibuffer :override
              'notmuch-address-from-minibuffer--use-notmuch-addr)
  (cl-pushnew 'notmuch message-expand-name-databases)
  (cl-pushnew (cons notmuch-addr-completion-headers-regexp
                    'notmuch-addr-expand-name)
              message-completion-alist :test #'equal))

(defun notmuch-addr-expand-name ()
  "Similar to `message-expand-name'.
* Use \"notmuch address ...\" as an additional source.
* Pretend `message-expand-name-standard-ui' is non-nil.
* Accept the empty string as initial input."
  (let ((beg (save-excursion
               (skip-chars-backward "^\n:,")
               (skip-chars-forward " \t")
               (point)))
        (end (save-excursion
               (skip-chars-forward "^\n,")
               (skip-chars-backward " \t")
               (point))))
    (when (< end beg)
      (setq beg (setq end (point))))
    (list beg end
          (notmuch-addr--name-table (buffer-substring beg end)))))

(defun notmuch-addr--name-table (_)
  "Like `message--name-table' but also use \"notmuch address...\"."
  (let (cached eudc-responses bbdb-responses notmuch-responses)
    (lambda (string pred action)
      (pcase action
        ('metadata '(metadata (category . email)))
        ('lambda t)
        ((or 'nil 't)
         (unless cached
           (when (and (memq 'eudc message-expand-name-databases)
                      (boundp 'eudc-protocol)
                      eudc-protocol)
             (setq eudc-responses (eudc-query-with-words nil)))
           (when (memq 'bbdb message-expand-name-databases)
             (setq bbdb-responses (message--bbdb-query-with-words nil)))
           (when (memq 'notmuch message-expand-name-databases)
             (setq notmuch-responses (notmuch-addr-query-with-words)))
           (ecomplete-setup)
           (setq cached t))
         (let ((candidates
                ;; TODO Occasionally check if they added `expand-abbrev'!
                (append (all-completions string eudc-responses pred)
                        (all-completions string bbdb-responses pred)
                        (all-completions string notmuch-responses pred)
                        (when (and (bound-and-true-p ecomplete-database)
                                   (fboundp 'ecomplete-completion-table))
                          (all-completions string
                                           (ecomplete-completion-table 'mail)
                                           pred)))))
           (if action candidates (try-completion string candidates))))))))

(defvar notmuch-addr--cache nil)

(defun notmuch-addr-query-with-words ()
  "Like `message--bbdb-query-with-words' but for notmuch."
  (or (and (not current-prefix-arg)
           notmuch-addr--cache)
      (setq notmuch-addr--cache
            (prog2 (message "Collecting email addresses...")
                (process-lines
                 "notmuch" "address" "--format=text" "--format-version=4"
                 "--output=recipients" "--deduplicate=address"
                 (mapconcat (lambda (addr) (concat "from:" addr))
                            (notmuch-user-emails)
                            " or "))
              (message "Collecting email addresses...done")))))

(defun notmuch-addr-read-recipient (prompt &optional initial-input)
  "Read a recipient in the minibuffer."
  (completing-read prompt
                   (let ((current-prefix-arg nil))
                     (notmuch-addr-query-with-words))
                   nil nil initial-input))

;;; _
(provide 'notmuch-addr)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; notmuch-addr.el ends here
