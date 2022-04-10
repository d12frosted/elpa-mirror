;;; btc-ticker.el --- Shows latest bitcoin price

;; Copyright (C) 2014  Jorge Niedbalski R.

;; Author: Jorge Niedbalski R. <jnr@metaklass.org>
;; Version: 0.1
;; Package-Version: 20220409.1647
;; Package-Commit: 2ed18ac6338d5fe98c578f0875840af07f0bc42a
;; Package-Requires: ((json "1.2") (request "0.2.0"))
;; Keywords: news

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

;;; Code:

(require 'request)
(require 'json)

(defgroup btc-ticker nil
  "btc-ticker extension"
  :group 'comms
  :prefix "btc-ticker-")

(defconst bitstamp-api-url "https://www.bitstamp.net/api/ticker/")
(defcustom btc-ticker-api-poll-interval 10
  "Default interval to poll to the bitstamp api"
  :type 'number
  :group 'btc-ticker)

(defvar btc-ticker-timer nil
  "Bitstamp API poll timer")

(defvar btc-ticker-mode-line " $0.00"
  "Displayed on mode-line")

;;very risky :)
(put 'btc-ticker-mode-line 'risky-local-variable t)

(defun btc-ticker-start()
  (unless btc-ticker-timer
    (setq btc-ticker-timer
          (run-at-time "0 sec"
                       btc-ticker-api-poll-interval
                       #'btc-ticker-fetch))
    (btc-ticker-update-status)))

(defun btc-ticker-stop()
  (when btc-ticker-timer
    (cancel-timer btc-ticker-timer)
    (setq btc-ticker-timer nil)
    (if (boundp 'mode-line-modes)
        (delete '(t btc-ticker-mode-line) mode-line-modes))))

(defun btc-ticker-update-status()
  (if (not(btc-ticker-mode))
      (progn
        (if (boundp 'mode-line-modes)
            (add-to-list 'mode-line-modes '(t btc-ticker-mode-line) t)))))

(defun btc-ticker-fetch()
  (request
    bitstamp-api-url
    :parser 'json-read
    :success (cl-function
              (lambda(&key data &allow-other-keys)
                (setq btc-ticker-mode-line
                      (concat " $" (assoc-default 'last data)))))))

;;;###autoload
(define-minor-mode btc-ticker-mode
  "Minor mode to display the latest BTC price."
  :init-value nil
  :global t
  :lighter btc-ticker-mode-line
  (if btc-ticker-mode
       (progn
        (btc-ticker-start)
         )
    (btc-ticker-stop)
    ))

(provide 'btc-ticker)
;;; btc-ticker.el ends here
